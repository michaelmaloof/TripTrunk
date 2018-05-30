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
#import "TTAddMembersViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "SocialUtility.h"
#import "TTProfileViewController.h"
#import "TTRoundedImage.h"
#import "TTPhotoViewController.h"
#import "Photo.h"
#import "TTAddPhotosViewController.h"
#import "TTAddMembersViewController.h"
#import "TTPopoverProfileViewController.h"
#import "TTPreviewPhotoViewController.h"
#import "TTOnboardingButton.h"
@interface TTTrunkViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,AddPhotosDelegate,PhotoDelegate,UIPopoverPresentationControllerDelegate,UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UICollectionView *mainCollectionView;
@property (strong, nonatomic) UICollectionView *membersCollectionView;
@property (strong, nonatomic) GMSMapView *googleMapView;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *trunkMembers;
@property (strong, nonatomic) Photo *photo;
@property NSInteger index;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTPreviewPhotoViewController *popoverPreviewPhotoViewController;
@property (strong, nonatomic) TTPopoverProfileViewController *popoverProfileViewController;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *addToTrunkButton;
@end

@implementation TTTrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Trip *trunk;
    PFUser *creator;
    if(self.excursion){
        trunk = self.excursion.trunk;
        creator = self.excursion.creator;
    }else{
        trunk = self.trip;
        creator = self.trip.creator;
    }

    [self.mainCollectionView registerClass:[TTTrunkViewCell class] forCellWithReuseIdentifier:@"cell"];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionFootersPinToVisibleBounds = YES;
    layout.sectionHeadersPinToVisibleBounds = YES;
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    self.mainCollectionView.collectionViewLayout = layout;
    self.mainCollectionView.contentInset = UIEdgeInsetsMake(0, 0, 100, 0);
    
    self.photos = [[NSMutableArray alloc] init];
    self.photo = [[Photo alloc] init];
    
    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
    [photoQuery whereKey:@"trip" equalTo:trunk];
//    [photoQuery whereKey:@"user" equalTo:creator];
    [photoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(!error){
            [self.photos addObjectsFromArray:objects];
            [self.mainCollectionView reloadData];
        }else{
            //There's an error. Handle this and add the Google tracking
            NSLog(@"error getting image");
        }
    }];
    

    self.trunkMembers = [[NSMutableArray alloc] init];
    [SocialUtility trunkMembers:trunk block:^(NSArray *users, NSError *error) {
        [self.trunkMembers addObjectsFromArray:users];
        [self.membersCollectionView reloadData];
    }];
    
    if(![self.trunkMembers containsObject:[PFUser currentUser]]){
        self.addToTrunkButton.enabled = NO;
        self.addToTrunkButton.hidden = YES;
    }
    
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
            numOfItems = (int)self.photos.count;
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
            size = CGSizeMake([UIScreen mainScreen].bounds.size.width, 200);
        
        if(indexPath.section == 1){
            if(indexPath.row == 0)
                size = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
            else size = CGSizeMake(([UIScreen mainScreen].bounds.size.width/3)-1, ([UIScreen mainScreen].bounds.size.width/3)-1);
        }
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
            self.googleMapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 200)];
            PFGeoPoint *geoPoint;
            if(self.excursion)
                geoPoint = [PFGeoPoint geoPointWithLatitude:self.excursion.trunk.lat longitude:self.excursion.trunk.longitude];
            else geoPoint = [PFGeoPoint geoPointWithLatitude:self.trip.lat longitude:self.trip.longitude];
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
            if(self.excursion)
                [self addLabelToMapWithGeoPoint:geoPoint AndText:self.excursion.trunk.city];
            else [self addLabelToMapWithGeoPoint:geoPoint AndText:self.trip.city];
            
            //Members Collection View
            UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
            CGRect frame = CGRectMake(0, 28, [UIScreen mainScreen].bounds.size.width, 60);
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
            
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                                       initWithTarget:self action:@selector(longPressToViewProfileAsPreview:)];
            longPress.minimumPressDuration = 0.5; //seconds
            longPress.delegate = self;
            [self.membersCollectionView addGestureRecognizer:longPress];
            
            //Members button
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button addTarget:self action:@selector(viewTrunkMembers) forControlEvents:UIControlEventTouchUpInside];
            [button setImage:[UIImage imageNamed:@"tt_members_button"] forState:UIControlStateNormal];
            button.frame = CGRectMake([UIScreen mainScreen].bounds.size.width-60, 35, 45, 45); //<--- Determine placement depending on number of members
            button.clipsToBounds = YES;
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 5;
            button.imageView.contentMode = UIViewContentModeScaleAspectFill;
            if([self.trunkMembers containsObject:[PFUser currentUser]])
                [collectionView addSubview:button];
        }else{
            CGRect frame;
            Photo *photo = self.photos[indexPath.row];
            if(indexPath.row == 0)
               frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
            else frame = CGRectMake(0, 0, ([UIScreen mainScreen].bounds.size.width/3)-1, ([UIScreen mainScreen].bounds.size.width/3)-1);
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
            [imageView setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            cell.tag = indexPath.row;
            if(!cell.tag)
                cell.tag = -1;
            [cell addSubview:imageView];
            
            if(photo.video){
                CGRect videoFrame = CGRectMake(cell.frame.size.width-26, 8, 16, 11);
                UIImageView *videoImageView = [[UIImageView alloc] initWithFrame:videoFrame];
                videoImageView.image = [UIImage imageNamed:@"video_icon"];
                [cell addSubview:videoImageView];
            }
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
        cell.tag = indexPath.row;
        if(!cell.tag)
            cell.tag = -1;
        [cell addSubview:imageView];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if(collectionView == self.mainCollectionView && indexPath.section == 1){
        TTTrunkViewCell *cell = (TTTrunkViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
                self.photo = cell.tag==-1 ? self.photos[0] : self.photos[cell.tag];
                self.photo.image = cell.imageView.image;
                self.index = cell.tag==-1 ? 0 : cell.tag;
        [self performSegueWithIdentifier:@"pushToPhoto" sender:self];
    }else{
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
        TTProfileViewController *profileViewController = (TTProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTProfileViewController"];
        profileViewController.user = self.trunkMembers[indexPath.row];
        profileViewController.delegate = self;
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
            CGRect labelFrame = CGRectMake(8, 0, 340, 21);
            UILabel *trunkTitleLabel = [[UILabel alloc] initWithFrame:labelFrame];
            trunkTitleLabel.text = self.trip.name;
            trunkTitleLabel.font = [TTFont tripTrunkFont16];
            trunkTitleLabel.numberOfLines = 1;
            trunkTitleLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
            trunkTitleLabel.adjustsFontSizeToFitWidth = YES;
//            initialsLabel.adjustsLetterSpacingToFitWidth = YES;
            trunkTitleLabel.minimumScaleFactor = 10.0f/12.0f;
            trunkTitleLabel.clipsToBounds = YES;
            trunkTitleLabel.backgroundColor = [UIColor clearColor];
            trunkTitleLabel.textColor = [UIColor darkGrayColor];
            trunkTitleLabel.textAlignment = NSTextAlignmentLeft;
            
            CGRect label2Frame = CGRectMake(8, 16, 340, 21);
            UILabel *trunkDatesLabel = [[UILabel alloc] initWithFrame:label2Frame];
            trunkDatesLabel.text = [NSString stringWithFormat:@"%@ - %@",self.trip.startDate,self.trip.endDate];
            trunkDatesLabel.font = [TTFont tripTrunkFont10];
            trunkDatesLabel.numberOfLines = 1;
            trunkDatesLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
            trunkDatesLabel.adjustsFontSizeToFitWidth = YES;
            //            initialsLabel.adjustsLetterSpacingToFitWidth = YES;
            trunkDatesLabel.minimumScaleFactor = 10.0f/12.0f;
            trunkDatesLabel.clipsToBounds = YES;
            trunkDatesLabel.backgroundColor = [UIColor clearColor];
            trunkDatesLabel.textColor = [UIColor darkGrayColor];
            trunkDatesLabel.textAlignment = NSTextAlignmentLeft;
            
            [theView addSubview:trunkTitleLabel];
            [theView addSubview:trunkDatesLabel];
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
    [self performSegueWithIdentifier:@"pushToAddMembersToTrunk" sender:self];
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

- (IBAction)longPressToViewPhotoAsPreview:(UILongPressGestureRecognizer*)gesture {
    if(gesture.state == UIGestureRecognizerStateBegan){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Trunk" bundle:nil];
        self.popoverPreviewPhotoViewController = (TTPreviewPhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PreviewPhotoViewController"];
        CGPoint touchPoint = [gesture locationInView:self.view];
        UIView *touchedView = [[UIView alloc] init];
        for(TTTrunkViewCell* cell in [self.mainCollectionView visibleCells]){
            CGRect cellFrameInSuperview = [self.mainCollectionView convertRect:cell.frame toView:[self.mainCollectionView superview]];
            if(CGRectContainsPoint(cellFrameInSuperview, touchPoint)){
                touchedView.tag = cell.tag;
                break;
            }
        }
        if(touchedView.tag){
            self.popoverPreviewPhotoViewController.photo = touchedView.tag==-1 ? self.photos[0] : self.photos[touchedView.tag];
            self.popoverPreviewPhotoViewController.modalPresentationStyle = UIModalPresentationPopover;
            self.popoverPreviewPhotoViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            
            //force the popover to display like an iPad popover otherwise it will be full screen
            self.popover  = self.popoverPreviewPhotoViewController.popoverPresentationController;
            self.popover.delegate = self;
            self.popover.sourceView = self.view;
            self.popover.sourceRect = CGRectMake(27,140,320,410);
            self.popover.permittedArrowDirections = 0;
            
            self.popoverPreviewPhotoViewController.preferredContentSize = CGSizeMake(320,410);
            self.popoverPreviewPhotoViewController.popoverPresentationController.sourceView = self.view;
            self.popoverPreviewPhotoViewController.popoverPresentationController.sourceRect = CGRectMake(27,140,320,410);
            
            //HACK because modalTransitionStyle doesn't work on fade in
            CATransition* transition = [CATransition animation];
            transition.duration = 0.5;
            transition.type = kCATransitionFade;
            [self.view.window.layer addAnimation:transition forKey:kCATransition];
            
            [self presentViewController:self.popoverPreviewPhotoViewController animated:NO completion:nil];
        }
    }
    
    if(gesture.state == UIGestureRecognizerStateEnded){
        [self.popoverPreviewPhotoViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)longPressToViewProfileAsPreview:(UILongPressGestureRecognizer*)gesture {
    if(gesture.state == UIGestureRecognizerStateBegan){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
        self.popoverProfileViewController = (TTPopoverProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ProfilePopoverView"];
        CGPoint touchPoint = [gesture locationInView:self.view];
        UIView *touchedView = [[UIView alloc] init];
        for(TTAddMembersViewCell* cell in [self.membersCollectionView visibleCells]){
            CGRect cellFrameInSuperview = [self.membersCollectionView convertRect:cell.frame toView:[self.membersCollectionView superview]];
            if(CGRectContainsPoint(cellFrameInSuperview, touchPoint)){
                touchedView.tag = cell.tag;
                break;
            }
        }
        if(touchedView.tag){
            self.popoverProfileViewController.user = touchedView.tag==-1 ? self.trunkMembers[0] : self.trunkMembers[touchedView.tag];
            self.popoverProfileViewController.modalPresentationStyle = UIModalPresentationPopover;
            self.popoverProfileViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            
            //force the popover to display like an iPad popover otherwise it will be full screen
            self.popover  = self.popoverProfileViewController.popoverPresentationController;
            self.popover.delegate = self;
            self.popover.sourceView = self.view;
            self.popover.sourceRect = CGRectMake(27,140,320,380);
            self.popover.permittedArrowDirections = 0;
            
            self.popoverProfileViewController.preferredContentSize = CGSizeMake(320,380);
            self.popoverProfileViewController.popoverPresentationController.sourceView = self.view;
            self.popoverProfileViewController.popoverPresentationController.sourceRect = CGRectMake(27,140,320,380);
            
            //HACK because modalTransitionStyle doesn't work on fade in
            CATransition* transition = [CATransition animation];
            transition.duration = 0.5;
            transition.type = kCATransitionFade;
            [self.view.window.layer addAnimation:transition forKey:kCATransition];
            
            [self presentViewController:self.popoverProfileViewController animated:NO completion:nil];
        }
        
    }
    
    if(gesture.state == UIGestureRecognizerStateEnded){
        [self.popoverProfileViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIModalPopoverDelegate
- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController: (UIPresentationController * ) controller {
    return UIModalPresentationNone;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"pushToPhoto"]){
        TTPhotoViewController *photoViewController = segue.destinationViewController;
        photoViewController.photos = self.photos;
        photoViewController.index = (int)self.index;
        photoViewController.photo = self.photo;
        photoViewController.delegate = self;
    }
    
    if([segue.identifier isEqualToString:@"pushToAddPhotosToTrunk"]){
        TTAddPhotosViewController *addPhotos = segue.destinationViewController;
        addPhotos.trunkMembers = self.trunkMembers;
        addPhotos.delegate = self;
        if(self.excursion)
            addPhotos.trip = self.excursion.trunk;
        else addPhotos.trip = self.trip;
    }
    
    if([segue.identifier isEqualToString:@"pushToAddMembersToTrunk"]){
        TTAddMembersViewController *addMembers = segue.destinationViewController;
        addMembers.trip = self.trip;
    }
    
}

#pragma mark - PhotoDelegate
-(void)photoWasDeleted:(NSNumber *)likes photo:(Photo *)photo{
    [self.photos removeObject:photo];
    [self.mainCollectionView reloadData];
}

#pragma mark - AddPhotosDelegate
-(void)photoUploadCompleted:(NSArray*)photos{
    for(Photo *photo in [photos reverseObjectEnumerator]){
        [self.photos insertObject:photo atIndex:0];
    }
    [self.mainCollectionView reloadData];
}

@end
