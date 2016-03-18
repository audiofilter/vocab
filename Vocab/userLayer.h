#import "AppConfig.h"
#import <Foundation/Foundation.h>
@interface userLayer : NSObject

#define LLEVELS 7
#define NUM_TEST_TYPES     4

+(id)sharedManager;
-(void)setup:(int)size;
-(void)readDB:(long)line_count;
-(int)getCurrentId;
-(NSMutableArray *)getAutoIdList;
-(NSMutableArray *)getIDListforLevel:(int)Level;
-(NSMutableArray *)getIDListforToday;
-(NSMutableArray *)getIDListforTomorrow;
-(int)getNumberWordsforLevel:(int)Level;
-(NSInteger)getTableSize;
//-(void)fillLevel1;
//-(void)addToLevel1;
-(void)incrementSoundRating;
-(void)resetSoundRating;
-(void)clearSoundRating;
-(void)SetSoundRatingDone;
-(void)moveTo7;
-(int)getCurrentSoundRating;
-(void)save;
-(NSDate *)get_start_date;
- (void)setTestType:(long)t;
- (long)getTestType;
-(void)clearSoundRatingForID:(long)sel;

@end
