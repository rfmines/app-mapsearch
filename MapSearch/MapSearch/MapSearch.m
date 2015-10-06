//
//  MapSearch.m
//  MapSearch
//
//  Created by Yeffry on 9/14/15.
//  Copyright (c) 2015 ooma. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "MapSearch.h"

@interface NSString (NSStringTrimSpace)
-(NSString*)trim;
@end

@implementation NSString (NSStringTrimSpace)

-(NSString*)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
}
@end

@interface MapSearch ()

@property NSInteger workCount;
@property (atomic, strong) NSFileHandle *outputFile;
@end

@implementation MapSearch

#define kSearchDone @"SearchDone"

@synthesize workCount;
@synthesize outputFile;
- (id)init
{
    if (self = [super init]) {
        self.workCount = 0;
        self.outputFile = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSearchDone:) name:kSearchDone object:nil];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"Search dealloc");
    [self closeOutputFile];
}

- (void)onSearchDone:(NSNotification*) notification
{
    workCount--;
    if (workCount <=0) {
        NSLog(@"Searching done.");
        [self closeOutputFile];
        [NSApp terminate:self];
    }
}

- (void)readCSV:(NSString*)inputFile outputFile:(NSString*)outFile maxRetry:(NSInteger)retry withCompletionHandler:(void (^)(NSError *error)) block
{
    if (self.workCount > 0) {
        NSLog(@"Search already in progress..");
        if (block) {
            block([NSError errorWithDomain:@"Ooma" code:1 userInfo:@{@"Search already in progress": NSLocalizedDescriptionKey}]);
        }
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

    NSError *outError = nil;
    NSString *fileString = [NSString stringWithContentsOfFile:inputFile encoding:NSUTF8StringEncoding error:&outError];
    if (!fileString) {
        NSLog(@"Error reading file. %@", [outError description]);
        if (block) {
            block(outError);
        }
        return;
    }
        NSLog(@"Opened input file: %@ with max_retry: %lu", inputFile, retry);
        
    NSArray *rows = [fileString componentsSeparatedByString:@"\n"];
    NSInteger count = [rows count];
    self.workCount = count;
    NSString *outputHeader = @"id,name,address,city,state,zip,phone,url\n";
    
    [self writeCSV:outputHeader filename:outFile];
        
    [self searchRows:rows outputFile:outFile retry:retry];
    
    if (block) {
        block(nil);
    }
        
    });
}

- (void)searchRows:(NSArray*)rows outputFile:(NSString*)outFile retry:(NSInteger)retry
{
    NSLocale *l_en = [[NSLocale alloc] initWithLocaleIdentifier: @"en_US"];
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setLocale: l_en];
    __block NSInteger curWork = 0;
    NSInteger count = [rows count];
    
    for (NSString *_row in rows) {
        NSString *row = [_row trim];
        if (row == nil ||
            row.length == 0 ||
            count == 0) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kSearchDone object:self];
            continue;
        }
        NSString *ref, *did, *name, *address, *city, *state, *zip_code;
        NSString *keywords;
        
        @try {
            NSArray *cols = [row componentsSeparatedByString:@","];
            if (cols == nil || [cols count] == 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kSearchDone object:self];
                continue;
            }
            
            ref = [cols[0] trim];
            did = [cols[1] trim];
            name = [cols[2] trim];
            address = [cols[3] trim];
            city = [cols[4] trim];
            state = [cols[5] trim];
            zip_code = [cols[6] trim];
            
            if ([f numberFromString:ref] == 0 ||
                [f numberFromString:did] == 0) {
                NSLog(@"Skipping line '%@' doesn't seem correct", row);
                [[NSNotificationCenter defaultCenter] postNotificationName:kSearchDone object:self];
                continue;
            }
            
            //keywords = [[NSString stringWithFormat:@"%@ %@ %@ %@ %@", name, address, city, state, zip_code] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            keywords = [[NSString stringWithFormat:@"%@ %@", name, zip_code] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            
            //NSLog(@"Scanned: key: %@ biz_name: %@ address: %@, city: %@ state: %@, zip_code: %@", ref, name, address, city, state, zip_code);
        }
        @catch (NSException *exception) {
            NSLog(@"Exception: %@", [exception description]);
            [[NSNotificationCenter defaultCenter] postNotificationName:kSearchDone object:self];
            continue;
        }

        if (retry == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kSearchDone object:self];
            continue;
        }
        [self search:keywords ref:(NSString*)ref withCompletionHandler:^(NSError *error, NSString *ref, NSArray *mapItems) {
            if ( error ) {
                NSLog(@"Search keywords: %@ got error: %@. Will retry %lu more time", keywords, [error description], (long)retry);
               
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self searchRows:@[row] outputFile:outFile retry:retry-1];
                });
            } else {
                for (MKMapItem *mapItem  in mapItems) {
                    NSString *out = [NSString stringWithFormat:@"%@,%@,%@ %@,%@,%@,%@,%@\n", ref, mapItem.name, mapItem.placemark.subThoroughfare,  mapItem.placemark.thoroughfare, mapItem.placemark.locality, mapItem.placemark.postalCode, mapItem.phoneNumber, mapItem.url];
                    
                    [self writeCSV:out filename:outFile];
                    
                    NSLog(@"Search keywords: %@ result: %@", keywords, out);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kSearchDone object:self];
            }
            curWork--;
            
        }];
        
        curWork++;
        if (curWork >= 200000) {
            do {
                [NSThread sleepForTimeInterval:0.0];
            }while(curWork != 0);
        } else {
            [NSThread sleepForTimeInterval:0.0];
        }
        
    }
}

- (NSString*)defaultOutputFilename
{
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY_MM_dd_HH_mm_ss"];
    NSString *filename = [NSString stringWithFormat:@"output_%@_.csv",[dateFormatter stringFromDate:now]];
    return filename;
}

- (BOOL)openOutputFile:(NSString*)filename
{
    @try {
        [[NSFileManager defaultManager] createFileAtPath:filename contents:nil attributes:nil];
        self.outputFile = [NSFileHandle fileHandleForWritingAtPath:filename];
        
        NSLog(@"Open output file: %@", filename);
    }
    @catch (NSException *exception) {
        NSLog(@"Open file exception: %@", [exception description]);
    }

    return (self.outputFile != nil);
}

- (void)closeOutputFile
{
    @try {
        if (self.outputFile) {
            [self.outputFile closeFile];
            self.outputFile = nil;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", [exception description]);
    }

}

- (BOOL)writeCSV:(NSString*)line filename:(NSString*)filename
{
    if (self.outputFile == nil) {
        if (filename == nil || filename.length == 0) {
            NSString *defFilename = [self defaultOutputFilename];
            filename = [NSString stringWithFormat:@"./%@", defFilename];
            NSLog(@"Default output file: %@", filename);
        }
        
        [self openOutputFile:filename];
        if (self.outputFile == nil) {
            NSLog(@"Unable to open file: %@", filename);
        }
    }

    
    @try {
        [self.outputFile seekToEndOfFile];
        [self.outputFile writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", [exception description]);
    }
    
    return YES;
}


- (void)search:(NSString*)keywords ref:(NSString*)ref withCompletionHandler:(void (^)(NSError *error, NSString *ref, NSArray *mapItems)) block
{
    @autoreleasepool {
     
        MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
       
        request.naturalLanguageQuery = keywords;
        MKLocalSearchCompletionHandler completionHandler = ^(MKLocalSearchResponse *response, NSError *error) {
            if (error != nil) {
                
                if (block) {
                    block(error, ref, nil);
                }
            } else {
                if (block) {
                    block(error, ref, [response mapItems]);
                }
            }
        };
        
        MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:request];
        [localSearch startWithCompletionHandler:completionHandler];
    }
    
}

@end