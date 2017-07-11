//
//  TTHomeMapCollectionViewCell.m
//  TripTrunk
//
//  Created by Michael Cannell on 6/15/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTHomeMapCollectionViewCell.h"

@implementation TTHomeMapCollectionViewCell

-(void)awakeFromNib{
    [super awakeFromNib];
    self.layer.cornerRadius = 10.0f;
    self.layer.masksToBounds = YES;
}

-(void)prepareForReuse{
    self.trunkTitle.text = @"";
    self.trunkDates.text = @"";
    self.trunkLocation.text = @"";
    self.trunkMemberInfo.text = @"";
    self.spotlightTrunkImage.image = [UIImage imageNamed:@"tt_square_placeholder"];
    self.secondaryTrunkImage.image = [UIImage imageNamed:@"tt_square_placeholder"];
    self.tertiaryTrunkImage.image = [UIImage imageNamed:@"tt_square_placeholder"];
    self.quaternaryTrunkImage.image = [UIImage imageNamed:@"tt_square_placeholder"];
    
    self.spotlightImageHeightConstraint.constant = 249;
    self.lowerInfoConstraint.constant = 148;
}

@end
