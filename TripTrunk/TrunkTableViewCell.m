//
//  TrunkTableViewCell.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/26/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TrunkTableViewCell.h"
#import "TTColor.h"

@implementation TrunkTableViewCell

- (void)awakeFromNib {
    [self.profileImage setContentMode:UIViewContentModeScaleAspectFill];
    [self.profileImage.layer setCornerRadius:15.0f];
    [self.profileImage.layer setMasksToBounds:YES];
    [self.profileImage.layer setBorderWidth:2.0f];
    self.profileImage.layer.borderColor = (__bridge CGColorRef _Nullable)([TTColor tripTrunkWhite]);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
