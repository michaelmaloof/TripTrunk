//
//  TTPreviewPhotoViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 1/17/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTPreviewPhotoViewController.h"
#import "UIImageView+AFNetworking.h"
#import "TTCache.h"
#import "TTUtility.h"
#import "TTAnalytics.h"
#import "SocialUtility.h"
#import "SharkfoodMuteSwitchDetector.h"
#import "MBProgressHUD.h"

@interface TTPreviewPhotoViewController ()
@property (strong, nonatomic) IBOutlet TTRoundedImage *ProfilePic;
@property (strong, nonatomic) IBOutlet UILabel *firstLastName;
@property (strong, nonatomic) IBOutlet UILabel *username;
@property (strong, nonatomic) IBOutlet UIImageView *photoPreview;
@property (strong, nonatomic) IBOutlet UIImageView *video_icon;
@property int viewCount;
@property (nonatomic, weak) AVPlayerLayer *layer;
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIView *videoPlayerView;
@property (nonatomic, weak) SharkfoodMuteSwitchDetector* detector;
@end

@implementation TTPreviewPhotoViewController

//Monitor Ring/Silent switch and adjust the GUI to match
//-(id)initWithCoder:(NSCoder *)aDecoder{
//    self = [super initWithCoder:aDecoder];
//    if (self){
//        self.detector = [SharkfoodMuteSwitchDetector shared];
//        __weak TTPreviewPhotoViewController* sself = self;
//        self.detector.silentNotify = ^(BOOL silent){
//            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
//            if(silent)
//                sself.video_sound_button.selected = NO;
//            else sself.video_sound_button.selected = YES;
//        };
//    }
//    return self;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.photoPreview setImageWithURL:[NSURL URLWithString:self.photo.imageUrl]];
    self.photoPreview.contentMode = UIViewContentModeScaleAspectFill;
    [self.photo.user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self.ProfilePic setImageWithURL:[NSURL URLWithString:self.photo.user[@"profilePicUrl"]]];
        self.firstLastName.text = self.photo.user[@"name"];
    }];
    self.username.text = [NSString stringWithFormat:@"@%@",self.photo.userName];
    if(self.photo.video)
        self.video_icon.hidden = NO;
    
    [self setupViewForVideo];
}

//-(void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:YES];
//    __weak TTPhotoViewController* sself = self;
//    self.detector.silentNotify = ^(BOOL silent){
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
//        if(silent)
//            sself.video_sound_button.selected = NO;
//        else sself.video_sound_button.selected = YES;
//
//    };
//}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    //prevent calling this if it's a photo
    if(self.photo.video && self.viewCount > 0)
        [TTUtility updateVideoViewCount:self.photo.objectId withCount:self.viewCount];
    [self.activityIndicator stopAnimating];
    [self clearVideo];
}

-(void)viewDidLayoutSubviews{
    self.photoPreview.contentMode = UIViewContentModeScaleAspectFill;
    self.ProfilePic.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupNotificationCenter{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveVideoViews)
                                                 name:UIApplicationWillTerminateNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveVideoViews)
                                                 name:UIApplicationWillResignActiveNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivePlaybackStartedNotification:)
                                                 name:@"PlaybackStartedNotification"
                                               object:nil];
}

-(void)setupViewForVideo{
//    self.video_sound_button.hidden = YES;
//    self.viewCountLabel.hidden = YES;
    
    if(self.photo.video){
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicator.frame = CGRectMake((kScreenWidth/2), (kScreenHeight/2), 32, 32);
        [self.view addSubview:self.activityIndicator];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator startAnimating];
        });
        
        [self.photo.video fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            NSURL *url = [NSURL URLWithString:self.photo.video[@"videoUrl"]];
            self.player = [AVPlayer playerWithURL:url];
            
            self.layer = [AVPlayerLayer layer];
            [self.layer setPlayer:self.player];
            [self.layer setFrame:CGRectMake(0, 0, 320, 368)];
            [self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            
            [self.videoPlayerView.layer addSublayer:self.layer];
            
            [self.player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:[self.player currentItem]];
            [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
            self.viewCount = 1;
            self.photo.viewCount=[NSNumber numberWithInt:[self.photo.viewCount intValue]+1];
//            self.viewCountLabel.text = [NSString stringWithFormat:@"%@",self.photo.viewCount];
            [self.player.currentItem seekToTime:kCMTimeZero];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.player play];
                //                view.scrollEnabled = NO;
                //                view.pinchGestureRecognizer.enabled = NO;
            });
//            self.video_sound_button.hidden = NO;
//            self.viewCountLabel.hidden = NO;
            
            // Declare block scope variables to avoid retention cycles
            // from references inside the block
            __block AVPlayer* blockPlayer = self.player;
            __block id obs;
            
            // Setup boundary time observer to trigger when audio really begins,
            // specifically after 1/3 of a second playback
            obs = [self.player addBoundaryTimeObserverForTimes:
                   @[[NSValue valueWithCMTime:CMTimeMake(1, 3)]]
                                                         queue:NULL
                                                    usingBlock:^{
                                                        
                                                        // Raise a notificaiton when playback has started
                                                        [[NSNotificationCenter defaultCenter]
                                                         postNotificationName:@"PlaybackStartedNotification"
                                                         object:url];
                                                        
                                                        // Remove the boundary time observer
                                                        [blockPlayer removeTimeObserver:obs];
                                                    }];
        }];
    }
}

//AVPlayer Observers
//handle the end of the video
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    self.viewCount++;
    self.photo.viewCount=[NSNumber numberWithInt:[self.photo.viewCount intValue]+1];
//    self.viewCountLabel.text = [NSString stringWithFormat:@"%@",self.photo.viewCount];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.player play];
        //        self.scrollView.scrollEnabled = NO;
        //        self.scrollView.pinchGestureRecognizer.enabled = NO;
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerItemStatusReadyToPlay) {
            [self.activityIndicator stopAnimating];
            //            [self.scrollView sendSubviewToBack:self.imageView];
        } else if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"There was an error loading the video");
        }
    }
}

#pragma mark - Video
-(void)deallocateVideo{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillTerminateNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillResignActiveNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:@"PlaybackStartedNotification"];
    
    @try{
        [self.player removeObserver:self forKeyPath:@"status"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

-(void)clearVideo{
    
    @try{
        [self.player removeObserver:self forKeyPath:@"status"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
//    __weak TTPreviewPhotoViewController* sself = self;
//    self.detector.silentNotify = ^(BOOL silent){
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
////        if(silent)
////            sself.video_sound_button.selected = NO;
////        else sself.video_sound_button.selected = YES;
//
//    };
    [self.activityIndicator stopAnimating];
//    self.video_sound_button.hidden = YES;
    [self.player pause];
    [self.layer removeFromSuperlayer];
    self.player = nil;
    self.layer = nil;
}

-(void)saveVideoViews{
    if(self.photo.video && self.viewCount > 0){
        [TTUtility updateVideoViewCount:self.photo.objectId withCount:self.viewCount];
        self.viewCount = 0;
    }
}

-(void) receivePlaybackStartedNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"PlaybackStartedNotification"]) {
        [self.activityIndicator stopAnimating];
        [self.player play];
    }
}

@end
