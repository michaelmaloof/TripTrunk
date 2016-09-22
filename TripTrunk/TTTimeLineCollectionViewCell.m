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
    [super awakeFromNib];
    self.userprofile.backgroundColor = [TTColor tripTrunkBlue];
    self.newsfeedPhoto.backgroundColor = [TTColor tripTrunkBlue];
}




@end
