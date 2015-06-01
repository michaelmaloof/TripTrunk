//
//  UserTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "UserTableViewCell.h"

@interface UserTableViewCell ()

@property (nonatomic, strong) PFUser *user;

@end

@implementation UserTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(PFUser *)user {
    _user = user;
    
    [self.nameLabel setText:user[@"name"]];
    [self.usernameLabel setText:[NSString stringWithFormat:@"@%@", user.username]];
    
}

- (IBAction)followButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didPressFollowButton:)]) {
        [self.delegate cell:self didPressFollowButton:_user];
    }
}

@end
