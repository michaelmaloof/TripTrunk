//
//  Excursion.h
//  TripTrunk
//
//  Created by Michael Cannell on 8/11/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>
#import "Trip.h"

@interface Excursion : PFObject <PFSubclassing>

@property PFUser *creator;
@property NSString *trip;
@property Trip *trunk;
@property PFGeoPoint *homeAtCreation;

@end
