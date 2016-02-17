//
//  TTTimeLineCollectionViewCell.m
//  TripTrunk
//
//  Created by Michael Maloof on 2/15/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTTimeLineCollectionViewCell.h"

@implementation TTTimeLineCollectionViewCell
- (void)awakeFromNib {
    [self.userprofile.layer setCornerRadius:20.0f];
    [self.userprofile.layer setMasksToBounds:YES];
    [self.userprofile.layer setBorderWidth:2.0f];
    self.userprofile.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);}


@end
