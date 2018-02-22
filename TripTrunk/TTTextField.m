//
//  TTTextField.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/21/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTTextField.h"
#import "TTColor.h"

@implementation TTTextField

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
