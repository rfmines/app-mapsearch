//
//  AppDelegate.h
//  MapSearch
//
//  Created by Yeffry on 9/15/15.
//  Copyright (c) 2015 zakizon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MapSearch.h"

/* Maximum search retry */
#define MAX_RETRY 3

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) MapSearch *mapsearch;

@end

