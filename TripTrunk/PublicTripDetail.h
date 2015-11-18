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

@interface PublicTripDetail : PFObject <PFSubclassing>
@property NSDate *mostRecentPhoto;
@property int photoCount;
@property int totalLikes;


@end
