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
    
//    self.videoContainerView.frame = self.newsfeedPhoto.frame;
}

-(void)prepareForReuse{
    [super prepareForReuse];
    
//    self.privateImageView;
//    self.userprofile;
//    self.newsfeedPhoto;
//    self.username;
//    self.tripName;
//    self.timeStamp;
//    self.location;
//    self.subPhotoButtons;
//    self.photoVideoView;
//    self.viewCountLabel;
//    self.videoSoundButton;
//    self.videoContainerView = nil;
//    self.avPlayer = nil;
}

@end
