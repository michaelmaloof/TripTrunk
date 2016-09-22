//
//  Activity.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/22/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "Activity.h"

@implementation Activity

@dynamic trip;
@dynamic toUser;
@dynamic type;
@dynamic photo;
@dynamic fromUser;
@dynamic content;
@dynamic isCaption;
@dynamic latitude;
@dynamic longitude;
@dynamic gpID;


+ (NSString *)parseClassName
{
    return @"Activity";
}


+ (void)load
{
    [self registerSubclass];
}

- (void)setPlaceData:(TTPlace *)place;
{
    self.latitude = place.latitude;
    self.longitude = place.longitude;
    self.gpID = place.gpID;
}

@end
