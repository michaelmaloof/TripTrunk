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

@interface TTProfileViewController ()
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
@property (strong, nonatomic) IBOutlet UICollectionView *trunkCollectionView;
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;


@end

@implementation TTProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userProfilePictureSmall.hidden = YES;
    self.userFirstLastNameSmall.hidden = YES;
    self.usernameSmall.hidden = YES;
    
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
//    [self.trunkCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
//                                atScrollPosition:UICollectionViewScrollPositionTop
//                                        animated:YES];
    [self initMap];
    if(!self.user[@"profilePicUrl"])
        [self handleMissingProfilePicture];
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
    initialsLabel.adjustsLetterSpacingToFitWidth = YES;
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
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(0, 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
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

#pragma mark - UIButton Actions
- (IBAction)backButtonAction:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)followButtonAction:(TTOnboardingButton *)sender {
    NSLog(@"button 2 pressed");
}

@end
