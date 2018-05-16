//
//  TTHomeMapViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 6/14/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTHomeMapViewController.h"
#import "TTHomeMapCollectionViewCell.h"
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "Trip.h"
#import "UIImageView+AFNetworking.h"
#import "TTTrunkViewController.h"
#import "TTOnboardingViewController.h"
#import "TTCreateTrunkViewController.h"
#import "TTActivityNotificationsViewController.h"

@import GoogleMaps;

@interface TTHomeMapViewController ()
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) NSArray *trunks;
@property (strong, nonatomic) NSMutableArray *filteredArray;
@property (strong, nonatomic) NSMutableArray *imageSet;
@property (strong, nonatomic) NSMutableArray *sortedArray;
@end

@implementation TTHomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.user = [PFUser currentUser];
    
    //init the arrays
    self.filteredArray = [[NSMutableArray alloc] init];
    self.sortedArray = [[NSMutableArray alloc] init];
    self.imageSet = [[NSMutableArray alloc] init];
    
    //setup the view controller
    [self initMap];
//    [self initExcursion]; //not sure how we're doing this yet so may not do this at all
    [self initTrips]; //not sure how we're doing this yet so may not do this at all
}

#pragma mark - UICollectionView
-(void)initExcursion{
    
    //Load all the Excursions from the current user and sort by descending based on start date
    PFQuery *query = [PFQuery queryWithClassName:@"Excursion"];
    [query whereKey:@"creator" equalTo:self.user];
    [query includeKey:@"trunk"];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if(!error){
    
        NSSet *data = [NSSet setWithArray:[objects valueForKey:@"trip"]];
        NSArray *dataArray = [data allObjects];
        
        for(int i = 0; i<data.count; i++){
            NSMutableArray *filter = [[NSMutableArray alloc] init];
            for(id object in objects){
                if([object[@"trip"] isEqualToString:dataArray[i]]){
                    [filter addObject:object];
                }
            }
            
            [self.filteredArray addObject:filter];
        }
            
            [self initTrips];
            
        }else{
            //FIXME: Add google error event
            NSLog(@"Error retrieving Excursions");
        }
     
    }];
}



-(void)initTrips{
    
    //Load all the trips from the current user and sort by descending based on start date
    PFQuery *tripQuery = [PFQuery queryWithClassName:@"Trip"];
    [tripQuery whereKey:@"creator" equalTo:self.user];
    [tripQuery orderByDescending:@"start"];
    [tripQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(!error){
            //sort the array by start... Why am I doing this? Was "orderByDescending" not working?
            NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
            NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
            self.sortedArray = [NSMutableArray arrayWithArray:[objects sortedArrayUsingDescriptors:descriptors]];

            //Call image URL download and wait
            [self initSpotlightImagesWithBlock:^(BOOL succeeded, NSError *error) {
                
                //the block is done so reload the cells or there's an error
                if(succeeded){
                    [self.collectionView reloadData];
                }else{
                    //There's an error. Handle this and add the Google tracking
                    NSLog(@"initSpotlightImagesWithBlock failed");
                }
                
            }];
        }else{
            //There's an error. Handle this and add the Google tracking
            NSLog(@"error initializing trips");
        }
    }];
}

-(void)initSpotlightImagesWithBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    
    //Weed out Trips that don't have any images in them
    NSMutableArray *deleteObjects = [[NSMutableArray alloc] init];
    
    //Set up a last record check
    __block NSUInteger objectCount = self.sortedArray.count;
    __block NSUInteger count = 0;
    
    //Loop though the array and get each trunks 4 newest photo URLs
    for(Trip *trunk in self.sortedArray){
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
                    [self.sortedArray removeObjectsInArray:deleteObjects];
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

#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.sortedArray.count;
}

- (TTHomeMapCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    __block TTHomeMapCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    //Load the current trunk details and display them in the cell, obviously
    Trip *trunk = self.sortedArray[indexPath.row];
    cell.trunkTitle.text = trunk.name;
    cell.trunkDates.text = [NSString stringWithFormat:@"%@ - %@",[self formattedDate:trunk.startDate],[self formattedDate:trunk.endDate]];
    cell.trunkLocation.text = [NSString stringWithFormat:@"%@, %@, %@",trunk.city,trunk.state,trunk.country];
//FIXME: This obviously needs to be fixed
    cell.trunkMemberInfo.text = @"Some info here";
    
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Trunk" bundle:nil];
    TTTrunkViewController *trunkViewController = (TTTrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTTrunkViewController"];
    trunkViewController.trip = self.sortedArray[indexPath.row];
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGFloat cellWidth = 300;
    CGFloat cellPadding = 10;
    
    NSInteger page = (scrollView.contentOffset.x - cellWidth / 2) / (cellWidth + cellPadding) + 1;
    
    if (velocity.x > 0) page++;
    if (velocity.x < 0) page--;
    page = MAX(page,0);
    
    CGFloat newOffset = page * (cellWidth + cellPadding);
    targetContentOffset->x = newOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        CGPoint convertedPoint=[self.collectionView convertPoint:cell.frame.origin toView:self.collectionView.superview];
        int amountVisible = convertedPoint.x + cell.frame.size.height < cell.frame.size.width ? convertedPoint.x + cell.frame.size.width : cell.frame.size.width;
        amountVisible = screenWidth-convertedPoint.y < amountVisible ? screenWidth-convertedPoint.x : amountVisible;
        
        
        if(amountVisible>screenWidth/2.1){
            Trip *trunk = self.sortedArray[indexPath.row];
            PFGeoPoint* geoPoint = [PFGeoPoint geoPointWithLatitude:trunk.lat longitude:trunk.longitude];
            [self updateMap:geoPoint];
        }
    }
}

-(NSString*)formattedDate:(NSString*)date{
    //FIXME: This is only US date format, create a date formatter class to handle all locations
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *formattedDate = [dateFormatter dateFromString:date];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    
    return [dateFormatter stringFromDate:formattedDate];
}

-(UIImage *) getImageFromURL:(NSString *)fileURL {
    UIImage * result;
    
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]];
    result = [UIImage imageWithData:data];
    
    return result;
}

#pragma mark - Google Maps
-(void)initMap{
    double mapOffset = 1.425;
    PFGeoPoint *geoPoint = self.user[@"hometownGeoPoint"];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:geoPoint.latitude-mapOffset
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
    
    GMSGroundOverlay *overlay = [self mapOverlayWithLatitude:geoPoint.latitude AndLongitude:geoPoint.longitude];
    overlay.map = self.googleMapView;
    
//    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
//    GMSMarker *marker = [GMSMarker markerWithPosition:position];
//    marker.title = @"Los Angeles";
//    marker.map = self.googleMapView;
}

-(void)updateMap:(PFGeoPoint*)geoPoint{
    double mapOffset = 1.425;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:geoPoint.latitude-mapOffset
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
    
    GMSGroundOverlay *overlay = [self mapOverlayWithLatitude:geoPoint.latitude AndLongitude:geoPoint.longitude];
    overlay.map = self.googleMapView;
}

-(GMSGroundOverlay*)mapOverlayWithLatitude:(double)latitude AndLongitude:(double)longitude{
    double iconSize = 0.2;
    CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(latitude-iconSize/2,longitude-iconSize/2);
    CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(latitude+iconSize/2,longitude+iconSize/1.25);
    GMSCoordinateBounds *overlayBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:southWest
                                                                              coordinate:northEast];
    
    UIImage *icon = [UIImage imageNamed:@"bluedot"];
    GMSGroundOverlay *overlay =
    [GMSGroundOverlay groundOverlayWithBounds:overlayBounds icon:icon];
    overlay.bearing = 0;
    
    return overlay;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goToCreateTrunk:(UIButton *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Trunk" bundle:nil];
    TTCreateTrunkViewController *createTrunkViewController = (TTCreateTrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CreateTrunkViewController"];
    //    activityViewController.trip
    [self.navigationController pushViewController:createTrunkViewController animated:YES];
}

- (IBAction)goToActivity:(UIButton *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Activity" bundle:nil];
    TTActivityNotificationsViewController *activityViewController = (TTActivityNotificationsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTActivityNotificationsViewController"];
    //    activityViewController.trip
    [self.navigationController pushViewController:activityViewController animated:YES];
}
@end
