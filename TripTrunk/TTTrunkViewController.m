//
//  TTTrunkViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 9/5/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTTrunkViewController.h"
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import <QuartzCore/QuartzCore.h>
#import "TTTrunkViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "SocialUtility.h"
#import "TTProfileViewController.h"
#import "TTRoundedImage.h"
#import "TTPhotoViewController.h"

@interface TTTrunkViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) IBOutlet UICollectionView *mainCollectionView;
//@property (strong, nonatomic) UICollectionView *mainCollectionView;
@property (strong, nonatomic) UICollectionView *membersCollectionView;
@property (strong, nonatomic) GMSMapView *googleMapView;
@property (strong, nonatomic) NSMutableArray *imageSet;
@property (strong, nonatomic) NSArray *trunkMembers;
@property (strong, nonatomic) UIImage *photo;
@end

@implementation TTTrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self.mainCollectionView registerClass:[TTTrunkViewCell class] forCellWithReuseIdentifier:@"cell"];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionFootersPinToVisibleBounds = YES;
    layout.sectionHeadersPinToVisibleBounds = YES;
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    self.mainCollectionView.collectionViewLayout = layout;
    self.mainCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
    
    //Get imageURLs of all images in the trunk
    self.imageSet = [[NSMutableArray alloc] init];
    
    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
    [photoQuery whereKey:@"trip" equalTo:self.excursion.trunk];
    [photoQuery whereKey:@"user" equalTo:self.excursion.creator];
    [photoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(!error){
            //Loop though retrieved objects and extract photo's URL
            for(Photo* object in objects){
                [self.imageSet addObject:object.imageUrl];
            }
            [self.mainCollectionView reloadData];
        }else{
            //There's an error. Handle this and add the Google tracking
            NSLog(@"error getting image");
            NSLog(@"%@",self.excursion);
            NSLog(@"%@",self.excursion.trunk);
        }
    }];
    

    self.trunkMembers = [[NSArray alloc] init];
    [SocialUtility trunkMembers:self.excursion.trunk block:^(NSArray *users, NSError *error) {
        self.trunkMembers = users;
        [self.membersCollectionView reloadData];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    int numOfItems = 0;
    
    if(collectionView == self.mainCollectionView){
        if(section == 0){
            numOfItems = 1;
        }else{
            numOfItems = (int)self.imageSet.count;
        }
    }else if(collectionView == self.membersCollectionView){
        numOfItems = (int)self.trunkMembers.count;
    }
    
    return numOfItems;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize size = CGSizeMake(0, 0);
    
    if(collectionView == self.mainCollectionView){
        if(indexPath.section == 0)
            size = CGSizeMake(375, 200);
        
        if(indexPath.section == 1)
            size = CGSizeMake(124, 124);
    }
    
    if(collectionView == self.membersCollectionView){
        size = CGSizeMake(60, 60);
    }
    
    return size;
}

- (TTTrunkViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    TTTrunkViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    if(collectionView == self.mainCollectionView){
        
        if(indexPath.section == 0){
            double mapOffset = .4; //<------determine if the map should offset because a point is below the photos
            
            //Map View of trunk location
            self.googleMapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 0, 375, 200)];
            PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:self.excursion.trunk.lat longitude:self.excursion.trunk.longitude];
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
            [collectionView addSubview:self.googleMapView];
            
            [self addPointToMapWithGeoPoint:geoPoint];
            [self addLabelToMapWithGeoPoint:geoPoint AndText:self.excursion.trunk.city];
            
            //Members Collection View
            UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
            CGRect frame = CGRectMake(0, 28, 375, 60);
            layout.minimumInteritemSpacing = 3;
            layout.minimumLineSpacing = 3;
            layout.itemSize = CGSizeMake(60, 60);
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            self.membersCollectionView=[[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
            self.membersCollectionView.backgroundColor = [UIColor clearColor];
            self.membersCollectionView.showsVerticalScrollIndicator = NO;
            self.membersCollectionView.showsHorizontalScrollIndicator = NO;
            self.membersCollectionView.contentInset = UIEdgeInsetsMake(0, 6, 0, 74); //<--- only if there are more than 4 members
            [self.membersCollectionView setDataSource:self];
            [self.membersCollectionView setDelegate:self];
            
            [self.membersCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
            [collectionView addSubview:self.membersCollectionView];
            
            //Members button
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button addTarget:self action:@selector(viewTrunkMembers) forControlEvents:UIControlEventTouchUpInside];
            [button setImage:[UIImage imageNamed:@"tt_members_button"] forState:UIControlStateNormal];
            button.frame = CGRectMake(315, 35, 45, 45); //<--- Determine placement depending on number of members
            button.clipsToBounds = YES;
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 5;
            button.imageView.contentMode = UIViewContentModeScaleAspectFill;
            [collectionView addSubview:button];
        }else{
            
            CGRect frame = CGRectMake(0, 0, 124, 124);
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            [imageView setImageWithURL:[NSURL URLWithString:self.imageSet[indexPath.row]]];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            [cell addSubview:imageView];
            cell.videoIcon.hidden = YES;
        }
        
    }else if(collectionView == self.membersCollectionView){
        PFUser *member = self.trunkMembers[indexPath.row];
        CGRect frame = CGRectMake(0, 0, 60, 60);
        TTRoundedImage *imageView = [[TTRoundedImage alloc] initWithFrame:frame];
        if(member[@"profilePicUrl"]){
            [imageView setImageWithURL:[NSURL URLWithString:member[@"profilePicUrl"]]];
        }else{
            imageView.image = [UIImage imageNamed:@"tt_square_placeholder"];
            CGRect labelFrame = CGRectMake(10, 10, 40, 40);
            UILabel *initialsLabel = [[UILabel alloc] initWithFrame:labelFrame];
            initialsLabel.text = [NSString stringWithFormat:@"%@%@",[member[@"firstName"] substringToIndex:1],[member[@"lastName"] substringToIndex:1]];
            initialsLabel.font = [TTFont tripTrunkFont28];
            initialsLabel.numberOfLines = 1;
            initialsLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
            initialsLabel.adjustsFontSizeToFitWidth = YES;
//            initialsLabel.adjustsLetterSpacingToFitWidth = YES;
            initialsLabel.minimumScaleFactor = 10.0f/12.0f;
            initialsLabel.clipsToBounds = YES;
            initialsLabel.backgroundColor = [UIColor clearColor];
            initialsLabel.textColor = [UIColor darkGrayColor];
            initialsLabel.textAlignment = NSTextAlignmentCenter;
            [imageView addSubview:initialsLabel];
        }
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [cell addSubview:imageView];
    }
    
    
    
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if(collectionView == self.mainCollectionView && indexPath.section == 1){
        TTTrunkViewCell *cell = (TTTrunkViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
        for (UIImageView *subview in cell.subviews){
            if([subview isKindOfClass:[UIImageView class]]){
                self.photo = subview.image;
                break;
            }
        }
        [self performSegueWithIdentifier:@"pushToPhoto" sender:self];
    }else{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
        TTProfileViewController *profileViewController = (TTProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTProfileViewController"];
        profileViewController.user = self.trunkMembers[indexPath.row];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    
    if(collectionView == self.mainCollectionView)
        return 2;
    
    return 1;
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{

    UICollectionReusableView *theView;
        if(collectionView == self.mainCollectionView){
        
        if(kind == UICollectionElementKindSectionHeader){
            theView = [self.mainCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        } else {
            theView = [self.mainCollectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        }
    }
    
    return theView;


}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    
    if(collectionView == self.mainCollectionView && section == 1)
        return CGSizeMake(self.view.frame.size.width, 35);
    
    return CGSizeMake(0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    return CGSizeMake(0,0);
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
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(point.x-10,point.y+3,50,21)];
    label.font = [TTFont tripTrunkFont8];
    label.textColor = [TTColor tripTrunkDarkGray];
    label.text = text;
    
    [self.googleMapView addSubview:label];
}


#pragma mark - UIButtons
-(void)viewTrunkMembers{
    
}

-(void)buttonOneAction{
    
}

-(void)buttonTwoAction{
    
}

-(void)buttonThreeAction{
    
}

- (IBAction)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)addToTrunkButtonAction:(id)sender {
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TTPhotoViewController *photoViewController = segue.destinationViewController;
    photoViewController.photo = self.photo;
}

@end
