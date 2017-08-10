//
//  TTTimelineViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 7/28/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTTimelineViewController.h"
#import "TTTimelinePhotoCellCollectionViewCell.h"
#import <GoogleMaps/GoogleMaps.h>
#import <MapKit/MapKit.h>
#import "UIImageView+AFNetworking.h"
#import "TTColor.h"
#import "TTFont.h"

@interface TTTimelineViewController () <UICollectionViewDelegate>

@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation TTTimelineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.user = [PFUser currentUser];
    [self initMap];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Google Maps
-(void)initMap{
    double mapOffset = 0;
    //load geoPoints of each trunk in an excursion
    
//-------------------------------------------------------------
// ALL OF THIS IS HARDCODED. IT NEEDS TO CONNECT TO THE DATABASE
    PFGeoPoint *geoPoint = self.user[@"hometownGeoPoint"];//LA  -  latitude: 34.052200, longitude: -118.243700
    PFGeoPoint *geoPoint2 = [PFGeoPoint geoPointWithLatitude:51.539434 longitude:-0.901973]; //London
    PFGeoPoint *geoPoint3 = [PFGeoPoint geoPointWithLatitude:40.7128 longitude:-74.0059]; //NYC
    PFGeoPoint *geoPoint4 = [PFGeoPoint geoPointWithLatitude:32.7767 longitude:-96.7970]; //Dallas
    PFGeoPoint *geoPoint5 = [PFGeoPoint geoPointWithLatitude:38.993060 longitude:-94.618074]; //Kansas City
    PFGeoPoint *geoPoint6 = [PFGeoPoint geoPointWithLatitude:50.958015 longitude:-114.063875]; //Calgary
    
    //add geopoints to an array in chronological order
    NSArray *geoPointsChronologicalArray = @[geoPoint,geoPoint3,geoPoint4,geoPoint5,geoPoint6];
    NSArray *geoPointsChronologicalLabelArray = @[@"Home",@"New York",@"Dallas",@"Kansas City",@"Calgary"];
    
    //add geopoints to an array with map left & right
    NSArray *geoPointsDirectionalArray = @[geoPoint,geoPoint6,geoPoint4,geoPoint5,geoPoint3];
//----------------------------------------------------- ^^^^
    //load furthest left and furthest right
    PFGeoPoint *mapLeftGeoPoint = geoPointsDirectionalArray[0];
    PFGeoPoint *mapRightGeoPoint = geoPointsDirectionalArray[geoPointsDirectionalArray.count-1];
    
    //determine middle point between extent of trip locations
    PFGeoPoint *midGeoPoint = [PFGeoPoint geoPointWithLatitude:(mapLeftGeoPoint.latitude+mapRightGeoPoint.latitude)/2 longitude:(mapLeftGeoPoint.longitude+mapRightGeoPoint.longitude)/2];
    //latitude: 37.382500, longitude: -96.124800
    
    //set camera position to the middle of the route
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:midGeoPoint.latitude-mapOffset
                                                            longitude:midGeoPoint.longitude
                                                                 zoom:3];
    
    self.googleMapView.camera = camera;
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *styleUrl = [mainBundle URLForResource:@"style" withExtension:@"json"];
    NSError *error;
    
    GMSMapStyle *style = [GMSMapStyle styleWithContentsOfFileURL:styleUrl error:&error];
    if (!style)
        NSLog(@"The style definition could not be loaded: %@", error);
    self.googleMapView.mapStyle = style;

    [self createBezierPathForMapWithArrayOfGeoPoints:geoPointsChronologicalArray];
    
    int i=0; // <------ this is temporary until it's connected to the database
    for(PFGeoPoint *point in geoPointsChronologicalArray){
        [self addPointToMapWithGeoPoint:point];
        [self addLabelToMapWithGeoPoint:point AndText:geoPointsChronologicalLabelArray[i]];
        i++;
    }
    
}

#pragma mark - Market Creation Code
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

-(void)addLabelToMapWithGeoPoint:(PFGeoPoint*)geoPoint AndText:(NSString*)text{
    CGPoint point = [self createMapPointWithGeoPoint:geoPoint];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(point.x-10,point.y+3,50,21)];
    label.font = [TTFont tripTrunkFont8];
    label.textColor = [TTColor tripTrunkDarkGray];
    label.text = text;
    
    [self.googleMapView addSubview:label];
}

-(void)createBezierPathForMapWithArrayOfGeoPoints:(NSArray*)array{
        
    UIBezierPath *aPath = [UIBezierPath bezierPath];
    
    for(int i=0;i<array.count;i++){
        if(i==0){
            //move to first geo point
           [aPath moveToPoint:[self createMapPointWithGeoPoint:array[i]]];
        }else{
            //add curved line to path
            [aPath addQuadCurveToPoint:[self createMapPointWithGeoPoint:array[i]] controlPoint:[self createControlPointFromGeoPoint:array[i-1] To:array[i]]];
        }
    }
    
    //close out path to original geoPoint
    [aPath addQuadCurveToPoint:[self createMapPointWithGeoPoint:array[0]] controlPoint:[self createControlPointFromGeoPoint:[array lastObject] To:array[0]]];
    
    [aPath setLineWidth:3.0];
    [[UIColor blueColor] setStroke];
    [aPath stroke];
    
    CAShapeLayer * layer = [[CAShapeLayer alloc] init];
    layer.path = aPath.CGPath;
    layer.bounds = CGPathGetBoundingBox(layer.path);
    layer.strokeColor = [TTColor tripTrunkBlueMapLine].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor; /*if you just want lines*/
    layer.lineWidth = 3;
//FIXME: WHY DO I HAVE TO HAVE AN OFFSET ON Y FOR IT TO LOOK RIGHT?
    layer.position = CGPointMake([self createMapPointWithGeoPoint:array[0]].x-10,[self createMapPointWithGeoPoint:array[0]].y-62);
    layer.anchorPoint = CGPointMake(0,0.5);
    [self.googleMapView.layer addSublayer:layer];
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


#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 5;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize mElementSize;
    if(indexPath.row == 3 || indexPath.row ==4)
        mElementSize = CGSizeMake(95, 133);
    else mElementSize = CGSizeMake(75, 133);
    
    return mElementSize;
}

- (TTTimelinePhotoCellCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    TTTimelinePhotoCellCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    //FIXME: Why isn't cellForReuse being called?
    cell.imageView.image = [UIImage imageNamed:@"tt_square_placeholder"];
    cell.dateView.hidden = YES;
    cell.month.hidden = YES;
    cell.month.text = @"September";

    cell.imageView.image = [UIImage imageNamed:@"tt_square_placeholder"];
    
    if(indexPath.row == 0){
        cell.dateView.hidden = NO;
        cell.month.hidden = NO;
        cell.month.text = @"March";
    }
    
    if(indexPath.row == 3){
        cell.dateView.hidden = NO;
        cell.month.hidden = NO;
        cell.month.text = @"February";
    }
    
    if(indexPath.row == 4){
        cell.dateView.hidden = NO;
        cell.month.hidden = NO;
        cell.month.text = @"January";
    }
    
    
    
    
    
    //Load images from Array of image URLs
//    NSArray* photos = self.imageSet[indexPath.row];
//    NSString *photoUrl;
//    if(photos.count>0){
//        photoUrl = photos[0];
//        [cell.image setImageWithURL:[NSURL URLWithString:photoUrl]];
//    }
    
    return cell;
}


@end
