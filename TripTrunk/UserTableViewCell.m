//
//  UserTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "UserTableViewCell.h"
#import "UIColor+HexColors.h"

@interface UserTableViewCell ()

@property (nonatomic, weak) PFUser *user;

@end

@implementation UserTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.profilePicImageView setClipsToBounds:YES];
    UIColor *ttBlueColor = [UIColor colorWithHexString:@"76A4B8"];
    
    [self.followButton setTintColor:ttBlueColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(PFUser *)user {
    _user = user;
    NSString *name = [NSString stringWithFormat:@"%@ %@",user[@"firstName"],user[@"lastName"]];
    [self.nameLabel setText:name];
    [self.usernameLabel setText:[NSString stringWithFormat:@"@%@", user.username]];
    
}

- (IBAction)followButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didPressFollowButton:)]) {
        [self.delegate cell:self didPressFollowButton:_user];
    }
}

@end
