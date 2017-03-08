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

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
}

-(void)prepareForReuse{
    [super prepareForReuse];
//    self.privateImageView=nil;
//    self.userprofile=nil;
//    self.newsfeedPhoto=nil;
//    self.username=nil;
//    self.tripName=nil;
//    self.timeStamp=nil;
//    self.location=nil;
//    self.subPhotoButtons=nil;
//    self.photoVideoView=nil;
//    self.viewCountLabel=nil;
//    self.videoSoundButton=nil;
//    self.avPlayer=nil;
}

@end
