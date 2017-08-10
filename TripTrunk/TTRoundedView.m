//
//  TTRoundedView.m
//  TripTrunk
//
//  Created by Michael Cannell on 7/31/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTRoundedView.h"
#import "TTColor.h"
#import <QuartzCore/QuartzCore.h>

@implementation TTRoundedView

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.layer setCornerRadius:11.0f];
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[[TTColor tripTrunkGray] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(0.5f,0.5f)];
    [self.layer setShadowOpacity:0.5f];
}

@end
