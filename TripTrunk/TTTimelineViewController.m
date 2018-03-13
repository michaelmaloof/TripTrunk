//
//  TTTimelineViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 7/28/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#define BETWEEN(value, min, max) (value >= min && value < max)

#import "TTTimelineViewController.h"
#import "TTTimelinePhotoCellCollectionViewCell.h"
#import <GoogleMaps/GoogleMaps.h>
#import <MapKit/MapKit.h>
#import "UIImageView+AFNetworking.h"
#import "TTColor.h"
#import "TTFont.h"
#import "Excursion.h"
#import "math.h"
#import "TTTrunkViewController.h"
#import "TTActivityNotificationsViewController.h"
#import "TTCreateTrunkViewController.h"
#import "TTOnboardingViewController.h"
#import "SocialUtility.h"

@interface TTTimelineViewController () <UICollectionViewDelegate>

@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *filteredArray;
@property (strong, nonatomic) NSMutableArray *sortedArray;
@property (strong, nonatomic) NSMutableArray *excursionGroups;
@property (strong, nonatomic) NSMutableArray *cellWidths;
@property (strong, nonatomic) NSString *photoDate;
@property (strong, nonatomic) UIBezierPath *routePath;
@property NSInteger currentGroup;
@property (strong, nonatomic) NSArray *following;
@end

@implementation TTTimelineViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    self.filteredArray = [[NSMutableArray alloc] init];
    self.sortedArray = [[NSMutableArray alloc] init];
    self.excursionGroups = [[NSMutableArray alloc] init];
    self.cellWidths = [[NSMutableArray alloc] init];
    
    self.user = [PFUser currentUser];
    
    if(self.user)
        [self loadTimelineData];
    else [self sendUserToLogin];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [self clearMap];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *styleUrl = [mainBundle URLForResource:@"style" withExtension:@"json"];
    NSError *error;
    GMSMapStyle *style = [GMSMapStyle styleWithContentsOfFileURL:styleUrl error:&error];
    if (!style)
        NSLog(@"The style definition could not be loaded: %@", error);
    self.googleMapView.mapStyle = style;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadTimelineData{
    
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error){
            self.following = users;


            PFQuery *query = [PFQuery queryWithClassName:@"Trip"];
            [query whereKey:@"creator" containedIn:users];
            [query includeKey:@"PublicTripDetail"];
            [query orderByDescending:@"start"];
            [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {

                //sort objects and group them into excursions
                [self groupTripsIntoExcursions:objects block:^(BOOL succeeded, NSString *error) {
                        NSSet *data = [NSSet setWithArray:[self.sortedArray valueForKey:@"trip"]];
                        NSArray *dataArray = [data allObjects];

                            for(int i = 0; i<data.count; i++){
                                NSMutableArray *filter = [[NSMutableArray alloc] init];
                                for(id object in self.sortedArray){
                                    if([object[@"trip"] isEqualToString:dataArray[i]]){
                                        [filter addObject:object];
                                    }
                                }

                                [self.filteredArray addObject:filter];
                            }

                        [self explodeFilteredArray];
                        self.currentGroup = [self currentlySelectedGroup];
                        [self initMap:self.filteredArray[self.currentGroup]];
                        Excursion *excursion = self.sortedArray[self.currentGroup];
                        PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:excursion.trunk.lat longitude:excursion.trunk.longitude];
                        [self addFlagToMapWithGeoPoint:point];
                }];


            }];


        }else{
            //HANDLE THIS ERROR
        }

    }];

}

#pragma mark - Google Maps
-(void)initMap:(NSArray*)array{
    
    double mapOffset = 0; //<------determine if the map should offset because a point is below the photos

    NSMutableArray *geoPointsChronologicalArray = [[NSMutableArray alloc] init];
    NSMutableArray *geoPointsChronologicalLabelArray = [[NSMutableArray alloc] init];
    PFGeoPoint *homePoint;

    //add geopoints to an array in chronological order
    for(Excursion *excursion in array){
        homePoint = [PFGeoPoint geoPointWithLatitude:excursion.homeAtCreation.latitude longitude:excursion.homeAtCreation.longitude];
        PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:excursion.trunk.lat longitude:excursion.trunk.longitude];
        [geoPointsChronologicalArray addObject:point];
        [geoPointsChronologicalLabelArray addObject:excursion.trunk.city];
    }

    //add geopoints to an array with map left & right so we can determine camera position and zoom
    NSArray *geoPointsDirectionalArray = [self sortGeoPointsByLongitudeWithArray:array];

    //load furthest left and furthest right
    PFGeoPoint *mapLeftGeoPoint = homePoint;
    PFGeoPoint *mapRightGeoPoint = [geoPointsDirectionalArray lastObject];

    //determine middle point between extent of trip locations
    PFGeoPoint *midGeoPoint = [PFGeoPoint geoPointWithLatitude:(mapLeftGeoPoint.latitude+mapRightGeoPoint.latitude)/2 longitude:(mapLeftGeoPoint.longitude+mapRightGeoPoint.longitude)/2];

    float distance = ABS(mapLeftGeoPoint.longitude-mapRightGeoPoint.longitude);
    float mapZoom = -1.4847*log(distance) + 8.62645;

    //set camera position to the middle of the route
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:midGeoPoint.latitude-mapOffset
                                                            longitude:midGeoPoint.longitude
                                                                 zoom:mapZoom];
    self.googleMapView.camera = camera;

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *styleUrl = [mainBundle URLForResource:@"style" withExtension:@"json"];
    NSError *error;

    GMSMapStyle *style = [GMSMapStyle styleWithContentsOfFileURL:styleUrl error:&error];
    if (!style)
        NSLog(@"The style definition could not be loaded: %@", error);
    self.googleMapView.mapStyle = style;

    [self createBezierPathForMapWithArrayOfGeoPoints:geoPointsChronologicalArray homePoint:homePoint];

    int i=0; // <------ this is temporary until it's connected to the database
    [self addPointToMapWithGeoPoint:homePoint];
    [self addLabelToMapWithGeoPoint:homePoint AndText:@"Home"];
    for(PFGeoPoint *point in geoPointsChronologicalArray){
        [self addPointToMapWithGeoPoint:point];
        [self addLabelToMapWithGeoPoint:point AndText:geoPointsChronologicalLabelArray[i]];
        i++;
    }

    [self.collectionView reloadData];
}

- (void) drawRect:(CGRect)rect {
    [[UIColor blueColor] setStroke];
    [self.routePath stroke];
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

-(void)explodeFilteredArray{
    int count = 0;
    self.sortedArray = [[NSMutableArray alloc] init];
    for(NSArray *array in self.filteredArray){
        count = count+(int)array.count;
        [self.excursionGroups addObject:@(count)];
        for(Excursion *excursion in array){
            [self.sortedArray addObject:excursion];
        }
    }
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
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(point.x-10,point.y+3,50,21)];
    label.font = [TTFont tripTrunkFont8];
    label.textColor = [TTColor tripTrunkDarkGray];
    label.text = text;
    
    [self.googleMapView addSubview:label];
}

-(void)createBezierPathForMapWithArrayOfGeoPoints:(NSArray*)array homePoint:(PFGeoPoint*)homePoint{
        
    UIBezierPath *aPath = [UIBezierPath bezierPath];
    //move to first geo point
    [aPath moveToPoint:[self createMapPointWithGeoPoint:homePoint]];
    
    for(int i=0;i<array.count;i++){
        if(i==0){
           [aPath addQuadCurveToPoint:[self createMapPointWithGeoPoint:array[i]] controlPoint:[self createControlPointFromGeoPoint:homePoint To:array[i]]];
        }else{
            [aPath addQuadCurveToPoint:[self createMapPointWithGeoPoint:array[i]] controlPoint:[self createControlPointFromGeoPoint:array[i-1] To:array[i]]];
        }
    }
    
    //close out path to original geoPoint
    [aPath addQuadCurveToPoint:[self createMapPointWithGeoPoint:homePoint] controlPoint:[self createControlPointFromGeoPoint:[array lastObject] To:homePoint]];
    
    [aPath setLineWidth:3.0];
    self.routePath = aPath;
    [self.googleMapView setNeedsDisplay];
    
    CAShapeLayer * layer = [[CAShapeLayer alloc] init];
    layer.path = aPath.CGPath;
    layer.bounds = [[UIScreen mainScreen] bounds]; //CGPathGetBoundingBox(layer.path);
    layer.strokeColor = [TTColor tripTrunkBlueMapLine].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor; /*if you just want lines*/
    layer.lineWidth = 3;
    layer.position = CGPointMake(0,0);
    layer.anchorPoint = CGPointMake(0,0);
    [self.googleMapView.layer addSublayer:layer];
    [self.googleMapView.layer setValue:layer forKey:@"curvesLayer"];

}

-(CGPoint)createControlPointFromGeoPoint:(PFGeoPoint*)startPoint To:(PFGeoPoint*)endPoint{
    NSArray *array = @[startPoint,endPoint];
    CGPoint offset = [self calculateControlPointOffsetForPoints:array];
    CGPoint mapStartPoint = [self createMapPointWithGeoPoint:startPoint];
    CGPoint mapEndPoint = [self createMapPointWithGeoPoint:endPoint];
    CGPoint controlPoint = CGPointMake(((mapStartPoint.x+mapEndPoint.x)/2)+offset.x,((mapStartPoint.y+mapEndPoint.y)/2)+offset.y);
    
    return controlPoint;
}

-(CGPoint)calculateControlPointOffsetForPoints:(NSArray*)points{
    //Determine if the points are North/South or Easst/West from each other

    int x; int y; int xOffset; int yOffset;
    
    PFGeoPoint *startPoint = points[0];
    PFGeoPoint *endPoint= points[1];
    CGPoint mapStartPoint = [self createMapPointWithGeoPoint:startPoint];
    CGPoint mapEndPoint = [self createMapPointWithGeoPoint:endPoint];
    double distanceX = ABS(mapStartPoint.x-mapEndPoint.x);
    double distanceY = ABS(mapStartPoint.y-mapEndPoint.y);
    
    if(mapEndPoint.x < mapStartPoint.x){
        //endpoint is left of startpoint on the screen
        xOffset = -1;
    }else{
        //endpoint is right of startpoint on the screen
        xOffset = 1;
    }
    
    if(mapEndPoint.y < mapStartPoint.y){
        //endpoint is above startpoint on the screen
        yOffset = -1;
    }else{
        //endpoint is below startpoint on the screen
        yOffset = 1;
    }
    
//FIXME: I'm going to need to know the zoom of the map actually do this dynamically
//The divided by 6 is assuming LA to NY hardcoded <----------------------------------------
    if(distanceX > distanceY){
        //point is further away on X axis
        y = distanceX/6;
        x = 0;
    }else{
        //point is further away on Y axis
        y = 0;
        x = distanceY/6;
    }
    
    return CGPointMake(x*xOffset, y*yOffset);
}


#pragma mark - Trip Sorting
-(void)groupTripsIntoExcursions:(NSArray*)trips block:(void (^)(BOOL succeeded, NSString *error))completionBlock
{
    //seperate trips by user
    NSArray *sortedTrips = [trips valueForKeyPath:@"@distinctUnionOfObjects.user"];
    NSMutableArray *sortedArray = [[NSMutableArray alloc] init];
    for (NSString *t in sortedTrips) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user == %@",t];
        NSArray *currentUserTrips = [trips filteredArrayUsingPredicate:predicate];
        [sortedArray addObject:(Trip*)currentUserTrips];
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSMutableDictionary *groupedDict = [[NSMutableDictionary alloc] init];
    NSMutableArray *groupedTrips = [[NSMutableArray alloc] init];
    //group trips into excursions by user (hard part)
    for(NSArray *trips in sortedArray){
        if(trips.count>1){
            NSArray* reversedArray = [[trips reverseObjectEnumerator] allObjects];
            int i=0;
            NSString *sd;
            for(Trip *trip in trips){
                if(i==0)
                    sd = trip.startDate;
                
                if(i==trips.count-1){
                    if(groupedTrips.count>0){
                        [groupedDict setObject:groupedTrips forKey:sd];
                        groupedTrips = [[NSMutableArray alloc] init];
                    }else{
                        [groupedDict setObject:trip forKey:trip.startDate];
                    }
                    break;
                }
                
                Trip *trip2 = reversedArray[i+1];
                i++;
                [df setDateFormat:@"MM/dd/yyyy"];
                NSDate *startDate = [df dateFromString:trip2.startDate];
                NSDate *endDate = [df dateFromString:trip.endDate];
                NSTimeInterval secondsBetween = [startDate timeIntervalSinceDate:endDate];
                int numberOfDays = secondsBetween / 86400;
                if(numberOfDays < 2){
                    //group this with the previous
                    [groupedTrips addObject:trip];
                    [groupedTrips addObject:trip2];
                }else{
                    if(groupedTrips.count>0){
                        [groupedDict setObject:groupedTrips forKey:sd];
                        groupedTrips = [[NSMutableArray alloc] init];
                    }else{
                        [groupedDict setObject:trip forKey:trip.startDate];
                    }
                }
            }
            
        }else{
            for(Trip *trip in trips){
                [groupedDict setObject:trip forKey:trip.startDate];
            }
        }
    }
    
    
    //sort dictionary by date
    NSArray *Keys = [groupedDict allKeys];
    NSMutableArray *sortedValues = [NSMutableArray array];
    NSArray *sortedKeys = [Keys sortedArrayUsingFunction:dateSort context:nil];
    NSArray* reversedsortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
    //resort excursions in chronological order by first trips start date
    for (NSString *key in reversedsortedKeys)
        [sortedValues addObject: [groupedDict objectForKey: key]];
    
    
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:34.0522 longitude:-118.2437];
    for(id object in sortedValues){
        if([object isKindOfClass:[Trip class]]){
            Trip *trip = (Trip*)object;
            Excursion *ex = [[Excursion alloc] init];
            ex.creator = trip.creator;
            ex.trip = trip.objectId;
            ex.trunk = trip;
            ex.homeAtCreation = point; //<--FIXME: THIS IS HARDCODED AND MUST BE FIXED
            [self.sortedArray addObject:ex];
        }else{
            //it's an array of trips
            NSArray *array = (NSArray*)object;
            Trip *trip = (Trip*)array[0];
            NSString *tripId = trip.objectId;
            for(Trip *trip in array){
                Excursion *ex = [[Excursion alloc] init];
                ex.creator = trip.creator;
                ex.trip = tripId;
                ex.trunk = trip;
                ex.homeAtCreation = point; //<--FIXME: THIS IS HARDCODED AND MUST BE FIXED
                [self.sortedArray addObject:ex];
            }
        }
    }
    
    if (completionBlock)
        completionBlock(YES, nil);
    else completionBlock(NO, @"Something went wrong creating excursions");
    
}

#pragma mark - PFGeoPoint Sorting
-(NSArray*)sortGeoPointsByLongitudeWithArray:(NSArray*)array{
    
    NSMutableArray *geoPoints = [[NSMutableArray alloc] init];
    PFGeoPoint *geoPoint = [[PFGeoPoint alloc] init];
    
    for(Excursion *point in array){
        geoPoint = [PFGeoPoint geoPointWithLatitude:point.trunk.lat longitude:point.trunk.longitude];
        [geoPoints addObject:geoPoint];
    }
    NSArray *sortedArray = [geoPoints sortedArrayUsingComparator:^NSComparisonResult(PFGeoPoint *point1, PFGeoPoint *point2) {
        NSNumber *longitude1 = [NSNumber numberWithFloat:point1.longitude];
        NSNumber *longitude2 = [NSNumber numberWithFloat:point2.longitude];
        
        if (longitude1 && longitude2)
            return [longitude1 compare:longitude2];
        else if(longitude1)
            return NSOrderedAscending;
        else if(longitude2)
            return NSOrderedDescending;
        else return [longitude1 compare:longitude2];
    }];
    
    return sortedArray;
}

NSComparisonResult dateSort(NSString *s1, NSString *s2, void *context) {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *d1 = [df dateFromString:s1];
    NSDate *d2 = [df dateFromString:s2];
    return [d1 compare:d2];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGFloat cellWidth = 75;
    CGFloat cellPadding = 2;
    
    NSInteger page = (scrollView.contentOffset.x - cellWidth / 2) / (cellWidth + cellPadding) + 1;
    
    if (velocity.x > 0) page++;
    if (velocity.x < 0) page--;
    page = MAX(page,0);
    
    CGFloat newOffset = 0;
    for (int i = 0; i < page; ++i){
        if(i+1 >= self.cellWidths.count)
            cellWidth = 75;
        else cellWidth = [self.cellWidths[i+1] intValue];
        newOffset = newOffset + cellWidth + cellPadding;
    }
    
    targetContentOffset->x = newOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

    CGPoint centerPoint = CGPointMake(self.collectionView.frame.size.width/2 + self.collectionView.contentOffset.x,self.collectionView.frame.size.height/2 + self.collectionView.contentOffset.y);
    NSIndexPath *centerCellIndexPath = [self.collectionView indexPathForItemAtPoint:centerPoint];
    
    int group = [self currentlySelectedGroup];
    
    if(group != self.currentGroup){
        [self clearMap];
        self.currentGroup = group;
        [self initMap:self.filteredArray[group]];
    }else{
        [self clearFlag];
    }
    
    Excursion *excursion = self.sortedArray[centerCellIndexPath.row];
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:excursion.trunk.lat longitude:excursion.trunk.longitude];
    [self addFlagToMapWithGeoPoint:point];
    
}

-(int)currentlySelectedGroup{
    CGPoint centerPoint = CGPointMake(self.collectionView.frame.size.width/2 + self.collectionView.contentOffset.x,self.collectionView.frame.size.height/2 + self.collectionView.contentOffset.y);
    NSIndexPath *centerCellIndexPath = [self.collectionView indexPathForItemAtPoint:centerPoint];
    
    
    //need to determine which group the IndexPath is in
    int group = 0;
    if(centerCellIndexPath.item > 0){
        for(int i=1;i<self.excursionGroups.count; i++){
            if(BETWEEN(centerCellIndexPath.item, [self.excursionGroups[i-1] intValue], [self.excursionGroups[i] intValue])){
                group=i;
                break;
            }
        }
    }
    
    return group;
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.sortedArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize mElementSize;
    if([self.excursionGroups containsObject:[NSNumber numberWithInteger:indexPath.row]])
        mElementSize = CGSizeMake(95, 133);
    else mElementSize = CGSizeMake(75, 133);
    
    [self.cellWidths insertObject:[NSNumber numberWithFloat:mElementSize.width] atIndex:indexPath.row];
    
    return mElementSize;
}

- (TTTimelinePhotoCellCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    TTTimelinePhotoCellCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

    //FIXME: Why isn't cellForReuse being called?
    cell.imageView.image = [UIImage imageNamed:@"tt_square_placeholder"];
    cell.dateView.hidden = YES;
    cell.month.hidden = YES;
    cell.month.text = @"";

    __block Excursion *excursion = self.sortedArray[indexPath.row];

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM"];
    int month = [[df stringFromDate:excursion.trunk.start] intValue];
    __block NSString *monthName = [[df monthSymbols] objectAtIndex:(month-1)];


    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
    [photoQuery whereKey:@"trip" equalTo:excursion.trunk];
    [photoQuery setLimit:1];
    [photoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if(!error){
            Photo *photo = (Photo*)object;
            [cell.imageView setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
            if(![self.photoDate isEqualToString:monthName]){
                self.photoDate = monthName;
                cell.dateView.hidden = NO;
                cell.month.hidden = NO;
                cell.month.text = monthName;
            }
             }else{
                 //There's an error. Handle this and add the Google tracking
                 NSLog(@"error getting image");
                 NSLog(@"%@",excursion);
                 NSLog(@"%@",excursion.trunk);
             }
    }];

//    TTTimelinePhotoCellCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
//
//    //FIXME: Why isn't cellForReuse being called?
//    cell.imageView.image = [UIImage imageNamed:@"tt_square_placeholder"];
//    cell.dateView.hidden = YES;
//    cell.month.hidden = YES;
//    cell.month.text = @"";
//
//    __block Trip *trip = self.sortedArray[indexPath.row];
//
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    [df setDateFormat:@"MM"];
//    int month = [[df stringFromDate:trip.start] intValue];
//    __block NSString *monthName = [[df monthSymbols] objectAtIndex:(month-1)];
//
//
//    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
//    [photoQuery whereKey:@"trip" equalTo:trip];
//    [photoQuery orderByAscending:@"createdAt"];
////    [photoQuery whereKey:@"user" equalTo:self.user];
//    [photoQuery setLimit:1];
//    [photoQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//        if(!error){
//            Photo *photo = (Photo*)object;
//            [cell.imageView setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
//            if(![self.photoDate isEqualToString:monthName]){
//                self.photoDate = monthName;
//                cell.dateView.hidden = NO;
//                cell.month.hidden = NO;
//                cell.month.text = monthName;
//            }
//        }else{
//            //There's an error. Handle this and add the Google tracking
//            NSLog(@"error getting image");
////            NSLog(@"%@",excursion);
////            NSLog(@"%@",excursion.trunk);
//        }
//    }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Trunk" bundle:nil];
    TTTrunkViewController *trunkViewController = (TTTrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTTrunkViewController"];
    trunkViewController.excursion = self.sortedArray[indexPath.row];
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

-(void)sendUserToLogin{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    TTOnboardingViewController *loginViewController = (TTOnboardingViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTOnboardingViewController"];
    [self.navigationController presentViewController:loginViewController animated:YES completion:nil];
}


//NOTE: THIS IS TEMPORARY
- (IBAction)goToActivity:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Activity" bundle:nil];
    TTActivityNotificationsViewController *activityViewController = (TTActivityNotificationsViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTActivityNotificationsViewController"];
//    activityViewController.trip
    [self.navigationController pushViewController:activityViewController animated:YES];
}

- (IBAction)goToCreateTrunk:(UIButton *)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Trunk" bundle:nil];
    TTCreateTrunkViewController *createTrunkViewController = (TTCreateTrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CreateTrunkViewController"];
    //    activityViewController.trip
    [self.navigationController pushViewController:createTrunkViewController animated:YES];
}
@end