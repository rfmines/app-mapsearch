//
//  AppDelegate.m
//  MapSearch
//
//  Created by Yeffry on 9/15/15.
//  Copyright (c) 2015 zakizon. All rights reserved.
//

#import "AppDelegate.h"


void SIGTERM_handler(int signum) {
    
    NSLog(@"Caught signal: [%d]. Cleaning up ...",signum);
    AppDelegate *app = (AppDelegate*)[NSApplication sharedApplication].delegate;
    if (app.mapsearch) {
        app.mapsearch = nil;
    }
    NSLog(@"Done cleaning up. Exiting ...");
    exit(EXIT_FAILURE);
}
@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate
@synthesize mapsearch;

- (NSString*)getUsage
{
    NSString *usage = [NSString stringWithFormat:@"MapSearch v%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey]];
    usage = [usage stringByAppendingString: @"\nUsage: MapSearch -input input_file.csv -output output_file.csv [other options]\n"];
    usage = [usage stringByAppendingString:@"Example: MapSearch -input /Users/ooma/10k.csv -output /Users/ooma/10k_out.csv -retry 5 -sleep 30 -maxquery 25 -filter name,address,city,state,zip_code\n"];
    usage = [usage stringByAppendingString:@"Example above means read file 10k.csv, use column name,address,city,state,zip_code as search keyword. Run search for 25 keywords than sleep 30 seconds, run next 25 keyword. Retry search 5 times on failure then write the result to 10k_out.csv.\n\n"];
    
    usage = [usage stringByAppendingString:@"Options:\n\n"];
    usage = [usage stringByAppendingString:@"-input <string> : Takes a full path or relative path to your csv file. This is required.\n"];
    usage = [usage stringByAppendingString:@"-output <string> : Takes a full path or relative path to your csv file. This is required.\n"];
    usage = [usage stringByAppendingString:@"-retry <number> : The number to retry searching map address.\n"];
    usage = [usage stringByAppendingString:@"-sleep <number> : The number in second of application should sleep before searching again.\n"];
    usage = [usage stringByAppendingString:@"-sleep-in-search <number> : The number in second of application should sleep before searching another keyword.\n"];
    usage = [usage stringByAppendingString:@"-max-query <number> : The number of searches before stop searching and sleep.\n"];
    usage = [usage stringByAppendingString:@"-filter <string> : The column of your input csv that will be used as search keyword.\n"];
    usage = [usage stringByAppendingString:@"Valid keyword filters are : name,address,city,state,zip_code should be comma delimited.\nIf filter is empty, name and zip_code will be used as default search keywords.\n"];
    return usage;
}
- (void) printUsage
{
    NSLog([self getUsage]);
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    signal(SIGTERM, SIGTERM_handler);
    signal(SIGINT, SIGTERM_handler);
    
    mapsearch = [[MapSearch alloc] init];
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger maxQuery = [standardDefaults integerForKey:@"max-query"];
    NSInteger sleep = [standardDefaults integerForKey:@"sleep"];
    NSInteger sleepInSearch = [standardDefaults integerForKey:@"sleep-in-search"];
    NSInteger maxRetry = [standardDefaults integerForKey:@"retry"];
    NSString *filter = [standardDefaults stringForKey:@"filter"];
    NSString *input = [standardDefaults stringForKey:@"input"];
    NSString *output = [standardDefaults stringForKey:@"output"];
    
    NSLog(@"MapSearch version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey]);
    NSLog(@"MapSearch input parameters: \n");
    NSLog(@"maxQuery: %ld", maxQuery);
    NSLog(@"filter : %@", filter);
    NSLog(@"sleep : %ld", sleep);
    NSLog(@"maxRetry : %ld", maxRetry);
    NSLog(@"input : %@", input);
    NSLog(@"output : %@", output);
    
        if (input.length == 0 || output.length == 0) {
            [self printUsage];
           
            NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid arguments" defaultButton:@"Close" alternateButton:nil otherButton:nil informativeTextWithFormat:[self getUsage]];
            [alert runModal];
            [NSApp terminate:self];
        }
    
            @try {
                
                NSDictionary *data = @{@"input":input, @"output":output, @"retry":[NSNumber numberWithInteger:maxRetry], @"filter":filter, @"sleep":[NSNumber numberWithInteger:sleep], @"max-query":[NSNumber numberWithInteger:maxQuery], @"sleep-in-search":[NSNumber numberWithInteger:sleepInSearch]};
                [mapsearch readCSV:data withCompletionHandler:^(NSError *error) {
                    if (error) {
                        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"Close" alternateButton:nil otherButton:nil informativeTextWithFormat:[error localizedDescription]];
                        [alert runModal];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:kSearchDone object:self];
                    }
                }];
            }
            @catch (NSException *exception) {
                NSLog(@"Exception: %@", [exception description]);
            }
    
 }

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    self.mapsearch = nil;
}

@end
