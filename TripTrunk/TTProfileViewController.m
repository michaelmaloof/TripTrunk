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

@interface TTProfileViewController () <UICollectionViewDelegate,UICollectionViewDataSource>
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
@property (strong, nonatomic) NSMutableArray *trunkArray;
@property (strong, nonatomic) NSMutableArray *imageSet;

//Is this stuff needed? It's carried over from the old Trunk VC
@property NSMutableArray *parseLocations;
@property NSMutableArray *meParseLocations;
@property NSMutableArray *friends;
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

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.userProfilePictureSmall.hidden = YES;
//    self.userFirstLastNameSmall.hidden = YES;
//    self.usernameSmall.hidden = YES;
    
    [self.userProfilePictureSmall setImageWithURL:[NSURL URLWithString:self.user[@"profilePicUrl"]]];
    self.userFirstLastNameSmall.text = self.user[@"name"];
    self.usernameSmall.text = [NSString stringWithFormat:@"@%@",self.user.username];
    [self.userProfilePictureMain setImageWithURL:[NSURL URLWithString:self.user[@"profilePicUrl"]]];
    self.userFirstLastNameMain.text = self.user[@"name"];
    self.usernameMain.text = [NSString stringWithFormat:@"@%@",self.user.username];
    self.userBio.text = self.user[@"bio"];
    self.followersCount.text = @"0";
    self.trunksCount.text = @"0";
    self.followingCount.text = @"0";
    
    self.trunkArray = [[NSMutableArray alloc] init];
    self.imageSet = [[NSMutableArray alloc] init];
    
    [self initMap];
    if(!self.user[@"profilePicUrl"])
        [self handleMissingProfilePicture];
    
    [self loadTrunkList];
    
}

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
    
    //Load images from Array of image URLs
    NSArray* photos = self.imageSet[indexPath.row];
    NSString *photoUrl;
    if(photos.count>0){
        photoUrl = photos[0];
        [cell.spotlightTrunkImage setImageWithURL:[NSURL URLWithString:photoUrl]];
        
        //If there are 4 photos then load all of them into the cell, otherwise, only load 1 photo and enlarge the imageView
        if(photos.count>3){
            photoUrl = photos[1];
            [cell.secondaryTrunkImage setImageWithURL:[NSURL URLWithString:photoUrl]];
            
            photoUrl = photos[2];
            [cell.tertiaryTrunkImage setImageWithURL:[NSURL URLWithString:photoUrl]];
            
            
            photoUrl = photos[3];
            [cell.quaternaryTrunkImage setImageWithURL:[NSURL URLWithString:photoUrl]];
        }else{
            //only 1 photo is being used so enlarge the imageView
            cell.lowerInfoConstraint.constant = 248;
            cell.spotlightImageHeightConstraint.constant = 350;
        }
        
    }
    
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
    double mapOffset = -2.0; //<------determine if the map should offset because a point is below the photos
    
    //Map View of trunk location
//    self.googleMapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 0, 375, 200)];
    PFGeoPoint *geoPoint = self.user[@"hometownGeoPoint"];
    if(!geoPoint)
        geoPoint = [PFGeoPoint geoPointWithLatitude:32.715736 longitude:-117.161087];//<----- this is temporary. Delete this when hometownGeoPoint is added to everyone's database row
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
    [self addLabelToMapWithGeoPoint:geoPoint AndText:self.user[@"hometown"]];
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
    int limit = 200; //<-----????????
    int skip = 0; //<--------????????
    NSMutableArray *friendsObjectIds = [[NSMutableArray alloc] init];
    [friendsObjectIds addObject:[PFUser currentUser].objectId];
    NSDictionary *params = @{
                             @"objectIds" : friendsObjectIds,
                             @"limit" : [NSString stringWithFormat:@"%d",limit],
                             @"skip" : [NSString stringWithFormat:@"%d",skip]
                             };
    [PFCloud callFunctionInBackground:@"queryForUniqueTrunks" withParameters:params block:^(NSArray *response, NSError *error) {

        if(error){
            self.wasError = YES;
            NSLog(@"Error: %@",error);
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadTrunkList"];
        }else{
            [[TTUtility sharedInstance] internetConnectionFound];
            for(id activity in response){
                [self.trunkArray addObject:activity[@"trip"]];
            }
            [self initSpotlightImagesWithBlock:^(BOOL succeeded, NSError *error) {
                [self.trunkCollectionView reloadData];
            }];
        }
    
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
        //FIXME: This needs to move to Utility <------------------------------------
        PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
        [photoQuery whereKey:@"trip" equalTo:trunk];
        [photoQuery whereKey:@"user" equalTo:self.user];
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
                    [self.imageSet addObject:images];
                }else{
                    //no images found, flag for removal from sorted array
                    [deleteObjects addObject:trunk];
                }
                
                //increment the count for the last record check
                count++;
                
                //check if this is the last record
                if(count == objectCount){
                    //remove the trunks that have no images in them
                    [self.trunkArray removeObjectsInArray:deleteObjects];
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

#pragma mark - UIButton Actions
- (IBAction)backButtonAction:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)followButtonAction:(TTOnboardingButton *)sender {
    NSLog(@"button 2 pressed");
}

- (IBAction)profileImageTapAction:(UITapGestureRecognizer*)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Trunk" bundle:nil];
    TTPhotoViewController *photoViewController = (TTPhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTPhotoViewController"];
    photoViewController.photo = self.userProfilePictureMain.image;
    [self.navigationController pushViewController:photoViewController animated:YES];
}

@end
