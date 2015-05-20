//
//  ViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "HomeMapViewController.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "Trip.h"
#import "TrunkListViewController.h"

#define METERS_PER_MILE 1609.344

@interface HomeMapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSMutableArray *locations;
@property NSMutableArray *parseLocations;
@property NSString *pinCityName;
@property NSMutableArray *tripsToCheck;
@property NSInteger originalCount;
@property (weak, nonatomic) IBOutlet UIButton *zoomOut;
@property BOOL hot;

@end

@implementation HomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"TripTrunk";
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    

    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
   self.tripsToCheck = [[NSMutableArray alloc]init];


}

-(void)viewDidAppear:(BOOL)animated {


    self.locations = nil;
    self.locations = [[NSMutableArray alloc]init];
    self.parseLocations = nil;
    self.parseLocations = [[NSMutableArray alloc]init];
    
    if(![PFUser currentUser] || ![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
    {
            [self.navigationController performSegueWithIdentifier:@"loginView" sender:nil];
            
    }
    else {
        [self queryParseMethod];
    }
}

-(void)queryParseMethod
{
    
    NSString *user = [PFUser currentUser].username;
    PFQuery *findTrip = [PFQuery queryWithClassName:@"Trip"];
    [findTrip whereKey:@"user" equalTo:user];

    [findTrip findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
            {
                self.parseLocations = [NSMutableArray arrayWithArray:objects];
                [self placeTrips];
                
            }else
            {
                NSLog(@"Error: %@",error);
            }
            
        }];
}

- (IBAction)zoomOut:(id)sender {
    [self fitPins];
}

-(void)placeTrips
{
    NSInteger count = 0;
    
    if (self.parseLocations.count < self.originalCount)
        {
            //FIXME (long term) to only remove deleted Trunk
            [self.mapView removeAnnotations:self.mapView.annotations];
            self.tripsToCheck = nil;
            self.tripsToCheck = [[NSMutableArray alloc]init];
            self.originalCount = 0;
            [self viewDidAppear:YES];
        }
    else
    {
    for (Trip *trip in self.parseLocations)
    {
        NSString *string = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
        if(![self.tripsToCheck containsObject:string])
        {
           count = count +1;
           [self addTripToMap:trip count:count];
            self.originalCount = self.parseLocations.count;
        }
    }
    }

}

-(void)addTripToMap:(Trip*)trip count:(NSInteger)count;
{
    //FIXEM needs to be address not city
    NSString *string = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
    __block NSString *countString = [[NSString alloc]init];
    [self.tripsToCheck addObject:string];
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:string completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        annotation.coordinate = placemark.location.coordinate;
        
        NSInteger count = 0;
        for (Trip *tripCount in self.parseLocations) {
            NSDate *today = [NSDate date];
            NSTimeInterval tripInterval = [today timeIntervalSinceDate:trip.mostRecentPhoto];
            BOOL color = 0;
            if (tripInterval < 3600) {
                color = 1;
            } else{
                color = 0;
            }
            
            NSString *address = [NSString stringWithFormat:@"%@ %@ %@", tripCount.city, tripCount.state, tripCount.country];
            if ([address isEqualToString:string] || color == 1)
            {
                if ([address isEqualToString:string])
                    {
                        count = count +1;
                    }
                
                if (tripInterval < 3600) {
                    self.hot = 1;
                } else{
                    self.hot = 0;
                }
                [self.mapView addAnnotation:annotation];

            }
        
        countString = [NSString stringWithFormat:@"%ld",(long)count];
        }
        
        annotation.title = trip.city;
        
    }];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    CLLocationCoordinate2D center = view.annotation.coordinate;
    
    MKCoordinateSpan span;
    span.longitudeDelta = 10.0;
    span.latitudeDelta = 10.0;
    
    MKCoordinateRegion region;
    region.center = center;
    region.span = span;
    self.zoomOut.hidden = NO;

    
    [self.mapView setRegion:region animated:YES];}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *startAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startpin"];
    startAnnotation.canShowCallout = YES;
    
    if (self.hot == 1) {
        startAnnotation.image = [UIImage imageNamed:@"Trunk Circle"];
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);

    } else {
        startAnnotation.image = [UIImage imageNamed:@"BlueCircle"];
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);
    }
    
    self.hot = 0;
    
    startAnnotation.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.rightCalloutAccessoryView.tag = 0;
    startAnnotation.leftCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.leftCalloutAccessoryView.tag = 1;
    startAnnotation.rightCalloutAccessoryView.hidden = YES;
    startAnnotation.leftCalloutAccessoryView.hidden = YES;
    
    [self.locations addObject:startAnnotation];
    
    
    return startAnnotation;
}
-(void)fitPins
{
    self.mapView.camera.altitude *= 1.8;
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    self.pinCityName = view.annotation.title;
    [self performSegueWithIdentifier:@"Trunk" sender:self];
    self.pinCityName = nil;

}


#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Trunk"])
    {
        TrunkListViewController *trunkView = segue.destinationViewController;
        trunkView.city = self.pinCityName;
        self.pinCityName = nil;
    }
      [self fitPins];
}
- (IBAction)onProfileTapped:(id)sender {

    
    
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}

@end
