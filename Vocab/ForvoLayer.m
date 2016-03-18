#import "ForvoLayer.h"
#import "AFNetworking.h"
#import <Foundation/Foundation.h>

@interface ForvoLayer ()
@end


@implementation ForvoLayer

#pragma mark - String Stuff

+(NSString *)farsiToHex:(NSString *)string
{
    const char *utf8 = [string UTF8String];
    NSMutableString *hex = [NSMutableString string];
    while ( *utf8 ) [hex appendFormat:@"%02X" , *utf8++ & 0x00FF];
    
    return [ [NSString stringWithFormat:@"%@", hex] lowercaseString];
}

+(NSString *)stringToHex:(NSString *)string
{
    const char *utf8 = [string UTF8String];
    NSMutableString *hex = [NSMutableString string];
    while ( *utf8 ) [hex appendFormat:@"%%%02X" , *utf8++ & 0x00FF];
    
    return [NSString stringWithFormat:@"%@", hex];
}

+(NSString *)extractString:(NSString *)fullString toLookFor:(NSString *)lookFor skipForwardX:(NSInteger)skipForward toStopBefore:(NSString *)stopBefore
{
    
    NSRange firstRange = [fullString rangeOfString:lookFor];
    if (firstRange.length > 0) {
        NSRange secondRange = [[fullString substringFromIndex:firstRange.location + skipForward] rangeOfString:stopBefore];
        NSRange finalRange = NSMakeRange(firstRange.location + skipForward, secondRange.location + [stopBefore length]);
    
        if (finalRange.length > 0) {
            return [fullString substringWithRange:finalRange];
        } else {
            return @"";
        }
    } else {
        return @"";
    }
}

+(void)get_forvo_mp3:(NSString *)word {
    
    NSString *docsDir;
    NSArray *dirPaths;
    
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    docsDir = dirPaths[0];
   
    NSString *mess = [NSString stringWithFormat:@" Searching Forvo for %@.mp3",word];
    [self showAlertMessageWithTimeout:mess withTitle:@"Please wait"];
    
    
    NSString *myhex = [self stringToHex:word];
    NSString *url_string = [NSString stringWithFormat:
                            @"http://apifree.forvo.com/key/${FORVO_KEY}/format/xml/language/fa/action/word-pronunciations/word/%@",myhex];
    
    //MyLog(@" URL is %@",url_string);
    
    // Now try to download !!!!!
    NSURL *url = [NSURL URLWithString:url_string];
    
    NSString *Download_dir = [NSString stringWithFormat:@"%@/audio", docsDir];
    
    BOOL audioDirExists = [[NSFileManager defaultManager] fileExistsAtPath:Download_dir];
    
    if (!audioDirExists) {
        [[NSFileManager defaultManager] createDirectoryAtPath:Download_dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    // Build the path to the database file
    NSString *path = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:@"my.txt"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        MyLog(@"got XML file for %@\n",word);// %@!",path);
        //Read in my.txt line by until you see pathmp3, then extract link & download!!!!
        NSString * fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        NSString *strTemp = [self extractString:fileContents toLookFor:@"<pathmp3>" skipForwardX:9 toStopBefore:@"<"];
        if ([strTemp length] > 1) {
            NSString *link_string = [strTemp substringToIndex:[strTemp length]-1];
            MyLog(@" Found mp3 link for %@\n",word);// for = %@",link_string);
            NSString *fpath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:
                                                                 [NSString stringWithFormat:@"/audio/%@.mp3",word]]];
            
            NSURL *url2 = [NSURL URLWithString:link_string];
            
            NSURLRequest *request2 = [NSURLRequest requestWithURL:url2];
            AFHTTPRequestOperation *operation2 = [[AFHTTPRequestOperation alloc] initWithRequest:request2];
            operation2.outputStream = [NSOutputStream outputStreamToFileAtPath:fpath append:NO];
            
            [operation2 setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                MyLog(@" Got mp3 file! = %@ for %@",fpath, word);
                
                NSString *mess = [NSString stringWithFormat:@" The file %@.mp3 was downloaded from Forvo",word];
                [self showAlertMessageWithTimeout:mess withTitle:@"Download Completed"];
                //sleep(5);
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                // Deal with failure
                MyLog(@" Failed to get mp3 file! = %@", word);
            }];
            [operation2 start];
        } else {
            MyLog(@" There is no mp3 file for %@", word);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MyLog(@" There is no mp3 file for %@",word);
        // Deal with failure
    }];
    [operation start];
}


+(void)showAlertMessageWithTimeout:(NSString *)message withTitle:(NSString *)title
{
    /*
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    int64_t delayInSeconds = 1.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:YES];
    });
     */
}


@end


