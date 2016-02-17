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
#import "UIColor+HexColors.h"
#import "TrunkListViewController.h"

@interface TTNewsFeedViewController () <UICollectionViewDataSource
, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property NSMutableArray *following;
@property NSMutableArray *photos;
@property TTTTimeIntervalFormatter *timeFormatter;
@property NSMutableArray *objid;
@property BOOL isLoading;
@property NSMutableArray *trips;
@end

@implementation TTNewsFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitleImage];
    [self createLeftButtons];
    self.photos = [[NSMutableArray alloc]init];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    UIColor *ttBlueColor = [UIColor colorWithHexString:@"76A4B8"];
    refreshControl.tintColor = ttBlueColor;
    [refreshControl endRefreshing];
    self.objid = [[NSMutableArray alloc]init];
}

-(void)viewDidAppear:(BOOL)animated{
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error)
        {
            self.following = [[NSMutableArray alloc]init];
            for (PFUser *user in users)
            {
                [self.following addObject:user];
            }
        }
        
        PFQuery *trips = [PFQuery queryWithClassName:@"Activity"];
        [trips whereKey:@"toUser" equalTo:[PFUser currentUser]];
        [trips whereKey:@"type" equalTo:@"addToTrip"];
        [trips setCachePolicy:kPFCachePolicyCacheThenNetwork];
        [trips includeKey:@"trip"];
        [trips whereKeyExists:@"trip"];
        [trips setLimit:1000];
        [trips findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (!error)
            {
                self.trips = [[NSMutableArray alloc]init];
                for (PFObject *activity in objects)
                {
                    Trip *trip = activity[@"trip"];
                    if (trip.name != nil)
                    {
                        [self.trips addObject:trip];
                    }
                }
            }
                [self loadNewsFeed:NO refresh:nil];
        }];
        
    }];
}

-(void)loadNewsFeed:(BOOL)isRefresh refresh:(UIRefreshControl*)refreshControl{
    
    if (self.isLoading == NO){
        self.isLoading = YES;

            
            PFQuery *photos = [PFQuery queryWithClassName:@"Activity"];
            [photos whereKey:@"type" equalTo:@"addedPhoto"];
            [photos whereKey:@"fromUser" containedIn:self.following];
            [photos whereKeyExists:@"trip"];
            photos.limit = 5;
            [photos orderByDescending:@"createdAt"];
            if (self.photos.count > 0 && isRefresh == NO){
                Photo *photo = self.photos.lastObject;
                [photos whereKey:@"createdAt" lessThanOrEqualTo:photo.createdAt];
                [photos whereKey:@"objectId" notContainedIn:self.objid];
            } else if (self.photos.count > 0 && isRefresh == YES){
                Photo *photo = self.photos.firstObject;
                [photos whereKey:@"createdAt" greaterThanOrEqualTo:photo.createdAt];
                [photos whereKey:@"objectId" notContainedIn:self.objid];
            }
            [photos includeKey:@"fromUser"];
            [photos includeKey:@"photo"];
            [photos includeKey:@"trip"];
            [photos includeKey:@"trip.publicTripDetail"];
            [photos setCachePolicy:kPFCachePolicyNetworkOnly];
            
            [photos findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                for (PFObject *activity in objects)
                {
                    Photo *photo = activity[@"photo"];
                    photo.user = activity[@"fromUser"];
                    photo.trip = activity[@"trip"];
                    if (photo.trip != nil)
                    {
                        if (isRefresh == NO){
                            [self.photos addObject:photo];
                        } else {
                            [self.photos insertObject:photo atIndex:0];
                        }
                        [self.objid addObject:activity.objectId];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (refreshControl) {
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        [formatter setDateFormat:@"MMM d, h:mm a"];
                        NSString *lastUpdate = NSLocalizedString(@"Last update",@"Last update");
                        NSString *title = [NSString stringWithFormat:@"%@: %@", lastUpdate, [formatter stringFromDate:[NSDate date]]];
                        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                                    forKey:NSForegroundColorAttributeName];
                        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
                        refreshControl.attributedTitle = attributedTitle;
                        
                        [refreshControl endRefreshing];
                        [self.collectionView reloadData];
                        self.isLoading = NO;


                    } else {
                        [self.collectionView reloadData];
                        self.isLoading = NO;
                    }
                    
                });
            }];

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
    
    self.navigationItem.leftBarButtonItem = nil;
    UIImage *image = [UIImage imageNamed:@"newsFeedListToggle"];
    CGRect buttonFrame = CGRectMake(0, 0, 80, 25);
    
    UIButton *bttn = [[UIButton alloc] initWithFrame:buttonFrame];
    [bttn addTarget:self action:@selector(switchToMap) forControlEvents:UIControlEventTouchUpInside];
    [bttn setImage:image forState:UIControlStateNormal];
    [bttn setImage:image forState:UIControlStateHighlighted];
    [bttn setImage:image forState:UIControlStateSelected];
    
    UIBarButtonItem *buttonOne= [[UIBarButtonItem alloc] initWithCustomView:bttn];
    
    self.navigationItem.leftBarButtonItem = buttonOne;
    
}

-(void)switchToMap{
    [self.delegate backWasTapped:self];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

-(TTTimeLineCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    

    TTTimeLineCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NewsFeedCell" forIndexPath:indexPath];
    
    cell.username.titleLabel.text= nil;
    cell.tripName.titleLabel.text = nil;
    cell.location.titleLabel.text = nil;
    cell.userprofile.image = nil;
    cell.newsfeedPhoto.image = nil;
    cell.timeStamp.text = nil;
    
    Photo *photo = self.photos[indexPath.row];
    
    
    NSString *timeStamp = [self stringForTimeStamp:photo.createdAt];
    cell.timeStamp.text = timeStamp;
    [cell.username setTitle:photo.user.username forState:UIControlStateNormal];
    [cell.tripName setTitle:photo.trip.name forState:UIControlStateNormal];
    [cell.location setTitle:[NSString stringWithFormat:@"%@, %@",photo.trip.city, photo.trip.country] forState:UIControlStateNormal];
    cell.tag = indexPath.row;
    
    [cell.username addTarget:self action:@selector(usernameTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.tripName addTarget:self action:@selector(trunkTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.location addTarget:self action:@selector(locationWasTapped:) forControlEvents:UIControlEventTouchUpInside];

    
    //within cellForRowAtIndexPath (where customer table cell with imageview is created and reused)
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
    
    tap.cancelsTouchesInView = YES;
    tap.numberOfTapsRequired = 1;
    [cell.newsfeedPhoto addGestureRecognizer:tap];
    cell.newsfeedPhoto.userInteractionEnabled = YES;
    tap.view.tag =  indexPath.row;
    
    UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapProfile:)];
    
    profileTap.cancelsTouchesInView = YES;
    profileTap.numberOfTapsRequired = 1;
    [cell.userprofile addGestureRecognizer:profileTap];
    cell.userprofile.userInteractionEnabled = YES;
    profileTap.view.tag =  indexPath.row;
    cell.location.tag = indexPath.row;
    

    
    [cell.username.titleLabel adjustsFontSizeToFitWidth];
    [cell.tripName.titleLabel adjustsFontSizeToFitWidth];
    cell.username.tag= indexPath.row;
    cell.tripName.tag= indexPath.row;
    [cell.location.titleLabel adjustsFontSizeToFitWidth];
    
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profilePreviewImageUrl:photo.user[@"profilePicUrl"]]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    
    
    [cell.userprofile setImageWithURLRequest:request
                             placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                          
                                          [cell.userprofile setImage:image];
                                          [cell setNeedsLayout];
                                          
                                      } failure:nil];
    
    
    NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
    NSURLRequest *requestNew = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    UIImage *placeholderImage = photo.image;

    
    [cell.newsfeedPhoto setImageWithURLRequest:requestNew
                          placeholderImage:placeholderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       [cell.newsfeedPhoto setImage:image];
                                       [cell setNeedsLayout];
                                   } failure:nil];
    
    return  cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.photos.count;
}

-(void)usernameTapped:(UIButton*)sender{
    Photo *photo = self.photos[sender.tag];
    PFUser *user = (PFUser*)photo.user;
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}


-(void)trunkTapped:(UIButton*)sender{
    Photo *photo = self.photos[sender.tag];
    Trip *trip = photo.trip;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
    trunkViewController.trip = (Trip *)trip;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

-(void)locationWasTapped:(UIButton*)sender{
    Photo *photo = self.photos[sender.tag];
    Trip *trip = photo.trip;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkListViewController *trunkViewController = (TrunkListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkList"];
    trunkViewController.city = trip.city;
    CLLocation *location = [[CLLocation alloc]initWithLatitude:trip.lat longitude:trip.longitude];
    trunkViewController.location = location;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}


// handle method
- (void) handleImageTap:(UIGestureRecognizer *)gestureRecognizer {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    Photo *photo = self.photos[gestureRecognizer.view.tag];
    photoViewController.photo = (Photo *)photo;
    
    [self.navigationController showViewController:photoViewController sender:self];
}

- (void) handleImageTapProfile:(UIGestureRecognizer *)gestureRecognizer {
    Photo *photo = self.photos[gestureRecognizer.view.tag];
    PFUser *user = (PFUser*)photo.user;
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}
- (NSString *)stringForTimeStamp:(NSDate*)created {
    
    self.timeFormatter = [[TTTTimeIntervalFormatter alloc] init];

    NSString *time = @"";
    time = [self.timeFormatter stringTimeStampFromDate:[NSDate date] toDate:created];

    return time;
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

- (void)refresh:(UIRefreshControl *)refreshControl {
    
    [self loadNewsFeed:YES refresh:refreshControl];
    
}










@end
