//
//  TTPlace.h
//  TripTrunk
//
//  Created by Matt Schoch on 9/20/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>

@interface TTPlace : PFObject <PFSubclassing>

@property NSString *name;
@property NSString *city;
@property NSString *state;
@property NSString *country;
@property NSString *gpID;
@property NSString *admin2;
@property double latitude;
@property double longitude;


@end
