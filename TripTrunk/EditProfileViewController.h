//
//  EditProfileViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 9/10/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TTBaseViewController.h"


@protocol EditProfileViewControllerDelegate;

@interface EditProfileViewController : TTBaseViewController

@property (weak, nonatomic) id<EditProfileViewControllerDelegate> delegate;



/**
 *  Initialize the view controller for the given user, loads EditProfileViewController.xib
 *
 *  @param user PFUser to load for editing
 *
 *  @return self
 */
- (id)initWithUser:(PFUser *)user;

@end

@protocol EditProfileViewControllerDelegate <NSObject>

- (void)shouldSaveUserAndClose:(PFUser *)user;
- (void)privacyChanged:(PFUser *)user;

@end