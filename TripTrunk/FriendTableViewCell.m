//
//  FriendTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/7/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "FriendTableViewCell.h"
#import "TTColor.h"

@interface FriendTableViewCell ()

@property (nonatomic, strong) PFUser *user;

@end

@implementation FriendTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.userImageView setClipsToBounds:YES];

    [self.followButton setTintColor:[TTColor tripTrunkBlue]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setUser:(PFUser *)user {
    _user = user;
    
    NSString *name;
    if (_user[@"firstName"] == nil || _user[@"lastName"] == nil){
        name = [NSString stringWithFormat:@"%@",_user[@"name"]];
    } else {
        name = [NSString stringWithFormat:@"%@ %@",_user[@"firstName"],_user[@"lastName"]];
    }
    
    [self.nameLabel setText:name];
    [self.usernameLabel setText:user.username];
    
}


- (IBAction)followButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didPressFollowButton:)]) {
        [self.delegate cell:self didPressFollowButton:_user];
    }
}

@end
