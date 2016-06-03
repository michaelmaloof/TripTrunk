//
//  TTUserProfileImage.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/25/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTUserProfileImage.h"

@implementation TTUserProfileImage

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

-(void)layoutSubviews{
    [super layoutSubviews];
    int imageWidth = self.frame.size.width;
    self.layer.cornerRadius = imageWidth/2;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 0;

}
@end
