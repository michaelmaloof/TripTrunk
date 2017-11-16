//
//  TTLikeButton.m
//  TripTrunk
//
//  Created by Michael Cannell on 11/14/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTLikeButton.h"
#import "TTColor.h"

@implementation TTLikeButton

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.layer setCornerRadius:25.0f];
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[[TTColor tripTrunkGray] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(2.0f,2.0f)];
    [self.layer setShadowOpacity:1.0f];
    [[self.imageView layer] setCornerRadius:25.0f];
}

@end
