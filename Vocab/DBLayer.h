#import "AppConfig.h"
#import <Foundation/Foundation.h>

@interface DBLayer : NSObject

// Column names for SQLITE table (lowercase for actual names)
#define WNAME  1
#define WTRANSLIT 2
#define WMEAN 3
#define WCLASS 4
#define WIMAGE 5
#define WNEWMEAN 6
#define WCATEGORY 7
//#define WCOMPOUND 8
// name in db is WCOMPOUND
#define WIMAGENUM 8

+ (id)sharedManager;

- (void)startup;
- (void)MakeSearchString:(NSString *)dbValues;
- (void)findMeaning:(long)line_count;
- (void)checkDatabase;
- (int)getCurrentId;
- (int)getWordClass;
- (long)getImageNumber:(long)line_count;
- (NSString *)getCurrentImage;
- (NSString *)getCurrentWord;
- (NSString *)getOriginalMeaning;
- (NSString *)getCurrentTranslit;
- (NSString *)getCurrentSearch;
- (NSString *)getCurrentCategory;
- (NSString *)getUpdatedMeaning;

- (NSArray *)getWordList;
- (NSArray *)getSortedWordList;
- (NSDictionary *)getImageList;

-(NSInteger)getTableSize;

-(void)saveImageData:(NSURL *)url;
-(int)setNewMeaning:(NSString *)s;
-(void)setWordClass:(int)w;
-(bool)checkWordClass:(int)class forClass:(int)ref;
-(bool)checkCategory:(int)class forCategory:(NSString *)ref;
-(void)deleteCurrentWord;

@end
