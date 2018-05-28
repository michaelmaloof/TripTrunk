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
#import "SocialUtility.h"
#import "TTCache.h"

@import GoogleMaps;

@interface TTHomeMapViewController ()
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) NSArray *trunks;
@property (strong, nonatomic) NSMutableArray *filteredArray;
@property (strong, nonatomic) NSMutableDictionary *imageSet;
@property (strong, nonatomic) NSMutableArray *sortedArray;
@property (strong, nonatomic) NSMutableArray *following;
@property (strong, nonatomic) NSMutableArray *objid;
@property (strong, nonatomic) NSMutableArray *userTrips;
@property BOOL reachedBottom;
@property BOOL isLoading;
@end

@implementation TTHomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.user = [PFUser currentUser];
    
    //init the arrays
    self.filteredArray = [[NSMutableArray alloc] init];
    self.sortedArray = [[NSMutableArray alloc] init];
    self.imageSet = [[NSMutableDictionary alloc] init];
    self.objid = [[NSMutableArray alloc] init];
    self.userTrips = [[NSMutableArray alloc] init];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                       action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    self.refreshControl.tintColor = [TTColor tripTrunkBlue];
    [self.refreshControl endRefreshing];
    
    //get following list
    [self loadFollowingWithBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded){
            [[TTCache sharedCache] setFollowing:self.following];
            //setup the view controller
            [self initMap];
      //    [self initExcursion]; //not sure how we're doing this yet so may not do this at all
            [self initTrips:NO refresh:self.refreshControl]; //not sure how we're doing this yet so may not do this at all
        }
    }];
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
            
//            [self initTrips];
            
        }else{
            //FIXME: Add google error event
            NSLog(@"Error retrieving Excursions");
        }
     
    }];
}



-(void)initTrips:(BOOL)isRefresh refresh:(UIRefreshControl*)refreshControl{
  
    NSMutableArray *followingObjectIds = [[NSMutableArray alloc] init];
    for(PFUser *user in self.following){
        [followingObjectIds addObject:user.objectId];
    }
    [followingObjectIds addObject:[PFUser currentUser].objectId];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *tomorrow = [cal dateByAddingUnit:NSCalendarUnitDay
                                       value:2
                                      toDate:[NSDate date]
                                     options:0];
    
    NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
    [dateformate setDateFormat:@"YYYY-MM-dd"];
    NSString *dateString=[dateformate stringFromDate:tomorrow];
    //@"createdDate" : photo.createdAt ? photo.createdAt : dateString,
    NSDictionary *params = @{
                             @"objectIds" : followingObjectIds,
                             @"activityObjectIds" : self.objid,
                             @"createdDate" : dateString,
                             @"isRefresh" : [NSString stringWithFormat:@"%@",isRefresh ? @"YES" : @"NO"],
                             @"userTrips" : self.userTrips
                             };
    
    [PFCloud callFunctionInBackground:@"queryForNewsFeed" withParameters:params block:^(NSArray *response, NSError *error) {
        if (!error) {
            if (!isRefresh && response.count == 0)
                self.reachedBottom = YES;
            [[TTUtility sharedInstance] internetConnectionFound];
            NSMutableArray *trips = [[NSMutableArray alloc] init];
            for (PFObject *activity in response[0]){
                Trip *atrip = activity[@"trip"];
                PFUser *auser = activity[@"fromUser"];
                NSString *mashup = [NSString stringWithFormat:@"%@.%@",atrip.objectId,auser.objectId];
                if(![self.userTrips containsObject:mashup])
                    [self.userTrips addObject:mashup];
                
                [trips addObject:atrip];
            }
            
                NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"start" ascending:NO];
                NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
                self.sortedArray = [NSMutableArray arrayWithArray:[trips sortedArrayUsingDescriptors:descriptors]];
            
            Trip *trunk = self.sortedArray[0];
            PFGeoPoint* geoPoint = [PFGeoPoint geoPointWithLatitude:trunk.lat longitude:trunk.longitude];
            [self clearMap];
            [self updateMap:geoPoint WithTrunk:trunk];
    
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
        }

        self.isLoading = NO;
        [refreshControl endRefreshing];
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
                    NSLog(@"deleted: %@",trunk);
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

-(void)loadFollowingWithBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error){
            self.following = [[NSMutableArray alloc] init];
            self.following  = [NSMutableArray arrayWithArray:users];
            completionBlock(YES,nil);
        }else{
            completionBlock(NO,error);
        }
        
    }];
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
    NSArray *photos = self.imageSet[trunk.objectId];
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
            [self clearMap];
            [self updateMap:geoPoint WithTrunk:trunk];
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
    
//    [self addPointToMapWithGeoPoint:geoPoint];
//    [self addLabelToMapWithGeoPoint:geoPoint AndText:self.user[@"hometown"]];
    
//    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
//    GMSMarker *marker = [GMSMarker markerWithPosition:position];
//    marker.title = @"Los Angeles";
//    marker.map = self.googleMapView;
}

-(void)updateMap:(PFGeoPoint*)geoPoint WithTrunk:(Trip*)trip{
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
    
//    GMSGroundOverlay *overlay = [self mapOverlayWithLatitude:geoPoint.latitude AndLongitude:geoPoint.longitude];
//    overlay.map = self.googleMapView;
    
    [self addPointToMapWithGeoPoint:geoPoint];
    [self addLabelToMapWithGeoPoint:geoPoint AndText:trip.city];
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

-(void)clearMap{
    for(UIView *subview in self.googleMapView.subviews){
        if([subview isKindOfClass:[UIImageView class]] || [subview isKindOfClass:[UILabel class]])
            [subview removeFromSuperview];
    }
    
    CALayer* layer = [self.googleMapView.layer valueForKey:@"curvesLayer"];
    [layer removeFromSuperlayer];
    [self.googleMapView.layer setValue:nil forKey:@"curvesLayer"];
    
}

-(void)clearFlag{
    for(UIView *subview in self.googleMapView.subviews){
        if(subview.tag == 1000)
            [subview removeFromSuperview];
    }
    
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
