//
//  TTTrunkMemberViewCell.m
//  TripTrunk
//
//  Created by Michael Cannell on 6/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTTrunkMemberViewCell.h"


@implementation TTTrunkMemberViewCell

-(void)awakeFromNib{
    [super awakeFromNib];
    self.userName.adjustsFontSizeToFitWidth = YES;
}

@end
