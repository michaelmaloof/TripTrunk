//
//  TTRoundedImage.m
//  TripTrunk
//
//  Created by Michael Cannell on 8/1/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTRoundedImage.h"
#import "TTColor.h"
#import <QuartzCore/QuartzCore.h>

@implementation TTRoundedImage

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.layer setCornerRadius:6.0f];
    [self.layer setMasksToBounds:YES];
//    [self.layer setShadowColor:[[TTColor tripTrunkGray] CGColor]];
//    [self.layer setShadowOffset:CGSizeMake(2.0f,2.0f)];
//    [self.layer setShadowOpacity:1.0f];
}

@end
