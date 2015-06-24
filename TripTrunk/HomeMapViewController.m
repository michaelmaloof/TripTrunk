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
#import "TTUtility.h"
#import "AddTripPhotosViewController.h"


#define METERS_PER_MILE 1609.344

@interface HomeMapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSMutableArray *locations;
@property NSMutableArray *parseLocations;
@property NSMutableArray *tripsToCheck;
@property NSMutableArray *hotDots;
@property NSString *pinCityName;
@property NSInteger originalCount;
@property (weak, nonatomic) IBOutlet UIButton *zoomOut;
@property (weak, nonatomic) IBOutlet UIButton *mapFilter;
@property int dropped;
@property int notDropped;
@property BOOL loadedOnce;
@property MKAnnotationView *photoPin;
@property NSMutableArray *friends;

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
    self.mapFilter.hidden = YES; //leave hidden for now. Ill explain if you email me and remind me lol
    
    
    //TODOSTILL How do I access the hometown property? Also, this should be saved as a geopoint and name
    NSString *hometown = [[PFUser currentUser] objectForKey:@"hometown"];
    NSLog(@"hometown = %@", hometown);

    
}

-(void)viewDidAppear:(BOOL)animated {
    self.hotDots = nil;
    self.hotDots = [[NSMutableArray alloc]init];
    self.locations = nil;
    self.locations = [[NSMutableArray alloc]init];
    self.parseLocations = nil;
    self.parseLocations = [[NSMutableArray alloc]init];
    
//    if(![PFUser currentUser] || ![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
    if(![PFUser currentUser])
    {
        [self.navigationController performSegueWithIdentifier:@"loginView" sender:nil];
            
    }
    else {
        [self queryParseMethodEveryone];
    }
}

//-(void)queryTrunks
//{
//    PFQuery *findTrip = [PFQuery queryWithClassName:@"Trip"];
//    [findTrip findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        if (self.loadedOnce == NO){
//            self.title = @"Loading Trunks...";
//            self.loadedOnce = YES;
//        }
//        if(!error)
//            {
//                self.parseLocations = [NSMutableArray arrayWithArray:objects];
//                [self placeTrips];
//                
//            }else
//            {
//                NSLog(@"Error: %@",error);
//                self.title = @"TripTrunk";
//
//            }
//            
//        }];
//}

-(void)queryForTrunks{
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKey:@"toUser" containedIn:self.friends];
    [followingQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    NSLog(@"friends = %@", self.friends);
    [followingQuery whereKey:@"type" equalTo:@"addToTrip"];
    [followingQuery includeKey:@"trip"];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (self.loadedOnce == NO)
        {
            self.title = @"Loading Trunks...";
            self.loadedOnce = YES;
        }
        if(error)
        {
            NSLog(@"Error: %@",error);
            self.title = @"TripTrunk";
        }
        else
        {
            int count = 0;
            self.parseLocations = [[NSMutableArray alloc]init];
            for (PFObject *activity in objects)
            {
                Trip *trip = activity[@"trip"];
                NSLog(@"trip = %@", trip.name);
                NSLog(@"location = %@", trip.city);
                NSLog(@"user = %@", trip.user);
                
                if (trip.name != nil)
                {
                    if (trip.isPrivate == YES)
                    {
                        if (activity[@"toUser"] == [PFUser currentUser])
                        {
                            [self.parseLocations addObject:trip];

                        }
                            
                    } else
                    {
                        [self.parseLocations addObject:trip];
                    }
                    
                }
                count += 1;
                if(count == objects.count){
                    [self placeTrips];
                }
            }
        }
        
    }];
}


-(void)queryParseMethodEveryone
{
    if (self.loadedOnce == NO){
        self.loadedOnce = YES;
    }
        self.friends = [[NSMutableArray alloc]init];
        [self.friends addObject:[PFUser currentUser]];
        PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
        [followingQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
        [followingQuery whereKey:@"type" equalTo:@"follow"];
        [followingQuery includeKey:@"toUser"];
        [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (self.loadedOnce == NO){
            self.title = @"Loading Trunks...";
            self.loadedOnce = YES;
        }
            if(error)
            {
                self.title = @"TripTrunk";
                NSLog(@"Error: %@",error);
            }
            else if (!error)
            {
                int count = 0;
                for (PFObject *activity in objects)
                {
                    PFUser *user = activity[@"toUser"];
                    [self.friends addObject:user];
                    count += 1;
                    
                    if(count == objects.count)
                    {
                        [self queryForTrunks];
                    }
                }
            }
    }];
}

- (IBAction)zoomOut:(id)sender {
    self.mapView.camera.altitude *= 3.5;
}

-(void)placeTrips
{
    if (self.parseLocations.count < self.originalCount )
        {
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

            NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
            
            
            NSDate *today = [NSDate date];
            NSTimeInterval tripInterval = [today timeIntervalSinceDate:trip.mostRecentPhoto];
        
            
            BOOL color = 0;
            if (tripInterval < 86400) {
                color = 1;
            } else{
                color = 0;
            }

            if(![self.tripsToCheck containsObject:address] || color == 1)
            {
                [self addTripToMap:trip dot:color];
                self.originalCount = self.parseLocations.count;
            } else {
                self.notDropped = self.notDropped +1;
            }
        }
    }

}

-(void)addTripToMap:(Trip*)trip dot:(BOOL)hot;
{
    NSString *string = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];

    [self.tripsToCheck addObject:string];
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:string completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        annotation.coordinate = placemark.location.coordinate;
        annotation.title = trip.city;

        if (hot == YES)
        {
            [self.hotDots addObject:annotation.title];
            [self.mapView addAnnotation:annotation];

        }
        
        else if (hot == NO && ![self.hotDots containsObject:annotation.title]) {

        [self.mapView addAnnotation:annotation];
        }
        
        self.dropped = self.dropped + 1;
        
        
        if (self.dropped + self.notDropped == self.parseLocations.count){
//            [self fitPins]; showing hometown now
            self.dropped = 0;
            self.notDropped = 0;
            self.title = @"TripTrunk";
        }

    }];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    CLLocationCoordinate2D center = view.annotation.coordinate;
    
    MKCoordinateSpan span;
    span.longitudeDelta = 3.5;
    span.latitudeDelta = 3.5;
    
    MKCoordinateRegion region;
    region.center = center;
    region.span = span;
    self.zoomOut.hidden = NO;

    
    [self.mapView setRegion:region animated:YES];}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *startAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startpin"];
    startAnnotation.canShowCallout = YES;
    
    if ([self.hotDots containsObject:annotation.title]) {
        startAnnotation.image = [UIImage imageNamed:@"Trunk Circle"];
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);
    } else {
        startAnnotation.image = [UIImage imageNamed:@"BlueCircle"];
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);
    }
    
    startAnnotation.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.rightCalloutAccessoryView.tag = 0;
    startAnnotation.leftCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.leftCalloutAccessoryView.tag = 1;
    startAnnotation.rightCalloutAccessoryView.hidden = YES;
    startAnnotation.leftCalloutAccessoryView.hidden = YES;
    
    [self.locations addObject:startAnnotation];
//    self.dropped = self.dropped + 1;
//
//    
//    if (self.dropped + self.notDropped == self.parseLocations.count){
//        [self fitPins];
//        self.dropped = 0;
//        self.notDropped = 0;
//    }
    return startAnnotation;
}
-(void)fitPins
{
    self.mapView.camera.altitude *= 1.0;
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    self.pinCityName = view.annotation.title;
    [self performSegueWithIdentifier:@"Trunk" sender:self];
    self.pinCityName = nil;
    self.photoPin = view;

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


- (IBAction)mapToggleTapped:(id)sender {
    
    if (self.mapFilter.tag == 0)
    {
        [self.mapFilter setImage:[UIImage imageNamed:@"Them"] forState:UIControlStateNormal];
        self.originalCount = 0;
        self.hotDots = nil;
        self.hotDots = [[NSMutableArray alloc]init];
        self.locations = nil;
        self.locations = [[NSMutableArray alloc]init];
        self.parseLocations = nil;
        self.parseLocations = [[NSMutableArray alloc]init];
        self.tripsToCheck = nil;
        [self.mapView removeAnnotations:self.mapView.annotations]; //TEMP REMOVE LATER
        //        NSString *user = [PFUser currentUser].username;
        //        NSMutableArray *users = [[NSMutableArray alloc]init];
        //        //ADD USERS HERE
        //        [self queryParseMethod:users];
        
    }
    
    else if (self.mapFilter.tag == 1)
    {
        [self.mapFilter setImage:[UIImage imageNamed:@"Me"] forState:UIControlStateNormal];
        self.originalCount = 0;
        self.hotDots = nil;
        self.hotDots = [[NSMutableArray alloc]init];
        self.locations = nil;
        self.locations = [[NSMutableArray alloc]init];
        self.parseLocations = nil;
        self.parseLocations = [[NSMutableArray alloc]init];
        self.tripsToCheck = nil;
        [self.mapView removeAnnotations:self.mapView.annotations]; //TEMP REMOVE LATER
        NSString *user = [PFUser currentUser].username;
        NSMutableArray *users = [[NSMutableArray alloc]init];
        [users addObject:user];
        [self queryParseMethodEveryone];
 

    }
    self.mapFilter.tag = !self.mapFilter.tag;
    
    
}

// This is needed for the login to work properly
// DO NOT DELETE
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}



@end





























