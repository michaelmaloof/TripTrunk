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


@interface HomeMapViewController : TTBaseViewController
@property PFUser *user;
@property NSMutableArray *viewedTrunks;


/**
 *  Updates the trunk color on the map
 *
 *
 */
-(void)updateTrunkColor:(Trip*)trip isHot:(BOOL)isHot member:(BOOL)isMember;

/**
 *  Deletes the city pin because there aren't actually trunks in there. Don't use this to delete a trunk off the map, instead use checkToDeleteCity
 *
 *
 */
-(void)deleteTrunk:(CLLocation*)location trip:(Trip*)trip;

/**
 *  Updates the map icon on the city of the trunk when a particular trunk was delete. Use this when you delete a trunk and need to update the map.
 *
 *
 */
-(void)checkToDeleteCity:(CLLocation*)location trip:(Trip*)trip;

-(void)dontRefreshMap;

-(void)addTripToViewArray:(Trip*)trip;



@end

