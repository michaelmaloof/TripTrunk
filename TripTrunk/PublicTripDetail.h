//
//  PublicTripDetail.h
//  TripTrunk
//
//  Created by Michael Maloof on 11/18/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>
#import "Trip.h"
@class Trip;
@interface PublicTripDetail : PFObject <PFSubclassing>
@property NSDate *mostRecentPhoto;
@property int photoCount;
@property int totalLikes;
@property int memberCount;
@property Trip *trip;
@property PFGeoPoint *geoPoint;
@end
