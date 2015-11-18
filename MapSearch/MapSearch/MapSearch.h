//
//  MapSearch.h
//  MapSearch
//
//  Created by Yeffry on 9/14/15.
//  Copyright (c) 2015 ooma. All rights reserved.
//

#ifndef MapSearch_MapSearch_h
#define MapSearch_MapSearch_h

#define kSearchDone @"SearchDone"

#import <CoreLocation/CoreLocation.h>

#import <MapKit/MapKit.h>


@interface MapSearch : NSObject

- (void)readCSV:(NSDictionary*)data withCompletionHandler:(void (^)(NSError *error)) block;

@end


#endif
