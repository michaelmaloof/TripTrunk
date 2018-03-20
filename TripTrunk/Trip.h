//
//  Trip.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>
#import "PublicTripDetail.h"
#import "TTPlace.h"

@class PublicTripDetail;

@interface Trip : PFObject <PFSubclassing>

@property NSString *name;
@property NSString *city;
@property NSString *country;
@property NSString *state;
@property PFUser *creator;
@property PublicTripDetail *publicTripDetail;
@property NSString *user;
@property NSString *startDate;
@property NSDate *start;
@property NSString *endDate;
@property BOOL isPrivate;
@property double lat;
@property double longitude;
@property NSString *descriptionStory;
@property NSString *gpID; // gpID is a Google ID for this Place


- (void)setPlaceData:(TTPlace *)place;


@end
