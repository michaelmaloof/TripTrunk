//
//  TTOnboardingTextField.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/10/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTOnboardingTextField.h"
#import <QuartzCore/QuartzCore.h>
#import "TTColor.h"

@interface TTOnboardingTextField()

@end

@implementation TTOnboardingTextField

- (CGRect)textRectForBounds:(CGRect)bounds{
    return CGRectInset(bounds, 10.0f, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds{
    return [self textRectForBounds:bounds];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[[TTColor tripTrunkBlack] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(2.0f,2.0f)];
    [self.layer setShadowOpacity:0.25f];
}

@end
