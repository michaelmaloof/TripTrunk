//
//  Trip.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "Trip.h"

@implementation Trip

@dynamic name;
@dynamic city;
@dynamic creator;
@dynamic user;
@dynamic startDate;
@dynamic endDate;
@dynamic state;
@dynamic country;
@dynamic mostRecentPhoto;
@dynamic isPrivate;
@dynamic start;
@dynamic lat;
@dynamic longitude;
@dynamic descriptionStory;


+(NSString *)parseClassName
{
    return @"Trip";
}


+(void)load
{
    [self registerSubclass];
}

@end
