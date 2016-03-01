//
//  UserTableViewCell.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@protocol UserTableViewCellDelegate;

@interface UserTableViewCell : UITableViewCell
@property (nonatomic, weak) id<UserTableViewCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicImageView;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (nonatomic, weak, readonly) PFUser *user;



- (void)setUser:(PFUser *)user;


@end

@protocol UserTableViewCellDelegate <NSObject>

- (void)cell:(UserTableViewCell *)cellView didPressFollowButton:(PFUser *)user;

@end
