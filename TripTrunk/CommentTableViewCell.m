//
//  CommentTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 8/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "CommentTableViewCell.h"

@interface CommentTableViewCell ()
@property (nonatomic, strong) PFUser *user;

@end

@implementation CommentTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(PFUser *)user {
    _user = user;
    
    [self.usernameLabel setText:user[@"username"]];

}

@end
