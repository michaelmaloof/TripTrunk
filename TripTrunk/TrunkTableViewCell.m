//
//  TrunkTableViewCell.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/26/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TrunkTableViewCell.h"

@implementation TrunkTableViewCell

- (void)awakeFromNib {
    [self.profileImage setContentMode:UIViewContentModeScaleAspectFill];
    self.profileImage.frame = CGRectMake(self.profileImage.frame.origin.x, self.profileImage.frame.origin.y, self.frame.size.height,  self.frame.size.height);
    [self.profileImage.layer setCornerRadius:22.0f];
    [self.profileImage.layer setMasksToBounds:YES];
    self.profileImage.backgroundColor = [TTColor tripTrunkBlue];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
