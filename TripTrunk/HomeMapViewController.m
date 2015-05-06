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

}

-(void)viewDidAppear:(BOOL)animated {
    // only add pins that have been updated
    [self.mapView  removeAnnotations:self.mapView.annotations];
    
    //FIXME needs to cache at some point
    
    self.tripsToCheck = nil;
    self.tripsToCheck = [[NSMutableArray alloc]init];
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

-(void)placeTrips
{
    NSInteger count = 0;
    for (Trip *trip in self.parseLocations)
    {
        if(![self.tripsToCheck containsObject:trip.city])
        {
           count = count +1;
           [self addTripToMap:trip count:count];
        }
    }

}

-(void)addTripToMap:(Trip*)trip count:(NSInteger)count;
{
    //FIXEM needs to be address not city
    [self.tripsToCheck addObject:trip.city];
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:trip.city completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        annotation.coordinate = placemark.location.coordinate;
        annotation.title = trip.city;
        
        [self.mapView addAnnotation:annotation];
        
    //FIXME Does it include last pin? DO I ACTUALLY EVEN NEED THIS FOR THE MAP?
//        if (count == self.tripsToCheck.count) {
//            [self fitPins];
//        }
        
    }];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *startAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startpin"];
    startAnnotation.canShowCallout = YES;
    startAnnotation.image = [UIImage imageNamed:@"Trunk Circle"];
    startAnnotation.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.rightCalloutAccessoryView.tag = 0;
    startAnnotation.leftCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.leftCalloutAccessoryView.tag = 1;
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
    if (control.tag == 0)
    {
    CLLocationCoordinate2D center = view.annotation.coordinate;
    
    MKCoordinateSpan span;
    span.longitudeDelta = 10.0;
    span.latitudeDelta = 10.0;
    
    MKCoordinateRegion region;
    region.center = center;
    region.span = span;
    
    [self.mapView setRegion:region animated:YES];
    }
    
    else if (control.tag == 1)
    {
        self.pinCityName = view.annotation.title;
        [self performSegueWithIdentifier:@"Trunk" sender:self];
        self.pinCityName = nil;
    }
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
}
- (IBAction)onProfileTapped:(id)sender {

    
    
}


@end
