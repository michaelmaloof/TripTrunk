//
//  TTProfileViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 9/20/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTProfileViewController.h"
#import "TTOnboardingButton.h"
#import "UIImageView+AFNetworking.h"
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "TTFont.h"
#import "TTColor.h"
#import "TTPhotoViewController.h"
#import "TTAnalytics.h"
#import "TTUtility.h"
#import "ParseErrorHandlingController.h"
#import "TTHomeMapCollectionViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "TTTrunkViewController.h"
#import "SocialUtility.h"
#import "TTCache.h"
#import "TTSearchViewController.h"

@interface TTProfileViewController () <UICollectionViewDelegate,UICollectionViewDataSource,UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UICollectionView *trunkCollectionView;
@property (strong, nonatomic) IBOutlet UIImageView *userProfilePictureSmall;
@property (strong, nonatomic) IBOutlet UILabel *userFirstLastNameSmall;
@property (strong, nonatomic) IBOutlet UILabel *usernameSmall;
@property (strong, nonatomic) IBOutlet UIImageView *userProfilePictureMain;
@property (strong, nonatomic) IBOutlet UILabel *userFirstLastNameMain;
@property (strong, nonatomic) IBOutlet UILabel *usernameMain;
@property (strong, nonatomic) IBOutlet UITextView *userBio;
@property (strong, nonatomic) IBOutlet UILabel *followersCount;
@property (strong, nonatomic) IBOutlet UILabel *trunksCount;
@property (strong, nonatomic) IBOutlet UILabel *followingCount;
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UIView *miniUserDetails;
@property (strong, nonatomic) IBOutlet UIView *userDetails;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *followButton;
@property (strong, nonatomic) NSMutableArray *trunkArray;
@property (strong, nonatomic) NSMutableDictionary *imageSet;
@property (strong, nonatomic) NSNumber *followStatus;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *backButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *refreshActivityIndicator;
@property BOOL isLoading;

//Is this stuff needed? It's carried over from the old Trunk VC
@property NSMutableArray *parseLocations;
@property NSMutableArray *meParseLocations;
//@property NSMutableArray *friends;
@property NSMutableArray *objectIDs;
@property NSMutableArray *meObjectIDs;
@property NSMutableArray *haventSeens;
@property NSMutableArray *visitedTrunks;
@property NSMutableArray *mutualTrunks;
@property int objectsCountTotal;
@property int objectsCountMe;
@property BOOL isMine;
@property BOOL didLoad;
@property UIImage *flame;
@property BOOL wasError;
@property BOOL attemptedToLoad;
@property UIRefreshControl *refreshController;
@property int color;
@property NSTimer *colorTimer;
@end

@implementation TTProfileViewController
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.isLoading = NO;
    
    self.followStatus = [[TTCache sharedCache] followStatusForUser:self.user];
    [self setFollowButtonState];
    if(self.delegate){
        self.backButton.hidden = NO;
        self.backButton.userInteractionEnabled = YES;
    }else{
        self.backButton.hidden = YES;
        self.backButton.userInteractionEnabled = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(!self.user)
        self.user = [PFUser currentUser];
    
    //set user details to main details
    self.miniUserDetails.alpha = 0;
    self.userDetails.alpha = 1;
    
    //setup profile information
    [self.userProfilePictureSmall setImageWithURL:[NSURL URLWithString:self.user[@"profilePicUrl"]]];
    self.userFirstLastNameSmall.text = self.user[@"name"];
    self.usernameSmall.text = [NSString stringWithFormat:@"@%@",self.user.username];
    [self.userProfilePictureMain setImageWithURL:[NSURL URLWithString:self.user[@"profilePicUrl"]]];
    self.userFirstLastNameMain.text = self.user[@"name"];
    self.usernameMain.text = [NSString stringWithFormat:@"@%@",self.user.username];
    self.userBio.text = self.user[@"bio"];
    self.followersCount.text = @"";
    self.trunksCount.text = @"";
    self.followingCount.text = @"";
    
    self.trunkArray = [[NSMutableArray alloc] init];
    self.imageSet = [[NSMutableDictionary alloc] init];
    
    //initialize the map and move to user's home location
    [self initMap];
    
    //If the user doesn't have a profile image, set it to User's initials
    if(!self.user[@"profilePicUrl"])
        [self handleMissingProfilePicture];
    
    //update the user's social stats
    [self refreshSocialStatCounts];
    
    //get the trunk list
    [self loadTrunkList];
}

//FIXME: MOVE THIS TO UTILITY
-(void)handleMissingProfilePicture{
    self.userProfilePictureMain.image = [UIImage imageNamed:@"tt_square_placeholder"];
    CGRect labelFrame = CGRectMake(10, 10, 105, 105);
    UILabel *initialsLabel = [[UILabel alloc] initWithFrame:labelFrame];
    initialsLabel.text = [NSString stringWithFormat:@"%@%@",[self.user[@"firstName"] substringToIndex:1],[self.user[@"lastName"] substringToIndex:1]];
    initialsLabel.font = [TTFont tripTrunkFont56];
    initialsLabel.numberOfLines = 1;
    initialsLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
    initialsLabel.adjustsFontSizeToFitWidth = YES;
//    initialsLabel.adjustsLetterSpacingToFitWidth = YES;
    initialsLabel.minimumScaleFactor = 10.0f/12.0f;
    initialsLabel.clipsToBounds = YES;
    initialsLabel.backgroundColor = [UIColor clearColor];
    initialsLabel.textColor = [UIColor darkGrayColor];
    initialsLabel.textAlignment = NSTextAlignmentCenter;
    [self.userProfilePictureMain addSubview:initialsLabel];
}

-(void)setUserProfileState:(BOOL)minimum{
    if(minimum){
        //show top profile info, hide center info
        [UIView animateWithDuration:0.25
                              delay:1.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.miniUserDetails.alpha = 1; }
                         completion:^(BOOL finished){}
         ];
        
        [UIView animateWithDuration:0.25
                              delay:1.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ self.userDetails.alpha = 0; }
                         completion:^(BOOL finished){}
         ];
        
    }else{
        //show center profile info, hide top info
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{ self.miniUserDetails.alpha = 0; }
                         completion:^(BOOL finished){}
         ];
        
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{ self.userDetails.alpha = 1; }
                         completion:^(BOOL finished){}
         ];
    }
}

-(void)setFollowButtonState{
    self.followButton.hidden = YES;
    NSString *followText = NSLocalizedString(@"FOLLOW", @"FOLLOW");
    NSString *followingText = NSLocalizedString(@"FOLLOWING", @"FOLLOWING");
    
    if(![[PFUser currentUser].objectId isEqualToString:self.user.objectId]){
        if(!self.followStatus){
            [SocialUtility followingStatusFromUser:[PFUser currentUser] toUser:self.user block:^(NSNumber *followingStatus, NSError *error){
                if (!error)
                    [[TTCache sharedCache] setFollowStatus:followingStatus user:self.user];
                else [ParseErrorHandlingController handleError:error];
                self.followStatus = followingStatus;
                
                if([followingStatus intValue] > 0){
                    [self.followButton setTitle:followingText forState:UIControlStateNormal];
                    self.followButton.backgroundColor = [TTColor tripTrunkWhite];
                    [self.followButton setTitleColor:[TTColor onboardingButtonColorBlue] forState:UIControlStateNormal];
                }else{
                    [self.followButton setTitle:followText forState:UIControlStateNormal];
                    self.followButton.backgroundColor = [TTColor onboardingButtonColorBlue];
                    [self.followButton setTitleColor:[TTColor tripTrunkWhite] forState:UIControlStateNormal];
                }
                self.followButton.hidden = NO;
            }];
        }else{
            if([self.followStatus intValue] > 0){
                [self.followButton setTitle:followingText forState:UIControlStateNormal];
                self.followButton.backgroundColor = [TTColor tripTrunkWhite];
                [self.followButton setTitleColor:[TTColor onboardingButtonColorBlue] forState:UIControlStateNormal];
            }else{
                [self.followButton setTitle:followText forState:UIControlStateNormal];
                self.followButton.backgroundColor = [TTColor onboardingButtonColorBlue];
                [self.followButton setTitleColor:[TTColor tripTrunkWhite] forState:UIControlStateNormal];
            }
            self.followButton.hidden = NO;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.trunkArray.count;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
//    return CGSizeMake(0, 0);
//}

- (TTHomeMapCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    TTHomeMapCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
//    id activity = self.trunkArray[indexPath.row];
    Trip *trip = self.trunkArray[indexPath.row];
    cell.trunkTitle.text = trip.name;
    cell.trunkLocation.text = [NSString stringWithFormat:@"%@, %@",trip.city,trip.state];
    
    if(trip.memberCount){
        if(trip.memberCount>2)
            cell.trunkMemberInfo.text = [NSString stringWithFormat:@"Made with %lu others",(unsigned long)trip.memberCount];
        else cell.trunkMemberInfo.text = @"Just one member";
        
    }else{
        NSLog(@"Making a call to parse for the member count");
        [SocialUtility trunkMembers:trip block:^(NSArray *users, NSError *error) {
            if(!error){
                if(users.count>2){
                    trip.memberCount = users.count;
                    cell.trunkMemberInfo.text = [NSString stringWithFormat:@"Made with %lu others",(unsigned long)users.count];
                }else{
                    trip.memberCount = 1;
                    cell.trunkMemberInfo.text = @"Just one member";
                }
                
                [self.trunkArray replaceObjectAtIndex:indexPath.row withObject:trip];
            }
        }];
    }
    
    //Load images from Array of image URLs
    NSArray* photos = self.imageSet[trip.objectId];
    NSString *photoUrl;
    if(photos.count>0){
        photoUrl = photos[0];
        NSArray *urlComponents = [photoUrl componentsSeparatedByString:@"/"];
        NSString *file = [urlComponents lastObject];
        NSString *newPhotoUrl = [NSString stringWithFormat:@"http://res.cloudinary.com/triptrunk/image/upload/w_300,h_250,c_fit/%@",file];
        [cell.spotlightTrunkImage setImageWithURL:[NSURL URLWithString:newPhotoUrl]];
        
        //If there are 4 photos then load all of them into the cell, otherwise, only load 1 photo and enlarge the imageView
        if(photos.count>3){
            photoUrl = photos[1];
            urlComponents = [photoUrl componentsSeparatedByString:@"/"];
            file = [urlComponents lastObject];
            newPhotoUrl = [NSString stringWithFormat:@"http://res.cloudinary.com/triptrunk/image/upload/w_100,h_150,c_fit/%@",file];
            [cell.secondaryTrunkImage setImageWithURL:[NSURL URLWithString:newPhotoUrl]];
            
            photoUrl = photos[2];
            urlComponents = [photoUrl componentsSeparatedByString:@"/"];
            file = [urlComponents lastObject];
            newPhotoUrl = [NSString stringWithFormat:@"http://res.cloudinary.com/triptrunk/image/upload/w_100,h_150,c_fit/%@",file];
            [cell.tertiaryTrunkImage setImageWithURL:[NSURL URLWithString:newPhotoUrl]];
            
            
            photoUrl = photos[3];
            urlComponents = [photoUrl componentsSeparatedByString:@"/"];
            file = [urlComponents lastObject];
            newPhotoUrl = [NSString stringWithFormat:@"http://res.cloudinary.com/triptrunk/image/upload/w_100,h_150,c_fit/%@",file];
            [cell.quaternaryTrunkImage setImageWithURL:[NSURL URLWithString:newPhotoUrl]];
        }else{
            //only 1 photo is being used so enlarge the imageView
            cell.lowerInfoConstraint.constant = 248;
            cell.spotlightImageHeightConstraint.constant = 350;
        }
        
    }
    
    cell.tag = indexPath.row;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Trunk" bundle:nil];
    TTTrunkViewController *trunkViewController = (TTTrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTTrunkViewController"];
    trunkViewController.trip = self.trunkArray[indexPath.row];
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

-(UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if(section == 0)
        return UIEdgeInsetsMake(0, [UIScreen mainScreen].bounds.size.width-30, 0, [UIScreen mainScreen].bounds.size.width-300);
    
    return UIEdgeInsetsZero;
}

//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
//{
//    
//    UICollectionReusableView *theView;
//    if(collectionView == self.mainCollectionView){
//        
//        if(kind == UICollectionElementKindSectionHeader){
//            theView = [self.mainCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
//        } else {
//            theView = [self.mainCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
//        }
//    }
//    
//    return theView;
//    
//    
//}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    return CGSizeMake(0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    return CGSizeMake(0,0);
}

#pragma mark - GoogleMapView
-(void)initMap{
    double mapOffset = -1.75; //<------determine if the map should offset because a point is below the photos
    
    //Map View of trunk location
//    self.googleMapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 0, 375, 200)];
    PFGeoPoint *geoPoint = self.user[@"hometownGeoPoint"];
//    if(!geoPoint)
//        geoPoint = [PFGeoPoint geoPointWithLatitude:32.715736 longitude:-117.161087];//<----- this is temporary. Delete this when hometownGeoPoint is added to everyone's database row
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:geoPoint.latitude+mapOffset
                                                            longitude:geoPoint.longitude
                                                                 zoom:7];
    
    self.googleMapView.camera = camera;
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *styleUrl = [mainBundle URLForResource:@"style" withExtension:@"json"];
    NSError *error;
    
    GMSMapStyle *style = [GMSMapStyle styleWithContentsOfFileURL:styleUrl error:&error];
    
    if (!style) {
        NSLog(@"The style definition could not be loaded: %@", error);
    }
    
    self.googleMapView.mapStyle = style;
    self.googleMapView.userInteractionEnabled = NO;
//    [collectionView addSubview:self.googleMapView];
    
    [self addPointToMapWithGeoPoint:geoPoint];
    NSArray *city = [self.user[@"hometown"] componentsSeparatedByString:@","];
    [self addLabelToMapWithGeoPoint:geoPoint AndText:city[0]];
}

//FIXME: THIS NEEDS TO MOVE TO UTILITY
#pragma mark - Marker Creation Code
-(GMSMarker*)createMapMarkerWithGeoPoint:(PFGeoPoint*)geoPoint{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    
    return marker;
}

-(CGPoint)createMapPointWithGeoPoint:(PFGeoPoint*)geoPoint{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    CGPoint point = [self.googleMapView.projection pointForCoordinate:marker.position];
    
    return point;
}

-(void)addPointToMapWithGeoPoint:(PFGeoPoint*)geoPoint{
    CGPoint point = [self createMapPointWithGeoPoint:geoPoint];
    
    UIImageView *dot =[[UIImageView alloc] initWithFrame:CGRectMake(point.x-10,point.y-10,20,20)];
    dot.image=[UIImage imageNamed:@"bluedot"];
    
    [self.googleMapView addSubview:dot];
}

-(void)addFlagToMapWithGeoPoint:(PFGeoPoint*)geoPoint{
    CGPoint point = [self createMapPointWithGeoPoint:geoPoint];
    
    UIImageView *flag =[[UIImageView alloc] initWithFrame:CGRectMake(point.x-10,point.y-20,20,20)];
    flag.image=[UIImage imageNamed:@"map_point_flag"];
    flag.tag = 1000;
    [self.googleMapView addSubview:flag];
}

-(void)addLabelToMapWithGeoPoint:(PFGeoPoint*)geoPoint AndText:(NSString*)text{
    CGPoint point = [self createMapPointWithGeoPoint:geoPoint];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(point.x-10,point.y+3,100,21)];
    label.font = [TTFont tripTrunkFont8];
    label.textColor = [TTColor tripTrunkDarkGray];
    label.text = text;
    
    [self.googleMapView addSubview:label];
}

#pragma mark - Trunk Load from Cloud
-(void)loadTrunkList{
    self.isLoading = YES;
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query whereKey:@"toUser" equalTo:self.user];
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"trip" notContainedIn:self.trunkArray];
    [query includeKey:@"trip"];
//    [query setLimit:10];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error){
            self.wasError = YES;
            NSLog(@"Error: %@",error);
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadTrunkList"];
        }else{
            if(objects.count == 0){
                NSLog(@"Ain't no more trips to load for this user");
            }else{
            
                [[TTUtility sharedInstance] internetConnectionFound];
                NSMutableArray *trips = [[NSMutableArray alloc] init];
                for(id activity in objects){
                    if(activity[@"trip"])
                        [trips addObject:activity[@"trip"]];
                }
                
                NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
                NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
                NSArray *comboArray = [self.trunkArray arrayByAddingObjectsFromArray:[trips sortedArrayUsingDescriptors:descriptors]];
                self.trunkArray = [NSMutableArray arrayWithArray:[comboArray sortedArrayUsingDescriptors:descriptors]];
                
                if(self.trunkArray.count > 0){
                    [self initSpotlightImagesWithBlock:^(BOOL succeeded, NSError *error) {
                        [self.trunkCollectionView reloadData];
                        self.trunkCollectionView.hidden = NO;
                    }];
                }
            
            }
        }
        
        self.isLoading = NO;
        [self.refreshActivityIndicator stopAnimating];
        self.refreshActivityIndicator.hidden = YES;
    }];
}

-(void)refreshSocialStatCounts{
    
    if(self.followers && self.followers.count>0){
        self.followersCount.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.followers.count];
    }else{
        //FIXME: CACHE THESE
        [SocialUtility followerCount:self.user block:^(int count, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
    //            [self.followersButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateNormal];
    //            [self.followersButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateDisabled];
                self.followersCount.text = [NSString stringWithFormat:@"%i",count];
            });
        }];
    }
    
    if(self.following && self.following.count>0){
        self.followingCount.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.following.count];
    }else{
        [SocialUtility followingCount:self.user block:^(int count, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
    //            [self.followingButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateNormal];
    //            [self.followingButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateDisabled];
                self.followingCount.text = [NSString stringWithFormat:@"%i",count];
            });
        }];
    }
    
    [SocialUtility trunkCount:self.user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            self.trunkCount= count;
            
            if (count == 0){
//                [self.trunkCountButton setTitle:@"0" forState:UIControlStateNormal];
                self.trunksCount.text = @"0";
            }else {
//                [self.trunkCountButton   setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateNormal];
                self.trunksCount.text = [NSString stringWithFormat:@"%i",count];
            }
        });
    }];
}

//FIXME: How much of this is necessary for the trunk list of a Profile VC????
//-(void)loadTrunkListBasedOnProfile:(BOOL)isRefresh{
//
//    if (self.meParseLocations.count == 0 || isRefresh == YES) {
//        self.navigationItem.rightBarButtonItem.enabled = NO;
//        NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
//        //Build an array to send up to CC
//        NSMutableArray *friendsObjectIds = [[NSMutableArray alloc] init];
//        //we only have a single user but we still need to add it to an array and send up the params
//        if (!self.user){
//            [friendsObjectIds addObject:[PFUser currentUser].objectId];
//        }else{
//            [friendsObjectIds addObject:self.user.objectId];
//        }
//        int limit;
//        int skip;
//        if (isRefresh == NO){
//            limit = 50;
//            skip = self.objectsCountMe;
//        } else {
//            if (self.objectsCountMe == 0)
//                limit = 50;
//            else limit = self.objectsCountMe;
//            skip = 0;
//            self.objectsCountMe = 0;
//        }
//        NSDictionary *params = @{
//                                 @"objectIds" : friendsObjectIds,
//                                 @"limit" : [NSString stringWithFormat:@"%d",limit],
//                                 @"skip" : [NSString stringWithFormat:@"%d",skip]
//                                 };
//        self.attemptedToLoad = NO;
//        [PFCloud callFunctionInBackground:@"queryForUniqueTrunks" withParameters:params block:^(NSArray *response, NSError *error) {
//            self.attemptedToLoad = YES;
//            if(error)
//            {
//                self.wasError = YES;
//                NSLog(@"Error: %@",error);
//                [ParseErrorHandlingController handleError:error];
//                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadTrunkListBasedOnProfile:"];
//                [self.trunkCollectionView reloadData];
//            }
//            else if (!error)
//            {
//                self.wasError = NO;
//                [[TTUtility sharedInstance] internetConnectionFound];
//            }
//            {
//                if (isRefresh == YES){
//                    self.meObjectIDs = [[NSMutableArray alloc]init];;
//                    self.meParseLocations = [[NSMutableArray alloc]init];
//                }
//                self.didLoad = YES;
//                self.objectsCountMe = (int)response.count + self.objectsCountMe;
//                for (PFObject *activity in response)
//                {
//                    Trip *trip = activity[@"trip"];
//                    if (trip.name != nil && ![self.meObjectIDs containsObject:trip.objectId] && trip.publicTripDetail != nil)
//                    {
//                        [self.meParseLocations addObject:trip];
//                        [self.meObjectIDs addObject:trip.objectId];
//                    } else if (trip.name != nil && ![self.meObjectIDs containsObject:trip.objectId] && [trip.creator.objectId isEqualToString:[PFUser currentUser].objectId])
//                    {
//                        [self.meParseLocations addObject:trip];
//                        [self.meObjectIDs addObject:trip.objectId];
//                    }
//                }
//                for (Trip *trip in self.meParseLocations)
//                {
//                    NSTimeInterval lastTripInterval = [lastOpenedApp timeIntervalSinceDate:trip.createdAt];
//                    NSTimeInterval lastPhotoInterval = [lastOpenedApp timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];
//                    BOOL contains = NO;
//                    for (Trip* trunk in self.visitedTrunks){
//                        if ([trunk.objectId isEqualToString:trip.objectId]){
//                            contains = YES;
//                        }
//                    }
//                    if (self.visitedTrunks.count == 0){
//                        contains = NO;
//                    }
//                    if (lastTripInterval < 0 && contains == NO)
//                    {
//                        [self.haventSeens addObject:trip];
//                    } else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil && contains == NO){
//                        [self.haventSeens addObject:trip];
//                    }
//                }
//            }
//            [self.trunkCollectionView reloadData];
//        }];
//    } else
//    {
//        [self.trunkCollectionView reloadData];
//    }
//}

-(void)initSpotlightImagesWithBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    
    //Weed out Trips that don't have any images in them
    NSMutableArray *deleteObjects = [[NSMutableArray alloc] init];
    
    //Set up a last record check
    __block NSUInteger objectCount = self.trunkArray.count;
    __block NSUInteger count = 0;
    
    //Loop though the array and get each trunks 4 newest photo URLs
    for(Trip *trunk in self.trunkArray){
        //FIXME: This needs to move to Utility <---------------------------------------------------------------------
        PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
        [photoQuery whereKey:@"trip" equalTo:trunk];
//        [photoQuery whereKey:@"user" equalTo:self.user];
        [photoQuery setLimit:4];
        [photoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if(!error){
                NSMutableArray *images = [[NSMutableArray alloc] init];
                
                //Loop though retrieved objects and extract photo's URL
                for(Photo* object in objects){
                    [images addObject:object.imageUrl];
                }
                
                //Add the images to the imageSet, or
                //If the search doesn't return any photos, remove the trunk from the sorted Array
                if(objects.count != 0){
                    //add the images array to the imageSet Array
                    [self.imageSet setObject:images forKey:trunk.objectId];
                }else{
                    //no images found, flag for removal from sorted array
                    [deleteObjects addObject:trunk];
                }
                
                //increment the count for the last record check
                count++;
                
                //check if this is the last record
                if(count == objectCount){
                    //remove the trunks that have no images in them
                    //FIXME: DO WE WANT TO DELETE THESE? WHAT IF YOU WANT TO ADD A FIRST IMAGE?
//                    [self.trunkArray removeObjectsInArray:deleteObjects];
                    //finish the block and notify the caller
                    completionBlock(YES,nil);
                }
                
            }else{
                //There's an error. Handle this and add the Google tracking
                NSLog(@"error getting images");
            }
            
        }];
        
    }
    
}

#pragma mark - UIScrollViewDelegate
//Switch between larger main social details and smaller details on top of view
-(void)scrollViewDidScroll:(UIScrollView *)sender{
    UICollectionViewCell *firstCell = [[self.trunkCollectionView visibleCells] firstObject];
    NSIndexPath *firstIndexPath = [self.trunkCollectionView indexPathForCell: firstCell];
    CGRect frame = [self.trunkCollectionView convertRect:firstCell.frame toView:self.view];

    if(self.miniUserDetails.alpha == 0 && firstCell != nil){
        if(firstIndexPath.row == 0){
            //check if it is blocking the userDetails
            if(frame.origin.x < 130)
                [self setUserProfileState:YES];
            else [self setUserProfileState:NO];
        }else{
            //switch to mini details
            [self setUserProfileState:YES];
        }
    }
    
    if(self.userDetails.alpha == 0){
        if(firstIndexPath.row == 0){
            if(frame.origin.x > 130)
                [self setUserProfileState:NO];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView willDecelerate:(BOOL)decelerate{
    if(!self.isLoading){
        for (UICollectionViewCell *cell in [self.trunkCollectionView visibleCells]) {
            if(cell.tag > self.trunkArray.count-2){
                self.isLoading = YES;
                [self loadTrunkList];
            }
            
            if(cell.tag == 0){
                CGPoint convertedPoint=[self.trunkCollectionView convertPoint:cell.frame.origin toView:self.trunkCollectionView.superview];
                
                if(convertedPoint.x>300){
                    [self.refreshActivityIndicator startAnimating];
                    self.refreshActivityIndicator.hidden = NO;
                    self.isLoading = YES;
                    [self loadTrunkList];
                }
            }
        }
    }
}

#pragma mark - UIButton Actions
- (IBAction)backButtonAction:(TTOnboardingButton *)sender {
    self.trunkCollectionView.hidden = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)followButtonAction:(TTOnboardingButton *)sender {
    if ([self.followStatus intValue] > 0) {
        // Unfollow
//        [sender setSelected:NO]; // change the button for immediate user feedback
        [sender setTitle:@"FOLLOW" forState:UIControlStateNormal];
        //        [sender setTitleColor:[TTColor tripTrunkButtonTextBlue] forState:UIControlStateNormal];
        [sender setBackgroundColor:[UIColor clearColor]];
        [SocialUtility unfollowUser:self.user block:^(BOOL succeeded, NSError *error) {
            if(error){
                NSLog(@"Error: %@", error);
                NSString * title = NSLocalizedString(@"Unfollow Failed", @"Unfollow Failed");
                NSString * message = NSLocalizedString(@"Please try again", @"Please try again");
                NSString * button = NSLocalizedString(@"Okay", @"Okay");
                
                [self alertUser:title withMessage:message withYes:@"" withNo:button];
                [sender setSelected:YES];
            }else{
                NSLog(@"User unfollowed");
                //WE NEED TO UPDATE THE CACHE!!!
                NSMutableArray *following = [[TTCache sharedCache] following];
                [following removeObject:self.user];
                [[TTCache sharedCache] setFollowing:following];
            }
        }];
    }else{
        // Follow
//        [sender setSelected:YES];
        [sender setTitle:@"FOLLOWING" forState:UIControlStateNormal];
        //        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [sender setBackgroundColor:[TTColor tripTrunkButtonTextBlue]];
        [SocialUtility followUserInBackground:self.user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                //                [self.currentUserFriends removeObject:user.objectId];
                NSLog(@"Follow failed");
                
                NSLog(@"Error: %@", error);
                NSString * title = NSLocalizedString(@"Follow Failed", @"Follow Failed");
                NSString * message = NSLocalizedString(@"Please try again", @"Please try again");
                NSString * button = NSLocalizedString(@"Okay", @"Okay");
                
                [self alertUser:title withMessage:message withYes:@"" withNo:button];
                [sender setSelected:YES];
            }else{
                NSLog(@"User followed");
                //WE NEED TO UPDATE THE CACHE!!!
                NSMutableArray *following = [[TTCache sharedCache] following];
                [following addObject:self.user];
                [[TTCache sharedCache] setFollowing:following];
            }
        }];
    }
}

- (IBAction)profileImageTapAction:(UITapGestureRecognizer*)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Trunk" bundle:nil];
    TTPhotoViewController *photoViewController = (TTPhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTPhotoViewController"];

    Photo *image = [[Photo alloc] init];
    image.image = self.userProfilePictureMain.image;
    NSArray *array = @[image];
    photoViewController.photos = array;
    photoViewController.index = 0;
    photoViewController.photo = image;
    photoViewController.image = self.userProfilePictureMain.image;
    
    [self.navigationController pushViewController:photoViewController animated:YES];
}

@end
