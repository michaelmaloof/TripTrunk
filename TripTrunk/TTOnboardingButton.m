//
//  TTOnboardingButton.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/10/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTOnboardingButton.h"
#import "TTColor.h"
#import <QuartzCore/QuartzCore.h>

@implementation TTOnboardingButton

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.layer setCornerRadius:25.0f];
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[[TTColor tripTrunkGray] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(2.0f,2.0f)];
    [self.layer setShadowOpacity:1.0f];
}

@end
