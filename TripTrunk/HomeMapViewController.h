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

-(void)updateTrunkColor:(Trip*)trip isHot:(BOOL)isHot;
-(void)deleteTrunk:(CLLocation*)location trip:(Trip*)trip;

@end

