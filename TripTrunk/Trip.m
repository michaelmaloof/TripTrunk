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
@dynamic isPrivate;
@dynamic start;
@dynamic lat;
@dynamic longitude;
@dynamic descriptionStory;
@dynamic publicTripDetail;
@dynamic gpID;

+(NSString *)parseClassName
{
    return @"Trip";
}


+(void)load
{
    [self registerSubclass];
}

- (void)setPlaceData:(TTPlace *)place;
{
    self.lat = place.latitude;
    self.longitude = place.longitude;
    self.state = place.state;
    self.city = place.city;
    self.country = place.country;
    self.gpID = place.gpID;
}

@end
