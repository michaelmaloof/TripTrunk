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

@interface Trip : PFObject <PFSubclassing>

@property NSString *name;
@property NSString *city;
@property NSString *country;
@property NSString *state;
@property NSString *user;
@property NSString *startDate;
@property NSString *endDate;
@property NSDate *mostRecentPhoto;
@property BOOL isPrivate;

@end
