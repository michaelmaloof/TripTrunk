//
//  PhotoViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/29/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "PhotoViewController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "UIImageView+AFNetworking.h"
#import "Comment.h"
#import "TTUtility.h"
#import "SocialUtility.h"
#import "UserProfileViewController.h"
#import "ActivityListViewController.h"
#import "CommentListViewController.h"
#import "TTCache.h"
#import "TrunkViewController.h"
#import "EditCaptionViewController.h"
#import "UserProfileViewController.h"
#import "HomeMapViewController.h"
#import "TrunkListViewController.h"
#import "TTTTimeIntervalFormatter.h"
#import "TTTAttributedLabel.h"
#import "TTSuggestionTableViewController.h"
#import "TTHashtagMentionColorization.h"
#import "TTAnalytics.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
#import "AVFoundation/AVFoundation.h"
#import "SharkfoodMuteSwitchDetector.h"

#define screenWidth [[UIScreen mainScreen] bounds].size.width
#define screenHeight [[UIScreen mainScreen] bounds].size.height

@interface PhotoViewController () <UIAlertViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate,EditDelegate, UITextViewDelegate, UIPopoverPresentationControllerDelegate,TTSuggestionTableViewControllerDelegate, TTTAttributedLabelDelegate>
// IBOutlets
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *topButtonWrapper;
@property (weak, nonatomic) IBOutlet UIView *bottomButtonWrapper;
@property (strong, nonatomic) IBOutlet UIView *captionWrapper;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomButtonWrapperHeightConstraint;
@property (strong, nonatomic) IBOutlet UIView *photoToolbarWrapper;
@property (weak, nonatomic) IBOutlet UIButton *comments;
@property (strong, nonatomic) IBOutlet UIButton *likeCountButton;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *photoTakenBy;
@property (weak, nonatomic) IBOutlet UIButton *trunkNameButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *captionButtonConstraint;
@property (strong, nonatomic) IBOutlet UIButton *video_sound_button;
@property CGFloat height;
@property CGFloat originY;
@property CGFloat width;
@property CGFloat originX;
@property BOOL isEditingCaption;
@property TTTTimeIntervalFormatter *timeFormatter;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property BOOL isZoomed;
@property BOOL hideBottomWrapper;
//############################################# MENTIONS ##################################################
@property (weak, nonatomic) IBOutlet UITextView *caption;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *captionLabel;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTSuggestionTableViewController *autocompletePopover;
@property (strong, nonatomic) NSString *previousComment;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) NSMutableArray *softMentions;
//############################################# MENTIONS ##################################################
@property BOOL imageZoomed;
@property (weak, nonatomic) IBOutlet UIButton *addCaption;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomWrapperHeightCnt;
@property (weak, nonatomic) IBOutlet UILabel *timeStamp;
@property (weak, nonatomic) IBOutlet UIButton *privateButton;
// Data Properties
@property NSMutableArray *commentActivities;
@property NSMutableArray *likeActivities;
@property BOOL isLikedByCurrentUser;
@property BOOL viewMoved;
@property BOOL shouldShowTrunkNameButton;
@property AVPlayerLayer *layer;
@property AVPlayer *player;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property BOOL isFetchingTrip;
@property (nonatomic,strong) SharkfoodMuteSwitchDetector* detector;
@end

@implementation PhotoViewController

//Monitor Ring/Silent switch and adjust the GUI to match
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.detector = [SharkfoodMuteSwitchDetector shared];
        __weak PhotoViewController* sself = self;
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
    if (self.fromAddPhotosViewController == NO){
        [self prepareForViewPhotoFromTrunk];
    } else {
        [self prepareAddCaptionForNewPhoto];
    }
}

#pragma On Appear

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    if (self.fromAddPhotosViewController == NO){
        [self setCaptionAndNavBar];
        [self updateCommentsLabel];
        [self updateLikesLabel];
        [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
        [self markPhotoAsViewed];
    }
    else {
        // Still hide the tab bar!
        self.tabBarController.tabBar.hidden = YES;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    NSRange cursorPosition = [self.caption selectedRange];
    [self.caption setSelectedRange:NSMakeRange(cursorPosition.location, 0)];
    //If the player is loaded, continue playing the video
    //If it's not loaded, it will ignore this command
    [self.player play];
}

-(void)setCaptionAndNavBar{
    self.saveButton.hidden = YES;
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    self.captionLabel.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
}

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
                        [self.delegate photoWasViewed:self.photo];
                    }
                }
            }
        }
    }
}

#pragma Original Photo UI on ViewDidLoad
-(void)setOriginalUIForPhoto{
    self.caption.hidden = YES;
    self.privateButton.hidden = YES;
    // Set initial UI
    if ([self.photo.user.objectId isEqualToString:[PFUser currentUser].objectId]){
        self.addCaption.hidden = NO;
    } else {
        self.addCaption.hidden = YES;
    }
    self.bottomButtonWrapper.hidden = YES;
    self.captionWrapper.hidden = YES;
    self.topButtonWrapper.hidden = YES;
    self.photoToolbarWrapper.hidden = YES;
    [self hidePhotoContent:YES];
    self.timeStamp.text = @"";
    self.caption.selectable = NO;
    self.caption.editable = NO;
    self.caption.delegate = self;
    self.photoTakenBy.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.timeStamp.adjustsFontSizeToFitWidth = YES;
    [self.photoTakenBy setTitle:self.photo.userName forState:UIControlStateNormal];
    self.timeStamp.text = [self stringForTimeStamp:self.photo.createdAt];
    self.caption.hidden = YES;
}

-(void)setOriginalUIForTrunk{
    self.shouldShowTrunkNameButton = NO;
    if (self.fromProfile == NO){
        UITabBarController *tabbarcontroller = (UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        if (tabbarcontroller.selectedIndex == 3) {
            self.shouldShowTrunkNameButton = YES;
        }
        if (self.fromNotification == YES || self.fromTimeline){
            self.shouldShowTrunkNameButton = YES;
        }
    } else {
        self.shouldShowTrunkNameButton = YES;
    }
}

-(void)prepareAddCaptionForNewPhoto{
    self.trunkNameButton.hidden = YES;
    self.photoTakenBy.hidden = YES;
    self.privateButton.hidden = YES;
    self.moreButton.hidden = YES;
    self.timeStamp.hidden = YES;
    self.likeButton.hidden = YES;
    self.likeCountButton.hidden = YES;
    self.comments.hidden = YES;
    self.caption.selectable = NO;
    self.caption.editable = NO;
    self.caption.delegate = self;
    self.caption.hidden = YES;
    self.captionLabel.hidden = NO;
    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
    self.captionLabel.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
    [self setCaptionAndNavBar];
    [self setNotificationCenter];
    [self loadImageForPhoto:self.photo];
    [self editCaptionPhotoGestures];
//    [self editCaptionTapped:self];
    self.bottomButtonWrapper.hidden = YES;
    self.captionWrapper.hidden = YES;
    self.captionButtonConstraint.constant = 8;

}

-(void)prepareForViewPhotoFromTrunk{
    [self setOriginalUIForPhoto];
    [self setOriginalUIForTrunk];
    [self setScrollViewUI];
    self.commentActivities = [[NSMutableArray alloc] init];
    self.likeActivities = [[NSMutableArray alloc] init];
    [self addGestureRecognizers];
    [self loadImageForPhoto:self.photo];
    [self setNotificationCenter];
    [self refreshPhotoActivitiesWithUpdateNow:NO forPhotoStatus:NO];
}

-(void)setScrollViewUI{
    self.scrollView.delegate = self;
    [self.scrollView setClipsToBounds:YES];
    // Setup the scroll view - needed for Zooming
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 6.0;
    self.scrollView.zoomScale = 1.0;
    [self.scrollView setContentMode:UIViewContentModeScaleAspectFit];
    self.originY = self.scrollView.frame.origin.y;
    self.originX = self.scrollView.frame.origin.x;
    self.width = self.scrollView.frame.size.width;
    self.height = self.scrollView.frame.size.height;
}


-(void)setNotificationCenter{
    //FIXME was there a metod for this before (refreshPhotoActivities)? Junil I think deleted the code in refreshPhotoActivities
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshPhotoActivities)
                                                 name:@"commentUpdatedOnPhoto"
                                               object:nil];
    // Add keyboard notifications so that the keyboard won't cover the table when searching
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

//FIXME: added this to silence error on line 145
-(void)refreshPhotoActivities{
    
}

- (NSString *)stringForTimeStamp:(NSDate*)created {
    self.timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
    NSString *time = @"";
    time = [self.timeFormatter stringTimeStampFromDate:[NSDate date] toDate:created];
    return time;
}

#pragma Handle Gestures

- (void)handleDoubleTapFrom:(UITapGestureRecognizer *)recognizer {
    CGFloat originalTouchX, originalTouchY, originalWidth, originalHeight, zoomOriginX, zoomOriginY, zoomTouchX, zoomTouchY, zoomedWidth, zoomedHeight, zoomFactor;
    CGRect originalImageRect, zoomedImageRect;
    zoomFactor = 3.0;
    //Original image attributes
    originalWidth = screenWidth;
    originalHeight = originalWidth * self.imageView.image.size.height / self.imageView.image.size.width;
    originalImageRect = CGRectMake(0.0, (screenHeight / 2.0) - (originalHeight / 2.0), originalWidth, originalHeight);
    originalTouchX = [recognizer locationInView:self.scrollView].x;
    originalTouchY = [recognizer locationInView:self.scrollView].y;
    zoomedWidth = self.imageView.frame.size.width * zoomFactor;
    zoomedHeight = zoomedWidth * self.imageView.image.size.height / self.imageView.image.size.width;
    zoomedImageRect = CGRectMake(0.0, self.imageView.frame.size.height - (zoomedHeight / 2.0), zoomedWidth, zoomedHeight);
    if (CGRectContainsPoint(originalImageRect, [recognizer locationInView:self.imageView]) && !self.imageZoomed)
    {
        zoomTouchX = [recognizer locationInView:self.imageView].x * zoomFactor;
        zoomTouchY = ([recognizer locationInView:self.imageView].y - originalImageRect.origin.y) * zoomFactor;
        //Set Zoom Origin
        if (zoomTouchX < screenWidth)
        {
            zoomOriginX = 0.0;
        }
        else if (zoomTouchX > zoomedWidth - screenWidth)
        {
            zoomOriginX = -(zoomedWidth - screenWidth);
        }
        else
        {
            zoomOriginX = -zoomTouchX + screenWidth / 2.0;
        }

        if (zoomTouchY < screenHeight)
        {
            zoomOriginY = -zoomedImageRect.origin.y - screenHeight / 2.0;
        }
        else if (zoomTouchY > zoomedHeight - screenHeight)
        {
            zoomOriginY = -zoomedImageRect.origin.y - screenHeight / 2.0 - zoomedImageRect.size.height + screenHeight;
        }
        else
        {
            zoomOriginY = -zoomTouchY + screenHeight / 2.0;
        }
        [UIView animateWithDuration:0.45 animations:^{
            [self.imageView setTransform:CGAffineTransformMakeScale(zoomFactor, zoomFactor)];
            [self.imageView setFrame:CGRectMake(zoomOriginX, zoomOriginY, self.imageView.frame.size.width, self.imageView.frame.size.height)];
        }];
        self.imageZoomed = YES;
        self.isZoomed = YES;
        [UIView transitionWithView:self.view duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void){
            self.topButtonWrapper.hidden = YES;
            self.bottomButtonWrapper.hidden = YES;
            self.captionWrapper.hidden = YES;
            self.photoToolbarWrapper.hidden = YES;
        } completion:nil];
        _scrollView.scrollEnabled = YES;
    }
    else
    {
        //Zoom Out
        _scrollView.scrollEnabled = NO;
        [UIView animateWithDuration:0.45 animations:^{
            [self.imageView setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
            [self.imageView setFrame:CGRectMake(0.0, 0.0, screenWidth, screenHeight)];
        }];
        self.imageZoomed = NO;
        self.isZoomed = NO;
        [UIView transitionWithView:self.view duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void){
            self.topButtonWrapper.hidden = NO;
            self.bottomButtonWrapper.hidden = NO;
            if(![self.captionLabel.text isEqualToString:@""])
                self.captionWrapper.hidden = NO;
            self.photoToolbarWrapper.hidden = NO;
        } completion:nil];
    }
}

- (CAGradientLayer*) greyGradientForTop:(BOOL)isTop {
    
    UIColor *colorOne = [UIColor colorWithWhite:0.0 alpha:0.3];
    UIColor *colorTwo = [UIColor colorWithWhite:0.0 alpha:0.2];
    UIColor *colorThree = [UIColor colorWithWhite:0.0 alpha:0.0];
    
    NSArray *colors;
    NSNumber *stopTwo;
    if (isTop) {
        colors =  [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, colorThree.CGColor, nil];
        stopTwo = [NSNumber numberWithFloat:0.3];
    }
    else {
        colors =  [NSArray arrayWithObjects:(id)colorThree.CGColor, colorTwo.CGColor, colorOne.CGColor, nil];
        stopTwo = [NSNumber numberWithFloat:0.6];

    }
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];

    NSNumber *stopThree     = [NSNumber numberWithFloat:0.9];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, stopThree, nil];
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
    
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.imageView setFrame:[[UIScreen mainScreen] bounds]];
    [self.scrollView setContentSize:CGSizeMake(_imageView.frame.size.width, _imageView.frame.size.height)];
    [self centerScrollViewContents];
    self.topButtonWrapper.backgroundColor = [TTColor tripTrunkWhiteTransparent];
    self.bottomButtonWrapper.backgroundColor = [TTColor tripTrunkWhiteTransparent];
    self.captionWrapper.backgroundColor = [TTColor tripTrunkWhiteTransparent];
    self.photoToolbarWrapper.backgroundColor = [TTColor tripTrunkWhiteTransparent];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
    if (self.isEditingCaption){
        [self.caption endEditing:YES];
    }
    
    [self.activityIndicator stopAnimating];
}

- (void)centerScrollViewContents {
    self.isZoomed = NO;
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    self.imageView.frame = contentsFrame;
}

-(void)editCaptionPhotoGestures{
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.imageView addGestureRecognizer:tapGesture];
}


- (void)addGestureRecognizers {
    // Add swipe gestures
    UISwipeGestureRecognizer *swipeleft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeleft:)];
    swipeleft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeleft];
    
    UISwipeGestureRecognizer *swiperight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    swiperight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swiperight];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.imageView addGestureRecognizer:tapGesture];
    
//    
//    UITapGestureRecognizer *dblRecognizer;
//    dblRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
//                                                            action:@selector(handleDoubleTapFrom:)];
//    [dblRecognizer setNumberOfTapsRequired:2];
//    [self.view addGestureRecognizer:dblRecognizer];
//    
//    [tapGesture requireGestureRecognizerToFail:dblRecognizer];

}

- (void)toggleButtonVisibility {
    [UIView transitionWithView:self.view duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void){
        self.topButtonWrapper.hidden = !self.topButtonWrapper.hidden;
        self.captionWrapper.hidden = self.topButtonWrapper.hidden;
        self.photoToolbarWrapper.hidden = self.topButtonWrapper.hidden;
    
//        self.bottomButtonWrapper.hidden = !self.bottomButtonWrapper.hidden;
        
        if([self.captionLabel.text isEqualToString:@""])
            self.captionWrapper.hidden = YES;
            
    } completion:nil];
}

- (void)tripLoaded:(Trip *)trip {
    if (self.shouldShowTrunkNameButton) {
        [self.photo.trip fetchIfNeeded];
        [self.photo.video fetchIfNeeded];
        [self.trunkNameButton setTitle:trip.name forState:UIControlStateNormal];
    }
}

#pragma mark - Photo Data

- (void)loadImageForPhoto: (Photo *)photo {
    if (photo.imageUrl){ //it has an imagURL, thus its a photo were downloading from a trunk
        
        if(photo.video){
            self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            self.activityIndicator.center = self.view.center;
            [self.activityIndicator startAnimating];
            [self.navigationController.view addSubview:self.activityIndicator];
            
            NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            UIImage *placeholderImage = photo.image;
            [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.imageView setImageWithURLRequest:request
                                  placeholderImage:placeholderImage
                                           success:nil failure:nil];
            
            [photo.video fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {

                NSURL *url = [NSURL URLWithString:photo.video[@"videoUrl"]];
                self.player = [AVPlayer playerWithURL:url];http://stackoverflow.com/questions/6901363/detecting-the-iphones-ring-silent-mute-switch-using-avaudioplayer-not-worki
                
                self.layer = [AVPlayerLayer layer];
                [self.layer setPlayer:self.player];
                [self.layer setFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
                [self.layer setVideoGravity:AVLayerVideoGravityResizeAspect];
                
                int a = (int)self.view.layer.sublayers.count-7;
                [self.view.layer insertSublayer:self.layer atIndex:a];
                
                [self.player setActionAtItemEnd:AVPlayerActionAtItemEndPause];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playerItemDidReachEnd:)
                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                           object:[self.player currentItem]];
                [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
                
                [self.player play];
                self.video_sound_button.hidden = NO;

            }];
            
        }else{
            
        NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        UIImage *placeholderImage = photo.image;
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.imageView setImageWithURLRequest:request
                              placeholderImage:placeholderImage
                                       success:nil failure:nil];
            
        }
        
    } else if (photo.imageAsset){ //not imagURL, its an imageAsset from AddTripPhotosViewController
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat floatWidth = screenRect.size.width;
        CGFloat floatHeight = screenRect.size.height;
//        //TODO: change width/height scaling for iPhone 6+ since it's a 3x phone.
        [[PHImageManager defaultManager] requestImageForAsset:photo.imageAsset
                                                   targetSize:CGSizeMake(floatWidth*2, floatHeight*2)
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:nil
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    // Set the image.
                                                    self.imageView.image = result;
                                                }];
    }
}

//AVPlayer Observers
//handle the end of the video
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    
    [self.player play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerItemStatusReadyToPlay) {
            [self.activityIndicator stopAnimating];
        } else if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"There was an error loading the video");
        }
    }
}

-(void)refreshPhotoActivitiesWithUpdateNow:(BOOL)updateNow forPhotoStatus:(BOOL)isCurrentPhoto {
    if (isCurrentPhoto == NO){
        self.isLikedByCurrentUser = NO;
        [self hidePhotoContent:YES];
    } else {
        if (self.likeButton.selected == YES){
            self.isLikedByCurrentUser = YES;
        }else {
            self.isLikedByCurrentUser = NO;
        }
    }
    //FIXME this is causing the delay in going from when you select a photo to viewing it
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.photo.trip fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error){
                    self.trip = self.photo.trip;
                    [self.photo.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                        if (!error){
                            
                            if (self.shouldShowTrunkNameButton) {
                                [self.photo.trip fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error){
                                    self.trip = self.photo.trip;
                                    [self.trunkNameButton setTitle:self.photo.trip.name forState:UIControlStateNormal];
                                }];
                            }
                            
                            if ([self.photo.user[@"private"] boolValue] == YES && self.photo.trip.isPrivate == NO) {
                                self.privateButton.hidden = NO;
                            } else {
                                self.privateButton.hidden = YES;
                            }
                            
                            if (error){
                                NSLog(@"error %@", error);
                                [ParseErrorHandlingController handleError:error];
                            }
                        }
                    }];
                }
                else {
                    NSLog(@"Error loading trip: %@", error);
                    [ParseErrorHandlingController handleError:error];
                }
                [self initializeMentions];
            });
        }];
        
        self.caption.hidden = YES;
        
        // Get Activities for Photo
        //    PFQuery *query = [SocialUtility queryForActivitiesOnPhoto:self.photo cachePolicy:kPFCachePolicyNetworkOnly];
        PFQuery *query = [SocialUtility queryForActivitiesOnPhoto:self.photo cachePolicy:kPFCachePolicyNetworkOnly];
        query.limit = 1000; //fixme this limit wont work for popular photos
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                
                self.likeActivities = [[NSMutableArray alloc] init];
                self.commentActivities = [[NSMutableArray alloc] init];
                
                [[TTUtility sharedInstance] internetConnectionFound];
                for (PFObject *activity in objects) {
                    // Separate the Activities into Likes and Comments
                    if ([[activity objectForKey:@"type"] isEqualToString:@"like"] && [activity objectForKey:@"fromUser"]) {
                        PFUser *user = activity[@"fromUser"];
                        //need to double check the local file to see if its been liked or not by user
                        if (![user.objectId isEqualToString:[PFUser currentUser].objectId]){
                            [self.likeActivities addObject: activity];
                        } else {
                            //only add the like if the user has liked it
                            if ([[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo] == YES && isCurrentPhoto == YES){
                                [self.likeActivities addObject: activity];
                            } else if (isCurrentPhoto == NO){
                                [self.likeActivities addObject: activity];
                            }
                        }
                    }
                    else if ([[activity objectForKey:@"type"] isEqualToString:@"comment"] && [activity objectForKey:@"fromUser"]) {
                        [self.commentActivities addObject:activity];
                        //need to double check the local file to see if its been commented or not by user
                    }
                    
                    if ([[[activity objectForKey:@"fromUser"] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                        if ([[activity objectForKey:@"type"] isEqualToString:@"like"]) {
                            self.isLikedByCurrentUser = YES;
                        }
                    }
                }
                
                self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
                self.captionLabel.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
                
                //            [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.isLikedByCurrentUser];
                
                //TODO: update cached photo attributes, i.e. likers, commenters, etc.
                [[TTCache sharedCache] setAttributesForPhoto:self.photo likers:self.likeActivities commenters:self.commentActivities likedByCurrentUser:self.isLikedByCurrentUser];
                
                
                // Update number of likes & comments
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateCommentsLabel];
                    [self updateLikesLabel];
                    self.likeButton.alpha = 1;
                    self.likeButton.userInteractionEnabled = YES;
                    
                    if (isCurrentPhoto == NO){
                        [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
                    }
                    
                });
                
            }
            else {
                NSLog(@"Error loading photo Activities: %@", error);
                [ParseErrorHandlingController handleError:error];
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"refreshPhotoActivitiesWithUpdateNow:"];
            }
            [self hidePhotoContent:NO];
            
        }];
        
    });
}

#pragma mark - Gestures

- (void)swiperight:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self clearVideo];
    if (self.isZoomed == NO && self.isEditingCaption == NO){
        // Prevents a crash when the PhotoViewController was presented from a Push Notification--aka it doesn't have a self.photos array
        if (!self.photos || self.photos.count == 0) {
            return;
        }
        
        if (self.arrayInt > 0)
        {
            self.arrayInt = self.arrayInt - 1;
            self.photo = [self.photos objectAtIndex:self.arrayInt];
            [self loadImageForPhoto:self.photo];
            //        self.title = self.photo.userName;
              [self.photoTakenBy setTitle:self.photo.userName forState:UIControlStateNormal];
            self.timeStamp.text = [self stringForTimeStamp:self.photo.createdAt];

            if ([self.photo.user.objectId isEqualToString:[PFUser currentUser].objectId]){
                self.addCaption.hidden = NO;
            } else {
                self.addCaption.hidden = YES;
                
            }
            //update the label and likes now in case the user has already seen these and its cached
//            [self updateCommentsLabel];
//            [self updateLikesLabel];
            //FIXME SHould this be done in the refresh?
            [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
            [self markPhotoAsViewed];
            //load the new photo the user swiped too
            [self refreshPhotoActivitiesWithUpdateNow:NO forPhotoStatus:NO];
            self.imageZoomed = NO;
            
            PFImageView *newImageView = [[PFImageView alloc]init];
            newImageView = self.imageView;
            
            [UIView transitionWithView:self.imageView
                              duration:0.5
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:^{
                                self.imageView = newImageView;
                            }
                            completion:nil];
        }
    }
}

- (void)swipeleft:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self clearVideo];
    if (!self.isZoomed && !self.isEditingCaption){

        if (!self.photos || self.photos.count == 0) {
            return;
        }
        
        if (self.fromTimeline && self.arrayInt == self.photos.count - 1){
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
            [self.photo.trip fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                trunkViewController.trip = self.photo.trip;
                [self.navigationController pushViewController:trunkViewController animated:YES];
                return;
            }];
     
        } else {
            
        if (self.arrayInt != self.photos.count - 1)
        {
            self.arrayInt++;
            self.photo = [self.photos objectAtIndex:self.arrayInt];
            if ([self.photo.user.objectId isEqualToString:[PFUser currentUser].objectId]){
                self.addCaption.hidden = NO;
            } else {
                self.addCaption.hidden = YES;
            }
            [self loadImageForPhoto:self.photo];
            self.title = self.photo.userName;
               [self.photoTakenBy setTitle:self.photo.userName forState:UIControlStateNormal];
            self.timeStamp.text = [self stringForTimeStamp:self.photo.createdAt];

            //FIXME SHould this be done in the refresh?
            [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
            
            [self markPhotoAsViewed];

            //load photo on swipe left
            [self refreshPhotoActivitiesWithUpdateNow:NO forPhotoStatus:NO];
            
            self.imageZoomed = NO;
            
            PFImageView *newImageView = [[PFImageView alloc]init];
            newImageView = self.imageView;
            
            [UIView transitionWithView:self.imageView
                              duration:0.5
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                               self.imageView = newImageView;
                            }
                            completion:nil];
        }
    }
    }
}

- (void)swipeUp:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self.player pause];
    if (self.isZoomed == NO)
    {
    
    CommentListViewController *vc = [[CommentListViewController alloc] initWithComments:self.commentActivities forPhoto:self.photo];
    [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)swipeDown:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self clearVideo];
    if (self.isZoomed == NO){
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)handleTap:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self toggleButtonVisibility];
    if (self.isEditingCaption == YES)
    {
        [self.caption endEditing:YES];
    } else if (self.fromAddPhotosViewController == YES){
        [self.caption endEditing:YES];
    }
}

#pragma mark - Button Actions

- (IBAction)onSavePhotoTapped:(id)sender {
    
    UIActionSheet *actionSheet;
    
    if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]){
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
                                    destructiveButtonTitle:NSLocalizedString(@"Delete Photo",@"Delete Photo")
                                         otherButtonTitles:NSLocalizedString(@"Report Inappropriate",@"Report Inappropriate"),NSLocalizedString(@"Download Photo",@"Download Photo"), nil];
        
    }
    
    else if ([[PFUser currentUser].objectId isEqualToString:self.photo.trip.creator.objectId]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
                                    destructiveButtonTitle:NSLocalizedString(@"Delete Photo",@"Delete Photo")
                                         otherButtonTitles:NSLocalizedString(@"Report Inappropriate",@"Report Inappropriate"),NSLocalizedString(@"Download Photo",@"Download Photo"), nil];
    }
    else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Report Inappropriate",@"Report Inappropriate"),NSLocalizedString(@"Download Photo",@"Download Photo"), nil];
    }

    
    [actionSheet showInView:self.view];
}

- (IBAction)onCommentsTapped:(id)sender {
    
    CommentListViewController *vc = [[CommentListViewController alloc] initWithComments:self.commentActivities forPhoto:self.photo];
    vc.trunkMembers = self.trunkMembers;
    if (_fromProfile == NO){
        vc.trip = self.trip;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        if (self.isFetchingTrip == NO){
            self.isFetchingTrip = YES;
            [self.photo.trip fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                self.isFetchingTrip = NO;
                vc.trip = self.photo.trip;
                [self.navigationController pushViewController:vc animated:YES];
            }];
        }
    }

}

- (IBAction)likeCountButtonPressed:(id)sender {
    if (self.likeActivities.count > 0){
        ActivityListViewController *vc = [[ActivityListViewController alloc] initWithLikes:self.likeActivities];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)editCaptionTapped:(id)sender {
        //store the mentioned users from the current comment
    if (self.caption.attributedText.length > 0){
            self.previousComment = self.caption.text;
    }
    self.caption.hidden = NO;
    self.captionLabel.hidden = YES;
    self.caption.editable = YES;
    [self.caption becomeFirstResponder];
    self.bottomButtonWrapper.hidden = !self.bottomButtonWrapper.hidden;

}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if([textView.text isEqualToString:@""]){
        textView.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:NSLocalizedString(@"Type Photo/Video Caption Here", @"Type Photo/Video Caption Here")];
        textView.textColor = [TTColor tripTrunkLightGray];
        textView.selectedRange = NSMakeRange(0, 0);
    }
    self.isEditingCaption = YES;
    self.scrollView.scrollEnabled = NO;
    self.likeButton.hidden = YES;
    self.likeCountButton.hidden = YES;
    self.comments.hidden = YES;
    [self.addCaption setImage:[UIImage imageNamed:@"addCaption"] forState:UIControlStateNormal];
    self.addCaption.tag = 1;
    if ([self.photo.caption isEqualToString:@""] || self.photo.caption == nil){
        if (textView.text == nil || [textView.text isEqualToString:@""]){
            self.saveButton.hidden = YES;
        } else{
            self.saveButton.hidden = NO;
        }
    } else{
        self.saveButton.hidden = NO;
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView{
    self.saveButton.hidden = YES;
    self.caption.hidden = YES;
    self.captionLabel.hidden = NO;
    self.isEditingCaption = NO;
    self.scrollView.scrollEnabled = YES;
    [self.addCaption setImage:[UIImage imageNamed:@"editPencil"] forState:UIControlStateNormal];
    if (self.fromAddPhotosViewController == NO){
        self.likeButton.hidden = NO;
        self.likeCountButton.hidden = NO;
        self.comments.hidden = NO;
    }
    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
    self.captionLabel.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
    self.addCaption.tag = 0;
    self.caption.editable = NO;
}

- (void)keyboardWillShow:(NSNotification *)notification{

    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    int captionOffset = 0; int quicktype = 0;
    if(keyboardSize.height < 250){
        quicktype = 63;
    } else if (keyboardSize.height < 258) {
        quicktype = -90;
    }
    
    if(self.view.frame.origin.y >= 0)
        captionOffset = self.bottomButtonWrapper.frame.origin.y-self.bottomButtonWrapper.frame.size.height-keyboardSize.height-self.photoToolbarWrapper.frame.size.height-quicktype;
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                 self.view.frame.origin.y-captionOffset,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
    self.caption.hidden = NO;
    self.captionLabel.hidden = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification{
    self.bottomButtonWrapper.hidden = YES;
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                 0,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height);
    self.caption.hidden = YES;
    self.captionLabel.hidden = NO;
}

- (void)deletePhotoCaption { //FIXME: this is a little slopy from an error handling point of view
    [self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        self.photo.caption = @"";
        if (!error){
            [[TTUtility sharedInstance] internetConnectionFound];
            NSMutableArray *commentToDelete = [[NSMutableArray alloc]init];
            for (PFObject *obj in self.commentActivities){
                if ((BOOL)[obj objectForKey:@"isCaption"] == YES){
                    [commentToDelete addObject:obj];
                    [obj deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                        if (!error){
                            NSLog(@"Caption deleted");
                            self.caption.attributedText = [[NSAttributedString alloc] initWithString:@""];
                            NSAttributedString * emptyString= [[NSAttributedString alloc] initWithString:@""];
                            self.captionLabel.attributedText = emptyString;
                            [self.commentActivities removeObject:[commentToDelete objectAtIndex:0]];
                            [self.caption endEditing:YES];
                            self.captionWrapper.hidden = YES;
                            [[TTCache sharedCache] setAttributesForPhoto:self.photo likers:self.likeActivities commenters:self.commentActivities likedByCurrentUser:self.isLikedByCurrentUser];
                        } else {
                            NSLog(@"Error deleting caption");
                        }
                        [self updateCommentsLabel];
                    }];
                    break;
                }
            }
            
        }else{
            [ParseErrorHandlingController handleError:error];
        }
    }];
}



//Combine save and delete FIXME
- (IBAction)saveButtonWasTapped:(id)sender {
    
    if (self.fromAddPhotosViewController == NO){
        //FIXME: This needs to be looked at. Without know what all the bools and arrays do, it's hard to comment why but
        //this looks like it needs to be rewritten. Plus, there should probabaly be a break; in the for loop
        //and why is there no if(save == YES) for refreshPhotoActivitesWithUpdateNow?
        
        if (![self.caption.text isEqualToString:@""] && ![self.caption.text isEqualToString:@"Type Photo/Video Caption Here"] && self.caption.text != nil){
            //begin process of adding a caption to the current photo
            self.addCaption.enabled = NO;
            self.photo.caption = [self separateMentions:self.caption.text];
            [[TTCache sharedCache] incrementCommentCountForPhoto:self.photo];
            [self updateCommentsLabel];
            [self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                self.autocompletePopover = [[self storyboard] instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
                if (!error)
                {
                    [[TTUtility sharedInstance] internetConnectionFound];
                    //if there are no comments on the photo
                    if (self.commentActivities.count == 0)
                    {
                        [SocialUtility addComment:self.photo.caption forPhoto:self.photo isCaption:YES block:^(BOOL succeeded, PFObject *object, PFObject *commentObject, NSError *error) {
                            if(!error)
                            {
                                NSLog(@"Caption saved as comment");
                                [self refreshPhotoActivitiesWithUpdateNow:YES forPhotoStatus:YES];
                                [self updateMentionsInDatabase:commentObject];
                                [self.caption endEditing:YES];
                                if([self.caption.text isEqualToString:@""])
                                    self.captionWrapper.hidden = YES;
                                else self.captionWrapper.hidden = self.topButtonWrapper.hidden;
                            }else
                            {
                                NSLog(@"Error saving caption");
                                [[TTCache sharedCache] decrementCommentCountForPhoto:self.photo];
                                [self updateCommentsLabel];
                                [self.caption endEditing:YES];
                            }
                        }];
                    }
                    //if there are already comments on the photo
                    else
                    {
                        [ParseErrorHandlingController handleError:error];
                        //if there already is a caption we edit it and save it
                        __block BOOL save = NO;
                        for (PFObject *obj in self.commentActivities){
                            if ([[obj objectForKey:@"isCaption"] boolValue] && !save){
                                save = YES;
                                [obj setObject:[NSNumber numberWithBool:YES] forKey:@"isCaption"];
                                [obj setObject:self.photo.caption forKey:@"content"];
                                [obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                    if(!error){
                                        NSLog(@"Caption saved as comment");
                                        [self updateCommentsLabel];
                                        [self updateMentionsInDatabase:obj];
                                        if([self.caption.text isEqualToString:@""])
                                            self.captionWrapper.hidden = YES;
                                        else self.captionWrapper.hidden = self.topButtonWrapper.hidden;
                                    }else{
                                        NSLog(@"Error saving caption");
                                    }
                                }];
                            }
                        }
                        if (!save) {
                            [SocialUtility addComment:self.photo.caption forPhoto:self.photo isCaption:YES block:^(BOOL succeeded, PFObject *object, PFObject *commentObject, NSError *error)
                             {
                                 if(!error){
                                     NSLog(@"Caption saved as comment");
                                     [self refreshPhotoActivitiesWithUpdateNow:YES forPhotoStatus:YES];
                                     [self.caption endEditing:YES];
                                     [self updateMentionsInDatabase:commentObject];
                                     if([self.caption.text isEqualToString:@""])
                                         self.captionWrapper.hidden = YES;
                                     else self.captionWrapper.hidden = self.topButtonWrapper.hidden;
                                 }else{
                                     NSLog(@"Error saving caption");
                                     [self updateCommentsLabel];
                                     [self.caption endEditing:YES];
                                 }
                             }];
                            
                        }else{
                            //FIXME: shouldn't we handle this conditon?
                        }
                    }
                }
                [self.caption endEditing:YES];
                self.addCaption.enabled = YES;
            }];
        } else {
            if (![self.photo.caption isEqualToString:@""] && self.photo.caption != nil){
                [self deletePhotoCaption];
            }
        }
    } else {
        if(![self.caption.text isEqualToString:@""] && ![self.caption.text isEqualToString:@"Type Photo/Video Caption Here"])
            [self.delegate captionWasAdded:self.caption.text];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

//FIXME: Should we do saveEventually for likes or does it need to be real time responsive like this?
//FIXME: Total Like Handled Here
- (IBAction)likeButtonPressed:(id)sender {
    // Like Photo
    if (!self.likeButton.selected)
    {
        [self.likeButton setSelected:YES];
        [[TTCache sharedCache] incrementLikerCountForPhoto:self.photo];
        [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.likeButton.selected];
        [self updateLikesLabel];
        self.likeButton.alpha = .3;
        self.likeButton.userInteractionEnabled = NO;
        
        [SocialUtility likePhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [[TTUtility sharedInstance] internetConnectionFound];
                [self updateLikesLabel];
                [self refreshPhotoActivitiesWithUpdateNow:YES forPhotoStatus:YES];
                if (self.photo.trip.publicTripDetail){
                    [self.delegate photoWasLiked:NO];
                }
            }else {
                [self.likeButton setSelected:NO];
                [[TTCache sharedCache] decrementLikerCountForPhoto:self.photo];
                [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.likeButton.selected];
                [self updateLikesLabel];
                self.likeButton.alpha = 1;
                self.likeButton.userInteractionEnabled = YES;
                [ParseErrorHandlingController handleError:error];
            }
        }];
    }
    // Unlike Photo
    else if (self.likeButton.selected) {
        
        [self.likeButton setSelected:NO];
        [[TTCache sharedCache] decrementLikerCountForPhoto:self.photo];
        [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.likeButton.selected];
        [self updateLikesLabel];
        self.likeButton.alpha = .3;
        self.likeButton.userInteractionEnabled = NO;

        [SocialUtility unlikePhoto:self.photo block:^(BOOL succeeded, NSError *error) {

            if (succeeded) {
                [self updateLikesLabel];
                [self refreshPhotoActivitiesWithUpdateNow:YES forPhotoStatus:YES];
                [[TTUtility sharedInstance] internetConnectionFound];

            }else {
                [self.likeButton setSelected:YES];
                [[TTCache sharedCache] incrementLikerCountForPhoto:self.photo];
                [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.likeButton.selected];
                [self updateLikesLabel];
                if (self.photo.trip.publicTripDetail){
                    [self.delegate photoWasLiked:YES];
                }
                self.likeButton.alpha = 1;
                self.likeButton.userInteractionEnabled = YES;
                [ParseErrorHandlingController handleError:error];
                
            }
        }];
    }
    
    [self updateCommentsLabel]; //FIXME Why is this here?
    self.caption.hidden = YES;  //FIXME Why is this here?
    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
    self.captionLabel.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];  //FIXME Why is this here?

    
}

-(void)updateLikesLabel{
    NSNumber *likeCount = [[TTCache sharedCache] likeCountForPhoto:self.photo];
    if([likeCount intValue] > 0){
        [self.likeCountButton setTitle:[NSString stringWithFormat:@"%@", likeCount] forState:UIControlStateNormal];
        self.likeCountButton.hidden = NO;
    }else{
        [self.likeCountButton setTitle:@"" forState:UIControlStateNormal];
        self.likeCountButton.hidden = YES;
    }
}

-(void)updateCommentsLabel{
//    NSString *comments = NSLocalizedString(@"Comments",@"Comments");
//    NSNumber *commentCount = [[TTCache sharedCache] commentCountForPhoto:self.photo];
//    if([commentCount intValue] < 2){
////        comments = NSLocalizedString(@"Comment",@"Comment");
//        comments = NSLocalizedString(@"Comments",@"Comments");
//    }
    
//    if (commentCount.integerValue == 0){
//        [self.comments setTitle:comments forState:UIControlStateNormal];
//    } else {
//        //FIXME TEMP commented out. Cache doesnt work correctly when you add comments and remove them on commentListViewController
////        [self.comments setTitle:[NSString stringWithFormat:@"%@ %@", commentCount,comments] forState:UIControlStateNormal];
//        [self.comments setTitle:comments forState:UIControlStateNormal];
//    }
}

- (IBAction)trunkNameButtonPressed:(id)sender {
    if (![self.trunkNameButton.titleLabel.text isEqualToString:@""] || self.trunkNameButton.titleLabel.text == nil ){ //make sure were not in the trunk alredy
        //FIXME I MESSED UP THE FLOW HERE IM NOT SURE HOW WE WANT TO DO IT NOW WITH PUSHES
        [self.photo.trip fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
                trunkViewController.trip = self.photo.trip;
                
                UITabBarController *tabbarcontroller = (UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
                UINavigationController *activityNavController = [[tabbarcontroller viewControllers] objectAtIndex:3];
                if (tabbarcontroller.selectedIndex == 3) {
                    [activityNavController pushViewController:trunkViewController animated:YES];
                }else {
                    [self.navigationController pushViewController:trunkViewController animated:YES];
                }
            });
        }];
    }
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

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Delete
        if (alertView.tag == 0) {
            //TODO: What if they're deleting the only photo in the trunk?
            //fixme, this should me done after the photo has been confirmed and deleted
            [self.photo.trip.publicTripDetail fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                
                if (!error) {
                    self.photo.trip.publicTripDetail.totalLikes = self.photo.trip.publicTripDetail.totalLikes - (int)[[TTCache sharedCache] likeCountForPhoto:self.photo];
                    
                    if ([self.photo isEqual:[self.photos objectAtIndex:0]]){
                        if (self.photos.count > 1){
                            Photo *photoMost = [self.photos objectAtIndex:1];
                            self.photo.trip.publicTripDetail.mostRecentPhoto = photoMost.createdAt;
                            //reload map color here
                        } else {
                            NSString *dateString = @"1200-01-01 01:01:01";
                            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                            [dateFormat setTimeZone:[NSTimeZone systemTimeZone]];
                            [dateFormat setLocale:[NSLocale currentLocale]];
                            [dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
                            [dateFormat setFormatterBehavior:NSDateFormatterBehaviorDefault];
                            
                            NSDate *date = [dateFormat dateFromString:dateString];
                            self.photo.trip.publicTripDetail.mostRecentPhoto = date;
                        }
                    }
                    
                    if (self.trip.publicTripDetail.photoCount > 0){
                        self.trip.publicTripDetail.photoCount = self.trip.publicTripDetail.photoCount -1;
                    }
                    
                    [[TTUtility sharedInstance] deletePhoto:self.photo withblock:^(BOOL succeeded, NSError *error) {
                        if (error) {
                            //error!!
                            self.trip.publicTripDetail.photoCount = self.trip.publicTripDetail.photoCount +1;
                            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat: @"Sorry, photo/video was not deleted with following error \n %@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
                            [errorAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { }]];
                            [self presentViewController:errorAlert animated:YES completion:nil];
                        }
                        else{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate photoWasDeleted:[[TTCache sharedCache] likeCountForPhoto:self.photo] photo:self.photo];
                                NSDate *today = [NSDate date];
                                NSTimeInterval tripInterval = [today timeIntervalSinceDate:self.photo.trip.publicTripDetail.mostRecentPhoto];
                                
                                BOOL color = 0;
                                if (tripInterval < 86400){
                                    color = 1;
                                } else{
                                    color = 0;
                                }
                                [self deletePhotoFromHomeMap:color];
                                [self.photo.trip.publicTripDetail saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                    // dismiss the view
                                }];
                                [self.navigationController popViewControllerAnimated:YES];
                            });
                        }
                    }];
                }
                else{
                    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat: @"Sorry, photo/video was not deleted with following error \n %@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
                    [errorAlert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) { }]];
                    [self presentViewController:errorAlert animated:YES completion:nil];
                }
            }];

        }
        // Download Photo
        else if (alertView.tag == 1) {
//            [[TTUtility sharedInstance] downloadPhoto:self.photo];
            if(self.photo.video)
                [[TTUtility sharedInstance] downloadPhotoVideo:[self urlOfCurrentlyPlayingInPlayer:self.player]];
            else [[TTUtility sharedInstance] downloadPhotoImage:self.imageView.image];
        }
        // Report Photo
        else if (alertView.tag == 2) {
            NSString *reason = [alertView textFieldAtIndex:0].text;
            [[TTUtility sharedInstance] reportPhoto:self.photo withReason:reason];
        }
    }
}

-(void)deletePhotoFromHomeMap:(BOOL)color{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UINavigationController *controller in self.tabBarController.viewControllers)
        {
            for (UIViewController *view in controller.viewControllers)
            {
                if ([view isKindOfClass:[HomeMapViewController class]]){
                    if (self.photos.count < 1){
                        [(HomeMapViewController*)view dontRefreshMapOnViewDidAppear];
                        [(HomeMapViewController*)view updateTripColorOnMap:self.photo.trip isHot:NO member:YES];
                    } else  //instead, find interval and update is HOT
                    {
                        [(HomeMapViewController*)view dontRefreshMapOnViewDidAppear];
                        [(HomeMapViewController*)view updateTripColorOnMap:self.photo.trip isHot:color member:YES];
                    }
                } else if ([view isKindOfClass:[ActivityListViewController class]])
                {
                    [(ActivityListViewController*)view photoWasDeleted:self.photo];
                    
                }
            }
            
            for (TrunkListViewController *view in controller.viewControllers)
            {
                if ([view isKindOfClass:[TrunkListViewController class]]){
                    [view reloadTrunkList:self.photo.trip seen:NO addPhoto:NO photoRemoved:YES];
                }
            }
            for (UserProfileViewController *view in controller.viewControllers){
                if ([view isKindOfClass:[UserProfileViewController class]]){
                    [view photoWasDeletedFromPhotoViewController:self.photo];
                }
                
            }
        }
    });
}

- (IBAction)closeButtonPressed:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)textFieldDidChange :(UITextField *)theTextField{
    if ([theTextField.text length] > 1){

    NSString *code = [theTextField.text substringFromIndex: [theTextField.text length] - 2];
    if ([code isEqualToString:@" "]){
        [theTextField setKeyboardType:UIKeyboardTypeDefault];
    }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // if the user is the photo owner, they have the Delete option
    if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId] || [[PFUser currentUser].objectId isEqualToString:self.photo.trip.creator.objectId]) {
        if (buttonIndex == 0) {
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.title = NSLocalizedString(@"Are you sure you want to delete this photo?",@"Are you sure you want to delete this photo?");
            alertView.backgroundColor = [TTColor tripTrunkLightBlue];
            [alertView addButtonWithTitle:NSLocalizedString(@"No",@"No")];
            [alertView addButtonWithTitle:NSLocalizedString(@"Yes",@"Yes")];
            alertView.tag = 0;
            [alertView show];
            
        }
        else if (buttonIndex == 1) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Report Photo",@"Report Photo") message:NSLocalizedString(@"What is inappropriate about this photo?",@"What is inappropriate about this photo?") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") otherButtonTitles:NSLocalizedString(@"Submit",@"Submit"), nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField * alertTextField = [alert textFieldAtIndex:0];
            alertTextField.keyboardType = UIKeyboardTypeAlphabet;
            alertTextField.placeholder = NSLocalizedString(@"Enter photo's violation.",@"Enter photo's violation.");
            alert.tag = 2;
            [alert show];
        }
        else if (buttonIndex == 2 ){
//            [[TTUtility sharedInstance] downloadPhoto:self.photo];
            if(self.photo.video)
                [[TTUtility sharedInstance] downloadPhotoVideo:[self urlOfCurrentlyPlayingInPlayer:self.player]];
            else [[TTUtility sharedInstance] downloadPhotoImage:self.imageView.image];
        }
        
    }
    // Not photo owner, they can't delete.
    else {
        if (buttonIndex == 0) {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Report Photo",@"Report Photo") message:NSLocalizedString(@"What is inappropriate about this photo?",@"What is inappropriate about this photo?") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") otherButtonTitles:NSLocalizedString(@"Submit",@"Submit"), nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField * alertTextField = [alert textFieldAtIndex:0];
            alertTextField.keyboardType = UIKeyboardTypeAlphabet;
            alertTextField.placeholder = NSLocalizedString(@"Enter photo's violation.",@"Enter photo's violation.");
            alert.tag = 2;
            [alert show];
        }
        else if (buttonIndex == 1) {
//            [[TTUtility sharedInstance] downloadPhoto:self.photo];
            if(self.photo.video)
                [[TTUtility sharedInstance] downloadPhotoVideo:[self urlOfCurrentlyPlayingInPlayer:self.player]];
            else [[TTUtility sharedInstance] downloadPhotoImage:self.imageView.image];
            
        }
    }
    
}

-(NSURL *)urlOfCurrentlyPlayingInPlayer:(AVPlayer *)player{
    // get current asset
    AVAsset *currentPlayerAsset = player.currentItem.asset;
    // make sure the current asset is an AVURLAsset
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) return nil;
    // return the NSURL
    return [(AVURLAsset *)currentPlayerAsset URL];
}

#pragma mark - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
//    CGFloat offsetX = (self.scrollView.bounds.size.width > self.scrollView.contentSize.width)?
//    (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0;
//    CGFloat offsetY = (self.scrollView.bounds.size.height > self.scrollView.contentSize.height)?
//    (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0;
//    self.imageView.center = CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX,
//                                   self.scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if (scale > 1.0) {
        _scrollView.scrollEnabled = YES;
//        self.isZoomed = YES;
    }
    else {
        _scrollView.scrollEnabled = NO;
        [self centerScrollViewContents];
//        self.isZoomed = NO;
    
    }
}
//-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    [self centerScrollViewContents];
//}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [_scrollView frame].size.height / scale;
    zoomRect.size.width  = [_scrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}


//############################################# MENTIONS ##################################################
-(void)initializeMentions{
    [self buildMentionUsersCache];
    
    self.softMentions = [[NSMutableArray alloc] init];
    if([self.photo[@"caption"] containsString:@"@"]){
        NSArray *mentionArray = [self.photo[@"caption"] componentsSeparatedByString:@" "];
        for(NSString *username in mentionArray){
            if([username length] > 0){
                if([[username substringToIndex:1] isEqualToString:@"@"]){
                    
                    //check if user already exists in softMention Array
                    PFUser *user = [self array:self.softMentions containsPFObjectByUsername:[self getUsernameFromLink:username]];
                    
                    //If it doesn't exist in softMentions, check if it is already in cache
                    if(!user)
                        user = [self array:[[TTCache sharedCache] mentionUsers] containsPFObjectByUsername:[self getUsernameFromLink:username]];
                    
                    //If it isn't in cache, get it from Parse
                    if(!user){
                        [SocialUtility loadUserFromUsername:[self getUsernameFromLink:username] block:^(PFUser *user, NSError *error) {
                            if(user)
                                [self.softMentions addObject:user];
                            else NSLog(@"Error: %@",error);
                        }];
                    }
                }
            }
        }
    }
    
    self.captionLabel.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
    if([self.photo.caption containsString:@"@"]){
        NSArray *usernamesArray = [TTHashtagMentionColorization extractUsernamesFromComment:self.photo.caption];
        for(NSString *name in usernamesArray){
            NSRange userRange = [self.photo.caption rangeOfString:name];
            NSString *link = [NSString stringWithFormat:@"activity://%@",[name lowercaseString]];
            [self.captionLabel addLinkToURL:[NSURL URLWithString:link] withRange:userRange];
        }
    }
    
    self.captionLabel.delegate = self;
}

-(void)updateMentionsInDatabase:(PFObject*)object{
    [self.autocompletePopover saveMentionToDatabase:object comment:self.photo.caption previousComment:self.previousComment photo:self.photo members:self.trunkMembers];
    [self.autocompletePopover removeMentionFromDatabase:object comment:self.photo.caption previousComment:self.previousComment];
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
//    NSRange cursorPosition = [textView selectedRange];
//    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.caption.text];
//    [self.caption setSelectedRange:NSMakeRange(cursorPosition.location, 0)];
    NSString *placeholderText = NSLocalizedString(@"Type Photo/Video Caption Here", @"Type Photo/Video Caption Here");
    if ([textView.text isEqualToString:placeholderText])
        textView.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:@""];
    
    return YES;
}

//As the user types, check for a @mention and display a popup with a list of users to autocomplete
- (void)textViewDidChange:(UITextView *)textView{
    NSString *placeholderText = NSLocalizedString(@"Type Photo/Video Caption Here", @"Type Photo/Video Caption Here");
    if([textView.text isEqualToString:@""]){
        textView.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:placeholderText];
        textView.textColor = [TTColor tripTrunkLightGray];
        textView.selectedRange = NSMakeRange(0, 0);
    }
    
    if ([self.photo.caption isEqualToString:@""] || self.photo.caption == nil){
        if (textView.text == nil || [textView.text isEqualToString:@""]|| [textView.text isEqualToString:placeholderText]){
            self.saveButton.hidden = YES;
        } else{
            self.saveButton.hidden = NO;
        }
    } else{
        self.saveButton.hidden = NO;
    }
    
    if ([textView.text length] > 1){

        NSString *code = [textView.text substringFromIndex: [textView.text length] - 2];
        if ([code isEqualToString:@" "]){
            [textView setKeyboardType:UIKeyboardTypeDefault];
        }
    }
    
    //get the word that the user is currently typing
    NSRange cursorPosition = [textView selectedRange];
    NSString* substring = [textView.text substringToIndex:cursorPosition.location];
    NSString* lastWord = [[substring componentsSeparatedByString:@" "] lastObject];
    
    //Display the Popover if there is a @ plus a letter typed and only if it is not already showing
    if([self displayAutocompletePopover:lastWord]){
        if(!self.autocompletePopover.delegate){
            //Instantiate the view controller and set its size
            self.autocompletePopover = [[self storyboard] instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
            self.autocompletePopover.modalPresentationStyle = UIModalPresentationPopover;
            
            //force the popover to display like an iPad popover otherwise it will be full screen
            self.popover  = self.autocompletePopover.popoverPresentationController;
            self.popover.delegate = self;
            self.popover.sourceView = self.caption;
            self.popover.sourceRect = [self.caption bounds];
            self.popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
            
            if([[TTCache sharedCache] mentionUsers] && [[TTCache sharedCache] mentionUsers].count > 0){
                
                self.autocompletePopover.friendsArray = [NSMutableArray arrayWithArray:[[TTCache sharedCache] mentionUsers]];
                
                self.autocompletePopover.mentionText = lastWord;
                [self.autocompletePopover updateAutocompleteTableView];
                //If there are friends to display, now show the popup on the screen
                if(self.autocompletePopover.displayFriendsArray.count > 0 || self.autocompletePopover.displayFriendsArray != nil){
                    self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], [self.autocompletePopover preferredHeightForPopover]);
                    self.autocompletePopover.delegate = self;
                    [self presentViewController:self.autocompletePopover animated:YES completion:nil];
                }
                
            }else{
            
                if(!self.trunkMembers)
                    self.trunkMembers = [[NSArray alloc] init];
            
                //Build the friends list for the table view in the popover and wait
                
                NSDictionary *data = @{
                                       @"trunkMembers" : self.trunkMembers,
                                       @"trip" : self.trip,
                                       @"photo" : self.photo
                                       };
                [self.autocompletePopover buildPopoverList:data block:^(BOOL succeeded, NSError *error){
                    if(succeeded){
                        [[TTCache sharedCache] setMentionUsers:self.autocompletePopover.friendsArray];
                        //send the current word to the Popover to use for comparison
                        self.autocompletePopover.mentionText = lastWord;
                        [self.autocompletePopover updateAutocompleteTableView];
                        //If there are friends to display, now show the popup on the screen
                        if(self.autocompletePopover.displayFriendsArray.count > 0 || self.autocompletePopover.displayFriendsArray != nil){
                            self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], [self.autocompletePopover preferredHeightForPopover]);
                            self.autocompletePopover.delegate = self;
                            [self presentViewController:self.autocompletePopover animated:YES completion:nil];
                        }
                    }else{
                        NSLog(@"Error: %@",error);
                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"textViewDidChange:"];
                    }
                }];
                
            }

        }
    }
    
    //Update the table view in the popover but only if it is currently displayed
    if([self updateAutocompletePopover:lastWord]){
        self.autocompletePopover.mentionText = lastWord;
        [self.autocompletePopover updateAutocompleteTableView];
    }
    
    //Remove the popover if a space is typed
    if([self dismissAutocompletePopover:lastWord]){
        [self dismissViewControllerAnimated:YES completion:nil];
        self.popover.delegate = nil;
        self.autocompletePopover = nil;
    }
    
    if(![self.caption.text isEqualToString:placeholderText]){
        self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.caption.text];
        [self.caption setSelectedRange:NSMakeRange(cursorPosition.location, 0)];
    }
}

//Only true if user has typed an @ and a letter and if the popover is not showing
-(BOOL)displayAutocompletePopover:(NSString*)lastWord{
    return [lastWord containsString:@"@"] && ![lastWord isEqualToString:@"@"] && !self.popover.delegate;
}

//Only true if the popover is showing and the user typed a space
-(BOOL)dismissAutocompletePopover:(NSString*)lastWord{
    return self.popover.delegate && ([lastWord hasSuffix:@" "] || [lastWord isEqualToString:@""]);
}

//Only true if the popover is showing and there are friends to show in the table view and the @mention isn't broken
-(BOOL)updateAutocompletePopover:(NSString*)lastWord{
    return self.popover.delegate && self.autocompletePopover.displayFriendsArray.count > 0 && ![lastWord isEqualToString:@""];
}

//Dismiss the popover and reset the delegates
-(void)removeAutocompletePopoverFromSuperview{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.popover.delegate = nil;
    self.autocompletePopover = nil;
}

#pragma mark - TTSuggestionTableViewControllerDelegate
//The popover is telling this view controller to dismiss it
- (void)popoverViewControllerShouldDissmissWithNoResults{
    [self removeAutocompletePopoverFromSuperview];
}

//replace the currently typed word with the the username
-(void)insertUsernameAsMention:(NSString*)username{
    //Get the currently typed word
    NSRange cursorPosition = [self.caption selectedRange];
    NSString* substring = [self.caption.text substringToIndex:cursorPosition.location];
    NSString* lastWord = [[substring componentsSeparatedByString:@" "] lastObject];
    //get a mutable copy of the current caption
    NSMutableString *caption = [NSMutableString stringWithString:self.caption.text];
    //create the replacement range of the typed mention
    NSRange mentionRange = NSMakeRange(cursorPosition.location-[lastWord length], [lastWord length]);
    //replace that typed @mention with the user name of the user they want to mention
    NSString *mentionString = [caption stringByReplacingCharactersInRange:mentionRange withString:[NSString stringWithFormat:@"%@ ",username]];
    
    //display the new caption
    self.caption.text = mentionString;
    //dismiss the popover
    [self removeAutocompletePopoverFromSuperview];
    //reset the font colors and make sure the cursor is right after the mention. +1 to add a space
    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.caption.text];
    [self.caption setSelectedRange:NSMakeRange(cursorPosition.location-[lastWord length]+[username length]+1, 0)];
    self.autocompletePopover.delegate = nil;
}

//Adjust the height of the popover to fit the number of usernames in the tableview
-(void)adjustPreferredHeightOfPopover:(NSUInteger)height{
    self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], height);
}

- (NSString*)getUsernameFromLink:(NSString*)link{
    return [[link substringFromIndex:1] lowercaseString];
}

//-(NSString*)separateMentions:(NSString*)comment{
//    if(![comment containsString:@"@"])
//        return comment;
//
//    NSArray *array = [comment componentsSeparatedByString:@"@"];
//    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
//    return [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
//}

-(NSString*)separateMentions:(NSString*)comment{
    if(![comment containsString:@"@"])
        return comment;
    
    //separate the mentions
    NSArray *array = [comment componentsSeparatedByString:@"@"];
    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
    spacedMentions = [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
    
    //make all mentions lowercase
    array = [spacedMentions componentsSeparatedByString:@" "];
    NSMutableArray *lcArray = [[NSMutableArray alloc] init];
    for(NSString *string in array){
        //check if this is a mention
        if(![string isEqualToString:@""]){
            if([[string substringToIndex:1] isEqualToString:@"@"]){
                [lcArray addObject:[string lowercaseString]];
            }else{
                [lcArray addObject:string];
            }
        }
    }
    return [lcArray componentsJoinedByString:@" "];
}

#pragma mark - UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

-(void)buildMentionUsersCache{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.autocompletePopover = [storyboard instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
    
    //This is the prevent a crash
    if(!self.trunkMembers)
        self.trunkMembers = [[NSArray alloc] init];
    
    //Added this to prevent a crash but may want to use fetchIfNeeded
    if(!self.photo.trip)
        self.photo.trip = [[Trip alloc] init];
    
    //Added this to prevent a crash but may want to use fetchIfNeeded
    if(!self.photo)
        self.photo = [[Photo alloc] init];
    
    //Build the friends list for the table view in the popover and wait
    NSDictionary *data = @{
                           @"trunkMembers" : self.trunkMembers,
                           @"trip" : self.photo.trip,
                           @"photo" : self.photo
                           };
    [self.autocompletePopover buildPopoverList:data block:^(BOOL succeeded, NSError *error){
        if(succeeded){
            [[TTCache sharedCache] setMentionUsers:self.autocompletePopover.friendsArray];
        }else{
            NSLog(@"Error: %@",error);
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"buildMentionUsersCache:"];
        }
    }];
}

//Check if the object's objectId matches the objectId of any member of the array.
- (BOOL) array:(NSArray *)array containsPFObjectById:(PFObject *)object{
    for (PFObject *arrayObject in array){
        if ([[arrayObject objectId] isEqual:[object objectId]]) {
            return YES;
        }
    }
    return NO;
}

//Check if the user's username matches the username of any member of the array.
- (PFUser*) array:(NSArray *)array containsPFObjectByUsername:(NSString *)username{
    for (PFUser *user in array){
        if ([user.username isEqualToString:username]) {
            return user;
        }
    }
    return nil;
}

#pragma mark - UIPopoverControllerDelegate
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController{
    self.popover.delegate = nil;
    self.autocompletePopover = nil;
}

#pragma mark - TTTAttributedLabelDelegate methods
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    
    self.captionLabel.enabled = NO;
    
    if ([[url scheme] hasPrefix:@"activity"]) {
        NSString *urlString = [NSString stringWithFormat:@"%@",url];
        if([urlString containsString:@"@"]){
                PFUser *user;
        
                //check to see if tapped user exists as a PFObject in the mention cache
                if([[TTCache sharedCache] mentionUsers] && [[TTCache sharedCache] mentionUsers].count > 0)
                    user = [self array:[[TTCache sharedCache] mentionUsers] containsPFObjectByUsername:[url host]];
        
                //check if user is nil, if so it wasn't in the cache, so go ahead and load it
                if(!user)
                    user = [self array:self.softMentions containsPFObjectByUsername:[url host]];
        
                UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:user];
            if (vc && user) {
                    vc.user = user;
                    [self.navigationController pushViewController:vc animated:YES];
                }else{
                    NSLog(@"Error: unable to load view controller");
                    self.captionLabel.enabled = YES;

                }
            }
        }

}

-(void)clearVideo{
    @try{
        [self.player removeObserver:self forKeyPath:@"status"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    __weak PhotoViewController* sself = self;
    self.detector.silentNotify = ^(BOOL silent){
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
        if(silent)
            sself.video_sound_button.selected = NO;
        else sself.video_sound_button.selected = YES;
        
    };
    self.video_sound_button.hidden = YES;
    [self.player pause];
    [self.layer removeFromSuperlayer];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
    self.captionLabel.enabled = YES;
    
}

//############################################# MENTIONS ##################################################


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try{
        [self.player removeObserver:self forKeyPath:@"status"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"editCaption"]){
    
    }
}

-(void)captionButtonTapped:(int)button caption:(NSString *)text{
    
    if (button == 0) {
        self.photo.caption = text;
    } else if (button == 1){
        self.photo.caption = @"";
    }
    self.caption.hidden = YES;  
    self.caption.text = self.photo.caption;
    self.captionLabel.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.photo.caption];
    [self.photo saveInBackground];

}

- (IBAction)photoTakenByTapped:(id)sender {
    if (![(NSObject*)self.delegate respondsToSelector:@selector(photoWasDeletedFromPhotoViewController:)]) { //Any class but UserProfileViewController
        [self.photo.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UserProfileViewController *trunkViewController = [[UserProfileViewController alloc] initWithUser:self.photo.user];
                trunkViewController.user = self.photo.user;
                UITabBarController *tabbarcontroller = (UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
                UINavigationController *activityNavController = [[tabbarcontroller viewControllers] objectAtIndex:3];
                if (tabbarcontroller.selectedIndex == 3) {
                    [activityNavController pushViewController:trunkViewController animated:YES];
                } else {
                    [self.navigationController pushViewController:trunkViewController animated:YES];
                    
                }
            });
        }];
    }
}

- (IBAction)privatebuttonTapped:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = NSLocalizedString(@"The user who posted this photo/video has a private account. Their photos can only be seen by people they follow and by members of the trunk where the photo/video is located.",@"The user who posted this photo/video has a private account. Their photos can only be seen by people they follow and members of the trunk where the photo/video is located.");
    alertView.backgroundColor = [TTColor tripTrunkLightBlue];
   [alertView addButtonWithTitle:NSLocalizedString(@"Ok",@"Ok")];
    alertView.tag = 3;
    [alertView show];
}

-(void)hidePhotoContent:(BOOL)isHidden{
    if (isHidden == YES){
        self.likeCountButton.hidden = YES;
        self.likeButton.hidden = YES;
        self.caption.hidden = YES;
        self.captionLabel.hidden = YES;
    } else {
        self.likeCountButton.hidden = NO;
        self.likeButton.hidden = NO;
        self.captionLabel.hidden = NO;
    }
}

#pragma mark - Allow Landscape
//implement to allow landscape mode on landscape videos
//-(void)canRotate{}
@end

