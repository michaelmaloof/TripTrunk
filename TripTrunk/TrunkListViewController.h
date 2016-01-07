//
//  TrunkListViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/25/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TTBaseViewController.h"
#import "Trip.h"

@interface TrunkListViewController : TTBaseViewController
@property NSString *city;
@property NSString *state;
@property PFUser *user;
@property CLLocation *location;
@property BOOL isList;

@property NSMutableArray *parseLocations;
@property NSMutableArray *meParseLocations;

-(void)reloadTrunkList:(Trip*)trip;
-(void)deleteItemOnTrunkList:(Trip*)trip;



@end
