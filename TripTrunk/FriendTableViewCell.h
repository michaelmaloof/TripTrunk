//
//  FriendTableViewCell.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/7/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Parse/Parse.h>
#import "TTBaseTableViewCell.h"

@protocol FriendTableViewCellDelegate;

@interface FriendTableViewCell : TTBaseTableViewCell

@property (nonatomic, strong) id<FriendTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIButton *followButton;


- (void)setUser:(PFUser *)user;


@end


@protocol FriendTableViewCellDelegate <NSObject>

- (void)cell:(FriendTableViewCell *)cellView didPressFollowButton:(PFUser *)user;

@end
