//
//  ActivityListViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 7/27/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "TTBaseViewController.h"


@interface ActivityListViewController : TTBaseViewController

- (id)initWithLikes:(NSArray *)likes;

- (id)initWithActivities:(NSArray *)activities;



@end
