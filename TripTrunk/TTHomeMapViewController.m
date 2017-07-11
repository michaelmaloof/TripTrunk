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

@import GoogleMaps;

@interface TTHomeMapViewController ()
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) NSArray *trunks;
@property (strong, nonatomic) NSMutableArray *filteredArray;
@property (strong, nonatomic) NSMutableArray *imageSet;
@property (strong, nonatomic) NSArray *sortedArray;
@end

@implementation TTHomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.user = [PFUser currentUser];
    // Do any additional setup after loading the view.
    
    self.filteredArray = [[NSMutableArray alloc] init];
    self.sortedArray = [[NSMutableArray alloc] init];
    
    [self initMap];
    [self initExcursion];
    
}

#pragma mark - UICollectionView
-(void)initExcursion{
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
            
            [self initSpotlightImages];
            
        }else{
            //FIXME: Add google error event
            NSLog(@"Error retrieving Excursions");
        }
     
    }];
}

-(void)initSpotlightImages{
//    for(NSArray *array in self.filteredArray){
//        for(id excursion in array){
//            Trip *trunk = excursion[@"trunk"];
//            PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
//            [photoQuery whereKey:@"trip" equalTo:trunk];
//            [photoQuery whereKey:@"user" equalTo:self.user];
//            [photoQuery setLimit:4];
//            [photoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//                if(!error){
//                    NSLog(@"");
//                }
//            }];
//        }
//    }
    
            PFQuery *tripQuery = [PFQuery queryWithClassName:@"Trip"];
            [tripQuery whereKey:@"creator" equalTo:self.user];
            [tripQuery orderByDescending:@"start"];
            [tripQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if(!error){
                    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
                    NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
                    self.sortedArray = [objects sortedArrayUsingDescriptors:descriptors];
                    [self.collectionView reloadData];
                }
            }];
}



#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.sortedArray.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (TTHomeMapCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    __block TTHomeMapCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
//    NSArray *array = self.filteredArray[indexPath.row];
//
//    for(id excursion in array){
//        Trip *trunk = excursion[@"trunk"];
//        cell.trunkTitle.text = trunk.name;
//        cell.trunkDates.text = [NSString stringWithFormat:@"%@ - %@",[self formattedDate:trunk.startDate],[self formattedDate:trunk.endDate]];
//        cell.trunkLocation.text = [NSString stringWithFormat:@"%@, %@, %@",trunk.city,trunk.state,trunk.country];
//        cell.trunkMemberInfo.text = @"Some info here";
//        
//        PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
//        [photoQuery whereKey:@"trip" equalTo:trunk];
//        [photoQuery whereKey:@"user" equalTo:self.user];
//        [photoQuery setLimit:4];
//        [photoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//            if(!error){
//                Photo *photo;
//                if(objects.count>0){
//                    photo = objects[0];
//                    [cell.spotlightTrunkImage setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
//                
//                    if(objects.count>3){
//                        photo = objects[1];
//                        [cell.secondaryTrunkImage setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
//                        
//                        photo = objects[2];
//                        [cell.tertiaryTrunkImage setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
//                        
//
//                        photo = objects[3];
//                        [cell.quaternaryTrunkImage setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
//                    }else{
//                        
////                        CGFloat x = cell.spotlightTrunkImage.frame.origin.x;
////                        CGFloat y = cell.spotlightTrunkImage.frame.origin.y;
////                        CGFloat width = cell.spotlightTrunkImage.frame.size.width;
////                        cell.spotlightTrunkImage.frame = CGRectMake(x, y, width, 350);
//                    }
//                    
//                }
//            }
//        }];
//
//    }
    
    Trip *trunk = self.sortedArray[indexPath.row];
    cell.trunkTitle.text = trunk.name;
    cell.trunkDates.text = [NSString stringWithFormat:@"%@ - %@",[self formattedDate:trunk.startDate],[self formattedDate:trunk.endDate]];
    cell.trunkLocation.text = [NSString stringWithFormat:@"%@, %@, %@",trunk.city,trunk.state,trunk.country];
    cell.trunkMemberInfo.text = @"Some info here";
    
            PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
            [photoQuery whereKey:@"trip" equalTo:trunk];
            [photoQuery whereKey:@"user" equalTo:self.user];
            [photoQuery setLimit:4];
            [photoQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                if(!error){
                    Photo *photo;
                    if(objects.count>0){
                        photo = objects[0];
                        [cell.spotlightTrunkImage setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
    
                        if(objects.count>3){
                            photo = objects[1];
                            [cell.secondaryTrunkImage setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
    
                            photo = objects[2];
                            [cell.tertiaryTrunkImage setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
    
    
                            photo = objects[3];
                            [cell.quaternaryTrunkImage setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
                        }else{
                            
                            cell.lowerInfoConstraint.constant = 248;
                            cell.spotlightImageHeightConstraint.constant = 350;
                        }
                        
                    }
                }
            }];
    
    return cell;
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
            NSLog(@"Updating map!");
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
    double mapOffset = 1.725;
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
    double mapOffset = 1.725;
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
@end
