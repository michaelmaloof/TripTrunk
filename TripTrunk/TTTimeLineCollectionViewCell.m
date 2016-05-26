//
//  TTTimeLineCollectionViewCell.m
//  TripTrunk
//
//  Created by Michael Maloof on 2/15/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTTimeLineCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "TTColor.h"

@implementation TTTimeLineCollectionViewCell
- (void)awakeFromNib {

self.userprofile.backgroundColor = [TTColor tripTrunkBlue];
self.newsfeedPhoto.backgroundColor = [TTColor tripTrunkBlue];

}




@end
