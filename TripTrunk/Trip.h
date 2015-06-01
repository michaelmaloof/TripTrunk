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
//TODO: make user a PFUser object and change the Parse Class to be a pointer, not a string with just the username
@property NSString *user;
@property NSString *startDate;
@property NSString *endDate;
@property NSDate *mostRecentPhoto;
@property BOOL isPrivate;

@end
