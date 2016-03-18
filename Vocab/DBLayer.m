#import "DBLayer.h"
#import <Foundation/Foundation.h>
#import "sqlite3.h"
#import "UIImageView+AFNetworking.h"
#import "AFNetworking.h"

#define AUTOTHRESHOLDLEVEL 1
#define DB_NAME @"vocab.db"

@interface DBLayer ()

@property(strong,nonatomic) NSString *databasePath;
@property(nonatomic) sqlite3 *contactDB;
@property int CurrentId;
@property NSString *CurrentImageNumber;
@property NSString *CurrentWord;
@property NSString *CurrentTranslit;
@property NSString *CurrentMeaning;
@property NSString *CurrentSearch;
@property NSString *CurrentImages;
@property NSString *CurrentCategory;
@property NSString *CurrentNewMeaning;
@property int CurrentClass;
@property NSInteger table_size;

@property double soundRating;

@property (nonatomic) BOOL sharing;

@end

@implementation DBLayer

@synthesize CurrentId;
@synthesize CurrentWord;
@synthesize CurrentSearch;
@synthesize CurrentMeaning;
@synthesize CurrentTranslit;
@synthesize CurrentClass;
@synthesize CurrentImages;
@synthesize CurrentImageNumber;
@synthesize CurrentCategory;
@synthesize CurrentNewMeaning;

@synthesize soundRating;
@synthesize table_size;

+ (id)sharedManager {
    static DBLayer *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (NSString *)getCurrentCategory { return self.CurrentCategory; }
- (NSString *)getCurrentImage { return self.CurrentImages; }
- (NSString *)getCurrentWord { return self.CurrentWord; }
- (int)getCurrentId { return self.CurrentId; }
// Since db is storing string for this
- (long)getImageNumber:(long)line_count {
    [self findMeaning:line_count];
    return [self.CurrentImageNumber integerValue];
}
- (NSString *)getOriginalMeaning { return self.CurrentMeaning; }
- (NSString *)getCurrentTranslit { return self.CurrentTranslit; }

-(int)getWordClass { return self.CurrentClass;}

-(NSInteger)getTableSize { return table_size;}
// need to use db Writes, etc.

-(int)setNewMeaning:(NSString *)s {
    self.CurrentNewMeaning = s;
    int r = [self saveNewMeaningToDB:s];
    return r;
}
-(void)setWordClass:(int)s {
    self.CurrentClass = s;
    [self saveWordcatToDB:s];
}

-(bool)checkWordClass:(int)class forClass:(int)ref {
    [self findMeaning:class];
    return (self.CurrentClass == ref);
}
-(bool)checkCategory:(int)class forCategory:(NSString *)ref_string {
    [self findMeaning:class];
    return ([self.CurrentCategory isEqualToString:ref_string]);
}



// Return Original Meeting if it has not been edited,
// other return NewMeaning. Original Meeting should not change ever
- (NSString *)getUpdatedMeaning {
    if ([self.CurrentNewMeaning isEqualToString:@""]) {
        return self.CurrentMeaning;
    } else if (self.CurrentNewMeaning == nil) {
        return @" ";
    } else {
        NSMutableString * stringToSend = [[NSMutableString alloc] initWithString: self.CurrentNewMeaning];
        
        NSRange firstRange = [stringToSend rangeOfString:@"|"];
        if (firstRange.length > 0) {
            [stringToSend replaceOccurrencesOfString:@"|" withString:@"\"" options:NSBackwardsSearch range:NSMakeRange(0, [stringToSend length])];
        }
        return stringToSend;
    }
}

- (NSString *)getCurrentSearch {
    [self MakeSearchString:self.getUpdatedMeaning];
    return self.CurrentSearch;
}



- (void)MakeSearchString:(NSString *)dbValues {
    NSMutableArray *sents = [[dbValues componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] mutableCopy];
    
    // needs more Work!!
    for (int i=0;i<[sents count];i++) {
        NSString *each_sent = [sents objectAtIndex:i];
        //MyLog(@" Sentence %d : %@",i, each_sent);
        NSArray *words = [each_sent componentsSeparatedByString:@","];
        NSString *first_word = [words objectAtIndex:0];
        // Check for "(verbal noun" and skip
        NSRange verbValue = [first_word rangeOfString:@"(v" options:NSCaseInsensitiveSearch];
        
        // Check for "(plural" and skip
        NSRange rangeValue2 = [first_word rangeOfString:@"(p" options:NSCaseInsensitiveSearch];

#ifdef TEMPX
        /// FIXME
        NSRange rangeValue3 = [first_word rangeOfString:@"(n" options:NSCaseInsensitiveSearch];

        if (rangeValue3.length != 0) {
            return;
            self.CurrentSearch = [first_word substringToIndex:(rangeValue3.location-1)];
        }
        
        if (verbValue.length != 0) {
            self.CurrentSearch = [NSString stringWithFormat:@"to %@",[first_word substringToIndex:(verbValue.location-1)]];
            return;
        }
#endif

        
        if ((verbValue.length == 0) && (rangeValue2.length == 0)) {
           // MyLog(@" Search Term is: %@",first_word);
            self.CurrentSearch = first_word;
            return;
        }
        
        
    }
}

- (id)init {
    if (self = [super init]) {
        [self checkDatabase];
    }
    return self;
}

- (void)startup {
    [self checkDatabase];
}

///##########
#pragma mark -Database


// NEW!
- (int)saveNewMeaningToDB:(NSString *)newM {
    int added = 0;
    sqlite3_stmt    *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    NSMutableString * stringToSend = [[NSMutableString alloc] initWithString: newM];
  
    [stringToSend replaceOccurrencesOfString:@"\n" withString:@"\r" options:NSBackwardsSearch range:NSMakeRange(0, [stringToSend length])];
    
    NSRange firstRange = [stringToSend rangeOfString:@"\""];
    if (firstRange.length > 0) {
        [stringToSend replaceOccurrencesOfString:@"\"" withString:@"|" options:NSBackwardsSearch range:NSMakeRange(0, [stringToSend length])];
    }
    
    //  now you can send this string to your database
    
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        
        NSString *insertSQL = [NSString stringWithFormat:
                               @"UPDATE word SET wnewmean=\"%@\" where wname = \"%@\"",
                               stringToSend, self.CurrentWord];
/*
        NSString *insertSQL = [NSString stringWithFormat:
                               @"UPDATE word SET wnewmean=\"%@\" where id = \"%d\"",
                               stringToSend, self.CurrentId];
*/
        
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, insert_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            MyLog(@"Translation updated");
            added = 1;
        } else {
            added = 0;
            MyLog(@"Failed to add");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
    return added;
}

- (void)saveWordcatToDB:(int)w {
    
    sqlite3_stmt    *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        
        NSString *insertSQL = [NSString stringWithFormat:
                               @"UPDATE word SET wclass=\"%d\" where wname = \"%@\"",
                               w, self.CurrentWord];
        
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, insert_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            MyLog(@"Word Category updated");
        } else {
            MyLog(@"Failed to add");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
    
}
/*
- (void)saveCurrentSoundToDB:(NSString *)v {
    
    sqlite3_stmt    *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        
        NSString *insertSQL = [NSString stringWithFormat:
                               @"UPDATE word SET wsound=\"%@\" where wname = \"%@\"",
                               v, self.CurrentWord];
        
        
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, insert_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            // MyLog(@"For %@, rating updated with %d",self.CurrentWord,v);
        } else {
            MyLog(@"Failed to update sound existence");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
    
}
 */
- (void)saveImageData:(NSURL *)url {
    
    sqlite3_stmt    *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {

        NSString *insertSQL = [NSString stringWithFormat:
                               @"UPDATE word SET wimage=\"%@\" where wname = \"%@\"",
                               [url absoluteString], self.CurrentWord];
 
/*
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO word (wname, wtranslit, wmean, wclass, wimage, wsound, whide, wapprove) VALUES (\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\")",
                               self.CurrentWord, self.CurrentTranslit, self.CurrentMeaning, self.CurrentClass,
                               self.CurrentImages, self.CurrentSound, self.CurrentHide, self.CurrentApprove];
  */
        
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, insert_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            MyLog(@"For %@, images updated with %@",self.CurrentWord,[url absoluteString]);
        } else {
            MyLog(@"Failed to update Image data");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
    
}
// Extract data from db for a given 'word'
- (void)findWord:(NSString *)word  {
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        //MyLog(@"opened db OK\n");
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM word WHERE wname = %@", word];
        
        const char *query_stmt = [querySQL fileSystemRepresentation]; // UTF8String];
        
        if (sqlite3_prepare_v2(_contactDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                
                self.CurrentWord = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WNAME)];
                self.CurrentTranslit = [[NSString alloc]  initWithUTF8String: (const char *) sqlite3_column_text(statement, WTRANSLIT)];
                self.CurrentMeaning = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, WMEAN)];
                self.CurrentClass = sqlite3_column_int(statement, WCLASS);
                self.CurrentImages = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, WIMAGE)];
                self.CurrentCategory = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WCATEGORY)];
                self.CurrentNewMeaning = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WNEWMEAN)];
                self.CurrentImageNumber = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WIMAGENUM)];
                //[self MakeSearchString:self.CurrentMeaning];
                [self MakeSearchString:self.getUpdatedMeaning];
                //   MyLog(@" search with :: %@",self.CurrentSearch);
            } else {
                //_statuslabel.text = @"Match not found";
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_contactDB);
    }
    
}

// Extract data from db for a given 'id'/line_count
- (void)findMeaning:(long)line_count {
    
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (line_count == 0) line_count = 1;
    
    self.CurrentId = (int)line_count;
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        //MyLog(@"opened db OK\n");
        NSString *querySQL = [NSString stringWithFormat:
                              @"SELECT * FROM word WHERE id = %d", self.CurrentId];
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_contactDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                self.CurrentWord = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WNAME)];
                self.CurrentTranslit = [[NSString alloc]  initWithUTF8String: (const char *) sqlite3_column_text(statement, WTRANSLIT)];
                self.CurrentMeaning = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, WMEAN)];
                self.CurrentClass = sqlite3_column_int(statement, WCLASS);
                self.CurrentImages = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, WIMAGE)];
                self.CurrentCategory = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WCATEGORY)];
                self.CurrentNewMeaning = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WNEWMEAN)];
                self.CurrentImageNumber = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WIMAGENUM)];

                //[self MakeSearchString:self.CurrentMeaning];
                [self MakeSearchString:self.getUpdatedMeaning];
                
                //   MyLog(@" search with :: %@",self.CurrentSearch);
            } else {
                //_statuslabel.text = @"Match not found";
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(_contactDB);
    }
    
}

- (void)copyDatabaseIfNeeded
{
    BOOL success;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    success = [fileManager fileExistsAtPath:[self getDBPath]];
    if(success)
    {
        MyLog(@" removing old db from Documents\n");
        [fileManager removeItemAtPath:[self getDBPath] error:NULL];
        //return;// If exists, then do nothing.
    }
    MyLog(@" Copying db to Documents\n");
    //Get DB from bundle & copy it to the doc dirctory.
    NSString *databasePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_NAME];
    [fileManager copyItemAtPath:databasePath toPath:[self getDBPath] error:nil];
}

- (NSString *)getDBPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    return [documentsDir stringByAppendingPathComponent:DB_NAME];
}

-(void)checkDatabase{
    
    //[self copyDatabaseIfNeeded];
    NSString *databasePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DB_NAME];
    
    // Build the path to the database file
    _databasePath = [[NSString alloc] initWithString: databasePath];
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: _databasePath ] == NO)
    {
        MyLog(@"Failed to open database");
    } else {
        MyLog(@" Opened database at %@",_databasePath);
    }
    
    table_size = [self getDBSize];
    
    //MyLog(@"Here!");
}

// Get Size of the DB in number of table entries
- (NSInteger)getDBSize {
    NSInteger count = 0;
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        //MyLog(@"opened db OK\n");
        NSString *querySQL =  @"SELECT COUNT(*) from  word";
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(_contactDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            //Loop through all the returned rows (should be just one)
            while( sqlite3_step(statement) == SQLITE_ROW )
            {
                count = sqlite3_column_int(statement, 0);
            }
            ///MyLog(@"Rowcount is %d",count);
            sqlite3_finalize(statement);
        }
        sqlite3_close(_contactDB);
    }
    return count;
}
// Delete the Current table entry
-(void)deleteCurrentWord {
    
    sqlite3_stmt    *statement;
    const char *dbpath = [_databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK)
    {
        
        NSString *deleteSQL = [NSString stringWithFormat:
                               @"DELETE from word where wname = \"%@\"",
                               self.CurrentWord];
        

        const char *del_stmt = [deleteSQL UTF8String];
        sqlite3_prepare_v2(_contactDB, del_stmt,
                           -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            MyLog(@"For %@, record delete",self.CurrentWord);
        } else {
            MyLog(@"Failed to delete record");
        }
        sqlite3_finalize(statement);
        sqlite3_close(_contactDB);
    }
}

// The list of Farsi words
- (NSArray *)getWordList {
    NSMutableArray *WordArray = [[NSMutableArray alloc] init];
    
    long count = [self getDBSize];
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
        
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK) {
            for (int i=1;i<count+1;i++) {
                NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM word WHERE id = %d", i];
                const char *query_stmt = [querySQL UTF8String];
                if (sqlite3_prepare_v2(_contactDB,query_stmt, -1, &statement, NULL) == SQLITE_OK) {
                    if (sqlite3_step(statement) == SQLITE_ROW) {
                        [WordArray addObject:
                            [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WNAME)]
                         ];
                    }
                    sqlite3_finalize(statement);
                }
            }
    }
    sqlite3_close(_contactDB);
    return WordArray;
}

// Alphabetic sorting of Farsi Words
- (NSArray *)getSortedWordList {
    NSMutableArray *WordArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
   
    long count = [self getDBSize];
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    // Create a dictionary of words and their 'id'
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK) {
        for (int i=1;i<count+1;i++) {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM word WHERE id = %d", i];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(_contactDB,query_stmt, -1, &statement, NULL) == SQLITE_OK) {
                if (sqlite3_step(statement) == SQLITE_ROW) {
                    NSString *temp = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WNAME)];
                    [dict setObject:[NSNumber numberWithInt:i] forKey:temp];
                }
                sqlite3_finalize(statement);
            }
        }
    }
    sqlite3_close(_contactDB);
    
    // Just get words & then sort them
    NSArray *allkeys = [dict allKeys];
    NSArray *sorted_keys = [allkeys sortedArrayUsingSelector:@selector(compare:)];
    
    // Go through sorted words and put their ids into an array for later lookup
    for (NSString *key in sorted_keys) {
        [WordArray addObject: [dict valueForKey:key]];
    }
    return WordArray;
}

//  Get a dictionary with 'WNAME' and 'WIMAGE', i.e words with Image URLs (if not null)
- (NSDictionary *)getImageList {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    long count = [self getDBSize];
    const char *dbpath = [_databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    // Create a dictionary of image URLs and their 'words'
    if (sqlite3_open(dbpath, &_contactDB) == SQLITE_OK) {
        for (int i=1;i<count+1;i++) {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM word WHERE id = %d", i];
            const char *query_stmt = [querySQL UTF8String];
            if (sqlite3_prepare_v2(_contactDB,query_stmt, -1, &statement, NULL) == SQLITE_OK) {
                if (sqlite3_step(statement) == SQLITE_ROW) {
                    NSString *tempI = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WIMAGE)];
                    NSString *tempW = [[NSString alloc] initWithUTF8String: (const char *) sqlite3_column_text(statement, WNAME)];
                    if ([tempI isEqualToString:@""]) {
                    } else {
                        [dict setObject:tempI forKey:tempW];
                    }
                }
                sqlite3_finalize(statement);
            }
        }
    }
    sqlite3_close(_contactDB);
    return dict;
}

@end


