//
//  ViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "HomeMapViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "Trip.h"


#define METERS_PER_MILE 1609.344

@interface HomeMapViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property CLLocationManager *locationManager;
@property CLLocation *currentLocation;
@property NSMutableArray *locations;
@property NSMutableArray *parseLocations;

@end

@implementation HomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"TripTrunk";
    
    [super viewDidLoad];
    
    if(![PFUser currentUser])
    {
        
        [self.navigationController performSegueWithIdentifier:@"loginView" sender:nil];
    }
    
    self.locationManager = [[CLLocationManager alloc]init];
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
    self.currentLocation = [[CLLocation alloc]init];
    self.currentLocation = [self.locationManager location];
    self.mapView.region = MKCoordinateRegionMakeWithDistance(self.currentLocation.coordinate, 10000, 10000);
    self.locations = [[NSMutableArray alloc]init];
    
    
}

-(void)viewDidAppear:(BOOL)animated {
    self.locations = [[NSMutableArray alloc]init];
    self.parseLocations = [[NSMutableArray alloc]init];
    [self queryParseMethod];
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

-(void)placeTrips{
    NSInteger count = 0;
    for (Trip *trip in self.parseLocations)
    {
        [self addTripToMap:trip];
        count +=1;
                
        if (count == self.parseLocations.count)
        {

            [self.mapView showAnnotations:self.locations animated:YES];
        }
        
    }

}

-(void)addTripToMap:(Trip*)trip;
{
    //FIXEM needs to be address not city
    
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:trip.city completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        annotation.coordinate = placemark.location.coordinate;
        annotation.title = trip.city;
        
//        self.mapView.region = MKCoordinateRegionMakeWithDistance(placemark.location.coordinate, 10000, 10000);
        
        [self.mapView addAnnotation:annotation];
        
        
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *startAnnotation = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startpin"];
    startAnnotation.pinColor = MKPinAnnotationColorGreen;
    startAnnotation.animatesDrop = YES;
    startAnnotation.canShowCallout = YES;
    startAnnotation.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.image = [UIImage imageNamed:@"Trunk Circle"];
    [self.locations addObject:startAnnotation];
    
    return startAnnotation;
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    CLLocationCoordinate2D center = view.annotation.coordinate;
    
    MKCoordinateSpan span;
    span.longitudeDelta = 0.01;
    span.latitudeDelta = 0.01;
    
    MKCoordinateRegion region;
    region.center = center;
    region.span = span;
    
    [self.mapView setRegion:region animated:YES];
}


#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}


@end
