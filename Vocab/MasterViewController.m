#import "MasterViewController.h"
#import "UIImageView+AFNetworking.h"
#import "AFNetworking.h"
#import "DBLayer.h"
#import "userLayer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "Settings.h"
#import "ForvoLayer.h"

// for mp3s primarily
#define USE_WORD
// for jpegs
//#define USE_WORD_JPEGS
#define sampleRate 44100

//#define BYPASS_SOUND 1

typedef enum _wordType {
    Unknown,
    Noun,
    Adjective,
    Adverb,
    Article,
    Preposition,
    Conjunction,
    Verb,
    Other
} wordType;

typedef enum _testType {
    english2farsi,
    audio2english,
    farsi2english,
    farsi2image,
    randomized
} testType;


// Leitner Level schedule (day starts at 0, upto 63)
bool use_level(int level, int day) {
    switch (level) {
        case 2: return (day % 2 == 0); break;
        case 3: return ((day - 1) % 4 == 0); break;
        case 4: return ((day== 3) || (day == 12) || (day == 19) || (day == 28) || (day== 35) || (day == 44) || (day == 51) || (day == 60)); break;
        case 5: return ((day == 59) || (day == 43) || (day == 27) || (day == 11)); break;
        case 6: return ((day == 58) || (day == 23)); break;
        case 7: return (day == 56); break;
        case 1: return true;
        default: return false;
    }
}


@interface MasterViewController () <AVAudioPlayerDelegate,NSURLDownloadDelegate,NSSpeechSynthesizerDelegate>


@property (strong, nonatomic) NSMutableArray *imageResults;
@property (strong, nonatomic) NSMutableArray *questions;
@property (strong, nonatomic) NSArray *sortedWords;
@property (strong, nonatomic) NSMutableArray *autoIds;
@property (strong, nonatomic) NSNumber *currentLeitnerId;
@property (weak) IBOutlet NSImageView *currentImage;
@property (weak) IBOutlet NSButton *currentImage1;
@property (weak) IBOutlet NSButton *currentImage2;
@property (weak) IBOutlet NSButton *currentImage3;
@property (weak) IBOutlet NSButton *currentImage4;

@property (weak, nonatomic) IBOutlet NSTextField *Words;
@property (weak, nonatomic) IBOutlet NSTextField *English;
@property (weak, nonatomic) IBOutlet NSTextField *Translit;
@property (weak, nonatomic) IBOutlet NSTextField *Category;
@property (weak, nonatomic) IBOutlet NSTextField *Number;
@property (weak, nonatomic) IBOutlet NSButton *startTest;
@property (weak, nonatomic) IBOutlet NSButton *startEnglishToFarsi;
@property (weak, nonatomic) IBOutlet NSButton *startFarsiToEnglish;
@property (weak, nonatomic) IBOutlet NSButton *startFarsiToImage;
@property (weak, nonatomic) IBOutlet NSButton *startAudioToEnglish;

@property (weak, nonatomic) IBOutlet NSTextField *Lev0;
@property (weak, nonatomic) IBOutlet NSTextField *Lev1;
@property (weak, nonatomic) IBOutlet NSTextField *Lev2;
@property (weak, nonatomic) IBOutlet NSTextField *Lev3;
@property (weak, nonatomic) IBOutlet NSTextField *Lev4;
@property (weak, nonatomic) IBOutlet NSTextField *Lev5;
@property (weak, nonatomic) IBOutlet NSTextField *Lev6;
@property (weak, nonatomic) IBOutlet NSTextField *Lev7;
@property (weak, nonatomic) IBOutlet NSTextField *Result;

@property (weak, nonatomic) IBOutlet NSTextField *WLev0;
@property (weak, nonatomic) IBOutlet NSTextField *WLev1;
@property (weak, nonatomic) IBOutlet NSTextField *WLev2;
@property (weak, nonatomic) IBOutlet NSTextField *WLev3;
@property (weak, nonatomic) IBOutlet NSTextField *WLev4;
@property (weak, nonatomic) IBOutlet NSTextField *WLev5;
@property (weak, nonatomic) IBOutlet NSTextField *WLev6;
@property (weak, nonatomic) IBOutlet NSTextField *WLev7;


@property int CurrentId;
@property NSInteger startIndex;

@property long num_correct;
@property long num_wrong;
@property long line_count;
@property long auto_count;
@property int last_sel;
@property long table_size;
@property int test_sel;

@property int dayCount;
@property bool doing_exam;
@property bool doing_startup;
@property (strong, nonatomic) NSMutableDictionary *TodaysWords;

@property (strong, nonatomic) NSMutableArray *wordsMoved;
@property (strong, nonatomic) Settings *saved_settings;

@property (nonatomic, strong) IBOutlet NSSegmentedControl *timed;
//@property (nonatomic, strong) IBOutlet TextView *textView;
@property (nonatomic, weak) IBOutlet NSSlider *index_slider;
//@property (nonatomic, weak) IBOutlet NSSegmentedControl *wordcat;
//@property (nonatomic, weak) IBOutlet NSSegmentedControl *levelcat;

@property (strong, nonatomic) userLayer *user_layer;
@property (strong, nonatomic) DBLayer *db_layer;
@property (strong, nonatomic) AVAudioPlayer *player;




@property (nonatomic) BOOL sharing;
//@property (nonatomic, strong) NSMutableArray *selectedPhotos;

@property bool playing;
//@property (nonatomic,strong) NSTimer*                timer;

@property (nonatomic, retain) NSTimer *auto_timed;

@end

@implementation MasterViewController

@synthesize CurrentId;

@synthesize num_correct;
@synthesize num_wrong;
@synthesize line_count;
@synthesize auto_count;
@synthesize Words;
@synthesize English;
@synthesize Translit;
@synthesize Category;
@synthesize imageResults;
//@synthesize textView;
@synthesize last_sel;
@synthesize player;

@synthesize startTest;
@synthesize startEnglishToFarsi;
@synthesize startFarsiToEnglish;
@synthesize startFarsiToImage;
@synthesize startAudioToEnglish;

//@synthesize status;

//@synthesize wordcat;
//@synthesize levelcat;
@synthesize index_slider;

@synthesize db_layer;
@synthesize user_layer;
@synthesize startIndex;

@synthesize table_size;
@synthesize saved_settings;
@synthesize dayCount;
@synthesize currentLeitnerId;
@synthesize TodaysWords;
@synthesize wordsMoved;
@synthesize doing_exam;
@synthesize doing_startup;

@synthesize playing;
//@synthesize timer;
@synthesize timed;

@synthesize auto_timed;
@synthesize sortedWords;
@synthesize autoIds;
@synthesize test_sel;


#pragma mark - S3 Layer interfaces (from optionsview)
-(void)get_s3_mp3s {
}
-(void)get_s3_jpgs {
}
-(void)get_s3_files {
}

-(void)upload_file {
}

-(NSString *)getImagePathFor:(long)j {
    long s = [db_layer getImageNumber:j];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"jpegs" ofType:@"bundle"];
    NSString *filename = [NSString stringWithFormat:@"%04ld", s];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *fname = [bundle pathForResource:filename ofType:@"jpg"];
    return fname;
}


-(NSString *)getCurrentImageFilePath {
    // Check Documents Directory!!! (no longer look in bundle!)
    // MyLog(@"checking %@ in documents dir",aud);
    NSString *imageFilePath = [self getImagePathFor:[db_layer getCurrentId]];
    return imageFilePath;
}


-(NSString *)getCurrentMP3FilePath {
    // Check Documents Directory!!! (no longer look in bundle!)
    // MyLog(@"checking %@ in documents dir",aud);
    NSString *docsDir;
    NSArray *dirPaths;
    
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    docsDir = dirPaths[0];
    
    // Build the path to the document dir + file
#ifdef USE_WORD
    NSString *aud = [db_layer getCurrentWord];
    NSString *filePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:
                                                           [NSString stringWithFormat:@"/mp3s/%@.mp3", aud]]];
#else
    NSString *filePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:
                                                           [NSString stringWithFormat:@"/mp3s/%04d.mp3", [db_layer getCurrentId]]]];
#endif
    
    return filePath;
}

-(NSString *)getRecordingMP3FilePath {
    
    // Get the documents directory
    NSArray  *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    
    // Assume we will record & thus create directoy if it doesn't exist
    NSString *upload_dir = [NSString stringWithFormat:@"%@/recording", docsDir];
    BOOL dirExists = [[NSFileManager defaultManager] fileExistsAtPath:upload_dir];
    if (!dirExists) {
        [[NSFileManager defaultManager] createDirectoryAtPath:upload_dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // Build the path to the document dir + file
#ifdef USE_WORD
    NSString *aud = [db_layer getCurrentWord];
    NSString *filePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:
                                                           [NSString stringWithFormat:@"/recording/%@.mp3", aud]]];
#else
    NSString *filePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:
                                                           [NSString stringWithFormat:@"/recording/%04d.mp3", [db_layer getCurrentId]]]];
#endif
    
    return filePath;
}


- (NSInteger)numberOfDaysFromStart {
    NSDate* now = [NSDate date];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorianCalendar components:NSDayCalendarUnit fromDate:[user_layer get_start_date] toDate:now options:0];
    return [components day];
}

-(void)getTodaysWords {
    NSMutableArray *wordsAtCurrentLevel  = [user_layer getIDListforToday];
    for (NSNumber *w in wordsAtCurrentLevel) {
        [TodaysWords setObject:[NSNumber numberWithInt:0] forKey:w];
    }
}

-(void)InitSession {
    num_correct = 0;
    num_wrong = 0;
    [saved_settings load];
    line_count = saved_settings.lineCount;
    int newDayCount = (int)[self numberOfDaysFromStart];
    
    if (newDayCount > dayCount) {
        saved_settings.dayCount = newDayCount;
        [saved_settings save];
    }
    [self getTodaysWords];
    //Category.text = [NSString stringWithFormat:@"%d",LeitnerLevel];
    [self HighLightLevel];
    
}


-(void)hideQuiz {
    
    self.currentImage1.hidden = true;
    self.currentImage2.hidden = true;
    self.currentImage3.hidden = true;
    self.currentImage4.hidden = true;
    self.currentImage.hidden = false;
    doing_startup = false;
    doing_exam = false;
    self.Category.hidden = false;
    self.Translit.hidden = false;
//    self.unknown.hidden = true;
  //  self.showWord.hidden = true;
    
}
-(void)showQuiz {
    self.currentImage1.hidden = false;
    self.currentImage2.hidden = false;
    self.currentImage3.hidden = false;
    self.currentImage4.hidden = false;
    self.currentImage.hidden = true;
    self.Category.hidden =  false; ////true;
    self.Translit.hidden = true;
//    self.unknown.hidden = false;
 //   self.showWord.hidden = false;
    
}
-(void)HighLightLevel {
    [self showLevels];
    
    [self.Lev0 setBackgroundColor:[NSColor blueColor]];
    [self.Lev1 setBackgroundColor:[NSColor blueColor]];
    [self.Lev2 setBackgroundColor:[NSColor blueColor]];
    [self.Lev3 setBackgroundColor:[NSColor blueColor]];
    [self.Lev4 setBackgroundColor:[NSColor blueColor]];
    [self.Lev5 setBackgroundColor:[NSColor blueColor]];
    [self.Lev6 setBackgroundColor:[NSColor blueColor]];
    [self.Lev7 setBackgroundColor:[NSColor blueColor]];
    
    int lev = [user_layer getCurrentSoundRating];
    switch (lev) {
        case 0: [self.Lev0 setBackgroundColor:[NSColor redColor]]; break;
        case 1: [self.Lev1 setBackgroundColor:[NSColor redColor]]; break;
        case 2: [self.Lev2 setBackgroundColor:[NSColor redColor]]; break;
        case 3: [self.Lev3 setBackgroundColor:[NSColor redColor]]; break;
        case 4: [self.Lev4 setBackgroundColor:[NSColor redColor]]; break;
        case 5: [self.Lev5 setBackgroundColor:[NSColor redColor]]; break;
        case 6: [self.Lev6 setBackgroundColor:[NSColor redColor]]; break;
        case 7: [self.Lev7 setBackgroundColor:[NSColor redColor]]; break;
    }
}
-(void)showLevels {
    [self.Lev0 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:0]]];
    [self.Lev1 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:1]]];
    [self.Lev2 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:2]]];
    [self.Lev3 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:3]]];
    [self.Lev4 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:4]]];
    [self.Lev5 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:5]]];
    [self.Lev6 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:6]]];
    [self.Lev7 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:7]]];
}

-(void)showPastLevels {
    [self.WLev0 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:0]]];
    [self.WLev1 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:1]]];
    [self.WLev2 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:2]]];
    [self.WLev3 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:3]]];
    [self.WLev4 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:4]]];
    [self.WLev5 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:5]]];
    [self.WLev6 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:6]]];
    [self.WLev7 setStringValue:[NSString stringWithFormat:@"%d",[user_layer getNumberWordsforLevel:7]]];
}

-(IBAction)StartTest:(id)sender {

    if (sender == startEnglishToFarsi) {
        test_sel = english2farsi;
    } else if (sender == startFarsiToEnglish) {
        test_sel = farsi2english;
    } else if (sender == startFarsiToImage) {
        test_sel = farsi2image;
    } else if (sender == startAudioToEnglish) {
        test_sel = audio2english;
    } else {
        test_sel = randomized;
    }
    
    // Already doing something, just change test_sel & return
    if (doing_exam || doing_startup) {
        if (doing_startup) {
            doing_startup = [self ContinueStartUp];
        } else {
            doing_exam = [self ContinueSession];
        }
    } else {
        
            
        [saved_settings load];
        dayCount = (int)saved_settings.dayCount;
        //dayCount = (int)[self numberOfDaysFromStart];
        
        NSString *mess = [NSString stringWithFormat:@" You have \n"];
        for (int i=0;i<LLEVELS+1;i++) {
            int num  = [user_layer getNumberWordsforLevel:i];
            mess = [NSString stringWithFormat:@"%@ %d words at level %d\n",mess,num,i];
        }
        [self showLevels];
        
        [self getTodaysWords];
        NSString *list = [NSString stringWithFormat:@"\n\nYou are on day %d\n%ld words to review\n",dayCount,[TodaysWords count]];
        
        if (!doing_exam && (auto_timed == nil) && ([TodaysWords count] > 0)) {
            mess = [NSString stringWithFormat:@"%@ %@Would you like to start self-test?\n",mess,list];
            NSAlert *testAlert = [NSAlert alertWithMessageText:@"Please answer"
                                                 defaultButton:@"Yes"
                                               alternateButton:@"No"
                                                   otherButton:nil
                                     informativeTextWithFormat:@"%@", mess];
            NSInteger result = [testAlert runModal];
            switch(result)
            {
                case NSAlertDefaultReturn:
                    doing_exam = true;
                    [self InitSession];
                    doing_exam = [self ContinueSession];
                    break;
                    
                case NSAlertAlternateReturn:
                    doing_exam = false;
                    break;
            }
        } else {
            mess = [NSString stringWithFormat:@"%@ %@",mess,list];
            [self showAlertMessage:mess withTitle:@"Notice"];
        }
    }
    
}

-(bool)ContinueStartUp {
    if ([TodaysWords  count] == 0) {
        NSString *mess = [NSString stringWithFormat:@"You got %ld words correct and %ld words wrong\n",num_correct,num_wrong];
        [self showAlertMessage:mess withTitle:@"Well Done!"];
        [user_layer save];
        return false;
    }
    // Just get 1st element of dictionary each time, since removing it shortly after
    currentLeitnerId = [[TodaysWords allKeys] objectAtIndex:0];
    line_count = [currentLeitnerId intValue];
    
    [db_layer findMeaning:(int)line_count];
    [TodaysWords removeObjectForKey:currentLeitnerId];
    saved_settings.lineCount = line_count;
    [saved_settings save];
    table_size = (int)[user_layer getTableSize];
    
    [user_layer readDB:(int)line_count];
    [self.Words setStringValue:[db_layer getCurrentWord]];
    [self.English setStringValue:[db_layer getUpdatedMeaning]];
    [self.Category setStringValue:[db_layer getCurrentCategory]];
    
    [self HighLightLevel];

    [self getQuestions];
    [self playForeign];
    [self showEnglishTexts];
    self.Words.hidden = true;
    [self.Number setStringValue:[NSString stringWithFormat:@"%ld",[TodaysWords count]]];
    
    [self clearShowResult];
    return true;
}

// Returns false when done
-(bool)ContinueSession {
    if ([TodaysWords  count] == 0) {
        NSString *mess = [NSString stringWithFormat:@"You are done for the day!\n"];
        for (int i=0;i<LLEVELS+1;i++) {
            int num  = [user_layer getNumberWordsforLevel:i];
            mess = [NSString stringWithFormat:@"%@ %d words at level %d\n",mess,num,i];
        }
        [self showAlertMessage:mess withTitle:@"No more words"];
        [user_layer save];
        return false;
    }
    // Just get 1st element of dictionary each time, since removing it shortly after
    currentLeitnerId = [[TodaysWords allKeys] objectAtIndex:0];
    line_count = [currentLeitnerId intValue];
    
    [self.Words setStringValue:[db_layer getCurrentWord]];
    [self.Category setStringValue:[db_layer getCurrentCategory]];

    MyLog(@" Getting %ld line_count from leitner ",line_count);
    [TodaysWords removeObjectForKey:currentLeitnerId];
    saved_settings.lineCount = line_count;
    [saved_settings save];
    table_size = (int)[user_layer getTableSize];
    
    [db_layer findMeaning:(int)line_count];
    [user_layer readDB:(int)line_count];
    [self.Words setStringValue:[db_layer getCurrentWord]];
    [self.English setStringValue:[db_layer getUpdatedMeaning]];
    [self getQuestions];
    long ttype = test_sel;
    if (test_sel == randomized) {
        ttype = rand() % NUM_TEST_TYPES;
        // if same as previous test for this word, increment so as to change the test type
        if (ttype == [user_layer getTestType]) ttype = (ttype + 1) % NUM_TEST_TYPES;
    }
    
    switch (ttype) {
        case farsi2english:  [self showEnglishTexts]; break;
        case audio2english: [self playForeign]; [self showEnglishTexts];  self.Words.hidden = true; break;
        case farsi2image: [self showImages]; break;
        case english2farsi:  [self showFarsiTexts]; break;
    }
    [self.Number setStringValue:[NSString stringWithFormat:@"%ld",[TodaysWords count]]];

    return true;
}

#pragma mark - View

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        db_layer = [[DBLayer alloc] init];
        user_layer = [[userLayer alloc] init];
        int db_size = (int)[db_layer getTableSize];
        [user_layer setup:db_size];
        
        sortedWords = [db_layer getSortedWordList];
        TodaysWords = [[NSMutableDictionary alloc] init];
        currentLeitnerId = [[NSNumber alloc] init];
        doing_exam = false;
        
        srand(0x11123247);
        
        saved_settings = [[Settings alloc] init];
        line_count = saved_settings.lineCount;
        if (line_count > db_size) line_count = 1;
        auto_count = saved_settings.autoCount;
        
        self.imageResults = [[NSMutableArray alloc] init];
        self.questions = [[NSMutableArray alloc] init];

        //self.imageResults = [NSMutableArray arrayWithObjects:nil];
        //self.questions = [NSMutableArray arrayWithObjects:nil];
        
        startIndex = 1;
        last_sel = 0;
        
        // Fix to compare dates only??
        dayCount = (int)[self numberOfDaysFromStart];
        saved_settings.dayCount = dayCount;
        saved_settings.lineCount = line_count;
        [saved_settings save];
        
       
    }
    
    return self;

}

-(void)fixLevel1 {
    NSMutableArray *wordsAtCurrentLevel  = [user_layer getIDListforLevel:1];
    for (NSNumber *w in wordsAtCurrentLevel) {
        [user_layer clearSoundRatingForID:[w integerValue]];
    }
}




// Needed since no viewDidLoad!
-(void)awakeFromNib {
    [self InitSession];
    
    if ([TodaysWords count] > 0) {
        
        NSString *mess = [NSString stringWithFormat:@" You have \n"];
        for (int i=0;i<LLEVELS+1;i++) {
            int num  = [user_layer getNumberWordsforLevel:i];
            mess = [NSString stringWithFormat:@"%@ %d words at level %d\n",mess,num,i];
        }
        [self showLevels];
        
        [self showPastLevels];

        NSAlert *testAlert = [NSAlert alertWithMessageText:mess
                                         defaultButton:@"Yes"
                                       alternateButton:@"No"
                                           otherButton:nil
                             informativeTextWithFormat:@"Would you like to review new words?"];
        NSInteger result = [testAlert runModal];
        switch(result)
        {
            case NSAlertDefaultReturn:
                doing_startup = true;
                doing_startup = [self ContinueStartUp];
                break;
            case NSAlertAlternateReturn: ;break;
        }
    } else {
        [self findMeaning];
    }
    
}

-(void)autoUpdate {
    int autotable_size = (int)[autoIds count];
    auto_count = ((auto_count + 1) % (autotable_size-1));
    line_count = [[autoIds objectAtIndex:auto_count] intValue];
    saved_settings.lineCount = line_count;
    saved_settings.autoCount = auto_count;
    [saved_settings save];
    [self findMeaning];
    
    if ([self haveAudio]) {
        [self playEnglishAudio];
    } else {
        [self autoUpdate]; // go to next line
    }
    [self.Number setStringValue:[NSString stringWithFormat:@"%ld/%d",auto_count,autotable_size]];

    
}
-(bool)haveAudio {
    bool notZero = false;
    NSString *soundFilePath = [self getCurrentMP3FilePath];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:soundFilePath];
    if (fileExists) {
        NSInteger size =  [self getFileSize:soundFilePath];
        notZero = (size > 1000);
    }
    // FOR DEBUG of DB!!
#ifdef NEEDTAG
    if (!notZero) {
        [db_layer setWordClass:-1];
    } else {
        [db_layer setWordClass:0];
    }
#endif
    return notZero;
}

#ifdef USING_CVIEW_IOS

- (void)handleLongPressGesture:(NSLongPressGestureRecognizer*)recognizer {
    // 1
    if (recognizer.state == NSGestureRecognizerStateRecognized)
    {
        // 2
        CGPoint tapPoint =
        [recognizer locationInView:self.collectionView];
        
        // 3
        NSIndexPath *item =
        [self.collectionView
         indexPathForItemAtPoint:tapPoint];
        
        // 4
        if (item) {
            // 5
            //////           NSString *searchTerm = self.searches[item.item];
            
            // 6
            //     [self.searches removeObjectAtIndex:item.item];
            //   [self.searchResults removeObjectForKey:searchTerm];
            
            // 7
            [self.collectionView performBatchUpdates:^{
                [self.collectionView
                 deleteItemsAtIndexPaths:@[item]];
            } completion:nil];
        }
    }
}
#endif

// Category for Leitner testing. Can be Sound/Image or Text
//- (IBAction)levelcat_changed:(id)sender {
    //  MyLog(@" wordcat is %d",wordcat.selectedSegmentIndex);
    ////    [db_layer setWordcat:wordcat.selectedSegmentIndex];
//}

//- (IBAction)wordcat_changed:(id)sender {
    //  MyLog(@" wordcat is %d",wordcat.selectedSegmentIndex);
//////    [db_layer setWordClass:wordcat.selectedSegmentIndex];
//}

-(IBAction)set_index:(NSSlider *)sender {
    [self hideQuiz];
    float fractional_index = [sender doubleValue];
    table_size = (int)[db_layer getTableSize];
    line_count = (int)floor(fractional_index * table_size + 0.5);
    [db_layer findMeaning:(int)line_count];
    [user_layer readDB:(int)line_count];
////    index_slider.popover.textLabel.text = [NSString stringWithFormat:@"%@",[db_layer getOriginalMeaning]];

    // from index_done.....
    saved_settings.lineCount = line_count;
    [saved_settings save];
    [self findMeaning]; // Update GUI


}
-(IBAction)index_done:(NSSlider *)sender {
    
    saved_settings.lineCount = line_count;
    [saved_settings save];
    [self findMeaning]; // Update GUI
}

#pragma mark -Database

- (void)Word_Update {
    long l;
    table_size = (int)[db_layer getTableSize];
    l = line_count + 1;
    line_count = (l % (table_size));
    if (line_count == 0) line_count = table_size;
    saved_settings.lineCount = line_count;
    [saved_settings save];
    [self findMeaning];
}

// From "stepper" action
- (IBAction)Word_Changed:(NSStepper *)dir {
    [saved_settings load];
    if (doing_exam) {
        // Move on without question
        doing_exam = [self ContinueSession];
    } else {
        [self hideQuiz];
        if ((int)[dir integerValue] > last_sel) {
            [self Word_Update];
        } else {
            line_count--;
            if (line_count < 1) line_count = table_size;
            saved_settings.lineCount = line_count;
            [saved_settings save];
            table_size = (int)[db_layer getTableSize];
            [self findMeaning];
        }
    }
    last_sel = (int)[dir integerValue];
    /////    MyLog(@"Stepper = %g line_count = %d",[dir value],line_count);
}

// TODO:
// Update Leitner level, category, show category?

- (void)findMeaning {
    //    bool should_hide = false; // Dont use as hide for now, just for marking
    
    if (saved_settings.use_sorted) {
        int lc = [[sortedWords objectAtIndex:line_count] intValue];
        [db_layer findMeaning:lc];
        [user_layer readDB:lc];
    } else {
        [db_layer findMeaning:(int)line_count];
        [user_layer readDB:(int)line_count];
        // should_hide = [db_layer getCurrentHidden];
    }
    
    self.title = [NSString stringWithFormat:@"#%d,level %d",[db_layer getCurrentId],(int)[user_layer getCurrentSoundRating]];
    
    [self.Words setStringValue:[db_layer getCurrentWord]];
    [self.English setStringValue:[db_layer getUpdatedMeaning]];
    [self.Translit setStringValue:[db_layer getCurrentTranslit]];
    [self.Category setStringValue:[db_layer getCurrentCategory]];
    
    bool has_jpg = [self hasImage];
    if (has_jpg) {
        [self showSavedImage:has_jpg];
    } else {
/////        [self doSearch];
    }
        //    NSString *aud = [db_layer getCurrentWord];
        //   [self copySavedImage:[db_layer getCurrentImage] withDest:[db_layer getCurrentWord]];
    [self loadAudio];
    //[self.hide setOn:should_hide]; // set if needed but dont hide
////    self.wordcat.selectedSegmentIndex = [db_layer getWordClass];
    [self update_slider];
}
-(void)update_slider {
    // Update slider
    int index = [db_layer getCurrentId];
    table_size = (int)[db_layer getTableSize];
    float fractional_index = (float)index/table_size;
    [self.index_slider setDoubleValue:fractional_index];
//    index_slider.popover.textLabel.text = [NSString stringWithFormat:@"%@",[db_layer getOriginalMeaning]];
    
}



#pragma mark - Image Stuff

- (void)doSearch {
    NSInteger start = 1;
   // NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ajax.googleapis.com/ajax/services/search/images?v=1.0&as_filetype=jpg&q=%@&start=%u", [[db_layer getCurrentSearch] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],(unsigned)start]];
    
    //https://www.google.com/search?q=%D8%A2%D9%81%D8%B1%D9%8A%D9%82%D8%A7&hl=fa&biw=1152&bih=671&tbm=isch&source=lnms
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://ajax.googleapis.com/ajax/services/search/images?v=1.0&as_filetype=jpg&q=%@&start=%u", [[db_layer getCurrentSearch] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],(unsigned)start]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    MyLog(@" Searching with \"%@\" : \"%@\"",[db_layer getCurrentSearch],[db_layer getCurrentWord]);
    startIndex = 1;
    // do we need next line?
    if (self.imageResults)  [self.imageResults removeAllObjects];
    else self.imageResults = [[NSMutableArray alloc] init];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        /////MyLog(@"JSON: %@", responseObject);
        id results = [responseObject valueForKeyPath:@"responseData.results"];
        //MyLog(@"Results are :%@",results);
        //MyLog(@"The count of images (AFHTTP):%u",(unsigned)self.imageResults.count);
        if ([results isEqual:[NSNull null]]) {
            MyLog(@"results isEqual:[NSNull null]");
        } else {
            if ([results count] > 0) {
                for (int i=0;i<[results count];i++) {
                    NSURL *o = [NSURL URLWithString:[[results objectAtIndex:i] valueForKey:@"url"]];
                    [self.imageResults addObject:o];
                    MyLog(@"URL :%@",o);
                }
                NSURL *down = [NSURL URLWithString:[[results objectAtIndex:0] valueForKey:@"url"]];
                [self startDownloadingURL:down];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        MyLog(@" Failed to get images \n");
    }];
    [operation start];
}


- (void)startDownloadingURL:(NSURL *)url
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:req progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        
#ifdef USE_WORD_JPEGS
        NSString *aud = [db_layer getCurrentWord];
        NSString *fname = [NSString stringWithFormat:@"/jpegs/%@.jpg", aud];
#else
        NSString *fname = [self getImagePathFor:[db_layer getCurrentId]];
#endif
        return [documentsDirectoryURL URLByAppendingPathComponent:fname];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        MyLog(@"File downloaded to: %@", filePath);
        [self showSavedImage:true];
        [db_layer saveImageData:url];
    }];
    [downloadTask resume];
}

// if we already have .jpg, show it as single image in 'currentImage', else use collectionView/downloaded images
- (void)showSavedImage:(bool)has {
    if (has) {
        NSString *destPath = [self getCurrentImageFilePath];
        NSImage *prodImg = [[NSImage alloc] initWithContentsOfFile:destPath];
        
///        self.currentImage.contentMode = .ScaleAspectFit
        [self.currentImage setImage:prodImg];
        self.currentImage.hidden = false;
    } else {
        [self.currentImage setImage:nil];
        self.currentImage.hidden = true;
        
        NSDictionary *results = [NSDictionary dictionaryWithObjectsAndKeys:[db_layer getCurrentImage], @"url", nil];
        [self.imageResults removeAllObjects];
        [self.imageResults addObject:results];
    }
    
}

// For copying image to Documents/jpeg folder (for later upload to s3)
// NOT_USED

- (void)copySavedImage:(NSString *)src withDest:(NSString *)dest {
    
    // Setup Destination 1st
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    // Build the path to the document dir + "jpeg" dir + file, Create DIR if needed
    
    NSString *Download_dir = [NSString stringWithFormat:@"%@/jpegs", docsDir];
    
    BOOL jpegDirExists = [[NSFileManager defaultManager] fileExistsAtPath:Download_dir];
    
    if (!jpegDirExists) {
        [[NSFileManager defaultManager] createDirectoryAtPath:Download_dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    NSString *destPath = [[NSString alloc] initWithString:[Download_dir stringByAppendingPathComponent:
                                                           [NSString stringWithFormat:@"%@.jpg", dest]]];
    
    
    // Now download op
    NSURL *p = [NSURL URLWithString:src];
    NSURLRequest *request = [NSURLRequest requestWithURL:p];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        MyLog(@" Downloaded %@\n",p);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        MyLog(@" Failed to get %@\n",p);
    }];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:destPath append:NO];
    [operation start];
    
}
// Not used
-(void)downloadJpegs {
    
    NSDictionary *wordlist = [db_layer getImageList];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        for (id w in wordlist) {
            NSString *word = [NSString stringWithFormat:@"%@",w];
            NSString *url = [wordlist objectForKey:w];
            [self copySavedImage:url withDest:word];
        }
    });
}


#pragma mark - Audio Stuff
-(void)loadAudio {
    NSString *soundFilePath = [self getCurrentMP3FilePath];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:soundFilePath];
    
    if (fileExists) {
        
        // FIXME -> Force sound field if mp3 exists
        /// [db_layer setSound:@"yes"];
        
        ////
        
    } else {
        //if (saved_settings.use_forvo) {
        //    [ForvoLayer get_forvo_mp3:[db_layer getCurrentWord]];
        //} else {
        //.....   [user_layer SetSoundRatingDone]; // FIXME, to avoid getting stuck
        //}
    }
}

// Look for .jpg in Documents directory
-(bool)hasImage {
    NSString *imageFilePath = [self getCurrentImageFilePath];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:imageFilePath];
    return fileExists;
}


-(void)playEnglishAudio {
    
    NSSpeechSynthesizer *speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:[NSSpeechSynthesizer defaultVoice]];
    
    [speechSynth setDelegate:self];
    // synthesizes text into a sound (AIFF) file
    [speechSynth startSpeakingString:[db_layer getUpdatedMeaning]];

    // wait until async speech is complete
    /*
    sleep(1);
    while([speechSynth isSpeaking]) {
        sleep(1);
    }
     */
}

-(void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {
   // Not used...
    [self playForeign];
    
}


#pragma mark - AVAudioPlayerDelegate
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if ([timed isSelectedForSegment:1]) {
        [self autoUpdate];
    }
}




- (void)getQuestions {
    if (self.questions)  [self.questions removeAllObjects];
    else self.questions = [[NSMutableArray alloc] init];

    
    int random_index = rand() % 4;
    int random_line=1;
    
    int random_line0 = -1;
    int random_line1 = -1;
    int random_line2 = -1;
    
//    int ref_class = [db_layer getWordClass];
//    bool class_ok = !(ref_class == Verb); // Extend as needed
    
    NSString *ref_category = [db_layer getCurrentCategory];
    //MyLog(@" reference category is %@",ref_category);
    bool cat_ok = false;
    const int max_random_attempts = 32;
    int random_attempts = 0;
    
    for (int i=0;i<4;i++) {
        if (i==random_index) random_line = (int)line_count;
        else {
            random_line = (rand() % (table_size-1)) + 1;
            // make sure we dont have same line as reference or any other cases
            random_attempts = 0;
            while ((!cat_ok)
                   || (random_line == (int)line_count)
                   || (random_line == random_line0)
                   || (random_line == random_line1)
                   || (random_line == random_line2)
                   ) {
                random_line = (rand() % (table_size-1)) + 1;
                cat_ok = [db_layer checkCategory:random_line forCategory:ref_category];
                random_attempts++;
                if (random_attempts > max_random_attempts) {
                    MyLog(@"Category ref = %@, tried %d times",ref_category,random_attempts);
                    cat_ok = true; //Break out after max attempts
                }
            }
        }
        switch (i) {
            case 0: random_line0 = random_line; break;
            case 1: random_line1 = random_line; break;
            case 2: random_line2 = random_line; break;
        }
        [self.questions addObject:[NSNumber numberWithInt:random_line]];
        cat_ok = false;
        //// MyLog(@" image %d is %d",i,random_line);
    }
    //restore
    [db_layer findMeaning:line_count];
    
}
-(void)clearShowResult {
    [self.Result setStringValue:@""];
}


-(void)showResult:(bool)correct {
    if (correct) {
        [self.Result setStringValue:@"Correct"];
        num_correct++;
    } else {
        [self.Result setStringValue:@"Wrong"];
        num_wrong++;
    }
    //self.Result.hidden = false;
    [self HighLightLevel];
    
    // Add delay!!!!
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(afterShow) userInfo:nil repeats:NO];

}
-(void)afterShow {
    // Move on either way....
    if (doing_startup)  doing_startup = [self ContinueStartUp];
    else
        doing_exam = [self ContinueSession];
}
-(void)checkResult:(bool)correct {
    if (correct) {
        //[self showAlertMessage:@"Correct!" withTitle:@"Result"];
        // if SoundRating = -1, this should move to 7, regardless of startup
        // although should only be -1 on startup (unless skipped/restarted?)
        [user_layer incrementSoundRating];
        
    } else {
        MyLog(@" %@ is correct answer for %@",[db_layer getCurrentWord],[db_layer getOriginalMeaning]);
        if (!doing_startup) {
            long words_left = [TodaysWords  count];
            NSString *title = [NSString stringWithFormat:@"%ld words to go", words_left];
            
            // Go back to original
            [db_layer findMeaning:line_count];
            NSString *word = [db_layer getCurrentWord];
            NSString *meaning = [db_layer getOriginalMeaning];
            NSString *message = [NSString stringWithFormat:@"Wrong : %@ - %@", word,meaning];
            [self showAlertMessage:message withTitle:title];
        }
        if (doing_startup) [user_layer clearSoundRating];
        else               [user_layer resetSoundRating];
    }
    
    [self showResult:correct];

    
}
- (IBAction)unknown:(id)sender {

    if (!doing_startup) {
        long words_left = [TodaysWords  count];
        NSString *title = [NSString stringWithFormat:@"%ld words to go", words_left];
            
        // Go back to original
        [db_layer findMeaning:line_count];
        NSString *word = [db_layer getCurrentWord];
        NSString *meaning = [db_layer getOriginalMeaning];
        NSString *message = [NSString stringWithFormat:@"Wrong : %@ - %@", word,meaning];
        [self showAlertMessage:message withTitle:title];
    }
    if (doing_startup) [user_layer clearSoundRating];
    else               [user_layer resetSoundRating];
 
    [self HighLightLevel];
    
    if (self.English.hidden == false) {
        [self afterUnknown];
    } else {
        [self.English setStringValue:[db_layer getOriginalMeaning]];
        self.English.hidden = false;
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(afterUnknown) userInfo:nil repeats:NO];
    }
}

-(void)afterUnknown {
    // Move on either way....
    if (doing_startup)  doing_startup = [self ContinueStartUp];
    else if (doing_exam)   doing_exam = [self ContinueSession];
    self.English.hidden = true;

}

- (IBAction)playQuestion1:(id)sender {
    if (self.questions) {
        long l = [[self.questions objectAtIndex:0] integerValue];
        [db_layer findMeaning:l];
        [user_layer readDB:l];
        //if ((test_sel != audio2english) && (test_sel != farsi2english)) [self playForeign];
//        MyLog(@" Reference line count is %ld, this is %ld",self.line_count,l);
        if (l!=line_count) {
            //   [self.currentImage1 setBackgroundColor:[UIColor redColor]];
            long l2 = [[self.questions objectAtIndex:1] integerValue];
            long l3 = [[self.questions objectAtIndex:2] integerValue];
            if (l2 == line_count) {
                [[self.currentImage2 cell] setBackgroundColor:[NSColor greenColor]];
            } else if (l3 == line_count) {
                [[self.currentImage3 cell] setBackgroundColor:[NSColor greenColor]];
            } else {
                [[self.currentImage4 cell] setBackgroundColor:[NSColor greenColor]];
            }
            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(incorrect) userInfo:nil repeats:NO];
        } else {
            [[self.currentImage1 cell] setBackgroundColor:[NSColor greenColor]];
            [self checkResult:(l==line_count)];
            //        MyLog(@" Reference line count is %ld, this is %ld",self.line_count,l);
        }

    }
}
- (IBAction)playQuestion2:(id)sender {
    if (self.questions) {
        long l = [[self.questions objectAtIndex:1] integerValue];
        [db_layer findMeaning:l];
        [user_layer readDB:l];
        //if ((test_sel != audio2english) && (test_sel != farsi2english)) [self playForeign];
//        MyLog(@" Reference line count is %ld, this is %ld",self.line_count,l);
        if (l!=line_count) {
            //   [self.currentImage1 setBackgroundColor:[UIColor redColor]];
            long l4 = [[self.questions objectAtIndex:3] integerValue];
            long l3 = [[self.questions objectAtIndex:2] integerValue];
            if (l4 == line_count) {
                [[self.currentImage4 cell] setBackgroundColor:[NSColor greenColor]];
            } else if (l3 == line_count) {
                [[self.currentImage3 cell] setBackgroundColor:[NSColor greenColor]];
            } else {
                [[self.currentImage1 cell] setBackgroundColor:[NSColor greenColor]];
            }
            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(incorrect) userInfo:nil repeats:NO];
        } else {
            [[self.currentImage2 cell] setBackgroundColor:[NSColor greenColor]];
            [self checkResult:(l==line_count)];
        }
     }
}
- (IBAction)playQuestion3:(id)sender {
    if (self.questions) {
        long l = [[self.questions objectAtIndex:2] integerValue];
        [db_layer findMeaning:l];
        [user_layer readDB:l];
        //if ((test_sel != audio2english) && (test_sel != farsi2english)) [self playForeign];
        if (l!=line_count) {
            //   [self.currentImage1 setBackgroundColor:[UIColor redColor]];
            long l1 = [[self.questions objectAtIndex:0] integerValue];
            long l2 = [[self.questions objectAtIndex:1] integerValue];
            if (l1 == line_count) {
                [[self.currentImage1 cell] setBackgroundColor:[NSColor greenColor]];
            } else if (l2 == line_count) {
                [[self.currentImage2 cell] setBackgroundColor:[NSColor greenColor]];
            } else {
                [[self.currentImage4 cell] setBackgroundColor:[NSColor greenColor]];
            }
            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(incorrect) userInfo:nil repeats:NO];
        } else {
            [[self.currentImage3 cell] setBackgroundColor:[NSColor greenColor]];
            [self checkResult:(l==line_count)];
            //        MyLog(@" Reference line count is %ld, this is %ld",self.line_count,l);
        }
     }
}
- (IBAction)playQuestion4:(id)sender {
    if (self.questions) {
        long l = [[self.questions objectAtIndex:3] integerValue];
        [db_layer findMeaning:l];
        [user_layer readDB:l];
        //if ((test_sel != audio2english) && (test_sel != farsi2english)) [self playForeign];
        if (l!=line_count) {
            //   [self.currentImage1 setBackgroundColor:[UIColor redColor]];
            long l2 = [[self.questions objectAtIndex:1] integerValue];
            long l3 = [[self.questions objectAtIndex:2] integerValue];
            if (l2 == line_count) {
                [[self.currentImage2 cell] setBackgroundColor:[NSColor greenColor]];
            } else if (l3 == line_count) {
                [[self.currentImage3 cell] setBackgroundColor:[NSColor greenColor]];
            } else {
                [[self.currentImage1 cell] setBackgroundColor:[NSColor greenColor]];
            }
            [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(incorrect) userInfo:nil repeats:NO];
        } else {
            [[self.currentImage4 cell] setBackgroundColor:[NSColor greenColor]];
            //   [self.currentImage1 setBackgroundColor:[UIColor redColor]];
            [self checkResult:(l==line_count)];
        }
    }
}

-(void)incorrect {
    [self checkResult:false];
}

- (void)showImages {
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Usually doesnt work since same word should have 2 images (i.e 'dar' for 'in' and 'door')
    
    self.English.hidden = true;
    self.Words.hidden = false;
    [self showQuiz];
    [self.currentImage1 setTitle:@""];
    [self.currentImage2 setTitle:@""];
    [self.currentImage3 setTitle:@""];
    [self.currentImage4 setTitle:@""];

    
    for (int i=0;i<4;i++) {
        NSNumber *num = [self.questions objectAtIndex:i];
        NSString *imageFilePath = [self getImagePathFor:[num integerValue]];
        NSImage *prodImg = [[NSImage alloc] initWithContentsOfFile:imageFilePath];
        if (i==0) {
            [self.currentImage1 setImage:prodImg];
        } else if (i==1) {
            [self.currentImage2 setImage:prodImg];
        } else if (i==2) {
            [self.currentImage3 setImage:prodImg];
        } else {
            [self.currentImage4 setImage:prodImg];
        }
    }
    
    // Go back to original in case listen is pressed
    [db_layer findMeaning:line_count];

}


- (void)showEnglishTexts {
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Usually doesnt work since same word should have 2 images (i.e 'dar' for 'in' and 'door')
    
    [self showQuiz];
    self.English.hidden = true;
    self.Words.hidden = false;
    [self.currentImage1 setImage:nil];
    [self.currentImage2 setImage:nil];
    [self.currentImage3 setImage:nil];
    [self.currentImage4 setImage:nil];
    
    for (int i=0;i<4;i++) {
        NSNumber *num = [self.questions objectAtIndex:i];
        [db_layer findMeaning:[num integerValue]];
        NSString *aud = [db_layer getOriginalMeaning];
        if (i==0) {
            [[self.currentImage1 cell] setBackgroundColor:[NSColor colorWithRed:0.8 green:0.8 blue:0.6 alpha:1.0]];
            [self.currentImage1 setTitle:aud];
        } else if (i==1) {
            [[self.currentImage2 cell] setBackgroundColor:[NSColor colorWithRed:0.75 green:0.7 blue:0.65 alpha:1.0]];
            [self.currentImage2 setTitle:aud];
        } else if (i==2) {
            [[self.currentImage3 cell] setBackgroundColor:[NSColor colorWithRed:0.7 green:0.9 blue:0.7 alpha:1.0]];
            [self.currentImage3 setTitle:aud];
        } else {
            [[self.currentImage4 cell] setBackgroundColor:[NSColor colorWithRed:0.65 green:0.8 blue:0.75 alpha:1.0]];
            [self.currentImage4 setTitle:aud];
        }
    }
    
    // Go back to original in case listen is pressed
    [db_layer findMeaning:line_count];

}



- (void)showFarsiTexts {
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Usually doesnt work since same word should have 2 images (i.e 'dar' for 'in' and 'door')
    
    [self showQuiz];
    self.Words.hidden = true;
    self.English.hidden = false;
    [self.currentImage1 setImage:nil];
    [self.currentImage2 setImage:nil];
    [self.currentImage3 setImage:nil];
    [self.currentImage4 setImage:nil];

    
    for (int i=0;i<4;i++) {
        NSNumber *num = [self.questions objectAtIndex:i];
        [db_layer findMeaning:[num integerValue]];
        NSString *aud = [db_layer getCurrentWord];
        if (i==0) {
            [self.currentImage1 setTitle:aud];
        } else if (i==1) {
            [self.currentImage2 setTitle:aud];
        } else if (i==2) {
            [self.currentImage3 setTitle:aud];
        } else {
             [self.currentImage4 setTitle:aud];
        }
    }
    // Go back to original in case listen is pressed
    [db_layer findMeaning:line_count];

}
- (IBAction)show:(id)sender {
    if (self.Words.hidden == false) {
        self.English.hidden = false;
    }
    self.Words.hidden = false;
}


- (IBAction)playAudio:(id)sender {
    [self playForeign];
}
-(void)OldTest {
    [saved_settings load];
    if (doing_exam && (auto_timed == nil)) {
       long words_left = [TodaysWords  count];
        NSString *title = [NSString stringWithFormat:@"%ld words to go", words_left];
        // CHECK did you get it right??
        //       leitnerAlert = [[UIAlertView alloc]initWithTitle:title message:@"Did you get this correct?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        NSAlert *testAlert = [NSAlert alertWithMessageText:title
                                             defaultButton:@"Yes"
                                           alternateButton:@"No"
                                               otherButton:nil
                                 informativeTextWithFormat:@"%@", @"Move to Level 7?"];
        NSInteger result = [testAlert runModal];
        switch(result)
        {
            case NSAlertDefaultReturn: [user_layer moveTo7]; break;
            case NSAlertAlternateReturn: [user_layer incrementSoundRating];break;
        }
        // Move on either way....
        doing_exam = [self ContinueSession];
    }
}

-(void)playForeign {
    
    NSString *soundFilePath = [self getCurrentMP3FilePath];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:soundFilePath];
    BOOL notZero = true;// only matters if file exists
    
    if (fileExists) {
        NSInteger size =  [self getFileSize:soundFilePath];
        notZero = (size > 1000);
        if (notZero) {
            //MyLog(@" size of %@ is %d",soundFilePath,(int)size);
        }
    }
    
    if (fileExists && soundFilePath && notZero) {
       
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
        
        AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: fileURL error: nil];
        self.player = newPlayer;
        [player setDelegate:self];
        [player prepareToPlay];
        [player play];
        
        playing = true;
    }
    // else Nothing to play!!!!
}


/// Recording Stuff
#pragma mark - Recording


- (NSInteger) getFileSize:(NSString*) path
{
    NSFileManager * filemanager = [[NSFileManager alloc] init] ;
    if([filemanager fileExistsAtPath:path]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
            return  [theFileSize intValue];
        else
            return -1;
    }
    else
    {
        return -1;
    }
}


#pragma mark - Background Thread

- (void)showCheckErrorMessage:(NSError *)error
{
    if(error != nil)
    {
        MyLog(@"Error: %@", error);
        [self showAlertMessage:[error.userInfo objectForKey:@"message"] withTitle:@"Upload Error"];
    }
    else
    {
        [self showAlertMessage:@"The image was successfully uploaded." withTitle:@"Upload Completed"];
    }
    
}

#pragma mark



- (IBAction)timer_changed:(id)sender {
    NSInteger selectedSeg = [sender selectedSegment];
    bool isOn = selectedSeg;

    if ((auto_timed == nil) && (isOn)) {
        [self start_auto];
    } else if (!isOn) {
        [auto_timed invalidate];
        auto_timed = nil;
    }
}

- (void)start_auto
{
    NSAlert *testAlert = [NSAlert alertWithMessageText:@"Please answer"
                                         defaultButton:@"Yes"
                                       alternateButton:@"No"
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", @"Todays words only?"];
    NSInteger result = [testAlert runModal];
    switch(result)
    {
        case NSAlertDefaultReturn:
            autoIds = [user_layer getIDListforTomorrow];

            break;
            
        case NSAlertAlternateReturn:
            autoIds = [user_layer getAutoIdList];
            break;
    }
    
        // Make sure count > 0 before starting counter
        if ([autoIds count] > 0) {
            auto_timed = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                          target:self selector:@selector(autoUpdate)
                                                        userInfo:nil repeats:NO];
        }
    
    self.currentImage1.hidden = true;
    self.currentImage2.hidden = true;
    self.currentImage3.hidden = true;
    self.currentImage4.hidden = true;
    self.currentImage.hidden = false;
    self.English.hidden = false;
    self.Words.hidden = false;
}


- (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title
{
    NSAlert *testAlert = [NSAlert alertWithMessageText:title
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", message];
    [testAlert runModal];
}


- (void)showAlertMessageWithTimeout:(NSString *)message withTitle:(NSString *)title
{
    NSAlert *testAlert = [NSAlert alertWithMessageText:title
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", message];

    int64_t delayInSeconds = 1.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[testAlert window] close];
    });
    [testAlert runModal];
    
}

-(void)show_file_count {
    
    NSString *docsDir;
    NSArray *dirPaths;
    
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = [[NSError alloc] init];
    NSArray *directoryAndFileNames = [fm contentsOfDirectoryAtPath:docsDir error:&error];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF EndsWith '.mp3'"];
    NSArray *mp3Array =  [directoryAndFileNames filteredArrayUsingPredicate:predicate];
    
    NSString *jpegPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"/jpegs/"]];
    NSArray *directoryAndFileNamesForJpegs = [fm contentsOfDirectoryAtPath:jpegPath error:&error];
    
    NSPredicate *predicateJ = [NSPredicate predicateWithFormat:@"SELF EndsWith '.jpg'"];
    NSArray *jpgArray =  [directoryAndFileNamesForJpegs filteredArrayUsingPredicate:predicateJ];
    
    NSString *mess = [NSString stringWithFormat:@"%@%d%@%d%@", @"You have ",
                      (unsigned)[mp3Array count],@" mp3s and ",(unsigned)[jpgArray count],@" jpgs"];
    
    [self showAlertMessage:mess withTitle:@"Notice"];
    
}

-(int)get_jpg_count {
    
    NSString *docsDir;
    NSArray *dirPaths;
    
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = [[NSError alloc] init];
    
    NSString *jpegPath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:@"/jpegs/"]];
    NSArray *directoryAndFileNamesForJpegs = [fm contentsOfDirectoryAtPath:jpegPath error:&error];
    
    NSPredicate *predicateJ = [NSPredicate predicateWithFormat:@"SELF EndsWith '.jpg'"];
    NSArray *jpgArray =  [directoryAndFileNamesForJpegs filteredArrayUsingPredicate:predicateJ];
    
    return (int)[jpgArray count];
    
}


@end
