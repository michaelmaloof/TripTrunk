//
//  FriendsListViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "TTBaseTableViewController.h"


@interface FriendsListViewController : TTBaseTableViewController
- (id)initWithUser:(PFUser *)user andFollowingStatus:(BOOL)isFollowing;

@end
