#import <Foundation/Foundation.h>

@interface Settings : NSObject {
}

//@property bool use_leitner;
//@property bool use_forvo;
//@property bool use_images;
@property bool use_sorted;

//@property long leitnerLevel;
@property long dayCount;
@property long lineCount;
@property long autoCount;


-(id)init;
-(void)load;
-(void)save;

@end
