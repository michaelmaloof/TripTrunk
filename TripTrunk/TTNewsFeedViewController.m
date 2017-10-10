//
//  TTNewsFeedViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 2/12/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTNewsFeedViewController.h"
#import "TTTimeLineCollectionViewCell.h"
#import "Trip.h"
#import "Photo.h"
#import "SocialUtility.h"
#import "TTUtility.h"
#import "UIImageView+AFNetworking.h"
#import <Parse/Parse.h>
#import "UserProfileViewController.h"
#import "TrunkViewController.h"
#import "PhotoViewController.h"
#import "TTTTimeIntervalFormatter.h"
#import <CoreText/CoreText.h>
#import "TrunkListViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TTColor.h"
#import "TTSubPhotoButton.h"
#import "TTAnalytics.h"
#import "SharkfoodMuteSwitchDetector.h"

@interface TTNewsFeedViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, PhotoDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *following;
@property TTTTimeIntervalFormatter *timeFormatter;
@property (strong, nonatomic) NSMutableArray *objid;
@property BOOL isLoading;
//@property (strong, nonatomic) NSMutableArray *mainPhotos;
@property (strong, nonatomic) NSMutableDictionary *subPhotos;
@property (strong, nonatomic) NSMutableArray *userTrips;
@property BOOL reachedBottom;
@property (strong, nonatomic) NSMutableArray *trips;
@property (strong, nonatomic) NSMutableArray *photoUsers;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) SharkfoodMuteSwitchDetector* detector;
@property BOOL phoneMuted; ///<--Maloof would be so proud
@property int viewCount;
@property (nonatomic, strong) NSMutableDictionary *viewsDictionary;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) AVPlayer *currentVideo;
@end

@implementation TTNewsFeedViewController

//Monitor Ring/Silent switch and adjust the GUI to match
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.detector = [SharkfoodMuteSwitchDetector shared];
        __weak TTNewsFeedViewController* sself = self;
        self.detector.silentNotify = ^(BOOL silent){
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
            if(silent)
                sself.phoneMuted = YES;
            else sself.phoneMuted = NO;
            
            for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
                TTTimeLineCollectionViewCell *videoCell = (TTTimeLineCollectionViewCell*)cell;
                
                if(silent)
                    videoCell.videoSoundButton.selected = NO;
                else videoCell.videoSoundButton.selected = YES;
            }
        };
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    refreshControl.tintColor = [TTColor tripTrunkBlue];
    [refreshControl endRefreshing];
    
    self.viewsDictionary = [[NSMutableDictionary alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveViewCountsFromDictionaryToParse)
                                                 name:UIApplicationWillTerminateNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveViewCountsFromDictionaryToParse)
                                                 name:UIApplicationWillResignActiveNotification
                                               object: nil];

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    //moved from viewDidLoad to fix delete bug
    self.navigationItem.hidesBackButton = YES;
    
    [self setTitleImage];
    [self createLeftButtons];
    self.trips = [[NSMutableArray alloc] init];
    if(self.mainPhotos == nil)
        self.mainPhotos = [[NSMutableArray alloc] init];
    self.subPhotos = [[NSMutableDictionary alloc] init];
    self.photoUsers = [[NSMutableArray alloc] init];
    self.userTrips = [[NSMutableArray alloc] init];
    self.objid = [[NSMutableArray alloc] init];
    
    
//    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
//        if (!error)
//        {
//            self.following = [[NSMutableArray alloc]init];
//            for (PFUser *user in users)
//            {
//                [self.following addObject:user];
//            }
//        }
//        if(self.mainPhotos == nil || self.mainPhotos.count == 0)
//            [self loadNewsFeed:NO refresh:nil];
//    }];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
    
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error)
        {
            self.following = [[NSMutableArray alloc]init];
            for (PFUser *user in users)
            {
                [self.following addObject:user];
            }
        }
        if(self.mainPhotos == nil || self.mainPhotos.count == 0)
            [self loadNewsFeed:NO refresh:nil];
    }];
    
    self.videoId = @"";
    
    __weak TTNewsFeedViewController* sself = self;
    self.detector.silentNotify = ^(BOOL silent){
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
        if(silent)
            sself.phoneMuted = YES;
        else sself.phoneMuted = NO;
        
        for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
            TTTimeLineCollectionViewCell *videoCell = (TTTimeLineCollectionViewCell*)cell;
            
            if(silent)
                videoCell.videoSoundButton.selected = NO;
            else videoCell.videoSoundButton.selected = YES;
        }
    };
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    if(self.mainPhotos.count > 0)
        [self performSelector:@selector(checkWhichVideoToEnable:) withObject:nil afterDelay:2.0];
}

-(void)loadNewsFeed:(BOOL)isRefresh refresh:(UIRefreshControl*)refreshControl{
    NSLog(@"LOADING");
    self.videoId = @"";
    
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
        TTTimeLineCollectionViewCell *videoCell = (TTTimeLineCollectionViewCell*)cell;
        [videoCell.avPlayer.currentItem seekToTime:kCMTimeZero];
        [videoCell.avPlayer pause];
    }


    if (!self.isLoading){
        self.isLoading = YES;
        int mainCount = (int)self.mainPhotos.count;

    //Build an array to send up to CC
    NSMutableArray *followingObjectIds = [[NSMutableArray alloc] init];
    for(PFUser *user in self.following){
        [followingObjectIds addObject:user.objectId];
    }
        [followingObjectIds addObject:[PFUser currentUser].objectId];
    
    Photo *photo = [[Photo alloc] init];
    if (self.mainPhotos.count > 0 && !isRefresh)
        photo = self.mainPhotos.lastObject;
    else photo = self.mainPhotos.firstObject;
        
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *tomorrow = [cal dateByAddingUnit:NSCalendarUnitDay
                                           value:2
                                          toDate:[NSDate date]
                                         options:0];
        
    NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
    [dateformate setDateFormat:@"YYYY-MM-dd"];
    NSString *dateString=[dateformate stringFromDate:tomorrow];

    NSDictionary *params = @{
                             @"objectIds" : followingObjectIds,
                             @"activityObjectIds" : self.objid,
                             @"createdDate" : photo.createdAt ? photo.createdAt : dateString,
                             @"isRefresh" : [NSString stringWithFormat:@"%@",isRefresh ? @"YES" : @"NO"],
                             @"userTrips" : self.userTrips
                             };

    [PFCloud callFunctionInBackground:@"queryForNewsFeed" withParameters:params block:^(NSArray *response, NSError *error) {
        if (!error) {
            if (!isRefresh && response.count == 0)
                self.reachedBottom = YES;
            
            [[TTUtility sharedInstance] internetConnectionFound];
            
            for (PFObject *activity in response[0]){
                Trip *atrip = activity[@"trip"];
                PFUser *auser = activity[@"fromUser"];
                NSString *mashup = [NSString stringWithFormat:@"%@.%@",atrip.objectId,auser.objectId];
                if(![self.userTrips containsObject:mashup])
                    [self.userTrips addObject:mashup];
                Photo *photo = activity[@"photo"];
                photo.user = activity[@"fromUser"];
                photo.trip = activity[@"trip"];
                if (photo.trip != nil){
                    
                    [self.objid addObject:activity.objectId];
                    
                    if (!isRefresh){
                        [self.mainPhotos addObject:photo];
                    } else {
                        //go through and check to see if this photo updates a current trip
                        int index = 0; BOOL updatedOldPhoto = NO;
                        for(Photo *oldPhoto in self.mainPhotos){
                            if([oldPhoto.trip.objectId isEqualToString:photo.trip.objectId] && [oldPhoto.user.objectId isEqualToString:photo.user.objectId]){
                                
                                Photo *originalPhoto = oldPhoto;
                                
                                //remove the old photo for this trip
                                [self.mainPhotos removeObjectAtIndex:index];
                                //insert new photo for this trip
                                [self.mainPhotos insertObject:photo atIndex:0];
                                
                                //get the subphoto array for this trip
                                NSMutableArray *sub = [self.subPhotos objectForKey:originalPhoto.objectId];
                                //add old photo to top of array
                                [sub insertObject:originalPhoto atIndex:0];
                                //insert array into subphotos dictionary with new photo key
                                [self.subPhotos setObject:sub forKey:photo.objectId];
                                //remove old subphotos array from dictionary
                                [self.subPhotos removeObjectForKey:originalPhoto.objectId];
                                updatedOldPhoto = YES;
                                
                                if(!sub)
                                    [refreshControl endRefreshing];  //this is temp to stop a very hard to reproduce bug where sometimes sub is nil and it makes the refresh hang
                                    
                                break;
                            }
                            index++;
                        }
                        
                        if(!updatedOldPhoto)
                            [self.mainPhotos insertObject:photo atIndex:0];
                        
                    }
                    
                    NSMutableArray *p = [[NSMutableArray alloc] init];
                    for (PFObject *activities in response[1]){
                        Trip *atrip = activities[@"trip"];
                        PFUser *auser = activities[@"fromUser"];
                        NSString *mashup = [NSString stringWithFormat:@"%@.%@",atrip.objectId,auser.objectId];
                        if(![self.userTrips containsObject:mashup])
                            [self.userTrips addObject:mashup];
                        [self.objid addObject:activities.objectId];
                        
                        Trip *trip = activities[@"trip"];
                        Photo *photo2 = activities[@"photo"];
                        photo2.user = activities[@"fromUser"];
                        photo2.trip = activities[@"trip"];
                        if([trip.objectId isEqual:photo.trip.objectId] && [photo2.user.objectId isEqual:photo.user.objectId]){
                            if(isRefresh){
                                NSMutableArray *sub = [self.subPhotos objectForKey:photo.objectId];
                                [sub insertObject:photo2 atIndex:0];
                                [self.subPhotos removeObjectForKey:photo.objectId];
                                [self.subPhotos setObject:sub forKey:photo.objectId];
                            }else{
                                [p addObject:photo2];
                                [self.subPhotos setObject:p forKey:photo.objectId];
                            }
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (self.mainPhotos.count < 2 && !self.reachedBottom){
                            self.isLoading = NO;
                            [self loadNewsFeed:NO refresh:nil];
                        } else if (mainCount == (int)self.mainPhotos && !self.reachedBottom){
                            self.isLoading = NO;
                            [self loadNewsFeed:NO refresh:nil];
                        }
                        
                        if (refreshControl) {
                            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                            [formatter setDateFormat:@"MMM d, h:mm a"];
                            //NSString *lastUpdate = NSLocalizedString(@"Last update",@"Last update");
                            //NSString *title = [NSString stringWithFormat:@"%@: %@", lastUpdate, [formatter stringFromDate:[NSDate date]]];
                            NSString *title = @"";
                            NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[TTColor tripTrunkWhite]
                                                                                        forKey:NSForegroundColorAttributeName];
                            NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
                            refreshControl.attributedTitle = attributedTitle;
                            
                            [refreshControl endRefreshing];
                            //why is this here? it gets called over and over
//                            [self.collectionView reloadData];
                            self.isLoading = NO;
                            
                            
                        } else {
                            [refreshControl endRefreshing];
                            //why is this here? it gets called over and over
//                            [self.collectionView reloadData];
                            
                        }
                    });
                    
        }else{
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadNewsFeed:"];
            [refreshControl endRefreshing];
        }
        }
            
            for(PFObject *activity in response[2]){
                if(![self.userTrips containsObject:activity])
                    [self.userTrips addObject:activity];
            }
            
        }
        
        self.isLoading = NO;
        [refreshControl endRefreshing];
        
        [self.collectionView reloadData];
//        [self.collectionView performBatchUpdates:^{}
//                                      completion:^(BOOL finished) {
//                                          if (self.isViewLoaded && self.view.window)
//                                              [self checkWhichVideoToEnable];
//                                      }];
    }];
        
    }else{
        [refreshControl endRefreshing];
    }

}

- (void)setTitleImage {
    UIImage *logo = [UIImage imageNamed:@"tripTrunkTitle"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
    logoView.frame = CGRectMake(logoView.frame.origin.x, logoView.frame.origin.y,logoView.frame.size.width,self.navigationController.navigationBar.frame.size.height*.6);
    [logoView setContentMode:UIViewContentModeScaleAspectFit];
    self.navigationItem.titleView = logoView;
    [self.navigationItem.titleView setContentMode:UIViewContentModeScaleAspectFit];
}

-(void)createLeftButtons{
    self.navigationItem.rightBarButtonItem = nil;
    UIImage *image = [UIImage imageNamed:@"globeRight"];
    CGRect buttonFrame = CGRectMake(0, 0, 40, 40);
    
    UIButton *bttn = [[UIButton alloc] initWithFrame:buttonFrame];
    [bttn addTarget:self action:@selector(switchToMap) forControlEvents:UIControlEventTouchUpInside];
    [bttn setImage:image forState:UIControlStateNormal];
    [bttn setImage:image forState:UIControlStateHighlighted];
    [bttn setImage:image forState:UIControlStateSelected];
    
    UIBarButtonItem *buttonOne= [[UIBarButtonItem alloc] initWithCustomView:bttn];
    
    self.navigationItem.rightBarButtonItem = buttonOne;
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [self clearVideo];
    [self deallocateVideo];
    [self.delegate backWasTapped:self];
    [self saveViewCountsFromDictionaryToParse];
}

-(void)switchToMap{
    [self.navigationController popToRootViewControllerAnimated:NO];
}


#pragma mark - Button Acctions
-(void)usernameTapped:(UIButton*)sender{
    [self clearVideo];
    [self deallocateVideo];
    Photo *photo = self.mainPhotos[sender.tag];
    PFUser *user = (PFUser*)photo.user;
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}


-(void)trunkTapped:(UIButton*)sender{
    [self clearVideo];
    [self deallocateVideo];
    Photo *photo = self.mainPhotos[sender.tag];
    Trip *trip = photo.trip;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
    trunkViewController.trip = (Trip *)trip;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

-(void)locationWasTapped:(UIButton*)sender{
    [self clearVideo];
    [self deallocateVideo];
    Photo *photo = self.mainPhotos[sender.tag];
    Trip *trip = photo.trip;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkListViewController *trunkViewController = (TrunkListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkList"];
    trunkViewController.city = trip.city;
    CLLocation *location = [[CLLocation alloc]initWithLatitude:trip.lat longitude:trip.longitude];
    trunkViewController.location = location;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

- (IBAction)subPhotoButtonWasTapped:(TTSubPhotoButton *)sender {
    [self clearVideo];
    [self deallocateVideo];
    Photo *mainPhoto = self.mainPhotos[sender.tag];
    NSArray *array = [self.subPhotos objectForKey:mainPhoto.objectId];
    
    if([[sender valueForKey:@"subPhotoIndex"] intValue]<5 && array.count >= [[sender valueForKey:@"subPhotoIndex"] intValue]){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
        Photo *photo = array[[[sender valueForKey:@"subPhotoIndex"] intValue]-1];
        photo.image = sender.imageView.image;
        photoViewController.photo = (Photo *)photo;
        photoViewController.arrayInt = [[sender valueForKey:@"subPhotoIndex"] intValue];
        photoViewController.fromTimeline = YES;
        photoViewController.photos = [self returnPhotosForView:mainPhoto];
        photoViewController.delegate = self;
        [self.navigationController showViewController:photoViewController sender:self];
    }else{
        Trip *trip = mainPhoto.trip;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
        trunkViewController.trip = (Trip *)trip;
        [self.navigationController pushViewController:trunkViewController animated:YES];
    }
}

-(void)swipeLeft:(UIGestureRecognizer *)gestureRecognizer {[self clearVideo];
    [self deallocateVideo];
    Photo *mainPhoto = self.mainPhotos[gestureRecognizer.view.tag];
    Trip *trip = mainPhoto.trip;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
    trunkViewController.trip = (Trip *)trip;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}


-(NSArray*)returnPhotosForView:(Photo*)mainPhoto{
    NSMutableArray *allPhotosInTrunkForThisUser = [NSMutableArray arrayWithObject:mainPhoto];
    NSArray *photos = [self.subPhotos objectForKey:mainPhoto.objectId];
    for(Photo* obj in photos){
        [allPhotosInTrunkForThisUser addObject:obj];
        if(allPhotosInTrunkForThisUser.count == 5)
            break;
    }
    return allPhotosInTrunkForThisUser;
}

// handle method
- (void) handleImageTap:(UIGestureRecognizer *)gestureRecognizer {
    [self clearVideo];
    [self deallocateVideo];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    Photo *mainPhoto = self.mainPhotos[gestureRecognizer.view.tag];
    photoViewController.photo = (Photo *)mainPhoto;
    photoViewController.photos = [self returnPhotosForView:mainPhoto];
    photoViewController.arrayInt = 0;
     photoViewController.fromTimeline = YES;
    photoViewController.trip = mainPhoto.trip;
    photoViewController.mainPhotos = self.mainPhotos;
    photoViewController.delegate = self;
    [self.navigationController showViewController:photoViewController sender:self];
}

- (void) handleImageTapProfile:(UIGestureRecognizer *)gestureRecognizer {
    [self clearVideo];
    [self deallocateVideo];
    Photo *photo = self.mainPhotos[gestureRecognizer.view.tag];
    PFUser *user = (PFUser*)photo.user;
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark -
- (NSString *)stringForTimeStamp:(NSDate*)created {
    
    self.timeFormatter = [[TTTTimeIntervalFormatter alloc] init];

    NSString *time = @"";
    time = [self.timeFormatter stringTimeStampFromDate:[NSDate date] toDate:created];

    return time;
}

#pragma mark - UIRefreshControl
- (void)refresh:(UIRefreshControl *)refreshControl {
    [self loadNewsFeed:YES refresh:refreshControl];
}

#pragma mark - UICollectionViewDelegate
-(TTTimeLineCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    __weak TTTimeLineCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NewsFeedCell" forIndexPath:indexPath];
    
    if(!self.mainPhotos.count)
        return cell;

    [cell.username.titleLabel setText:nil];
    [cell.tripName.titleLabel setText:nil];
    [cell.location.titleLabel setText:nil];
    [cell.userprofile setImage:nil];
    [cell.newsfeedPhoto setImage:nil];
    [cell.timeStamp setText:nil];
    cell.newsfeedPhoto.hidden = NO;
    cell.videoContainerView.hidden = YES;
    
    [cell.privateImageView setImage:nil];
    [cell.userprofile setImage:nil];
    cell.photoVideoView=nil;
    [cell.viewCountLabel setText:nil];
    cell.videoSoundButton.hidden = YES;
    
    Photo *photo = self.mainPhotos[indexPath.row];
    if (!photo.trip.isPrivate)
        cell.privateImageView.hidden = YES;
    else cell.privateImageView.hidden = NO;
    
    NSString *timeStamp = [self stringForTimeStamp:photo.createdAt];
    [cell.timeStamp setText:timeStamp];
    [cell.username setTitle:photo.user.username forState:UIControlStateNormal];
    [cell.tripName setTitle:photo.trip.name forState:UIControlStateNormal];
    [cell.location setTitle:[NSString stringWithFormat:@"%@, %@",photo.trip.city, photo.trip.country] forState:UIControlStateNormal];
    [cell setTag:indexPath.row];
    [cell.username addTarget:self action:@selector(usernameTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.tripName addTarget:self action:@selector(trunkTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.location addTarget:self action:@selector(locationWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapProfile:)];
    [profileTap setCancelsTouchesInView:YES];
    [profileTap setNumberOfTapsRequired:1];
    [profileTap.view setTag:indexPath.row];
    [cell.userprofile addGestureRecognizer:profileTap];
    
    [cell.userprofile setUserInteractionEnabled:YES];
    [cell.location setTag:indexPath.row];
    [cell.username.titleLabel adjustsFontSizeToFitWidth];
    [cell.tripName.titleLabel adjustsFontSizeToFitWidth];
    [cell.username setTag:indexPath.row];
    [cell.tripName setTag:indexPath.row];
    [cell.location.titleLabel adjustsFontSizeToFitWidth];
    
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profilePreviewImageUrl:photo.user[@"profilePicUrl"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    UIImage *elipsisImage = [UIImage imageNamed:@"ellipsis"];
    UIImageView *elipsis = [[UIImageView alloc] initWithImage:elipsisImage];
    float eWidth = elipsisImage.size.width;
    float eHeight = elipsisImage.size.height;
    
    [cell.userprofile setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [cell.userprofile setImage:image];
        [cell setNeedsLayout];
    } failure:nil];
    
    NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
    NSURLRequest *requestNew = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    UIImage *placeholderImage = photo.image;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
    [tap setCancelsTouchesInView:YES];
    [tap setNumberOfTapsRequired:1];
    [cell.newsfeedPhoto addGestureRecognizer:tap];
    [cell.newsfeedPhoto setUserInteractionEnabled:YES];
    [tap.view setTag:indexPath.row];
    
    UISwipeGestureRecognizer *swipeleft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft:)];
    swipeleft.direction = UISwipeGestureRecognizerDirectionLeft;
    swipeleft.delegate = self;
    [swipeleft.view setTag:indexPath.row];
    [cell.newsfeedPhoto addGestureRecognizer:swipeleft];
    
    [cell.newsfeedPhoto setImageWithURLRequest:requestNew placeholderImage:placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [cell.newsfeedPhoto setImage:image];
        [cell setNeedsLayout];
    } failure:nil];
    
    if(photo.video){
        cell.videoContainerView.hidden = NO;
        [cell.videoContainerView addGestureRecognizer:tap];
        [cell.videoContainerView setTag:indexPath.row];
        [photo.video fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            AVPlayerLayer *layer = [[AVPlayerLayer alloc] init];
            AVPlayer *player = [[AVPlayer alloc] init];
            layer.backgroundColor = (__bridge CGColorRef _Nullable)([UIColor clearColor]);
            
            NSURL *url = [NSURL URLWithString:photo.video[@"videoUrl"]];
            player = [AVPlayer playerWithURL:url];
            
            layer = [AVPlayerLayer layer];
            [layer setPlayer:player];
            [layer setFrame:CGRectMake(0, 0, cell.videoContainerView.frame.size.width, cell.videoContainerView.frame.size.height)];
            [layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
            cell.avPlayer = player;
            if(url == [self urlOfCurrentlyPlayingInPlayer:player]){
                [cell.videoContainerView.layer addSublayer:layer];
                cell.videoContainerView.backgroundColor = [UIColor clearColor];
                cell.videoContainerView.layer.backgroundColor = (__bridge CGColorRef _Nullable)([UIColor clearColor]);
                [cell.photoVideoView bringSubviewToFront:cell.videoContainerView];
            }
            
            [player setActionAtItemEnd:AVPlayerActionAtItemEndNone];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(newsFeedPlayerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:[player currentItem]];
            //                [player addObserver:self forKeyPath:@"status" options:0 context:nil];
            self.viewCount = 1;
            photo.viewCount=[NSNumber numberWithInt:[photo.viewCount intValue]+1];
            cell.viewCountLabel.text = [NSString stringWithFormat:@"%@",photo.viewCount];
            
            //------------------------
            //ABSOLUTELY RIDICULOUS PLAY HACK BECAUSE THE 'RIGHT WAY' WILL NOT WORK!
            //            if(indexPath.row == 0){ //<-----need to check if row 0 is visible, this isn't good enough
            //                dispatch_async(dispatch_get_main_queue(), ^{
            //                    [player play];
            //                    NSLog(@"Now playing video: %@",photo.objectId);
            //                });
            //                [self incrementViewInDictionaryForVideo:photo.objectId];
            //                self.videoId = photo.objectId;
            //            }
            //------------------------
            
            cell.videoSoundButton.hidden = NO;
            cell.viewCountLabel.hidden = NO;
            
            if(self.phoneMuted)
                cell.videoSoundButton.selected = NO;
            else cell.videoSoundButton.selected = YES;
            
            
        }];
    }
    
    for(int i=0;i<5;i++){
        UIButton *button = cell.subPhotoButtons[i];
        button.hidden = YES;
        button.tag = 0;
        if(i<4){
            button.imageView.image = nil;
            for(UIImageView *subview in button.subviews) {
                if(subview.tag == 9999)
                    [subview removeFromSuperview];
            }
            
            //force color correction when you scroll through the uicollectionview
            switch(i){
                case 0:
                    [button.layer setBorderColor:[[TTColor subPhotoBlue] CGColor]];
                    [button setBackgroundColor:[TTColor subPhotoBlue]];
                    break;
                case 1:
                    [button.layer setBorderColor:[[TTColor subPhotoPink] CGColor]];
                    [button setBackgroundColor:[TTColor subPhotoPink]];
                    break;
                case 2:
                    [button.layer setBorderColor:[[TTColor subPhotoTan] CGColor]];
                    [button setBackgroundColor:[TTColor subPhotoTan]];
                    break;
                case 3:
                    [button.layer setBorderColor:[[TTColor subPhotoGreen] CGColor]];
                    [button setBackgroundColor:[TTColor subPhotoGreen]];
                    break;
                case 4:{
                    [button.layer setBorderColor:[[TTColor subPhotoGray] CGColor]];
                    [button setBackgroundColor:[TTColor subPhotoGray]];
                    break;
                }
                default:
                    break;
            }
        }
    }
    
    NSMutableArray *subPhotoArray = [self.subPhotos objectForKey:photo.objectId];
    for(int i=0;i<subPhotoArray.count;i++){
        Photo *smallPhoto = subPhotoArray[i];
        NSString *urlString = [[TTUtility sharedInstance] thumbnailImageUrl:smallPhoto.imageUrl];
        NSURLRequest *requestNew = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        
        if(i<5){
            __weak UIButton *button = cell.subPhotoButtons[i];
            button.tag = indexPath.row;
            if(i<4){
                [button.imageView setImageWithURLRequest:requestNew placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    [button setImage:image forState:UIControlStateNormal];
                    button.hidden = NO;
                    smallPhoto.image = image;
                    [subPhotoArray replaceObjectAtIndex:i withObject:smallPhoto];
                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                    NSLog(@"Error loading subPhotoButtonimage: %@",error);
                    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"cellForItemAtIndexPath:"];
                }];
            }
            
            if(i==4 && subPhotoArray.count>4)
                button.hidden = NO;
        }else{
            break;
        }
        
        [self.subPhotos setObject:subPhotoArray forKey:photo.objectId];
        
        if(i==subPhotoArray.count-1){
            //subPhotoArray.count+1 because we have to account for the mainPhoto
            if(subPhotoArray.count<5 && smallPhoto.trip.publicTripDetail.photoCount > subPhotoArray.count+1){
                UIButton *button = cell.subPhotoButtons[subPhotoArray.count];
                button.tag = indexPath.row;
                button.hidden = NO;
                [button setImage:[UIImage imageNamed:@"moreTrunk"] forState:UIControlStateNormal];
                float buttonFrame = button.frame.size.width/2;
                [elipsis setFrame:CGRectMake(buttonFrame-eWidth/2, buttonFrame-eHeight/2, eWidth, eHeight)];
                elipsis.tag = 9999;
                [button addSubview:elipsis];
                [button.layer setBorderColor:[[TTColor subPhotoGray] CGColor]];
                [button setBackgroundColor:[TTColor subPhotoGray]];
            }
        }
    }

    [cell setNeedsDisplay];
    return  cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.mainPhotos.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.view.frame.size.width, 406.5);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{

}


#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)sender{
    if (self.isViewLoaded && self.view.window)
        [self checkWhichVideoToEnable:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView
                  willDecelerate:(BOOL)decelerate
{
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = -200;
    if(y > h + reload_distance) {
        [self loadNewsFeed:NO refresh:nil];
    }
}

#pragma mark - Video
-(NSURL *)urlOfCurrentlyPlayingInPlayer:(AVPlayer *)player{
    // get current asset
    AVAsset *currentPlayerAsset = player.currentItem.asset;
    // make sure the current asset is an AVURLAsset
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) return nil;
    // return the NSURL
    return [(AVURLAsset *)currentPlayerAsset URL];
}


-(void)checkWhichVideoToEnable:(BOOL)reset{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    if(self.mainPhotos.count > 0){
        for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
            CGPoint convertedPoint=[self.collectionView convertPoint:cell.frame.origin toView:self.collectionView.superview];
            int topBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
            int amountVisible = convertedPoint.y + cell.frame.size.height - topBarHeight < cell.frame.size.height ? convertedPoint.y + cell.frame.size.height - topBarHeight : cell.frame.size.height;
            amountVisible = screenHeight-convertedPoint.y < amountVisible ? screenHeight-convertedPoint.y : amountVisible;
            
            TTTimeLineCollectionViewCell *videoCell = (TTTimeLineCollectionViewCell*)cell;
            Photo *photo = self.mainPhotos[indexPath.row];
            if(photo.video){
                if(amountVisible>screenHeight/2.1){
                    if(![self.videoId isEqualToString:photo.objectId]){
                        if(videoCell.avPlayer != self.currentVideo){
                            [self incrementViewInDictionaryForVideo:photo.objectId];
                            self.currentVideo = videoCell.avPlayer;
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [videoCell.avPlayer play];
                                //videoCell.newsfeedPhoto.hidden = YES;
                                NSLog(@"Now playing video (check): %@",photo.objectId);
                            });
                            self.videoId = photo.objectId;
                        }
                    }
                }else{
                    [videoCell.avPlayer pause];
                }
            }
        }
    }
}

- (void)newsFeedPlayerItemDidReachEnd:(NSNotification *)notification{

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    if(self.mainPhotos.count > 0){
        for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
            CGPoint convertedPoint=[self.collectionView convertPoint:cell.frame.origin toView:self.collectionView.superview];
            int topBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
            int amountVisible = convertedPoint.y + cell.frame.size.height - topBarHeight < cell.frame.size.height ? convertedPoint.y + cell.frame.size.height - topBarHeight : cell.frame.size.height;
            amountVisible = screenHeight-convertedPoint.y < amountVisible ? screenHeight-convertedPoint.y : amountVisible;
            
            Photo *photo = self.mainPhotos[indexPath.row];
            TTTimeLineCollectionViewCell *videoCell = (TTTimeLineCollectionViewCell*)cell;

            if(amountVisible>screenHeight/2.1){
                self.viewCount++;
                photo.viewCount=[NSNumber numberWithInt:[photo.viewCount intValue]+1];
                [videoCell.avPlayer.currentItem seekToTime:kCMTimeZero];
                //[videoCell.avPlayer play];
                [self incrementViewInDictionaryForVideo:photo.objectId];
                videoCell.viewCountLabel.text = [NSString stringWithFormat:@"%@",photo.viewCount];
                NSLog(@"Now playing video (loop): %@",photo.objectId);
            }
        }
    }
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if (object == self.player && [keyPath isEqualToString:@"status"]) {
//        if (self.player.status == AVPlayerItemStatusReadyToPlay) {
//            [self.activityIndicator stopAnimating];
//        } else if (self.player.status == AVPlayerStatusFailed) {
//            NSLog(@"There was an error loading the video");
//        }
//    }
//}

-(void)deallocateVideo{
    
    @try{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillTerminateNotification];
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillResignActiveNotification];
//        [self.player removeObserver:self forKeyPath:@"status"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

-(void)clearVideo{
    
    @try{
//        [self.player removeObserver:self forKeyPath:@"status"];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
        TTTimeLineCollectionViewCell *videoCell = (TTTimeLineCollectionViewCell*)cell;
        [videoCell.avPlayer.currentItem seekToTime:kCMTimeZero];
        [videoCell.avPlayer pause];
        
        self.detector.silentNotify = ^(BOOL silent){
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
            if(silent){
                videoCell.videoSoundButton.selected = NO;
                self.phoneMuted = YES;
            }else{
                videoCell.videoSoundButton.selected = YES;
                self.phoneMuted = NO;
            }
    
        };
        videoCell.videoSoundButton.hidden = YES;
    }
}

- (IBAction)toggleVideoSound:(id)sender {
    
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
        TTTimeLineCollectionViewCell *videoCell = (TTTimeLineCollectionViewCell*)cell;
        if(videoCell.videoSoundButton.selected){
            videoCell.videoSoundButton.selected = NO;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error: nil];
            videoCell.avPlayer.muted = YES;
        }else{
            videoCell.videoSoundButton.selected = YES;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error: nil];
            videoCell.avPlayer.muted = NO;
        }
    }
    
}

-(void)incrementViewInDictionaryForVideo:(NSString*)objectId{
    BOOL savedCount = NO;
    for(id key in self.viewsDictionary){
        if([key isEqualToString:objectId]){
            int currentCount = [self.viewsDictionary[key] intValue]+1;
            self.viewsDictionary[key] = [NSNumber numberWithInt:currentCount];
            savedCount = YES;
            break;
        }
    }
    
    if(!savedCount){
        [self.viewsDictionary setObject:@"1" forKey:objectId];
    }
    
    NSLog(@"%@",self.viewsDictionary);
}

-(void)saveViewCountsFromDictionaryToParse{
    for(id key in self.viewsDictionary){
        [TTUtility updateVideoViewCount:key withCount:[self.viewsDictionary[key] intValue]];
    }
    
    [self.viewsDictionary removeAllObjects];
}

#pragma mark - PhotoDelegate
-(void)dissmissWasTapped:(NSArray *)mainPhotos{
    self.mainPhotos = [NSMutableArray arrayWithArray:mainPhotos];
}


@end
