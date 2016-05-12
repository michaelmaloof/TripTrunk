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
#import <QuartzCore/QuartzCore.h>

@interface TTNewsFeedViewController () <UICollectionViewDataSource
, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property NSMutableArray *following;
//@property NSMutableArray *photos;
@property TTTTimeIntervalFormatter *timeFormatter;
@property NSMutableArray *objid;
@property BOOL isLoading;
@property NSMutableArray *mainPhotos;
@property NSMutableDictionary *subPhotos;
@property NSMutableArray *duplicatePhotoStrings;
@property NSMutableArray *duplicatePhotos;
@property BOOL reachedBottom;
//@property NSMutableArray *arrayToSend;
@property (strong, nonatomic) NSMutableArray *trips;
@property NSMutableArray *photoUsers;
@end

@implementation TTNewsFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitleImage];
    [self createLeftButtons];
    self.trips = [[NSMutableArray alloc] init];
//    self.photos = [[NSMutableArray alloc]init];
//    self.arrayToSend = [[NSMutableArray alloc]init];
    self.mainPhotos = [[NSMutableArray alloc]init];
    self.subPhotos = [[NSMutableDictionary alloc]init];
    self.photoUsers = [[NSMutableArray alloc]init];
    self.duplicatePhotoStrings = [[NSMutableArray alloc]init];
    self.duplicatePhotos = [[NSMutableArray alloc]init];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:refreshControl];
    UIColor *ttBlueColor = [UIColor colorWithHexString:@"76A4B8"];
    refreshControl.tintColor = ttBlueColor;
    [refreshControl endRefreshing];
    self.objid = [[NSMutableArray alloc]init];
    
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error)
        {
            self.following = [[NSMutableArray alloc]init];
            for (PFUser *user in users)
            {
                [self.following addObject:user];
            }
        }
        [self loadNewsFeed:NO refresh:nil];
    }];

}

-(void)viewDidAppear:(BOOL)animated{
//    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
//        if (!error)
//        {
//            self.following = [[NSMutableArray alloc]init];
//            for (PFUser *user in users)
//            {
//                [self.following addObject:user];
//            }
//        }
//        [self loadNewsFeed:NO refresh:nil];
//    }];
}

-(void)loadNewsFeed:(BOOL)isRefresh refresh:(UIRefreshControl*)refreshControl{
    
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
                             @"isRefresh" : [NSString stringWithFormat:@"%@",isRefresh ? @"YES" : @"NO"]
                             };
    [PFCloud callFunctionInBackground:@"queryForNewsFeed" withParameters:params block:^(NSArray *response, NSError *error) {
        if (!error) {
            if (!isRefresh && response.count == 0)
                self.reachedBottom = YES;
            
            [[TTUtility sharedInstance] internetConnectionFound];
            
            for (PFObject *activity in response[0]){
                Photo *photo = activity[@"photo"];
                photo.user = activity[@"fromUser"];
                photo.trip = activity[@"trip"];
                if (photo.trip != nil){
                    
                    [self.objid addObject:activity.objectId];
                    
                    if (!isRefresh){
                        [self.mainPhotos addObject:photo];
//                        [self.photos addObject:photo]; //obsolete?
//                        [self.arrayToSend addObject:photo]; //obsolete?
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
                        
//                        [self.photos insertObject:photo atIndex:0]; //obsolete?
//                        [self.arrayToSend insertObject:photo atIndex:0]; //obsolete?
                    }
                    
                    NSMutableArray *p = [[NSMutableArray alloc] init];
                    for (PFObject *activities in response[1]){
                        
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
                            NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                                        forKey:NSForegroundColorAttributeName];
                            NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
                            refreshControl.attributedTitle = attributedTitle;
                            
                            [refreshControl endRefreshing];
                            [self.collectionView reloadData];
                            self.isLoading = NO;
                            
                            
                        } else {
                            [refreshControl endRefreshing];
                            [self.collectionView reloadData];
                            self.isLoading = NO;
                            
                        }
                        
                    });
                    
        }else{
            [ParseErrorHandlingController handleError:error];
            [refreshControl endRefreshing];
        }
        }
        }
        
        self.isLoading = NO;
        [refreshControl endRefreshing];
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

-(void)viewWillDisappear:(BOOL)animated{
    [self.delegate backWasTapped:self];

}

-(void)switchToMap{
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
    cell.image1.image = nil;
    cell.image2.image = nil;
    cell.image3.image = nil;
    cell.image4.image = nil;
    cell.image5.image = nil;
    
    cell.image1.hidden = YES;
    cell.image2.hidden = YES;
    cell.image3.hidden = YES;
    cell.image4.hidden = YES;
    cell.image5.hidden = YES;
    cell.imageBUtton.hidden = YES;
    cell.labelButton.hidden = YES;
    
    Photo *photo = self.mainPhotos[indexPath.row];
    
    if (photo.trip.isPrivate == NO){
        cell.privateImageView.hidden = YES;
    } else {
        cell.privateImageView.hidden = NO;

    }
    
    NSString *timeStamp = [self stringForTimeStamp:photo.createdAt];
    cell.timeStamp.text = timeStamp;
    [cell.username setTitle:photo.user.username forState:UIControlStateNormal];
    [cell.tripName setTitle:photo.trip.name forState:UIControlStateNormal];
    [cell.location setTitle:[NSString stringWithFormat:@"%@, %@",photo.trip.city, photo.trip.country] forState:UIControlStateNormal];
    cell.tag = indexPath.row;
    
    [cell.username addTarget:self action:@selector(usernameTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.tripName addTarget:self action:@selector(trunkTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.location addTarget:self action:@selector(locationWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.imageBUtton addTarget:self action:@selector(moreWasTapped:) forControlEvents:UIControlEventTouchUpInside];

    UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapProfile:)];
    
    profileTap.cancelsTouchesInView = YES;
    profileTap.numberOfTapsRequired = 1;
    [cell.userprofile addGestureRecognizer:profileTap];
    cell.userprofile.userInteractionEnabled = YES;
    profileTap.view.tag =  indexPath.row;
    cell.location.tag = indexPath.row;
    cell.imageBUtton.tag = indexPath.row;
    
    [cell.username.titleLabel adjustsFontSizeToFitWidth];
    [cell.tripName.titleLabel adjustsFontSizeToFitWidth];
    cell.username.tag= indexPath.row;
    cell.tripName.tag= indexPath.row;
    [cell.location.titleLabel adjustsFontSizeToFitWidth];
    
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profilePreviewImageUrl:photo.user[@"profilePicUrl"]]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    
    int count = 0;
    [cell.userprofile setImageWithURLRequest:request
                             placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                          
                                          [cell.userprofile setImage:image];
                                          [cell setNeedsLayout];
                                          
                                      } failure:nil];
    
    NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
                NSURLRequest *requestNew = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
                UIImage *placeholderImage = photo.image;
    
                //within cellForRowAtIndexPath (where customer table cell with imageview is created and reused)
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
    
                tap.cancelsTouchesInView = YES;
                tap.numberOfTapsRequired = 1;
                [cell.newsfeedPhoto addGestureRecognizer:tap];
                cell.newsfeedPhoto.userInteractionEnabled = YES;
                tap.view.tag =  indexPath.row; //indexCount - 1;
    
    
                [cell.newsfeedPhoto setImageWithURLRequest:requestNew
                                          placeholderImage:placeholderImage
                                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                       [cell.newsfeedPhoto setImage:image];
                                                       [cell setNeedsLayout];
                                                   } failure:nil];
    

    
    
    NSArray *subPhotoArray = [self.subPhotos objectForKey:photo.objectId];
    for(int i=0;i<subPhotoArray.count;i++){
        Photo *smallPhoto = subPhotoArray[i];
        NSString *urlString = [[TTUtility sharedInstance] thumbnailImageUrl:smallPhoto.imageUrl];
        NSURLRequest *requestNew = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        UIImage *placeholderImage = nil;
        count++;
        
        if (count == 1)
        {
            
            UITapGestureRecognizer *imageOneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapOne:)];
            
            imageOneTap.cancelsTouchesInView = YES;
            imageOneTap.numberOfTapsRequired = 1;
            [cell.image1 addGestureRecognizer:imageOneTap];
            cell.image1.userInteractionEnabled = YES;
            imageOneTap.view.tag = indexPath.row; //indexCount - 1;
            cell.image1.hidden = NO;
            
            [cell.image1 setImageWithURLRequest:requestNew
                               placeholderImage:placeholderImage
                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                            [cell.image1 setImage:image];
                                            cell.image1.hidden = NO;
//                                            [self.arrayToSend removeObjectAtIndex:indexCount-1];
                                            [smallPhoto setImage:image];
//                                            [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
                                            [cell setNeedsLayout];
                                        } failure:nil];
        }
        
        else if (count == 2)
        {
            UITapGestureRecognizer *imageTwoTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapTwo:)];
            
            imageTwoTap.cancelsTouchesInView = YES;
            imageTwoTap.numberOfTapsRequired = 1;
            [cell.image2 addGestureRecognizer:imageTwoTap];
            cell.image2.userInteractionEnabled = YES;
            imageTwoTap.view.tag = indexPath.row; //indexCount - 1;
            cell.image2.hidden = NO;
            
            [cell.image2 setImageWithURLRequest:requestNew
                               placeholderImage:placeholderImage
                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                            [cell.image2 setImage:image];
                                            cell.image2.hidden = NO;
//                                            [self.arrayToSend removeObjectAtIndex:indexCount-1];
                                            [smallPhoto setImage:image];
//                                            [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
                                            [cell setNeedsLayout];
                                        } failure:nil];
        }
        
        else if (count == 3)
        {
            UITapGestureRecognizer *imageThreeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapThree:)];
            imageThreeTap.cancelsTouchesInView = YES;
            imageThreeTap.numberOfTapsRequired = 1;
            [cell.image3 addGestureRecognizer:imageThreeTap];
            cell.image3.userInteractionEnabled = YES;
            imageThreeTap.view.tag = indexPath.row; //indexCount - 1;
            cell.image3.hidden = NO;
            
            
            [cell.image3 setImageWithURLRequest:requestNew
                               placeholderImage:placeholderImage
                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                            [cell.image3 setImage:image];
                                            
                                            
//                                            [self.arrayToSend removeObjectAtIndex:indexCount-1];
                                            [smallPhoto setImage:image];
//                                            [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
                                            
                                            
                                            [cell setNeedsLayout];
                                        } failure:nil];
        }
        
        else if (count == 4)
        {
            UITapGestureRecognizer *imageFourTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapFour:)];
            
            imageFourTap.cancelsTouchesInView = YES;
            imageFourTap.numberOfTapsRequired = 1;
            [cell.image4 addGestureRecognizer:imageFourTap];
            cell.image4.userInteractionEnabled = YES;
            imageFourTap.view.tag = indexPath.row; //indexCount - 1;
            cell.image4.hidden = NO;
            [cell.image4 setImageWithURLRequest:requestNew
                               placeholderImage:placeholderImage
                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                            [cell.image4 setImage:image];
//                                            [self.arrayToSend removeObjectAtIndex:indexCount-1];
                                            [smallPhoto setImage:image];
//                                            [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
                                            
                                            
                                            [cell setNeedsLayout];
                                        } failure:nil];
        }
        
        else if (count == 5)
        {
            
            cell.image5.hidden = NO;
            cell.labelButton.hidden = NO;
            cell.imageBUtton.hidden = NO;
            
            [cell.image5 setImageWithURLRequest:requestNew
                               placeholderImage:placeholderImage
                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                            [cell.image5 setImage:image];
//                                            [self.arrayToSend removeObjectAtIndex:indexCount-1];
                                            [smallPhoto setImage:image];
//                                            [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
                                            
                                            [cell setNeedsLayout];
                                        } failure:nil];
        }
    }

    
    return  cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
  
    return self.mainPhotos.count;
}

-(void)usernameTapped:(UIButton*)sender{
    Photo *photo = self.mainPhotos[sender.tag];
    PFUser *user = (PFUser*)photo.user;
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}


-(void)trunkTapped:(UIButton*)sender{
    Photo *photo = self.mainPhotos[sender.tag];
    Trip *trip = photo.trip;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
    trunkViewController.trip = (Trip *)trip;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

-(void)locationWasTapped:(UIButton*)sender{
    Photo *photo = self.mainPhotos[sender.tag];
    Trip *trip = photo.trip;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkListViewController *trunkViewController = (TrunkListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkList"];
    trunkViewController.city = trip.city;
    CLLocation *location = [[CLLocation alloc]initWithLatitude:trip.lat longitude:trip.longitude];
    trunkViewController.location = location;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

-(void)moreWasTapped:(UIButton*)sender{
    Photo *photo = self.mainPhotos[sender.tag];
    Trip *trip = photo.trip;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
    trunkViewController.trip = (Trip *)trip;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

-(void)handleImageTapOne:(UIGestureRecognizer *)gestureRecognizer {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    Photo *mainPhoto = self.mainPhotos[gestureRecognizer.view.tag];
    NSArray *array = [self.subPhotos objectForKey:mainPhoto.objectId];
    Photo *photo = array[0];
    photoViewController.photo = (Photo *)photo;
    photoViewController.photos = [self returnPhotosForView:mainPhoto];
    photoViewController.arrayInt = 1;
    photoViewController.fromTimeline = YES;
    [self.navigationController showViewController:photoViewController sender:self];
}

-(void)handleImageTapTwo:(UIGestureRecognizer *)gestureRecognizer {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    Photo *mainPhoto = self.mainPhotos[gestureRecognizer.view.tag];
    NSArray *array = [self.subPhotos objectForKey:mainPhoto.objectId];
    Photo *photo = array[1];
    photoViewController.photo = (Photo *)photo;
    photoViewController.photos = [self returnPhotosForView:mainPhoto];
    photoViewController.arrayInt = 2;
    photoViewController.fromTimeline = YES;
    [self.navigationController showViewController:photoViewController sender:self];
}

-(void)handleImageTapThree:(UIGestureRecognizer *)gestureRecognizer {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    Photo *mainPhoto = self.mainPhotos[gestureRecognizer.view.tag];
    NSArray *array = [self.subPhotos objectForKey:mainPhoto.objectId];
    Photo *photo = array[2];
    photoViewController.photo = (Photo *)photo;
    photoViewController.photos = [self returnPhotosForView:mainPhoto];
    photoViewController.arrayInt = 3;
    photoViewController.fromTimeline = YES;
    [self.navigationController showViewController:photoViewController sender:self];
}

-(void)handleImageTapFour:(UIGestureRecognizer *)gestureRecognizer {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    Photo *mainPhoto = self.mainPhotos[gestureRecognizer.view.tag];
    NSArray *array = [self.subPhotos objectForKey:mainPhoto.objectId];
    Photo *photo = array[3];
    photoViewController.photo = (Photo *)photo;
    photoViewController.arrayInt = 4;
    photoViewController.fromTimeline = YES;
    photoViewController.photos = [self returnPhotosForView:mainPhoto];
    [self.navigationController showViewController:photoViewController sender:self];
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

//-(NSArray*)returnPhotosForView:(Photo*)photo
//{
//    
//    NSMutableArray *mutablePhotos = [[NSMutableArray alloc]init];
//    for (Photo *smallPhoto in self.arrayToSend)
//    {
//        if ([photo.trip.objectId isEqualToString:smallPhoto.trip.objectId])
//        {
//            [mutablePhotos addObject:smallPhoto];
//        }
//    }
//    
//    NSArray *array = [mutablePhotos mutableCopy];
//    return array;
//}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.view.frame.size.width, 406.5);
}

// handle method
- (void) handleImageTap:(UIGestureRecognizer *)gestureRecognizer {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    Photo *mainPhoto = self.mainPhotos[gestureRecognizer.view.tag];
    photoViewController.photo = (Photo *)mainPhoto;
    photoViewController.photos = [self returnPhotosForView:mainPhoto];
    photoViewController.arrayInt = 0;
     photoViewController.fromTimeline = YES;
    photoViewController.trip = mainPhoto.trip;
    [self.navigationController showViewController:photoViewController sender:self];
}

- (void) handleImageTapProfile:(UIGestureRecognizer *)gestureRecognizer {
    Photo *photo = self.mainPhotos[gestureRecognizer.view.tag];
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



//MOVING THIS OUT OF MY WAY

//LOADNEWSFEED
// I don't think we'll need duplicatePhotoStrings anymore
// I don't think we'll need duplicatePhotos anymore
//this trip hasnt been represnted yet
//                    if (![self.duplicatePhotoStrings containsObject:photo.trip.objectId]){
//                        if (isRefresh == YES){
//                            [self.mainPhotos insertObject:photo atIndex:0];
//                            [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                            [self.duplicatePhotos addObject:photo.objectId];
//
//                            if (![self.photoUsers containsObject:photo.user.objectId])
//                                [self.photoUsers addObject:photo.user.objectId];
//
//
//                        } else {
//                            [self.mainPhotos addObject:photo];
//                            [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                            [self.duplicatePhotos addObject:photo.objectId];
//                            if (![self.photoUsers containsObject:photo.user.objectId]){
//                                if (photo.user.objectId != nil)
//                                    [self.photoUsers addObject:photo.user.objectId];
//                            }
//                        }
//                    } else if ([self.duplicatePhotoStrings containsObject:photo.trip.objectId]) {
//
//                        if (![_duplicatePhotos containsObject:photo.objectId]){
//                            if (![self.photoUsers containsObject:photo.user.objectId]){
//                                if (isRefresh == YES) {
//                                    [self.mainPhotos insertObject:photo atIndex:0];
//                                    [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                    [self.duplicatePhotos addObject:photo.objectId];
//                                    if (![self.photoUsers containsObject:photo.user.objectId])
//                                        [self.photoUsers addObject:photo.user.objectId];
//                                }else{
//                                    [self.mainPhotos addObject:photo];
//                                    [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                    [self.duplicatePhotos addObject:photo.objectId];
//                                    if (![self.photoUsers containsObject:photo.user.objectId]){
//                                        if (photo.user.objectId != nil)
//                                            [self.photoUsers addObject:photo.user.objectId];
//                                    }
//                                }
//
//                            }else{
//                                //so the photo and trip and user have been represnted. Lets make sure its all from one trunk though (in case a user is represented but its from a different trunk)
//                                NSUInteger fooIndex = [self.photoUsers indexOfObject:photo.user.objectId]; //BUG BUG BUG FIXME YOU IDIOT MICHAEL. THE INDEX OF THE USER IN PHOTOUSERS IS NOT ALWAYS THE SAME AS IN THE TRIPS
//                                NSString *tripID = self.duplicatePhotoStrings[fooIndex];
//
//                                //this user is represnted in a different trunk, so it doesnt count as being represtened already in this case
//                                if (![tripID isEqualToString:photo.trip.objectId]){
//                                    if (isRefresh == YES) {
//                                        [self.mainPhotos insertObject:photo atIndex:0];
//                                        [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                        [self.duplicatePhotos addObject:photo.objectId];
//                                        if (![self.photoUsers containsObject:photo.user.objectId])
//                                            [self.photoUsers addObject:photo.user.objectId];
//                                    }else{
//                                        [self.mainPhotos addObject:photo];
//                                        [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                        [self.duplicatePhotos addObject:photo.objectId];
//                                        if (![self.photoUsers containsObject:photo.user.objectId])
//                                            [self.photoUsers addObject:photo.user.objectId];
//                                    }
//
//                                }
//
//                            }
//                        }
//
//                    }






//    if (self.isLoading == NO)
//    {
//        self.isLoading = YES;
//        int mainCount = (int)self.mainPhotos.count;
//
//        PFQuery *memberQuery = [PFQuery queryWithClassName:@"Activity"];
//        [memberQuery whereKeyExists:@"fromUser"];
//        [memberQuery whereKeyExists:@"toUser"];
//        [memberQuery whereKey:@"toUser" equalTo:[PFUser currentUser]];
//        [memberQuery whereKey:@"type" equalTo:@"addToTrip"];
//        [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
//        [memberQuery setLimit:100];
//
//        [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
//         {
//             if(!error)
//             {
//                 [[TTUtility sharedInstance] internetConnectionFound];
//                 for(id object in objects)
//                 {
//                     [self.trips addObject:object[@"trip"]];
//                 }
//
//                 PFQuery *photos = [PFQuery queryWithClassName:@"Activity"];
//                 [photos whereKeyExists:@"trip"];
//                 [photos whereKey:@"type" equalTo:@"addedPhoto"];
//                 [photos whereKey:@"fromUser" containedIn:self.following];
//                 if (self.photos.count > 0 && isRefresh == NO)
//                 {
//                     Photo *photo = self.photos.lastObject;
//                     [photos whereKey:@"createdAt" lessThanOrEqualTo:photo.createdAt];
//                     [photos whereKey:@"objectId" notContainedIn:self.objid];
//                 } else if (self.photos.count > 0 && isRefresh == YES)
//                 {
//                     Photo *photo = self.photos.firstObject;
//                     [photos whereKey:@"createdAt" greaterThanOrEqualTo:photo.createdAt];
//                     [photos whereKey:@"objectId" notContainedIn:self.objid];
//                 }
//
//                 PFQuery *photos2 = [PFQuery queryWithClassName:@"Activity"];
//                 [photos2 whereKeyExists:@"trip"];
//                 [photos2 whereKey:@"type" equalTo:@"addedPhoto"];
//                 [photos2 whereKey:@"trip" containedIn:self.trips];
//                 if (self.photos.count > 0 && isRefresh == NO)
//                 {
//                     Photo *photo = self.photos.lastObject;
//                     [photos2 whereKey:@"createdAt" lessThanOrEqualTo:photo.createdAt];
//                     [photos2 whereKey:@"objectId" notContainedIn:self.objid];
//                 } else if (self.photos.count > 0 && isRefresh == YES)
//                 {
//                     Photo *photo = self.photos.firstObject;
//                     [photos2 whereKey:@"createdAt" greaterThanOrEqualTo:photo.createdAt];
//                     [photos2 whereKey:@"objectId" notContainedIn:self.objid];
//                 }
//
//                 PFQuery *photoQuery = [PFQuery orQueryWithSubqueries:@[photos,photos2]];
//                 [photoQuery whereKeyExists:@"fromUser"];
//                 [photoQuery whereKeyExists:@"toUser"];
//                 [photoQuery includeKey:@"fromUser"];
//                 [photoQuery includeKey:@"photo"];
//                 [photoQuery includeKey:@"trip"];
//                 [photoQuery includeKey:@"trip.publicTripDetail"];
//                 [photoQuery setCachePolicy:kPFCachePolicyNetworkOnly];
//                 photoQuery.limit = 100;
//                 [photoQuery orderByDescending:@"createdAt"];
//
//                 [photoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error)
//                  {
//
//                      if (error)
//                      {
//                          [ParseErrorHandlingController handleError:error];
//                          [refreshControl endRefreshing];
//                      }
//
//                      if (!error)
//                      {
//                          if (isRefresh == NO && objects.count == 0)
//                          {
//                              self.reachedBottom = YES;
//                          }
//                          [[TTUtility sharedInstance] internetConnectionFound];
//
//                          for (PFObject *activity in objects)
//                          {
//                              Photo *photo = activity[@"photo"];
//                              photo.user = activity[@"fromUser"];
//                              photo.trip = activity[@"trip"];
//                              if (photo.trip != nil)
//                              {
//
//                                  if (isRefresh == NO)
//                                  {
//                                      [self.photos addObject:photo];
//                                      [self.arrayToSend addObject:photo];
//                                  } else
//                                  {
//                                      [self.photos insertObject:photo atIndex:0];
//                                      [self.arrayToSend insertObject:photo atIndex:0];
//                                  }
//
//                                  //this trip hasnt been represnted yet
//                                  if (![self.duplicatePhotoStrings containsObject:photo.trip.objectId])
//                                  {
//                                      if (isRefresh == YES)
//                                      {
//                                          [self.mainPhotos insertObject:photo atIndex:0];
//                                          [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                          [self.duplicatePhotos addObject:photo.objectId];
//
//                                          if (![self.photoUsers containsObject:photo.user.objectId]){
//
//                                              [self.photoUsers addObject:photo.user.objectId];
//
//                                          }
//                                      } else
//                                      {
//                                          [self.mainPhotos addObject:photo];
//                                          [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                          [self.duplicatePhotos addObject:photo.objectId];
//                                          if (![self.photoUsers containsObject:photo.user.objectId]){
//                                              if (photo.user.objectId != nil){
//                                                  [self.photoUsers addObject:photo.user.objectId];
//                                              }
//                                          }
//                                      }
//                                  }
//
//
//                                  //this trip has been represented
//                                  else if ([self.duplicatePhotoStrings containsObject:photo.trip.objectId])
//                                  {
//
//                                      //this photo hasnt been represented
//                                      if (![_duplicatePhotos containsObject:photo.objectId])
//                                      {
//                                          //this user hasnt been represented
//                                          if (![self.photoUsers containsObject:photo.user.objectId])
//                                          {
//                                              if (isRefresh == YES)
//                                              {
//                                                  [self.mainPhotos insertObject:photo atIndex:0];
//                                                  [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                                  [self.duplicatePhotos addObject:photo.objectId];
//                                                  if (![self.photoUsers containsObject:photo.user.objectId]){
//
//                                                      [self.photoUsers addObject:photo.user.objectId];
//                                                  }
//                                              }
//                                              else
//                                              {
//                                                  [self.mainPhotos addObject:photo];
//                                                  [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                                  [self.duplicatePhotos addObject:photo.objectId];
//                                                  if (![self.photoUsers containsObject:photo.user.objectId]){
//                                                      if (photo.user.objectId != nil){
//                                                          [self.photoUsers addObject:photo.user.objectId];
//                                                      }
//                                                  }
//                                              }
//
//                                        //this user has been represented
//                                          }
//                                          else
//                                          {
//                                        //so the photo and trip and user have been represnted. Lets make sure its all from one trunk though (in case a user is represented but its from a different trunk)
//                                              NSUInteger fooIndex = [self.photoUsers indexOfObject:photo.user.objectId]; //BUG BUG BUG FIXME YOU IDIOT MICHAEL. THE INDEX OF THE USER IN PHOTOUSERS IS NOT ALWAYS THE SAME AS IN THE TRIPS
//                                              NSString *tripID = self.duplicatePhotoStrings[fooIndex];
//
//                                              //this user is represnted in a different trunk, so it doesnt count as being represtened already in this case
//                                              if (![tripID isEqualToString:photo.trip.objectId])
//                                              {
//                                                  if (isRefresh == YES)
//                                                  {
//                                                      [self.mainPhotos insertObject:photo atIndex:0];
//                                                      [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                                      [self.duplicatePhotos addObject:photo.objectId];
//                                                      if (![self.photoUsers containsObject:photo.user.objectId]){
//
//                                                          [self.photoUsers addObject:photo.user.objectId];
//                                                      }
//                                                  }
//                                                  else
//                                                  {
//                                                      [self.mainPhotos addObject:photo];
//                                                      [self.duplicatePhotoStrings addObject:photo.trip.objectId];
//                                                      [self.duplicatePhotos addObject:photo.objectId];
//                                                      if (![self.photoUsers containsObject:photo.user.objectId]){
//
//                                                          [self.photoUsers addObject:photo.user.objectId];
//                                                      }
//                                                  }
//
//                                              }
//
//                                          }
//                                      }
//
//                                  }
//
//                                  [self.objid addObject:activity.objectId];
//                              }
//                          }
//
//
//
//                          dispatch_async(dispatch_get_main_queue(), ^{
//
//                              if (self.mainPhotos.count < 2 && self.reachedBottom == NO){
//                                  self.isLoading = NO;
//                                  [self loadNewsFeed:NO refresh:nil];
//                              } else if (mainCount == (int)self.mainPhotos && self.reachedBottom == NO){
//                                  self.isLoading = NO;
//                                  [self loadNewsFeed:NO refresh:nil];
//                              }
//
//                              if (refreshControl) {
//                                  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//                                  [formatter setDateFormat:@"MMM d, h:mm a"];
////                                  NSString *lastUpdate = NSLocalizedString(@"Last update",@"Last update");
////                                  NSString *title = [NSString stringWithFormat:@"%@: %@", lastUpdate, [formatter stringFromDate:[NSDate date]]];
//                                NSString *title = @"";
//                                  NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
//                                                                                              forKey:NSForegroundColorAttributeName];
//                                  NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
//                                  refreshControl.attributedTitle = attributedTitle;
//
//                                  [refreshControl endRefreshing];
//                                  [self.collectionView reloadData];
//                                  self.isLoading = NO;
//
//
//                              } else {
//                                  [refreshControl endRefreshing];
//                                  [self.collectionView reloadData];
//                                  self.isLoading = NO;
//
//                              }
//
//                          });
//                      }
//                      [refreshControl endRefreshing];
//                      [self.collectionView reloadData];
//
//                  }];
//
//             }else
//             {
//                 [ParseErrorHandlingController handleError:error];
//                 NSLog(@"Error: %@",error);
//             }
//
//         }];
//
//
//
//
//    }




//CELLFORROWATINDEXPATH
//
//
//    __block int count = 0;
//    __block int indexCount = 0;
//    for (Photo *smallPhoto in self.photos){
//        indexCount += 1;
//        if ([photo.trip.objectId isEqualToString:smallPhoto.trip.objectId] && ![photo.objectId isEqualToString:smallPhoto.objectId] && [smallPhoto.user.objectId isEqualToString:photo.user.objectId])
//            {
//
//            NSString *urlString = [[TTUtility sharedInstance] thumbnailImageUrl:smallPhoto.imageUrl];
//            NSURLRequest *requestNew = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
//            UIImage *placeholderImage = nil;
//            count +=1;
//
//            if (count == 1)
//            {
//
//                UITapGestureRecognizer *imageOneTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapOne:)];
//
//                imageOneTap.cancelsTouchesInView = YES;
//                imageOneTap.numberOfTapsRequired = 1;
//                [cell.image1 addGestureRecognizer:imageOneTap];
//                cell.image1.userInteractionEnabled = YES;
//                imageOneTap.view.tag = indexCount - 1;
//                cell.image1.hidden = NO;
//
//            [cell.image1 setImageWithURLRequest:requestNew
//                                      placeholderImage:placeholderImage
//                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                                   [cell.image1 setImage:image];
//                                                   cell.image1.hidden = NO;
//                                                   [self.arrayToSend removeObjectAtIndex:indexCount-1];
//                                                   [smallPhoto setImage:image];
//                                                   [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
//                                                   [cell setNeedsLayout];
//                                               } failure:nil];
//            }
//
//            else if (count == 2)
//            {
//                UITapGestureRecognizer *imageTwoTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapTwo:)];
//
//                imageTwoTap.cancelsTouchesInView = YES;
//                imageTwoTap.numberOfTapsRequired = 1;
//                [cell.image2 addGestureRecognizer:imageTwoTap];
//                cell.image2.userInteractionEnabled = YES;
//                imageTwoTap.view.tag = indexCount - 1;
//                cell.image2.hidden = NO;
//
//                [cell.image2 setImageWithURLRequest:requestNew
//                                   placeholderImage:placeholderImage
//                                            success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                                [cell.image2 setImage:image];
//                                                cell.image2.hidden = NO;
//                                                [self.arrayToSend removeObjectAtIndex:indexCount-1];
//                                                [smallPhoto setImage:image];
//                                                [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
//                                                [cell setNeedsLayout];
//                                            } failure:nil];
//            }
//
//            else if (count == 3)
//            {
//                 UITapGestureRecognizer *imageThreeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapThree:)];
//                imageThreeTap.cancelsTouchesInView = YES;
//                imageThreeTap.numberOfTapsRequired = 1;
//                [cell.image3 addGestureRecognizer:imageThreeTap];
//                cell.image3.userInteractionEnabled = YES;
//                imageThreeTap.view.tag = indexCount - 1;
//                cell.image3.hidden = NO;
//
//
//                [cell.image3 setImageWithURLRequest:requestNew
//                                   placeholderImage:placeholderImage
//                                            success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                                [cell.image3 setImage:image];
//
//
//                                                [self.arrayToSend removeObjectAtIndex:indexCount-1];
//                                                [smallPhoto setImage:image];
//                                                [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
//
//
//                                                [cell setNeedsLayout];
//                                            } failure:nil];
//            }
//
//            else if (count == 4)
//            {
//                UITapGestureRecognizer *imageFourTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapFour:)];
//
//                imageFourTap.cancelsTouchesInView = YES;
//                imageFourTap.numberOfTapsRequired = 1;
//                [cell.image4 addGestureRecognizer:imageFourTap];
//                cell.image4.userInteractionEnabled = YES;
//                imageFourTap.view.tag = indexCount - 1;
//                cell.image4.hidden = NO;
//                [cell.image4 setImageWithURLRequest:requestNew
//                                   placeholderImage:placeholderImage
//                                            success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                                [cell.image4 setImage:image];
//                                                [self.arrayToSend removeObjectAtIndex:indexCount-1];
//                                                [smallPhoto setImage:image];
//                                                [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
//
//
//                                                [cell setNeedsLayout];
//                                            } failure:nil];
//            }
//
//            else if (count == 5)
//            {
//
//                cell.image5.hidden = NO;
//                cell.labelButton.hidden = NO;
//                cell.imageBUtton.hidden = NO;
//
//                [cell.image5 setImageWithURLRequest:requestNew
//                                   placeholderImage:placeholderImage
//                                            success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                                [cell.image5 setImage:image];
//                                                [self.arrayToSend removeObjectAtIndex:indexCount-1];
//                                                [smallPhoto setImage:image];
//                                                [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
//
//                                                [cell setNeedsLayout];
//                                            } failure:nil];
//            }
//
//        }  else if ([photo.objectId isEqualToString:smallPhoto.objectId]){
//
//            NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
//            NSURLRequest *requestNew = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
//            UIImage *placeholderImage = photo.image;
//
//            //within cellForRowAtIndexPath (where customer table cell with imageview is created and reused)
//            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
//
//            tap.cancelsTouchesInView = YES;
//            tap.numberOfTapsRequired = 1;
//            [cell.newsfeedPhoto addGestureRecognizer:tap];
//            cell.newsfeedPhoto.userInteractionEnabled = YES;
//            tap.view.tag =  indexCount - 1;
//
//
//            [cell.newsfeedPhoto setImageWithURLRequest:requestNew
//                                      placeholderImage:placeholderImage
//                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                                   [cell.newsfeedPhoto setImage:image];
//                                                   [self.arrayToSend removeObjectAtIndex:indexCount-1];
//                                                   [smallPhoto setImage:image];
//                                                   [self.arrayToSend insertObject:smallPhoto atIndex:indexCount-1];
//                                                   [cell setNeedsLayout];
//                                               } failure:nil];
//        }
//
//    }

@end
