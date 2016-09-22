//
//  Activity.h
//  TripTrunk
//
//  Created by Matt Schoch on 9/22/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>
#import "Trip.h"
#import "Photo.h"


@interface Activity : PFObject <PFSubclassing>

@property PFUser *toUser;
@property PFUser *fromUser;
@property NSString *type;
@property Trip *trip;
@property Photo *photo;

@property NSString *content;
@property BOOL isCaption;
@property double latitude;
@property double longitude;
@property NSString *gpID; // Google Place ID

/**
 * setPlaceData
 * Sets the Latitude and Longitude properties and the Google PlaceID property (gpID)
 */
- (void)setPlaceData:(TTPlace *)place;

@end
