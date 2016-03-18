#import "Settings.h"

@implementation Settings

//@synthesize use_leitner;
//@synthesize use_forvo;
//@synthesize use_images;
@synthesize use_sorted;

//@synthesize leitnerLevel;
@synthesize dayCount;
@synthesize lineCount;
@synthesize autoCount;

-(id)init {
    self = [super init];
    if (self != nil) {
        [self load];
    }
    return self;
}


// Load and Set default values for keys which won't exist upon first startup
-(void)load {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    if (![defs boolForKey:@"hasBeenLaunched"]) {
        [defs setBool:YES forKey:@"hasBeenLaunched"];
        lineCount = 0;
        autoCount = 0;
//        leitnerLevel = 1;
        dayCount = 0;
        
//        use_leitner = 0;
//        use_forvo = 0;
//        use_images = 1;
        use_sorted = 0;
        
         [self save];
    } else {
        lineCount = [defs integerForKey:@"count"];
        autoCount = [defs integerForKey:@"autoCount"];
 //       leitnerLevel = [defs integerForKey:@"level"];
        dayCount = [defs integerForKey:@"day"];
        
 //       use_leitner = [defs boolForKey:@"leitnerize"];
 //       use_forvo = [defs boolForKey:@"forvo"];
 //       use_images = [defs boolForKey:@"images"];
        use_sorted = [defs boolForKey:@"sorted"];
    }
    
    
}

-(void)save {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setInteger:autoCount forKey:@"autoCount"];
    [defs setInteger:lineCount forKey:@"count"];
//    [defs setInteger:leitnerLevel forKey:@"level"];
    [defs setInteger:dayCount forKey:@"day"];
    
//    [defs setBool:use_leitner forKey:@"leitnerize"];
//    [defs setBool:use_forvo forKey:@"forvo"];
//    [defs setBool:use_images forKey:@"images"];
    [defs setBool:use_sorted forKey:@"sorted"];
    [defs synchronize];
}




@end
