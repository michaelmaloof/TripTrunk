//
//  UserProfileViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface UserProfileViewController : UIViewController

/**
 *  Initialize the view controller for the given user, loads ProfileViewController.xib
 *
 *  @param user PFUser to load into the view
 *
 *  @return self
 */
- (id)initWithUser:(PFUser *)user;


@property (strong, nonatomic) IBOutlet UIButton *followersButton;
@property (strong, nonatomic) IBOutlet UIButton *followingButton;
@property (strong, nonatomic) IBOutlet UIButton *findFriendsButton;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;
@property (strong, nonatomic) IBOutlet UIButton *followButton;

@end
