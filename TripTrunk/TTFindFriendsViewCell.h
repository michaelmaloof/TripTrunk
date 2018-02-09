//
//  TTFindFriendsViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 2/7/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTBaseTableViewCell.h"
#import "TTUserProfileImage.h"

@interface TTFindFriendsViewCell : TTBaseTableViewCell
@property (strong, nonatomic) IBOutlet TTUserProfileImage *profilePic;
@property (strong, nonatomic) IBOutlet UILabel *firstLastName;
@property (strong, nonatomic) IBOutlet UIButton *followButton;

@end
