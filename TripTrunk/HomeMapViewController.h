//
//  ViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TTBaseViewController.h"
#import "Trip.h"

//HomeViewController displays trips on a map. Can be used on the user's "home" map, where all their friend's trips are shown, or can be used on a profile, which shows just that user's trips.

@interface HomeMapViewController : TTBaseViewController
@property PFUser *user;
@property NSMutableArray *viewedTrunks; //trunks the user has seen during this session of the app
@property NSMutableArray *viewedPhotos; //photos the user has seen during this session of the app

/**
 *   Updates the trunk color on the map
 *
 *   @param trip the trip
 *   @param isHot has a photo been added to the trip in the last 24 hours
 *   @param isMember is the current user a member of this trip
 */
-(void)updateTrunkColor:(Trip*)trip isHot:(BOOL)isHot member:(BOOL)isMember;

/**
 *   Updates the map icon on the city of the trunk when a particular trunk was delete. Use this when you delete a trunk and need to update the map.
 *
 *   @param location long and lat of where the dot is placed on the map that needs to be removed
 *   @param trip the trip that was just deleted
 *
 */
-(void)checkToDeleteCity:(CLLocation*)location trip:(Trip*)trip;

/**
 *   Deletes the city pin because there aren't actually trunks in there. Don't use this to delete a trunk off the map, instead use checkToDeleteCity
 *
 *   @param location long and lat of where the dot is placed on the map that needs to be removed
 *   @param trip the trip that was never found
 *
 */
-(void)deleteTrunk:(CLLocation*)location trip:(Trip*)trip;

/**
 *   This is called when the user just updated a trip on the map. We dont want to refresh the map in case the trip hasn't been updated in the database yet. For example, if I add a photo to a trip the dot will turn red. Then if I go back into the map itll relaod the trips. Because the photo hasnt finished uploading, itll appear as if this trip has no new photos so the dot will turn blue confusing the user. This method tells the map not to update the map through the databse and instead to trust our manual update of the dots through delegation
 *
 *
 *
 *
 */
-(void)dontRefreshMap;

/**
 *   Add Trip to the Array of Trips the user has seen
 *
 *   
 *   @param trip the trip the current user just saw
 *
 */
-(void)addTripToViewArray:(Trip*)trip;



@end

