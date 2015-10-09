//
//  ViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "HomeMapViewController.h"
#import <MapKit/MapKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "Trip.h"
#import "TrunkListViewController.h"
#import "TTUtility.h"
#import "SocialUtility.h"
#import "AddTripPhotosViewController.h"
#import "ParseErrorHandlingController.h"
#import "EULAViewController.h"

#define METERS_PER_MILE 1609.344

@interface HomeMapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSMutableArray *locations;
@property NSMutableArray *parseLocations;
@property NSMutableArray *tripsToCheck;
@property NSMutableArray *justMadeTrunk;
@property NSMutableArray *hotDots;
@property NSString *pinCityName;
@property NSString *pinStateName;
@property NSInteger originalCount;
@property (weak, nonatomic) IBOutlet UIButton *zoomOut;
@property (weak, nonatomic) IBOutlet UIButton *mapFilter;
@property int dropped;
@property int notDropped;
@property BOOL loadedOnce;
@property MKAnnotationView *photoPin;
@property NSMutableArray *friends;
@property BOOL isNew;
@property NSMutableArray *originalArray;
@property Trip *tripToCheck;


@end

@implementation HomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    
    if (self.user == nil) {
            
        self.tabBarController.tabBar.translucent = false;
        [self.tabBarController.tabBar setTintColor:[UIColor colorWithRed:(95.0/255.0) green:(148.0/255.0) blue:(172.0/255.0) alpha:1]];

        
    }

    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    
    if (self.user == nil){
        [self setTitleImage];
    } else {
        self.title = [NSString stringWithFormat:@"@%@'s Trips", self.user.username];
    }
    
    self.tripsToCheck = [[NSMutableArray alloc]init];
    
    self.hotDots = nil;
    self.hotDots = [[NSMutableArray alloc]init];
    self.locations = nil;
    self.locations = [[NSMutableArray alloc]init];
    self.parseLocations = nil;
    self.parseLocations = [[NSMutableArray alloc]init];
    self.justMadeTrunk = nil;
    self.justMadeTrunk = [[NSMutableArray alloc]init];
    self.isNew= NO;
    
    self.mapFilter.hidden = YES; //leave hidden for now. Ill explain if you email me and remind me lol
    self.originalArray = [[NSMutableArray alloc]init];
        
        //TODOSTILL How do I access the hometown property? Also, this should be saved as a geopoint and name
//        NSString *hometown = [[PFUser currentUser] objectForKey:@"hometown"];
    [self ensureEULA];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
}

-(void)viewDidAppear:(BOOL)animated {
    
//    if(![PFUser currentUser] || ![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
    if([self checkUserRegistration])
    {
        if (self.user == nil) {
            [self queryParseMethodEveryone];
            
            [self registerNotifications];
            
        } else {
            [self queryParseMethodForUser:self.user];
            
            [self registerNotifications];
        }
    }
    
    NSLog(@"count = %lu", (unsigned long)self.mapView.annotations.count);
    
}

- (void)setTitleImage {
    UIImage *logo = [UIImage imageNamed:@"tripTrunkTitle"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
    logoView.frame = CGRectMake(logoView.frame.origin.x, logoView.frame.origin.y,logoView.frame.size.width,self.navigationController.navigationBar.frame.size.height*.6);
    [logoView setContentMode:UIViewContentModeScaleAspectFit];
    self.navigationItem.titleView = logoView;
    [self.navigationItem.titleView setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)ensureEULA {
    BOOL didAgree = [[[NSUserDefaults standardUserDefaults] valueForKey:@"agreedToEULA"] boolValue];
    
    // If they've already agreed, AWESOME!
    // if not, we need to force them into our terms.
    if (!didAgree) {
        
        EULAViewController *eula = [[EULAViewController alloc] initWithNibName:@"EULAViewController" bundle:[NSBundle mainBundle]];
        
        UINavigationController *homeNavController = [[UINavigationController alloc] initWithRootViewController:eula];
        
        [self presentViewController:homeNavController animated:YES completion:nil];
        
    }
    
}

/**
 *  Determine the user status
 *
 *  @return YES if user is logged in and we should continue. NO if we are displaying a different view to do/finish login
 */
- (BOOL)checkUserRegistration {
    // No logged-in user
    if (![PFUser currentUser]) {
        [self.navigationController performSegueWithIdentifier:@"loginView" sender:nil];
        return NO;
    }
    // User is logged in, but hasn't completed registration (i.e. hasn't set a username or hometown, etc.)
    else if (![[PFUser currentUser] valueForKey:@"completedRegistration"] || [[[PFUser currentUser] valueForKey:@"completedRegistration"] boolValue] == FALSE) {
        
        [self.navigationController performSegueWithIdentifier:@"presentUsernameSegue" sender:nil];

        return NO;
    }
    // User is logged in and good-to-go
    return YES;
}

- (void)registerNotifications {

        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Okay button pressed - They want to add some friends
    if (buttonIndex == 1) {
        [self.tabBarController setSelectedIndex:1];
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

-(void)queryParseMethodForUser:(PFUser*)user
{
    if (self.loadedOnce == NO){
        self.loadedOnce = YES;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query includeKey:@"trip"];
    [query includeKey:@"toUser"];
    [query orderByDescending:@"createdAt"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (self.loadedOnce == NO)
        {
            self.title = @"Loading Trunks...";
            self.loadedOnce = YES;
        }
        if(error)
        {
            NSLog(@"Error: %@",error);
            
            if (self.user == nil){
                [self setTitleImage];
            } else {
                self.title = [NSString stringWithFormat:@"@%@'s Trips", self.user.username];
            }
            [ParseErrorHandlingController handleError:error];
        }
        else
        {
            int count = 0;
            self.parseLocations = [[NSMutableArray alloc]init];
            for (PFObject *activity in objects)
            {
                Trip *trip = activity[@"trip"];
//                PFUser *user = activity[@"toUser"];
                
                if (trip.name != nil)
                {
                    [self.parseLocations addObject:trip];

//                    if (trip.isPrivate == YES)
//                    {
//                        if ([user.objectId isEqualToString:[PFUser currentUser].objectId])
//                        {
//                            [self.parseLocations addObject:trip];
//                            
//                        }
//                        
//                    } else
//                    {
//                    }
                    
                }
                count += 1;
                if(count == objects.count){
                    [self placeTrips];
                }
            }
        }
        
    }];
}



-(void)queryForTrunks{ //City filter if (trip.name != nil && ![self.objectIDs containsObject:trip.objectId]) should be moved here to place less pins down later

    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" containedIn:self.friends];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query includeKey:@"trip"];
    [query includeKey:@"toUser"];
    [query orderByDescending:@"createdAt"];



    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
        if (self.loadedOnce == NO)
        {
            self.title = @"Loading Trunks...";
            self.loadedOnce = YES;
        }
        if(error)
        {
            NSLog(@"Error: %@",error);
            if (self.user == nil){
                [self setTitleImage];

            } else {
                self.title = [NSString stringWithFormat:@"@%@'s Trips", self.user.username];
            }
            [ParseErrorHandlingController handleError:error];
        }
        else
        {
            int count = 0;
            self.parseLocations = [[NSMutableArray alloc]init];
            for (PFObject *activity in objects)
            {
                Trip *trip = activity[@"trip"];
//                PFUser *user = activity[@"toUser"];

                if (trip.name != nil)
                {
                    [self.parseLocations addObject:trip];

//                    if (trip.isPrivate == YES)
//                    {
//                        if ([user.objectId isEqualToString:[PFUser currentUser].objectId])
//                        {
//                            [self.parseLocations addObject:trip];
//
//                        }
//                            
//                    } else
//                    {
//                    }
                    
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

    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (self.loadedOnce == NO){
            self.title = @"Loading Trunks...";
            self.loadedOnce = YES;
        }

        if (!error) {
            [self.friends addObjectsFromArray:users];
            
            [self queryForTrunks];
            
            if (users.count == 0) {
                NSLog(@"Not following any users");
                [self displayFollowUserAlertIfNeeded];
                
            }
        }
        else {
            if (self.user == nil){
                [self setTitleImage];

            } else {
                self.title = [NSString stringWithFormat:@"@%@'s Trips", self.user.username];
            }
            [ParseErrorHandlingController handleError:error];

        }
    }];
}

- (void)displayFollowUserAlertIfNeeded {
    NSUInteger timesShown = [[[NSUserDefaults standardUserDefaults] valueForKey:@"shownFollowUserAlert"] integerValue];
    if (!timesShown) {
        timesShown = 1;
    }
    // Show it every other time. After a few visits, then we'll pester them because they need to add friends.
    if (timesShown != 2 && timesShown != 4 && timesShown != 6 && timesShown != 8) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Follow Some Users" message:@"TripTrunk is more fun with friends. Start following some users now!" delegate:self cancelButtonTitle:@"Not Now" otherButtonTitles:@"Okay", nil];
            [alertView show];
        });
    }
    timesShown++;
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:timesShown] forKey:@"shownFollowUserAlert"];


}

- (IBAction)zoomOut:(id)sender {
    self.mapView.camera.altitude *= 3.5;
}

-(void)zoomTrunkOut{
    
}

-(void)placeTrips
{

    if (self.originalArray.count == 0)
    {
        
        for (Trip *trip in self.parseLocations)
        {
            
            NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
            
            
            NSDate *today = [NSDate date];
            NSTimeInterval tripInterval = [today timeIntervalSinceDate:trip.mostRecentPhoto];
            
            
            BOOL color = 0;
            if (tripInterval < 86400)
            {
                color = 1;
            } else{
                color = 0;
            }
            
            if(![self.tripsToCheck containsObject:address] || color == 1)
            {
                [self addTripToMap:trip dot:color];
                self.originalCount = self.parseLocations.count;
                self.originalArray = self.parseLocations;
            } else {
                self.notDropped = self.notDropped +1;
            }
        }
    }
    else
    {
        int indexCount = 0;
        BOOL update = NO;
        
        for (Trip *trip in self.parseLocations)
        {
            Trip *tripTwo = [self.originalArray objectAtIndex:indexCount];
            indexCount += 1;
            
            if (![trip.objectId isEqualToString:tripTwo.objectId] || ![trip.city isEqualToString:tripTwo.city])
            {
                update = YES;
                break;
            }
        }
        
        if (update == YES)
        {
            [self.mapView removeAnnotations:self.mapView.annotations];
            self.tripsToCheck = nil;
            self.tripsToCheck = [[NSMutableArray alloc]init];
            self.originalCount = 0;
            
            self.hotDots = nil;
            self.hotDots = [[NSMutableArray alloc]init];
            self.locations = nil;
            self.locations = [[NSMutableArray alloc]init];
            self.justMadeTrunk = nil;
            self.justMadeTrunk = [[NSMutableArray alloc]init];
            self.isNew= NO;

            for (Trip *trip in self.parseLocations)
            {

                NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
                
                
                NSDate *today = [NSDate date];
                NSTimeInterval tripInterval = [today timeIntervalSinceDate:trip.mostRecentPhoto];
            
                
                BOOL color = 0;
                if (tripInterval < 86400)
                {
                    color = 1;
                } else{
                    color = 0;
                }

                if(![self.tripsToCheck containsObject:address] || color == 1)
                {
                    [self addTripToMap:trip dot:color];
                    self.originalCount = self.parseLocations.count;
                    self.originalArray = self.parseLocations;
                } else {
                    self.notDropped = self.notDropped +1;
                }
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
        
        NSDate *date = trip.createdAt;
        NSTimeInterval interval = [date timeIntervalSinceNow];
        
        if ([trip.name isEqualToString:@"3"]){
            
        }
        
        if (interval > -30 && [trip.creator.objectId isEqualToString:[PFUser currentUser].objectId] && self.justMadeTrunk && trip.objectId != self.tripToCheck.objectId) {
            self.isNew = YES;
            self.tripToCheck = trip;
            [self.justMadeTrunk addObject:annotation];
        }

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
            if (self.user == nil){
                [self setTitleImage];

            } else {
                self.title = [NSString stringWithFormat:@"@%@'s Trunks", self.user.username];
            }
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

    
    [self.mapView setRegion:region animated:YES];
}



- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *startAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startpin"];
    startAnnotation.canShowCallout = YES;
    
    if ([self.hotDots containsObject:annotation.title]) {
        startAnnotation.image = [UIImage imageNamed:@"redMapCircle"];
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);
        startAnnotation.alpha = 1.0;
//        [[startAnnotation superview] bringSubviewToFront:startAnnotation];
        startAnnotation.layer.zPosition = 1;
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, startAnnotation.frame.size.width*1.1, startAnnotation.frame.size.height*1.1);

    } else {
        startAnnotation.image = [UIImage imageNamed:@"blueMapCircle"];
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);
        startAnnotation.alpha = .9;
//        [[startAnnotation superview] sendSubviewToBack:startAnnotation];
        startAnnotation.layer.zPosition = .9;
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, startAnnotation.frame.size.width*.9, startAnnotation.frame.size.height*.9);



    }
    
    startAnnotation.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.rightCalloutAccessoryView.tag = 0;
    startAnnotation.leftCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    startAnnotation.leftCalloutAccessoryView.tag = 1;
    startAnnotation.rightCalloutAccessoryView.hidden = YES;
    startAnnotation.leftCalloutAccessoryView.hidden = YES;
    
    [self.locations addObject:startAnnotation];

    
    if (self.isNew == YES) {
        self.isNew = NO;
        [self.mapView showAnnotations:self.justMadeTrunk animated:YES];

    }

    return startAnnotation;
}
-(void)fitPins
{
    self.mapView.camera.altitude *= 1.0;
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // TODO: Get the state in a more elloquent way. This is hacky.
    CLGeocoder *cod = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:view.annotation.coordinate altitude:0 horizontalAccuracy:0 verticalAccuracy:0 timestamp:[NSDate date]];
    [cod reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        CLPlacemark *placemark = [placemarks firstObject];
        
        self.pinCityName = view.annotation.title;
        self.pinStateName = placemark.administrativeArea;
        [self performSegueWithIdentifier:@"Trunk" sender:self];
        self.pinCityName = nil;
        self.pinStateName = nil;
        self.photoPin = view;
    }];
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
        trunkView.state = self.pinStateName;
        trunkView.user = self.user;
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





























