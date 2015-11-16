//
//  AppDelegate.m
//  MapSearch
//
//  Created by Yeffry on 9/15/15.
//  Copyright (c) 2015 zakizon. All rights reserved.
//

#import "AppDelegate.h"
#import "MapSearch.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong) MapSearch *mapsearch;
@end

@implementation AppDelegate
@synthesize mapsearch;

- (NSString*)getUsage
{
    NSString *usage = @"\nUsage: MapSearch <inputfile> <outputfile> <max_retry> <keyword_filter>\n";
    usage = [usage stringByAppendingString:@"Example: MapSearch /Users/ooma/10k.csv /Users/ooma/10k_out.csv 5 name,address,city,state,zip_code\n\n"];
    usage = [usage stringByAppendingString:@"Valid keyword filters are : name,address,city,state,zip_code should be comma delimited.\nIf filter is empty, name and zip_code will be used as default search keywords"];
    return usage;
}
- (void) printUsage
{
    NSLog([self getUsage]);
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    for (NSString *arg in args) {
        NSLog(@"arg: %@", arg);
    }
        mapsearch = [[MapSearch alloc] init];
        if ([args count] < 3) {
            [self printUsage];
           

            NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid arguments" defaultButton:@"Close" alternateButton:nil otherButton:nil informativeTextWithFormat:[self getUsage]];
            [alert runModal];
            [NSApp terminate:self];
        }
    
        if ([args count] > 2) {
            @try {
                NSString *inputFile = [args objectAtIndex:1];
                NSString *outputFile = [args objectAtIndex:2];
                NSInteger maxRetry = MAX_RETRY;
                NSString *filter = nil;
                
                if ([args count] > 3) {
                    maxRetry = [[args objectAtIndex:3] integerValue] ;
                    if (maxRetry == 0) {
                        maxRetry = MAX_RETRY;
                    }
                }
                
                if ([args count] > 4) {
                    filter = [args objectAtIndex:4];
                }
                
                [mapsearch readCSV:inputFile outputFile:outputFile maxRetry:maxRetry fiter:filter withCompletionHandler:^(NSError *error) {
                    
                }];
            }
            @catch (NSException *exception) {
                NSLog(@"Exception: %@", [exception description]);
            }
        }
 }

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    self.mapsearch = nil;
}

@end
