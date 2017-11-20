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

@interface TTPhotoViewController () <UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *backgroundView;
@property (strong, nonatomic) IBOutlet UIImageView *foregroundView;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *heartButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) AVPlayerLayer *layer;
@property (nonatomic, weak) AVPlayer *player;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property BOOL isFetchingTrip;
@property (nonatomic, weak) SharkfoodMuteSwitchDetector* detector;
@property (strong, nonatomic) IBOutlet UILabel *viewCountLabel;
@property int viewCount;
@end

@implementation TTPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.backgroundView.image = self.photo.image;
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFit;
    self.foregroundView.image = self.photo.image;
    self.foregroundView.contentMode = UIViewContentModeScaleAspectFill;
//    self.backgroundView.tag = 1000;
//    self.foregroundView.tag = 1001;
    
    if(self.photo.video){
        
        [self.photo.video fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            NSURL *url = [NSURL URLWithString:self.photo.video[@"videoUrl"]];
            self.player = [AVPlayer playerWithURL:url];
            
            self.layer = [AVPlayerLayer layer];
            [self.layer setPlayer:self.player];
            [self.layer setFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
            [self.layer setVideoGravity:AVLayerVideoGravityResizeAspect];
            
            [self.scrollView.layer addSublayer:self.layer];
            
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
                self.scrollView.scrollEnabled = NO;
                self.scrollView.pinchGestureRecognizer.enabled = NO;
            });
//            self.video_sound_button.hidden = NO;
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
    
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 6.0;
    self.scrollView.contentSize = self.foregroundView.frame.size;
    
    [self refreshPhotoActivities];
    [self updateLikeStatusForCurrentPhoto];
    
    [self preloadPreviousImage];
    [self preloadNextImage];

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


#pragma mark - touches
- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {

    if((int)self.index == 0)
        self.index = (int)self.photos.count-1;
    else self.index--;
    
    UIScrollView *sV = (UIScrollView *)[self.view viewWithTag:999];
    UIImageView *bI = (UIImageView *)[self.view viewWithTag:1000];
    
    UIScrollView *scrollView = [self setScrollViewForForegroundImage:0-kScreenWidth];
    
    UIImageView *newImageForeground = [self createUIImageView:0];
    newImageForeground.tag = 1001;
    newImageForeground.contentMode = UIViewContentModeScaleAspectFit;
    self.photo.image = newImageForeground.image;
    
    UISwipeGestureRecognizer *swipeleft=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [newImageForeground addGestureRecognizer:swipeleft];
    UISwipeGestureRecognizer *swiperight=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [newImageForeground addGestureRecognizer:swiperight];
    
    newImageForeground.userInteractionEnabled = YES;
    
    UIImageView *newImageBackground = [self createUIImageView:0-kScreenWidth];
    newImageBackground.contentMode = UIViewContentModeScaleAspectFill;
    newImageBackground.alpha = 0.45;
    newImageBackground.tag = 1000;
    
    [scrollView addSubview:newImageForeground];
    [self.view insertSubview:scrollView atIndex:2];
    [self.view insertSubview:newImageBackground atIndex:0];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        sV.frame = CGRectMake(kScreenWidth,0,kScreenWidth,kScreenHeight);
        bI.frame = CGRectMake(kScreenWidth,0,kScreenWidth,kScreenHeight);
        scrollView.frame = CGRectMake(0,0,kScreenWidth,kScreenHeight);
        newImageBackground.frame = CGRectMake(0,0,kScreenWidth,kScreenHeight);
    } completion:^(BOOL finished) {
        [self updateLikeStatusForCurrentPhoto];
        [sV removeFromSuperview];
        [bI removeFromSuperview];
    }];
    
    [self preloadPreviousImage];
}


//FIXME: swiping makes the first image and ONLY first image disappear instead of animate <-------------------------------------
- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    
    if((int)self.index == (int)self.photos.count-1)
        self.index = 0;
    else self.index++;
    
    UIScrollView *sV = (UIScrollView *)[self.view viewWithTag:999];
    UIImageView *bI = (UIImageView *)[self.view viewWithTag:1000];
    
    UIScrollView *scrollView = [self setScrollViewForForegroundImage:kScreenWidth];
    
    UIImageView *newImageForeground = [self createUIImageView:0];
    newImageForeground.tag = 1001;
    newImageForeground.contentMode = UIViewContentModeScaleAspectFit;
    self.photo.image = newImageForeground.image;
    
    UISwipeGestureRecognizer *swipeleft=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [newImageForeground addGestureRecognizer:swipeleft];
    UISwipeGestureRecognizer *swiperight=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [newImageForeground addGestureRecognizer:swiperight];
    
    newImageForeground.userInteractionEnabled = YES;
    
    UIImageView *newImageBackground = [self createUIImageView:kScreenWidth];
    newImageBackground.contentMode = UIViewContentModeScaleAspectFill;
    newImageBackground.alpha = 0.45;
    newImageBackground.tag = 1000;
    
    [scrollView addSubview:newImageForeground];
    [self.view insertSubview:scrollView atIndex:2];
    [self.view insertSubview:newImageBackground atIndex:0];
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        sV.frame = CGRectMake(0-kScreenWidth,0,kScreenWidth,kScreenHeight);
        bI.frame = CGRectMake(0-kScreenWidth,0,kScreenWidth,kScreenHeight);
        scrollView.frame = CGRectMake(0,0,kScreenWidth,kScreenHeight);
        newImageBackground.frame = CGRectMake(0,0,kScreenWidth,kScreenHeight);
    } completion:^(BOOL finished) {
        [self updateLikeStatusForCurrentPhoto];
        [sV removeFromSuperview];
        [bI removeFromSuperview];
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
    [imageView setImageWithURL:[NSURL URLWithString:newPhoto.imageUrl]];
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
        self.scrollView.scrollEnabled = NO;
        self.scrollView.pinchGestureRecognizer.enabled = NO;
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerItemStatusReadyToPlay) {
            //[self.activityIndicator stopAnimating];
//            [self.scrollView sendSubviewToBack:self.imageView];
        } else if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"There was an error loading the video");
        }
    }
}

-(void) receivePlaybackStartedNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"PlaybackStartedNotification"]) {
        [self.activityIndicator stopAnimating];
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
