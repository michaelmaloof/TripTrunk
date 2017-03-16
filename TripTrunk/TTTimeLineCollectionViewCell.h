//
//  TTTimeLineCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 2/15/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTBaseCollectionViewCell.h"
#import <AVFoundation/AVFoundation.h>

@interface TTTimeLineCollectionViewCell : TTBaseCollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *privateImageView;
@property (weak, nonatomic) IBOutlet UIImageView *userprofile;
@property (weak, nonatomic) IBOutlet UIImageView *newsfeedPhoto;
@property (weak, nonatomic) IBOutlet UIButton *username;
@property (weak, nonatomic) IBOutlet UIButton *tripName;
@property (weak, nonatomic) IBOutlet UILabel *timeStamp;
@property (weak, nonatomic) IBOutlet UIButton *location;
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *subPhotoButtons;
@property (strong, nonatomic) IBOutlet UIView *photoVideoView;
@property (strong, nonatomic) IBOutlet UILabel *viewCountLabel;
@property (strong, nonatomic) IBOutlet UIButton *videoSoundButton;
@property (strong, nonatomic) IBOutlet UIView *videoContainerView;
@property AVPlayer * avPlayer;
@end
