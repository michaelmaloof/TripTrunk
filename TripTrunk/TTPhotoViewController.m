//
//  TTPhotoViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 9/21/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTPhotoViewController.h"
#import "TTOnboardingButton.h"
#import "UIImageView+AFNetworking.h"
#import "TTCache.h"
#import "TTUtility.h"
#import "TTAnalytics.h"
#import "SocialUtility.h"
#import "SharkfoodMuteSwitchDetector.h"
#import "HomeMapViewController.h"
#import "MBProgressHUD.h"

@interface TTPhotoViewController () <UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet TTOnboardingButton *heartButton;
@property (nonatomic, weak) AVPlayerLayer *layer;
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property BOOL isFetchingTrip;
@property (nonatomic, weak) SharkfoodMuteSwitchDetector* detector;
@property (strong, nonatomic) IBOutlet UILabel *viewCountLabel;
@property (strong, nonatomic) IBOutlet UIButton *video_sound_button;
@property int viewCount;
@end

@implementation TTPhotoViewController

//Monitor Ring/Silent switch and adjust the GUI to match
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.detector = [SharkfoodMuteSwitchDetector shared];
        __weak TTPhotoViewController* sself = self;
        self.detector.silentNotify = ^(BOOL silent){
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
            if(silent)
                sself.video_sound_button.selected = NO;
            else sself.video_sound_button.selected = YES;
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Create views for image scrolling
    UIScrollView *scrollView = [self setScrollViewForForegroundImage:0];
    UIImageView *newImageForeground = [self createUIImageView:0];
    UIImageView *newImageBackground = [self createUIImageView:0];
    UIView *viewsWrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenWidth,kScreenHeight)];
    
    //Create gesture recognizers
    UISwipeGestureRecognizer *swipeleft=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *swiperight=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    UITapGestureRecognizer *tapMute=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleVideoSound:)];
    tapMute.numberOfTapsRequired=1;
    
    //Image view settings
    newImageBackground.contentMode = UIViewContentModeScaleAspectFill;
    newImageBackground.alpha = 0.45;
    newImageBackground.tag = 1000;
    newImageForeground.tag = 1001;
    newImageForeground.userInteractionEnabled = YES;
    self.photo.image = newImageForeground.image;
    [newImageForeground addGestureRecognizer:tapMute];
    [scrollView addSubview:newImageForeground];
    scrollView.minimumZoomScale = 1.0;
    scrollView.maximumZoomScale = 6.0;
    scrollView.scrollEnabled = NO;
    scrollView.contentSize = newImageForeground.frame.size;
    
    //viewsWrapper settings
    viewsWrapper.userInteractionEnabled = YES;
    if(self.photos.count > 1){
        [viewsWrapper addGestureRecognizer:swiperight];
        [viewsWrapper addGestureRecognizer:swipeleft];
    }
    viewsWrapper.tag = 998;
    [viewsWrapper addSubview:newImageBackground];
    [viewsWrapper addSubview:scrollView];
    [self.view insertSubview:viewsWrapper atIndex:0];
    
    [self setupNotificationCenter];
    [self setupViewForVideo];
    
    [self refreshPhotoActivities];
    [self updateLikeStatusForCurrentPhoto];
    
    [self markPhotoAsViewed];
    
    [self preloadPreviousImage];
    [self preloadNextImage];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    __weak TTPhotoViewController* sself = self;
    self.detector.silentNotify = ^(BOOL silent){
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
        if(silent)
            sself.video_sound_button.selected = NO;
        else sself.video_sound_button.selected = YES;
        
    };
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    //prevent calling this if it's a photo
    if(self.photo.video && self.viewCount > 0)
        [TTUtility updateVideoViewCount:self.photo.objectId withCount:self.viewCount];
    [self.activityIndicator stopAnimating];
    [self clearVideo];
}

//WHAT IS THIS FOR?
-(void)markPhotoAsViewed{
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (HomeMapViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[HomeMapViewController class]])
            {
                if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                    if (view == (HomeMapViewController*)controller.viewControllers[0]){
                        
                        [view.viewedPhotos addObject:self.photo.objectId];
                        [TTAnalytics photoViewed:self.photo.objectId];
                        if ([(NSObject*)self.delegate respondsToSelector:@selector(photoWasViewed:)])
                            [self.delegate photoWasViewed:self.photo];
                    }
                }
            }
        }
    }
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
    self.video_sound_button.hidden = YES;
    self.viewCountLabel.hidden = YES;
    
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
            [self.layer setFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
//            [self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            
            UIView *v = [self.view viewWithTag:998];
            [v.layer addSublayer:self.layer];
            
            [self.player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:[self.player currentItem]];
            [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
            self.viewCount = 1;
            self.photo.viewCount=[NSNumber numberWithInt:[self.photo.viewCount intValue]+1];
            self.viewCountLabel.text = [NSString stringWithFormat:@"%@",self.photo.viewCount];
            [self.player.currentItem seekToTime:kCMTimeZero];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.player play];
//                view.scrollEnabled = NO;
//                view.pinchGestureRecognizer.enabled = NO;
            });
            self.video_sound_button.hidden = NO;
            self.viewCountLabel.hidden = NO;
            
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return (UIImageView *)[self.view viewWithTag:1001];
}

#pragma mark - Button Actions
- (IBAction)backActionButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)heartActionButton:(id)sender {
    self.heartButton.alpha = .3;
    self.heartButton.userInteractionEnabled = NO;
    
    // Like Photo
    if (!self.heartButton.selected){
        [self.heartButton setSelected:YES];
        [SocialUtility likePhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [[TTUtility sharedInstance] internetConnectionFound];
                [[TTCache sharedCache] incrementLikerCountForPhoto:self.photo];
            }else {
                [self.heartButton setSelected:NO];
                [[TTCache sharedCache] decrementLikerCountForPhoto:self.photo];
                [ParseErrorHandlingController handleError:error];
            }
            
            [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.heartButton.selected];
            self.heartButton.alpha = 1.0;
            self.heartButton.userInteractionEnabled = YES;
        }];
        
    }else if (self.heartButton.selected) {
    
        // Unlike Photo
        [self.heartButton setSelected:NO];
        [SocialUtility unlikePhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            
            if (succeeded) {
                [[TTCache sharedCache] decrementLikerCountForPhoto:self.photo];
                [[TTUtility sharedInstance] internetConnectionFound];
                
            }else {
                [self.heartButton setSelected:YES];
                [[TTCache sharedCache] incrementLikerCountForPhoto:self.photo];
                [ParseErrorHandlingController handleError:error];
            }
            
            [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.heartButton.selected];
            self.heartButton.alpha = 1;
            self.heartButton.userInteractionEnabled = YES;
        }];
    }
    
//    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
//    self.captionLabel.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];  //FIXME Why is this here?
}

- (IBAction)toggleVideoSound:(id)sender {
    
    if(self.video_sound_button.selected){
        self.video_sound_button.selected = NO;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
        self.player.muted = YES;
    }else{
        self.video_sound_button.selected = YES;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error: nil];
        self.player.muted = NO;
    }
}

- (IBAction)photoActionButtonWasTapped:(UIButton *)sender {
//    NSString *message = NSLocalizedString(@"Photo/Video options","Photo/Video options");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Media Options" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSString *downloadString = NSLocalizedString(@"Download", @"Download");
    UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:downloadString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        if(self.photo.video){
            [[TTUtility sharedInstance] downloadPhotoVideo:[NSURL URLWithString:self.photo.video[@"videoUrl"]]];
        }else{
            UIImageWriteToSavedPhotosAlbum(self.photo.image, nil, nil, nil);
            [TTAnalytics downloadPhoto];
        }
    }];
    [alert addAction:downloadAction];
    
    PFUser *theuser = [PFUser currentUser];
    if([self.photo.user.objectId isEqualToString:theuser.objectId]){
        NSString *deleteString = NSLocalizedString(@"Delete", @"Delete");
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:deleteString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.labelText = NSLocalizedString(@"Deleting...",@"Deleting...");
            [[TTUtility sharedInstance] deletePhoto:self.photo withblock:^(BOOL succeeded, NSError *error) {
                if (error) {
//                    self.photo.trip.publicTripDetail.photoCount = self.photo.trip.publicTripDetail.photoCount +1;
                    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat: @"Sorry, photo/video was not deleted with following error \n %@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
                    [errorAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { }]];
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    [self presentViewController:errorAlert animated:YES completion:nil];
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        if ([(NSObject*)self.delegate respondsToSelector:@selector(photoWasDeleted:photo:)])
                            [self.delegate photoWasDeleted:[[TTCache sharedCache] likeCountForPhoto:self.photo] photo:self.photo];
                        [self.navigationController popViewControllerAnimated:YES];
                    });
                }
            }];
        }];
        [alert addAction:deleteAction];
    }
    
    NSString *cancelActionString = NSLocalizedString(@"Cancel", @"Cancel");
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelActionString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        
    }];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - touches
- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
    
    //prevent calling this if it's a photo
    if(self.photo.video && self.viewCount > 0)
        [TTUtility updateVideoViewCount:self.photo.objectId withCount:self.viewCount];
        [self clearVideo];
    
    if((int)self.index == 0)
        self.index = (int)self.photos.count-1;
    else self.index--;
    
    //Create views for image scrolling
    UIView *v = [self.view viewWithTag:998];
    UIScrollView *scrollView = [self setScrollViewForForegroundImage:0];
    UIImageView *newImageForeground = [self createUIImageView:0];
    UIImageView *newImageBackground = [self createUIImageView:0];
    UIView *viewsWrapper = [[UIView alloc] initWithFrame:CGRectMake(0-kScreenWidth,0,kScreenWidth,kScreenHeight)];
    
    //Create gesture recognizers
    UISwipeGestureRecognizer *swipeleft=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *swiperight=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    UITapGestureRecognizer *tapMute=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleVideoSound:)];
    tapMute.numberOfTapsRequired=1;
    
    //Image view settings
    newImageBackground.contentMode = UIViewContentModeScaleAspectFill;
    newImageBackground.alpha = 0.45;
    newImageBackground.tag = 1000;
    newImageForeground.tag = 1001;
    newImageForeground.userInteractionEnabled = YES;
    self.photo.image = newImageForeground.image;
    [newImageForeground addGestureRecognizer:tapMute];
    scrollView.scrollEnabled = NO;
    [scrollView addSubview:newImageForeground];
    
    //viewsWrapper settings
    viewsWrapper.userInteractionEnabled = YES;
    [viewsWrapper addGestureRecognizer:swiperight];
    [viewsWrapper addGestureRecognizer:swipeleft];
    viewsWrapper.tag = 998;
    [viewsWrapper addSubview:newImageBackground];
    [viewsWrapper addSubview:scrollView];
    [self.view insertSubview:viewsWrapper atIndex:0];
    
    //Animate the swipe
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        v.frame = CGRectMake(kScreenWidth,0,kScreenWidth,kScreenHeight);
        viewsWrapper.frame = CGRectMake(0,0,kScreenWidth,kScreenHeight);
        [self setupViewForVideo];
    } completion:^(BOOL finished) {
        [self updateLikeStatusForCurrentPhoto];
        [v removeFromSuperview];
    }];
    
    [self preloadPreviousImage];
}


- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {

    //prevent calling this if it's a photo
    if(self.photo.video && self.viewCount > 0)
        [TTUtility updateVideoViewCount:self.photo.objectId withCount:self.viewCount];
    [self clearVideo];

    if((int)self.index == (int)self.photos.count-1)
        self.index = 0;
    else self.index++;

    //Create views for image scrolling
    UIView *v = [self.view viewWithTag:998];
    UIScrollView *scrollView = [self setScrollViewForForegroundImage:0];
    UIImageView *newImageForeground = [self createUIImageView:0];
    UIImageView *newImageBackground = [self createUIImageView:0];
    UIView *viewsWrapper = [[UIView alloc] initWithFrame:CGRectMake(kScreenWidth,0,kScreenWidth,kScreenHeight)];
    
    //Create gesture recognizers
    UISwipeGestureRecognizer *swipeleft=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *swiperight=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    UITapGestureRecognizer *tapMute=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleVideoSound:)];
    tapMute.numberOfTapsRequired=1;
    
    //Image view settings
    newImageBackground.contentMode = UIViewContentModeScaleAspectFill;
    newImageBackground.alpha = 0.45;
    newImageBackground.tag = 1000;
    newImageForeground.tag = 1001;
    newImageForeground.userInteractionEnabled = YES;
    self.photo.image = newImageForeground.image;
    [newImageForeground addGestureRecognizer:tapMute];
    scrollView.scrollEnabled = NO;
    [scrollView addSubview:newImageForeground];
    
    //viewsWrapper settings
    viewsWrapper.userInteractionEnabled = YES;
    [viewsWrapper addGestureRecognizer:swiperight];
    [viewsWrapper addGestureRecognizer:swipeleft];
    viewsWrapper.tag = 998;
    [viewsWrapper addSubview:newImageBackground];
    [viewsWrapper addSubview:scrollView];
    [self.view insertSubview:viewsWrapper atIndex:0];
    
    //Animate the swipe
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        v.frame = CGRectMake(0-kScreenWidth,0,kScreenWidth,kScreenHeight);
        viewsWrapper.frame = CGRectMake(0,0,kScreenWidth,kScreenHeight);
        [self setupViewForVideo];
    } completion:^(BOOL finished) {
        [self updateLikeStatusForCurrentPhoto];
        [v removeFromSuperview];
    }];

    [self preloadNextImage];
}

-(void)preloadPreviousImage{
    int nextIndex;
    if((int)self.index == 0)
        nextIndex = (int)self.photos.count-1;
    else nextIndex = self.index-1;
    
    UIImageView *preloadImage = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    Photo *newPhoto = self.photos[self.index];
    [preloadImage setImageWithURL:[NSURL URLWithString:newPhoto.imageUrl]];
}

-(void)preloadNextImage{
    int nextIndex;
    if((int)self.index == (int)self.photos.count-1)
        nextIndex = 0;
    else nextIndex = self.index+1;
    
    UIImageView *preloadImage = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    Photo *newPhoto = self.photos[self.index];
    [preloadImage setImageWithURL:[NSURL URLWithString:newPhoto.imageUrl]];
}

-(UIImageView*)createUIImageView:(int)x{
    UIImageView *imageView = [[UIImageView alloc] init];
    Photo *newPhoto = self.photos[self.index];
    self.photo = newPhoto;
    [self updateLikeStatusForCurrentPhoto];
    if(self.image)
        imageView.image = self.image;
    else [imageView setImageWithURL:[NSURL URLWithString:newPhoto.imageUrl]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = CGRectMake(x, 0, kScreenWidth, kScreenHeight);
    imageView.clipsToBounds = YES;
    
    return imageView;
}

-(UIScrollView*)setScrollViewForForegroundImage:(int)x{
    UIScrollView *scrollView =[[UIScrollView alloc] initWithFrame:CGRectMake(x, 0, kScreenWidth, kScreenHeight)];
    scrollView.userInteractionEnabled = YES;
    scrollView.scrollEnabled = YES;
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1.0;
    scrollView.maximumZoomScale = 6.0;
    scrollView.bouncesZoom = NO;
    scrollView.contentSize = CGSizeMake(kScreenWidth,kScreenHeight);
    scrollView.tag = 999;
    
    return scrollView;
}

-(void)updateLikeStatusForCurrentPhoto{
    self.heartButton.alpha = .3;
    self.heartButton.userInteractionEnabled = NO;
    [self.heartButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
    self.heartButton.alpha = 1;
    self.heartButton.userInteractionEnabled = YES;
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
    __weak TTPhotoViewController* sself = self;
    self.detector.silentNotify = ^(BOOL silent){
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
        if(silent)
            sself.video_sound_button.selected = NO;
        else sself.video_sound_button.selected = YES;
        
    };
    [self.activityIndicator stopAnimating];
    self.video_sound_button.hidden = YES;
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

//AVPlayer Observers
//handle the end of the video
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    self.viewCount++;
    self.photo.viewCount=[NSNumber numberWithInt:[self.photo.viewCount intValue]+1];
    self.viewCountLabel.text = [NSString stringWithFormat:@"%@",self.photo.viewCount];
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

#pragma mark - Photo Activities
-(void)refreshPhotoActivities{
    for(Photo *photo in self.photos){
        // Get Activities for Photo
        PFQuery *query = [SocialUtility queryForActivitiesOnPhoto:photo cachePolicy:kPFCachePolicyNetworkOnly];
        query.limit = 1000; //FIXME: this limit wont work for popular photos
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                
                NSMutableArray *likeActivities = [[NSMutableArray alloc] init];
                BOOL isLikedByCurrentUser = NO;
                
                [[TTUtility sharedInstance] internetConnectionFound];
                for (PFObject *activity in objects) {
                    // Separate the Activities into Likes and Comments
                    if ([[activity objectForKey:@"type"] isEqualToString:@"like"] && [activity objectForKey:@"fromUser"]) {
                        PFUser *user = activity[@"fromUser"];
                        //need to double check the local file to see if its been liked or not by user
                        if (![user.objectId isEqualToString:[PFUser currentUser].objectId]){
                            [likeActivities addObject: activity];
                        }else{
                            //only add the like if the user has liked it
                            if ([[TTCache sharedCache] isPhotoLikedByCurrentUser:photo])
                                [likeActivities addObject:activity];
                        }
                    }
                    
                    if ([[[activity objectForKey:@"fromUser"] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                        if ([[activity objectForKey:@"type"] isEqualToString:@"like"])
                            isLikedByCurrentUser = YES;
                    }
                }
                
                //TODO: update cached photo attributes, i.e. likers, commenters, etc.
                [[TTCache sharedCache] setAttributesForPhoto:photo likers:likeActivities commenters:nil likedByCurrentUser:isLikedByCurrentUser];
                [self updateLikeStatusForCurrentPhoto];
            }else {
                NSLog(@"Error loading photo Activities: %@", error);
                [ParseErrorHandlingController handleError:error];
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"refreshPhotoActivitiesWithUpdateNow:"];
            }
        }];
    }
}


@end
