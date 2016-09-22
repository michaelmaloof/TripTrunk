//
//  UserCellCollectionViewCell.m
//  TripTrunk
//
//  Created by Michael Maloof on 9/22/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "UserCellCollectionViewCell.h"
#import "TTColor.h"

@implementation UserCellCollectionViewCell

-(void)awakeFromNib{
    [super awakeFromNib];
    [self.layer setCornerRadius:25.0f];
    [self.layer setMasksToBounds:YES];
    [self.layer setBorderWidth:2.0f];
    self.profileImage.backgroundColor = [TTColor tripTrunkBlue];
    self.layer.borderColor = (__bridge CGColorRef _Nullable)([TTColor tripTrunkWhite]);
}
@end
