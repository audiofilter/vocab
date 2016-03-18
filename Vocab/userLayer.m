#import "userLayer.h"
//#import "SDCloudUserDefaults.h"
//#define HAS_XDB
//#import "XDBLayer.h"
#import <Cocoa/Cocoa.h>

// Set this higher (16 for example if useful)
#define MINIMUM_WORDS 1
#define AUTOTHRESHOLDLEVEL 1

@interface userLayer ()

@property(strong,nonatomic) NSMutableArray *levels;
@property(strong,nonatomic) NSMutableArray *test_type;
@property(strong,nonatomic) NSMutableArray *next_time_check;
@property(strong,nonatomic) NSDate *startDate;
@property(strong,nonatomic) NSDate *lastUpdate;

@property int CurrentId;
@property int soundRating;
@property NSInteger table_size;
@end

@implementation userLayer

@synthesize CurrentId;
@synthesize soundRating;
@synthesize table_size;
@synthesize levels;
@synthesize test_type;
@synthesize next_time_check;
@synthesize startDate;
@synthesize lastUpdate;



- (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title
{
    
    NSAlert *testAlert = [[NSAlert alloc] init];
    [testAlert setMessageText:title];
    [testAlert setInformativeText:message];
    
 /*
    NSAlert *testAlert = [NSAlert alertWithMessageText:title
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", message];
  */
    [testAlert runModal];

}


+ (id)sharedManager {
    static userLayer *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        levels = [[ [NSUserDefaults standardUserDefaults] objectForKey:@"levels"] mutableCopy];
        test_type = [[ [NSUserDefaults standardUserDefaults] objectForKey:@"test_type"] mutableCopy];
        next_time_check = [[ [NSUserDefaults standardUserDefaults] objectForKey:@"next_time_check"] mutableCopy];
        startDate = [ [NSUserDefaults standardUserDefaults] objectForKey:@"StartDate"];
        lastUpdate = [ [NSUserDefaults standardUserDefaults] objectForKey:@"lastUpdate"];


        //[self showAlertMessage:[NSString stringWithFormat:@"%@",lastUpdate] withTitle:@"Last iCloud update!"];
        if (startDate == nil) {
            startDate = [NSDate date];
            [ [NSUserDefaults standardUserDefaults] setObject:startDate forKey:@"StartDate"];
        }
        if (lastUpdate == nil) {
            lastUpdate = [NSDate date];
            [ [NSUserDefaults standardUserDefaults] setObject:lastUpdate forKey:@"lastUpdate"];
        }
      //  MyLog(@" Last update of [NSUserDefaults standardUserDefaults] was %@\n",lastUpdate);
        table_size = [levels count];
        //for (int i=0;i<table_size;i++) {
          //  MyLog(@" date %@ for object %d\n",next_time_check[i],i);
        //}
       
        
    }
    return self;
}

-(void)save {
    [ [NSUserDefaults standardUserDefaults] setObject:levels forKey:@"levels"];
    [ [NSUserDefaults standardUserDefaults] setObject:test_type forKey:@"test_type"];
    [ [NSUserDefaults standardUserDefaults] setObject:next_time_check forKey:@"next_time_check"];
    //for (int i=0;i<table_size;i++) MyLog(@" date %@ for object %d\n",next_time_check[i],i);
    
    lastUpdate = [NSDate date];
    [ [NSUserDefaults standardUserDefaults] setObject:lastUpdate forKey:@"lastUpdate"];
   // MyLog(@" Updating of [NSUserDefaults standardUserDefaults] at %@\n",lastUpdate);
    [ [NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setup:(int)size {
    if (table_size == 0) {
//        if (table_size == size) {
        levels = [NSMutableArray array];
        next_time_check = [NSMutableArray array];
        test_type = [NSMutableArray array];
        NSDate *now = [NSDate date];
        /////int hoursToAdd = 2; // 2 hours between each word => 12 a day
        int hoursToAdd = 1; // 1 hours between each word => 24 a day
        int timeToAdd = -60*60*24; // Start 1 day ago
        for (int i=0;i<size;i++) {
            [levels addObject:[NSNumber numberWithInt:-1]];
            [test_type addObject:[NSNumber numberWithInt:-1]];
            
            timeToAdd += 60*60*hoursToAdd;
            NSDate *newDate = [now dateByAddingTimeInterval:timeToAdd];
            [next_time_check addObject:newDate];
        }
    } else if (table_size < size) {
        NSDate *now = [NSDate date];
        int hoursToAdd = 2; // 2 hours between each word => 12 a day
        int timeToAdd =0; // Start now
        for (long i=table_size;i<size;i++) {
            [levels addObject:[NSNumber numberWithInt:-1]];
            [test_type addObject:[NSNumber numberWithInt:-1]];
            timeToAdd += 60*60*hoursToAdd;
            NSDate *newDate = [now dateByAddingTimeInterval:timeToAdd];
            [next_time_check addObject:newDate];
        }
    }
#ifdef HACK2
    // legacy case
    next_time_check = [NSMutableArray array];
    for (int i=0;i<size;i++) {
        [next_time_check addObject:[NSDate date]];
    }
#endif
    
    table_size = [levels count];
    
}

-(int)getCurrentId { return self.CurrentId; }
-(int)getCurrentSoundRating {return soundRating;}
-(NSInteger)getTableSize { return table_size;}
-(NSDate *)get_start_date { return startDate;}

-(void)moveTo7 {
    self.soundRating = 7;
    [self saveSoundRatingToDB:self.soundRating];
}
// need to use db Writes, etc.
-(void)setCurrentSoundRating:(int)v {
    self.soundRating = v;
    [self saveSoundRatingToDB:v];
}
-(void)incrementSoundRating {
    self.soundRating = (int)[[levels objectAtIndex:self.CurrentId] integerValue];
    if (self.soundRating == -1) {
        [self SetSoundRatingDone]; // 1st time -> just move all the way
    } else {
        int v = self.soundRating + 1;
        [self saveSoundRatingToDB:v];
    }
    [self incrementTestType];
}

- (long)getTestType {
    NSNumber *val = [self.test_type objectAtIndex:self.CurrentId];
    long ret = [val integerValue];
    return ret;
}
- (void)setTestType:(long)t {
    NSNumber *inc = [NSNumber numberWithLong:t];
    [self.test_type replaceObjectAtIndex:self.CurrentId withObject:inc];
    [self save];
}

- (void)incrementTestType {
    NSNumber *val = [self.test_type objectAtIndex:self.CurrentId];
    long mod_inc = ([val integerValue]+1) % NUM_TEST_TYPES;
    NSNumber *inc = [NSNumber numberWithLong:mod_inc];
    [self.test_type replaceObjectAtIndex:self.CurrentId withObject:inc];
    [self save];
}


-(void)SetSoundRatingDone {
    [self saveSoundRatingToDB:LLEVELS];
}
///##########

// Extract data from db for a given 'id'/line_count
- (void)readDB:(long)line_count {
    self.CurrentId = (int)line_count;
    self.soundRating = (int)[[levels objectAtIndex:line_count] integerValue];
}

// Get ids at Level < AUTOTHRESHOLDLEVEL
- (NSMutableArray *)getAutoIdList {
    NSMutableArray *WordArray = [[NSMutableArray alloc] init];
    long count = [self getTableSize];
    for (int i=0;i<count;i++) {
        int theLevel = (int)[[levels objectAtIndex:i] integerValue];
        if (theLevel < AUTOTHRESHOLDLEVEL) {
            [WordArray addObject:[NSNumber numberWithInt:i]];
            }
    }
   return WordArray;
}


// Get the list of 'id's for a particular  'level'
- (NSMutableArray *)getIDListforLevel:(int)Level {
    NSMutableArray *WordArray = [[NSMutableArray alloc] init];
    long count = [self getTableSize];
    for (int i=0;i<count;i++) {
        // convert to int 1st
        int theLevel = (int)[[levels objectAtIndex:i] integerValue];
        if (theLevel == Level) [WordArray addObject:[NSNumber numberWithInt:i]];
    }
    return WordArray;
}

- (int)getNumberWordsforLevel:(int)Level  {
    int num=0;
    long count = [self getTableSize];
    for (int i=0;i<count;i++) {
        // convert to int 1st
        int theLevel = (int)[[levels objectAtIndex:i] integerValue];
        if (theLevel == Level) num++;
    }
    return num;
}

-(int)countLevel1 {
    int num = 0;
    long count = [self getTableSize];
    for (int i=0;i<count;i++) {
        int theLevel = (int)[[levels objectAtIndex:i] integerValue];
        if (theLevel == 1) num++;
    }
    return num;
}

-(void)resetSoundRatingForID:(int)sel {
    NSNumber *val = [NSNumber numberWithInt:1];
    [self.levels replaceObjectAtIndex:sel withObject:val];
    [self.next_time_check replaceObjectAtIndex:sel withObject:[NSDate date]];
    [self save];
}

-(void)clearSoundRatingForID:(long)sel {
    NSNumber *val = [NSNumber numberWithInt:0];
    [self.levels replaceObjectAtIndex:sel withObject:val];
    [self.next_time_check replaceObjectAtIndex:sel withObject:[NSDate date]];
    [self save];
}
-(void)clearSoundRating {
    NSNumber *val = [NSNumber numberWithInt:0];
    [self.levels replaceObjectAtIndex:self.CurrentId withObject:val];
    [self.next_time_check replaceObjectAtIndex:self.CurrentId withObject:[NSDate date]];
    [self save];
}

- (void)saveSoundRatingToDB:(int)v {
    NSNumber *val = [NSNumber numberWithInt:v];
    [self.levels replaceObjectAtIndex:self.CurrentId withObject:val];
    
    NSDate *now = [NSDate date];
    int daysToAdd = (1 << v) - 1;
    NSDate *newDate = [now dateByAddingTimeInterval:60*60*24*daysToAdd];
    [self.next_time_check replaceObjectAtIndex:self.CurrentId withObject:newDate];

    
    [self save];
}


-(void)resetSoundRating {
    [self saveSoundRatingToDB:1];
}


// Get the list of 'id's with Dates before now
- (NSMutableArray *)getIDListforToday {
    NSMutableArray *WordArray = [[NSMutableArray alloc] init];
    long count = [self getTableSize];
    NSDate *now = [NSDate date];
    
    int iter = 0;
    int words_added=0;
    do {
        words_added = 0;
        NSDate *next_date = [now dateByAddingTimeInterval:(60*60*24*iter)];
        for (int i=0;i<count;i++) {
            NSDate *next = [next_time_check objectAtIndex:i];
            if ([next compare:next_date] == NSOrderedDescending) {
            } else {
                words_added++;
            }
        }
        //MyLog(@"got total of %d for %@\n",words_added,next_date);
        iter++;
        if (words_added >= MINIMUM_WORDS) {
            for (int i=0;i<count;i++) {
                NSDate *next = [next_time_check objectAtIndex:i];
                if ([next compare:next_date] == NSOrderedDescending) {
                    //MyLog(@"next is in the future for %d at level %ld",i,[[levels objectAtIndex:i] integerValue]);
                } else {
                    [WordArray addObject:[NSNumber numberWithInt:i]];
                    //MyLog(@"got %d at level %ld\n",i,[[levels objectAtIndex:i] integerValue]);
                }
            }
            
        }
    } while (words_added < MINIMUM_WORDS);
    if (iter > 1) {
        MyLog(@"Looked ahead %d days to get words\n",iter-1);        
    }
    
    return WordArray;
}
//////
// Get the list of 'id's with Dates before 24 hours in the future
- (NSMutableArray *)getIDListforTomorrow {
    NSMutableArray *WordArray = [[NSMutableArray alloc] init];
    long count = [self getTableSize];
    NSDate *now = [NSDate date];
    NSDate *tomorrow = [now dateByAddingTimeInterval:60*60*24];
    for (int i=0;i<count;i++) {
        NSDate *next = [next_time_check objectAtIndex:i];
        if ([next compare:tomorrow] != NSOrderedDescending) {
            [WordArray addObject:[NSNumber numberWithInt:i]];
            MyLog(@"got %d at level %ld\n",i,[[levels objectAtIndex:i] integerValue]);
        }
    }
    return WordArray;
}


@end


