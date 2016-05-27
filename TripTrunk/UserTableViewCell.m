//
//  UserTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "UserTableViewCell.h"
#import "TTColor.h"

@interface UserTableViewCell ()

@property (nonatomic, weak) PFUser *user;


@end

@implementation UserTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.followButton setTintColor:[TTColor tripTrunkBlue]];
    [self setProfileImageDisplay];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    if (selected) {
        self.backgroundColor = [TTColor tripTrunkRedThirdAlpha];
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        self.backgroundColor = [TTColor tripTrunkWhite];
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [super setSelected:selected animated:animated];
}

- (void)setUser:(PFUser *)user {
    _user = user;
    NSString *name;
    if (user[@"firstName"] == nil || user[@"lastName"] == nil){
        name = [NSString stringWithFormat:@"%@",user[@"name"]];
    } else {
        name = [NSString stringWithFormat:@"%@ %@",user[@"firstName"],user[@"lastName"]];
    }
    [self.nameLabel setText:name];
    [self.usernameLabel setText:[NSString stringWithFormat:@"@%@", user.username]];
    
}

- (IBAction)followButtonPressed:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didPressFollowButton:)]) {
        [self.delegate cell:self didPressFollowButton:_user];
    }
}

-(void)setProfileImageDisplay{
    [self.profilePicImageView setClipsToBounds:YES];
    self.profilePicImageView.backgroundColor = [TTColor tripTrunkBlue];
    [self.profilePicImageView.layer setCornerRadius:28.0f];
    [self.profilePicImageView.layer setMasksToBounds:YES];
    [self.profilePicImageView.layer setBorderWidth:2.0f];
    self.profilePicImageView.layer.borderColor = (__bridge CGColorRef _Nullable)([TTColor tripTrunkWhite]);
}

@end
