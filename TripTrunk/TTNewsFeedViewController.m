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


@interface TTNewsFeedViewController () <UICollectionViewDataSource
, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property NSMutableArray *following;
@property NSMutableArray *photos;
@end

@implementation TTNewsFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitleImage];
    [self createLeftButtons];
    self.following = [[NSMutableArray alloc]init];
    self.photos = [[NSMutableArray alloc]init];
    [self loadNewsFeed];
}

-(void)loadNewsFeed{
    
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error)
        {
            for (PFUser *user in users) {
                [self.following addObject:user];
            }
            
            PFQuery *photos = [PFQuery queryWithClassName:@"Activity"];
            [photos whereKey:@"type" equalTo:@"addedPhoto"];
            [photos whereKey:@"fromUser" containedIn:self.following];
            [photos whereKeyExists:@"trip"];
            photos.limit = 5;
            [photos orderByDescending:@"createdAt"];
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
                        [self.photos addObject:photo];
                    }
                }
                
                [self.collectionView reloadData];
            }];

        }
    }];
    
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
    [self.navigationController popToRootViewControllerAnimated:NO];
}

-(TTTimeLineCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    TTTimeLineCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"NewsFeedCell" forIndexPath:indexPath];
    Photo *photo = self.photos[indexPath.row];
    [cell.username setTitle:photo.user.username forState:UIControlStateNormal];
    [cell.tripName setTitle:photo.trip.name forState:UIControlStateNormal];
    cell.location.text = [NSString stringWithFormat:@"%@, %@",photo.trip.city, photo.trip.country];
    cell.tag = indexPath.row;
    
    [cell.username addTarget:self action:@selector(usernameTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.tripName addTarget:self action:@selector(trunkTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    //within cellForRowAtIndexPath (where customer table cell with imageview is created and reused)
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
    
    tap.cancelsTouchesInView = YES;
    tap.numberOfTapsRequired = 1;
    [cell.newsfeedPhoto addGestureRecognizer:tap];
    cell.newsfeedPhoto.userInteractionEnabled = YES;
    tap.view.tag =  indexPath.row;

    
    [cell.username.titleLabel adjustsFontSizeToFitWidth];
    [cell.tripName.titleLabel adjustsFontSizeToFitWidth];
    [cell.location adjustsFontSizeToFitWidth];
    
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profilePreviewImageUrl:photo.user[@"profilePicUrl"]]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    
    __weak TTTimeLineCollectionViewCell *weakCell = cell;
    
    [cell.userprofile setImageWithURLRequest:request
                             placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                          
                                          [weakCell.userprofile setImage:image];
                                          [weakCell setNeedsLayout];
                                          
                                      } failure:nil];
    
    
    NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
    NSURLRequest *requestNew = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    UIImage *placeholderImage = photo.image;
    [cell.newsfeedPhoto setContentMode:UIViewContentModeScaleAspectFit];
    
    [cell.newsfeedPhoto setImageWithURLRequest:requestNew
                          placeholderImage:placeholderImage
                                   success:nil failure:nil];

    return weakCell;
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


// handle method
- (void) handleImageTap:(UIGestureRecognizer *)gestureRecognizer {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    Photo *photo = self.photos[gestureRecognizer.view.tag];
    photoViewController.photo = (Photo *)photo;
    
    [self.navigationController showViewController:photoViewController sender:self];}



@end
