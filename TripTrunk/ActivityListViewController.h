//
//  ActivityListViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 7/27/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityListViewController : UIViewController

- (id)initWithLikes:(NSArray *)likes;

- (id)initWithComments:(NSArray *)comments;

- (id)initWithActivities:(NSArray *)activities;



@end
