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
    [self.mapView showAnnotations:self.locations animated:YES];
    
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
    for (Trip *trip in self.parseLocations)
    {
        NSString *city = trip.city;
        [self addTripToMap:city];
    }
}

-(void)addTripToMap:(NSString*)location;
{
    
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        annotation.coordinate = placemark.location.coordinate;
        
        MKPinAnnotationView *startAnnotation = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startpin"];
        startAnnotation.pinColor = MKPinAnnotationColorGreen;
        startAnnotation.animatesDrop = YES;
        
        
        self.mapView.region = MKCoordinateRegionMakeWithDistance(placemark.location.coordinate, 10000, 10000);
        
        [self.mapView addAnnotation:annotation];
        [self.locations addObject:startAnnotation];
        [self.mapView showAnnotations:self.locations animated:YES];
        
    }];
}



#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}


@end
