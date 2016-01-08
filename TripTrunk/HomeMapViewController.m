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
#import "TutorialViewController.h"

#define METERS_PER_MILE 1609.344

@interface HomeMapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSMutableArray *parseLocations;
@property NSMutableArray *tripsToCheck;
@property NSMutableArray *hotDots;
@property NSString *pinCityName;
@property NSString *pinStateName;
@property (weak, nonatomic) IBOutlet UIButton *zoomOut;
@property int dropped;
@property int notDropped;
@property NSDate *today;
@property MKAnnotationView *photoPin;
@property NSMutableArray *friends;
@property Trip *tripToCheck;
@property BOOL tutorialComplete;
@property NSMutableArray *needsUpdates;
@property NSMutableArray *haventSeens;
@property CLLocation *location;
@property NSArray<id<MKAnnotation>> *annotationsToDelete;
@property BOOL isLoading;
@property int limit;
@property (weak, nonatomic) IBOutlet UIImageView *compassRose;
@property (weak, nonatomic) IBOutlet UIButton *compasButton;
@property NSDate *lastOpenedApp;
@property BOOL dontRefresh;
@property BOOL isFirstUserLoad;
@property MKPointAnnotation* annotationPinToZoomOn;
@property BOOL isMainMap;
@property NSMutableArray *visitedTrunks;

@end

@implementation HomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //compass rose shows users what the symbols on the map means. Red means a photo has been added in the last 24 hours, blue means a photo hasn't been added in the last 24 hours, and the TT Logo means the user hasn't seen this trunk yet or that it has photos the user hasn't seen in the trunk yet. We hide it on viewDidLoad and then on viewDidAppear check to see if the user should be shown it.
    self.compassRose.hidden = YES;
    self.isFirstUserLoad = YES;
    
    self.viewedTrunks = [[NSMutableArray alloc]init];
    self.viewedPhotos = [[NSMutableArray alloc]init];
    self.visitedTrunks =  [[NSMutableArray alloc]init];
    [self designNavBar];
    
    //we don't want the user loading multiple requests to refresh the map. This bool will prevent that.
    self.isLoading = NO;
    
    //we load 250 trunks from parse at a time unless the user selects to add more by clicking the "more trunks" button"
    self.limit = 250;
    
    //Each viewDidAppear we reload the trunks from parse with a query to get the most recent list of trunks and updates. We leave the old set of map locations in this array. Once we finish placing the new pins, we use this array to remove all the old ones. It prevents the user from ever seeing a blank map (excluding the original load)
    self.annotationsToDelete = [[NSMutableArray alloc]init];
    
    //Require users to agree to the terms and conditions
    [self ensureEULA];
    
    //We used to not save the long and lat of a trunk on the Trip parse data. Trunks of the user that dont have this info will be saved in this array and then updated to now include the long and lat.
    self.needsUpdates = nil;
    self.needsUpdates = [[NSMutableArray alloc]init];
    
    //We need this to do the logic in determing if a user has seen a trunk and if a trunk should be red or blue.
    self.today = [NSDate date];
    
    //we need the date the user last oppened the app to put the logo on certain trunks
    //TODO we should do this once on viewDidLoad
    self.lastOpenedApp = [PFUser currentUser][@"lastUsed"];
    
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (HomeMapViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[HomeMapViewController class]])
            {
                if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                    if (self == (HomeMapViewController*)controller.viewControllers[0]){
                        self.isMainMap = YES;
                    }
                }
            }
        }
    }

}

-(void)viewDidAppear:(BOOL)animated {
    self.visitedTrunks = [[NSMutableArray alloc]init];
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (HomeMapViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[HomeMapViewController class]])
            {
                if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                    self.visitedTrunks = view.viewedTrunks;
                }
            }
        }
    }
    
    //Make sure the user is logged in. If not we make them login.
    if([self checkUserRegistration])
    {
        //If user has not completed tutorial, show tutorial
        self.tutorialComplete = [[[PFUser currentUser] valueForKey:@"tutorialViewed"] boolValue];
        if (self.tutorialComplete == NO)
        {
            [self showTutorial];
        } else {
            //if they have already seen the tutorial we dont show them the compass rose unless they ask to see it.
            self.compassRose.hidden = YES;
            
        }
        
        if (self.user == nil) {
            
            //If self.user is nil then the user is looking at their home/newsfeed map. We want "everyone's" trunks that they follow, including themselves, from parse.
            //We're on the home taeb so register the user's notifications
            if (self.tutorialComplete == YES){
                [self registerNotifications];
                if (self.dontRefresh == NO){
                    [self beginLoadingTrunks];
                } else {
                    if (self.annotationPinToZoomOn){
                        [self zoomInOnNewPin];
                    }
                    self.dontRefresh = NO;
                }
            }
            
        } else {
            //If self.user is not nil then we are looking at a specific user's map. We just want that specific user's trunks from parse
            if (self.dontRefresh == NO){
                [self beginLoadingTrunks];
            } else {
                self.dontRefresh = NO;
            }
        }
    }
}

-(void)zoomInOnNewPin{
    CLLocationCoordinate2D center = self.annotationPinToZoomOn.coordinate;
    
    MKCoordinateSpan span;
    span.longitudeDelta = 3.5;
    span.latitudeDelta = 3.5;
    
    MKCoordinateRegion region;
    region.center = center;
    region.span = span;
    self.zoomOut.hidden = NO;
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView selectAnnotation:self.annotationPinToZoomOn animated:NO];
    
    self.annotationPinToZoomOn = nil;
}

/**
 *  Begins the process of loading the applicable trunks for this map from parse
 *
 *
 */
-(void)beginLoadingTrunks{
    
    //the user doesnt have a query in progress to load the trunks already, so go ahead and load the trunks
    if (self.isLoading == NO){
        
        //disable the refresh button until we finish loading the trunks
        self.navigationItem.rightBarButtonItem = nil;
        
        //save the current pins on the map so we can delete them once we place the new ones
        self.annotationsToDelete = self.mapView.annotations;
        
        [self setUpArrays];
        
        if (self.user == nil) {
            //If self.user is nil then the user is looking at their home/newsfeed map. We want "everyone's" trunks that they follow, including themselves, from parse.
            
            self.isLoading = YES;
            [self queryParseMethodEveryone];
            //We're on the home tab so register the user's notifications
            
        } else {
            //If self.user is not nil then we are looking at a specific user's map. We just want that specific user's trunks from parse
            self.isLoading = YES;
            [self queryParseMethodForUser:self.user];
        }
    }
}

/**
 *  Creates most the arrays we need for the map
 *
 *
 */
-(void)setUpArrays{
//we locate each trunk thats placed o nthe map here. If a trunk shares the same city as one in this array then we dont put the trunk here. This prevents us dropping multiple pins on the same city
    self.tripsToCheck = [[NSMutableArray alloc]init];
    
//containts map annotations of trips that need a red dot as opposed blue blue. They're red  because a user has added photos to them in the last 24 hours
//TODO: THIS SHOULD SAVE THE LOCATION AND NOT THE CITY NAME. Possbily applicable to other arrays
    self.hotDots = [[NSMutableArray alloc]init];
    
//the trunks we pull down from parse
    self.parseLocations = [[NSMutableArray alloc]init];
  
//list of trunks the user hasn't seen since last being in the app
    self.haventSeens = [[NSMutableArray alloc]init];
}

/**
 *  Make the title the "TripTrunk" image
 *
 *
 */
- (void)setTitleImage {
    UIImage *logo = [UIImage imageNamed:@"tripTrunkTitle"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
    logoView.frame = CGRectMake(logoView.frame.origin.x, logoView.frame.origin.y,logoView.frame.size.width,self.navigationController.navigationBar.frame.size.height*.6);
    [logoView setContentMode:UIViewContentModeScaleAspectFit];
    self.navigationItem.titleView = logoView;
    [self.navigationItem.titleView setContentMode:UIViewContentModeScaleAspectFit];
}

/**
 *  Create the navBar with proper design
 *
 *
 */
-(void)designNavBar{
    
    //if self.user is not nil then you are looking at a user's profile. Therefore the map will have their name in the title. If self.user is nil then we show the TripTrunk title since you are on the home or newsfeed map.
    if (self.user == nil) {
        [self setTitleImage];
    } else {
        self.title = [NSString stringWithFormat:@"@%@'s Trunks", self.user.username];
    }
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.tabBarController.tabBar.translucent = false;
    [self.tabBarController.tabBar setTintColor:[UIColor colorWithRed:(95.0/255.0) green:(148.0/255.0) blue:(172.0/255.0) alpha:1]];
}

/**
 *  Make the user agree to the terms and conditions
 *
 *
 */
- (void)ensureEULA {
    BOOL didAgree = [[[NSUserDefaults standardUserDefaults] valueForKey:@"agreedToEULA"] boolValue];
    
    // If they've already agreed, AWESOME!
    // if not, we need to force them into our terms. Or else...
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

/**
 *  Register user notifications
 *
 *
 */
- (void)registerNotifications {
    
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
}

//Currently the only alert view that is shown is if you open the homescreen and have no friends. We encourage you to follow people so you won't be such a loser.
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Okay button pressed - They want to add some friends
    if (buttonIndex == 1) {
        [self.tabBarController setSelectedIndex:1];
    }
}

/**
 *  Load all the user's who the current user is following
 *
 *
 */
-(void)queryParseMethodEveryone
{
    //self.friends will contrain the users that the current user is following.
    self.friends = [[NSMutableArray alloc]init];
    //add the current user to self.friends since we want the current user's trunks too
    [self.friends addObject:[PFUser currentUser]];
    
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error) {
            //add the users to self.friends. Now its containing the current user and all the people they are following
            [self.friends addObjectsFromArray:users];
            
            //use parse to download the trunks of the current user and the users they are following
            [self queryForTrunks];
            
            if (users.count == 0 && self.tutorialComplete == YES) {
                //They're following no one, tell them to make some friends
                [self displayFollowUserAlertIfNeeded];
            }
        }
        else {
            //if we didn't load the users then we set back the correct title.
            if (self.user == nil){
                [self setTitleImage];
            } else {
                NSString *trunks = NSLocalizedString(@"Trunks",@"Trunks");
                NSString *s = NSLocalizedString(@"'s",@"'s");
                self.title = [NSString stringWithFormat:@"%@%@ %@", self.user.username, s,trunks];
            }
            [ParseErrorHandlingController handleError:error];
        }
    }];
}


/**
 *  Load the trunks of a specific user from the trunk since we are looking at a user's profile
 *
 *
 */
-(void)queryParseMethodForUser:(PFUser*)user
{
    //Query to get trunks only from the user whose profile we are on. We get trunks that they made and that they're members of
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query includeKey:@"trip"];
    [query includeKey:@"trip.publicTripDetail"];
    [query includeKey:@"toUser"];
    [query includeKey:@"creator"];
    [query includeKey:@"createdAt"];
    [query orderByDescending:@"createdAt"]; //TODO does this actually work?
    [query setLimit: self.limit];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        //we finished loading so switch the bool and renable the refresh icon
        self.isLoading = NO;
        UIBarButtonItem *button = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(beginLoadingTrunks)];
        self.navigationItem.rightBarButtonItem = button;
        
        
        //If there is an error put the navBar title back to normal so that it isn't still telling the user we are loading the trunks.
        if(error)
        {
            NSLog(@"Error: %@",error);
            if (self.user == nil){
                [self setTitleImage];
            } else {
                NSString *trunks = NSLocalizedString(@"Trunks",@"Trunks");
                NSString *s = NSLocalizedString(@"'s",@"'s");
                self.title = [NSString stringWithFormat:@"%@%@ %@", self.user.username, s,trunks];
            }
            [ParseErrorHandlingController handleError:error];
        }
        
        //there is no error loading the trunks so begin the process of placing them on the map
        else
        {
            self.parseLocations = [[NSMutableArray alloc]init];
            for (PFObject *activity in objects)
            {
                Trip *trip = activity[@"trip"];
                if (trip.name != nil)
                {
                    [self.parseLocations addObject:trip];
                }
            }
            
            
            for (Trip *trip in self.parseLocations)
            {
                NSTimeInterval lastTripInterval = [self.lastOpenedApp timeIntervalSinceDate:trip.createdAt];
                NSTimeInterval lastPhotoInterval = [self.lastOpenedApp timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];
                CLLocation *location = [[CLLocation alloc]initWithLatitude:trip.lat longitude:trip.longitude];
                
                BOOL contains = NO;
                
                for (Trip* trunk in self.visitedTrunks){
                    if ([trunk.objectId isEqualToString:trip.objectId]){
                        contains = YES;
                    }
                }
                
                if (self.visitedTrunks.count == 0){
                    contains = NO;
                }
                
                if (lastTripInterval < 0 && contains == NO)
                {
                    [self.haventSeens addObject:location];
                } else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil && contains == NO){
                    [self.haventSeens addObject:location];
                }
            }
            [self placeTrips];
        }
    }];
}


/**
 *  Load the trunks of the user's who the current user is following. We use the self.friends array to store their following.
 *
 */
-(void)queryForTrunks{
    
    //TODO:City filter if (trip.name != nil && ![self.objectIDs containsObject:trip.objectId]) should be moved here to place less pins down later
    
    //This is documented in the method above.
    //TODO This method and the one above should be merged into one method during refactoring
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" containedIn:self.friends];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query includeKey:@"trip"];
    [query includeKey:@"toUser"];
    [query includeKey:@"creator"];
    [query includeKey:@"createdAt"];
    [query includeKey:@"trip.publicTripDetail"];
    [query orderByDescending:@"createdAt"]; //TODO does this actually work?
    [query setLimit: self.limit];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.isLoading = NO;
        NSLog(@"%lu",(unsigned long)self.mapView.annotations.count);
        UIBarButtonItem *button = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(beginLoadingTrunks)];
        self.navigationItem.rightBarButtonItem = button;
        
        if(error)
        {
            NSLog(@"Error: %@",error);
            if (self.user == nil)
            {
                [self setTitleImage];
                
            } else
            {
                NSString *trunks = NSLocalizedString(@"Trunks",@"Trunks");
                NSString *s = NSLocalizedString(@"'s",@"'s");
                self.title = [NSString stringWithFormat:@"%@%@ %@", self.user.username, s,trunks];
            }
            [ParseErrorHandlingController handleError:error];
        }
        else
        {
            self.parseLocations = [[NSMutableArray alloc]init];
            for (PFObject *activity in objects)
            {
                Trip *trip = activity[@"trip"];
                if (trip.name != nil)
                {
                    [self.parseLocations addObject:trip];
                }
            }
            
            
            for (Trip *trip in self.parseLocations)
            {
                NSTimeInterval lastTripInterval = [self.lastOpenedApp timeIntervalSinceDate:trip.createdAt];
                NSTimeInterval lastPhotoInterval = [self.lastOpenedApp timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];
                CLLocation *location = [[CLLocation alloc]initWithLatitude:trip.lat longitude:trip.longitude];
                
                BOOL contains = NO;
                
                for (Trip* trunk in self.visitedTrunks){
                    if ([trunk.objectId isEqualToString:trip.objectId]){
                        contains = YES;
                    }
                }
                
                if (self.visitedTrunks.count == 0 || self.visitedTrunks){
                    contains = NO;
                }
                
                if (lastTripInterval < 0 && contains == NO)
                {
                    [self.haventSeens addObject:location];
                } else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil && contains == NO){
                    [self.haventSeens addObject:location];
                }
            }
            [self placeTrips];
        }
    }];
}

/**
 *  The user is following no one so we tell them to follow people
 *
 *
 */
- (void)displayFollowUserAlertIfNeeded {
    NSUInteger timesShown = [[[NSUserDefaults standardUserDefaults] valueForKey:@"shownFollowUserAlert"] integerValue];
    if (!timesShown) {
        timesShown = 1;
    }
    // Show it every other time. After a few visits, then we'll pester them because they need to add friends.
    if (timesShown != 2 && timesShown != 4 && timesShown != 6 && timesShown != 8) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Follow Some Users",@"Follow Some Users") message:NSLocalizedString(@"TripTrunk is more fun with friends. Start following some users now!",@"TripTrunk is more fun with friends. Start following some users now!") delegate:self cancelButtonTitle:NSLocalizedString(@"Not Now",@"Not Now") otherButtonTitles:NSLocalizedString(@"Okay",@"Okay"), nil];
            [alertView show];
        });
    }
    timesShown++;
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:timesShown] forKey:@"shownFollowUserAlert"];
}

/**
 *  Zoom the map out
 *
 *
 */
- (IBAction)zoomOut:(id)sender {
    self.mapView.camera.altitude *= 3.5;
    
    
}

/**
 *  Place the trunks we got from parse on the map
 *
 *
 */
-(void)placeTrips
{
    //self.parselocations contains the trips we just pulled down from parse
    for (Trip *trip in self.parseLocations)
    {
        NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
        
        //TODO we should save the location not the address
        
        //find the last time a user added a photo to this trunk. If it is less than 24 hours the trunk on the map needs to be red instead of blue
        NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];
        
        BOOL color = 0;
        if (tripInterval < 86400)
        {
            color = 1;
        } else{
            color = 0;
        }
        //we make sure that we havent already placed a pin on a city. If the trunk is red (hot) then we place it anyways since we always want red pins showing
        if(![self.tripsToCheck containsObject:address] || color == 1)
        {
            
            if ([trip.name isEqualToString:@"Mike Test"]){
                NSLog(@"stip");
            }
            
            //if this is a user profile we zoom to show the most recent trunk on the map
            if (self.user && trip == [self.parseLocations objectAtIndex:0] && self.isFirstUserLoad == YES) {
                self.isFirstUserLoad = NO;
                [self addTripToMap:trip dot:color isMostRecent:YES needToDelete:NO];
            } else{
                [self addTripToMap:trip dot:color isMostRecent:NO needToDelete:NO];
            }
        } else {
            //we want a tally of the trunks we dropped and didn't drop on the map, this allows us to know when to zoom out the map
            self.notDropped = self.notDropped +1;
        }
    }
    
    
    [self.mapView removeAnnotations:self.annotationsToDelete];
    self.annotationsToDelete = [[NSMutableArray alloc]init];
}


/**
 *  Turn the trunk into a map annotation and place it on the map
 *
 *
 */
-(void)addTripToMap:(Trip*)trip dot:(BOOL)hot isMostRecent:(BOOL)isMostRecent needToDelete:(BOOL)replace;
{
    //we do this to make sure we dont place two pins down for a city
    NSString *string = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
    
    [self.tripsToCheck addObject:string]; //needs to be location not string
    
    //make the title of the pin for when you touch it
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
    annotation.title = trip.city;
    
    //make sure its a valid trip
    if (trip.longitude != 0 && trip.longitude != 0){
        annotation.coordinate = CLLocationCoordinate2DMake(trip.lat, trip.longitude);
        [self createTripForMap:trip dot:hot isMostRecent:isMostRecent annotation:annotation needToSave:NO delete:replace];
    }
    //if not, find its locations to make it valid through apple and then save it
    else
    {
        CLGeocoder *geocoder = [[CLGeocoder alloc]init];
        [geocoder geocodeAddressString:string completionHandler:^(NSArray *placemarks, NSError *error)
         {
             if (!error)
             {
                 CLPlacemark *placemark = placemarks.firstObject;
                 MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
                 annotation.coordinate = placemark.location.coordinate;
                 annotation.title = trip.city;
                 trip.lat = placemark.location.coordinate.latitude;
                 trip.longitude = placemark.location.coordinate.longitude;
                 [self createTripForMap:trip dot:hot isMostRecent:isMostRecent annotation:annotation needToSave:YES delete:replace];
             }
             
         }];
    }
}

-(void)createTripForMap:(Trip*)trip dot:(BOOL)hot isMostRecent:(BOOL)isMostRecent annotation:(MKPointAnnotation*)annotation needToSave:(BOOL)isNeeded delete:(BOOL)replace{
    
    
    //if were placing a new trip over an old one we need to remove the old one from the map to prevent it from ever showing. If you dont do this it will toggle between the old and new trunk when the user touches it
    
        if (isMostRecent == YES){
            self.annotationPinToZoomOn = annotation;
            
            if (self.user){
                if (replace == YES){
                    for (MKPointAnnotation *pnt in self.mapView.annotations){
                        if (pnt.coordinate.latitude == annotation.coordinate.latitude && pnt.coordinate.longitude == annotation.coordinate.longitude){
                            [self.mapView removeAnnotation:pnt];
                        }
                    }
                }
                [self zoomInOnNewPin];
            }
    }
    
    //if hot (meaning the trunk has had a photo added in less than 24 hours) then we place it on the map no matter what
    if (hot == YES)
    {
        if (replace == YES){
            for (MKPointAnnotation *pnt in self.mapView.annotations){
                if (pnt.coordinate.latitude == annotation.coordinate.latitude && pnt.coordinate.longitude == annotation.coordinate.longitude){
                    [self.mapView removeAnnotation:pnt];
                }
            }
        }
        [self.hotDots addObject:annotation.title];
        [self.mapView addAnnotation:annotation];
        
    }
    // if hot is no and we haven't already placed a hot trunk down on that city then we add the pin to the map
    else if (hot == NO && ![self.hotDots containsObject:annotation.title]) {
        if (replace == YES){
            for (MKPointAnnotation *pnt in self.mapView.annotations){
                if (pnt.coordinate.latitude == annotation.coordinate.latitude && pnt.coordinate.longitude == annotation.coordinate.longitude){
                    [self.mapView removeAnnotation:pnt];
                }
            }
        }
        [self.mapView addAnnotation:annotation];
    }else {
    }
    
    self.dropped = self.dropped + 1;
    
    //if we placed all the correct pins we're done
    if (self.dropped + self.notDropped == self.parseLocations.count){
        self.dropped = 0;
        self.notDropped = 0;
        if (self.user == nil){
            [self setTitleImage];
            
        } else {
            NSString *trunks = NSLocalizedString(@"Trunks",@"Trunks");
            NSString *s = NSLocalizedString(@"'s",@"'s");
            self.title = [NSString stringWithFormat:@"%@%@ %@", self.user.username, s,trunks];
        }
    }
    
    if (isNeeded == YES){
        [self.needsUpdates addObject:trip];
    }
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
    
    view.layer.zPosition = 1;
    
    [self.mapView setRegion:region animated:YES];
}



- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *startAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startpin"];
    startAnnotation.canShowCallout = YES;
    BOOL hasSeen = NO;
    for (CLLocation *loc in self.haventSeens){ //Save trip instead
        if ((float)loc.coordinate.longitude == (float)annotation.coordinate.longitude && (float)loc.coordinate.latitude == (float)annotation.coordinate.latitude){
            hasSeen = YES;
        }
    }
    
    
    
    
    //if the trunk is in the hotDots (meaning its hot) then make it red
    if ([self.hotDots containsObject:annotation.title]) {
        if (hasSeen == NO){
            startAnnotation.image = [UIImage imageNamed:@"redMapCircle"];
        }else {
            startAnnotation.image = [UIImage imageNamed:@"redTrunk"];
            
        }
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);
        startAnnotation.alpha = 1.0;
        //        [[startAnnotation superview] bringSubviewToFront:startAnnotation];
        startAnnotation.layer.zPosition = 1;
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, startAnnotation.frame.size.width*1.1, startAnnotation.frame.size.height*1.1);
        
    } else {
        if (hasSeen == NO){
            startAnnotation.image = [UIImage imageNamed:@"blueMapCircle"];
        }else {
            startAnnotation.image = [UIImage imageNamed:@"blueTrunk"];
            
        }
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);
        startAnnotation.alpha = 1.0;
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
    

    return startAnnotation;
}

/**
 *  Zoom to show all the pins on the map
 *
 *
 */
-(void)fitPins
{
    self.mapView.camera.altitude *= 1.0;
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}

//FIXME: Lets use the array of parselocations here
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // TODO: Get the state in a more elloquent way. This is hacky.
    //    view.enabled = NO;
    //    view.selected = YES;
    
    //    CLGeocoder *cod = [[CLGeocoder alloc] init];
    self.location = [[CLLocation alloc] initWithCoordinate:view.annotation.coordinate altitude:0 horizontalAccuracy:0 verticalAccuracy:0 timestamp:self.today];
    
    self.pinCityName = view.annotation.title;
    [self performSegueWithIdentifier:@"Trunk" sender:self];
    self.pinCityName = nil;
    self.pinStateName = nil;
    self.photoPin = view;
    
    
    //    [cod reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
    //
    //        if (!error){
    //            CLPlacemark *placemark = [placemarks firstObject];
    //            self.pinCityName = view.annotation.title;
    //            self.pinStateName = placemark.administrativeArea;
    //            [self performSegueWithIdentifier:@"Trunk" sender:self];
    //            self.pinCityName = nil;
    //            self.pinStateName = nil;
    //            self.photoPin = view;
    //            view.enabled = YES;
    //            view.selected = NO;
    //
    //
    //        } else {
    //            view.enabled = YES;
    //            view.selected = NO;
    //
    //        }
    //    }];
}


#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (Trip *trip in self.needsUpdates) {
            NSNumber *lat = [NSNumber numberWithDouble: trip.lat];
            NSNumber *lon = [NSNumber numberWithDouble: trip.longitude];
            [PFCloud callFunctionInBackground:@"updateTrunkLocation"
                               withParameters:@{@"latitude": lat, @"longitude": lon, @"tripId": trip.objectId}
                                        block:^(NSString *response, NSError *error) {
                                            if (!error) {
                                                NSLog(@"%@ upadated with lat %@ and long %@", trip.name, lat, lon);
                                            }
                                            else {
                                                NSLog(@"Error for %@ : %@", trip.name, error);
                                            }
                                        }];
        }
        
    });
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Trunk"])
    {
        TrunkListViewController *trunkView = segue.destinationViewController;
        trunkView.city = self.pinCityName;
        //        trunkView.state = self.pinStateName;
        trunkView.location = self.location;
        trunkView.user = self.user;
        self.pinCityName = nil;
    }
}


#pragma mark - Tutorial Management
-(void)showTutorial
{
    //Show Tutorial View Controller to User
    TutorialViewController *tutorialVC = [[TutorialViewController alloc] initWithNibName:@"TutorialViewController" bundle:nil];
    [self.navigationController presentViewController:tutorialVC	 animated:YES completion:nil];
    self.compassRose.hidden = NO;
    
}

// This is needed for the login to work properly
// DO NOT DELETE
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}

-(void)updateTrunkColor:(Trip *)trip isHot:(BOOL)isHot member:(BOOL)isMember
{
    BOOL isOnThisMap = NO;
    NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
    int count = 0;
    //make sure self.parseLocation contains this trip to avoid adding it to incorrect maps
    for (Trip *trunk in self.parseLocations)
    {
        if ([trunk.objectId isEqualToString:trip.objectId])
        {
            isOnThisMap = YES;
            
            [self.hotDots removeObject:trip.city];
            [self.tripsToCheck removeObject:address];
            
            CLLocation *deleteLoc = [[CLLocation alloc]init];
            for (CLLocation *loc in self.haventSeens)
            {
                if (trunk.lat == loc.coordinate.latitude && trunk.longitude == loc.coordinate.longitude)
                {
                    deleteLoc = loc;
                }
            }
            [self.haventSeens removeObject:deleteLoc];
            
            if (isHot == YES){
                [self addTripToMap:trip dot:YES isMostRecent:YES needToDelete:YES];
            } else {
                
                for (Trip *tripSaved in self.parseLocations)
                {
                    if (trip.longitude == tripSaved.longitude && trip.lat == tripSaved.lat && ![tripSaved.objectId isEqualToString:trip.objectId])
                    {
                        count += 1;
                        NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:tripSaved.publicTripDetail.mostRecentPhoto];
                        
                        BOOL color = 0;
                        if (tripInterval < 86400)
                        {
                            color = 1;
                        } else{
                            color = 0;
                        }
                        
                        //find how much time has passed since the trunk was made and when the current user last opened the app
                        NSTimeInterval lastTripInterval = [self.lastOpenedApp timeIntervalSinceDate:tripSaved.createdAt];
                        
                        //find how much time has passed since the trunk had a photo added and when the current user last opened the app
                        NSTimeInterval lastPhotoInterval = [self.lastOpenedApp timeIntervalSinceDate:tripSaved.publicTripDetail.mostRecentPhoto];
                        
                        //put the trip data into a CLLocation
                        CLLocation *location = [[CLLocation alloc]initWithLatitude:tripSaved.lat longitude:tripSaved.longitude];
                        
                        //if the lastTripInterval is less than 0 is means the user hasn't seen the trunk because they haven't been in the app since it was made
                        if (lastTripInterval < 0)
                        {
                            [self.haventSeens addObject:location];
                        }
                        //if the lastPhotoInterval is less than 0 is means the user hasn't seen the new photo because they haven't been in the app since it was added
                        else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil)
                        {
                            [self.haventSeens addObject:location];
                        }
                        
                        [self addTripToMap:tripSaved dot:color isMostRecent:NO needToDelete:YES];
                    }
                }
            }
        }
    }

        //this trip isn't in self.parseLocations, so we're adding a new trip to the map and not updating one.
        //TODO Currently this only applies to current users map and newsfeed. We should do it to any users also a member of this trunk
        if (isOnThisMap == NO && isMember == YES){
            [self.parseLocations addObject:trip];
            [self addTripToMap:trip dot:isHot isMostRecent:YES needToDelete:YES];
        } else if (isOnThisMap == YES && count == 0){
            [self addTripToMap:trip dot:isHot isMostRecent:YES needToDelete:YES];
        }
    }

-(void)checkToDeleteCity:(CLLocation *)location trip:(Trip *)trip
{
    //check if this map has this trip
    
    for (Trip *trunk in self.parseLocations){
        if ([trunk.objectId isEqualToString:trip.objectId]){
            
            for (MKPointAnnotation *pin in self.mapView.annotations)
            {
                if (pin.coordinate.latitude == trip.lat && trip.longitude == location.coordinate.longitude){
                    
                    [self.mapView removeAnnotation:pin];
                }
            }
            
            NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
            
            [self.tripsToCheck removeObject:address];
            [self.hotDots removeObject:trip.city];
            
            CLLocation *deleteLoc = [[CLLocation alloc]init];
            for (CLLocation *loc in self.haventSeens)
            {
                if (trip.lat == loc.coordinate.latitude && trip.longitude == location.coordinate.longitude)
                {
                    deleteLoc = loc;
                }
            }
            [self.haventSeens removeObject:deleteLoc];
            
            for (Trip *tripSaved in self.parseLocations)
            {
                if (trip.longitude == tripSaved.longitude && trip.lat == tripSaved.lat && ![tripSaved.objectId isEqualToString:trip.objectId])
                {
                    
                    NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:tripSaved.publicTripDetail.mostRecentPhoto];
                    
                    BOOL color = 0;
                    if (tripInterval < 86400)
                    {
                        color = 1;
                    } else{
                        color = 0;
                    }
                    
                    //find how much time has passed since the trunk was made and when the current user last opened the app
                    NSTimeInterval lastTripInterval = [self.lastOpenedApp timeIntervalSinceDate:tripSaved.createdAt];
                    
                    //find how much time has passed since the trunk had a photo added and when the current user last opened the app
                    NSTimeInterval lastPhotoInterval = [self.lastOpenedApp timeIntervalSinceDate:tripSaved.publicTripDetail.mostRecentPhoto];
                    
                    //put the trip data into a CLLocation
                    CLLocation *location = [[CLLocation alloc]initWithLatitude:tripSaved.lat longitude:tripSaved.longitude];
                    
                    //if the lastTripInterval is less than 0 is means the user hasn't seen the trunk because they haven't been in the app since it was made
                    if (lastTripInterval < 0)
                    {
                        [self.haventSeens addObject:location];
                    }
                    //if the lastPhotoInterval is less than 0 is means the user hasn't seen the new photo because they haven't been in the app since it was added
                    else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil)
                    {
                        [self.haventSeens addObject:location];
                    }
                    
                    [self addTripToMap:tripSaved dot:color isMostRecent:NO needToDelete:YES];
                }
            }
        }
    }
    
    [self.parseLocations removeObject:trip];
    
}


-(void)deleteTrunk:(CLLocation *)location trip:(Trip *)trip{
    
    for (MKPointAnnotation *pin in self.mapView.annotations)
    {
        if (pin.coordinate.latitude == location.coordinate.latitude && pin.coordinate.longitude == location.coordinate.longitude){
            
            
            [self.mapView removeAnnotation:pin];
            self.mapView.camera.altitude *= 3.5;
            self.mapView.camera.altitude *= 3.5;
            
        }
    }
}

- (IBAction)addMoreTrunks:(id)sender {
    if (self.limit < 100){
        self.limit = self.limit + 250;
    } else if (self.limit < 300){
        self.limit = self.limit + 400;
    }
    [self beginLoadingTrunks];
}

- (IBAction)compassTaped:(id)sender {
    self.compassRose.hidden = !self.compassRose.hidden;
}

-(void)dontRefreshMap{
    self.dontRefresh = YES;
}

-(void)addTripToViewArray:(Trip *)trip{
    
    BOOL isOnThisMap = NO;
    NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
    int count = 0;
    //make sure self.parseLocation contains this trip to avoid adding it to incorrect maps
    for (Trip *trunk in self.parseLocations)
    {
        if ([trunk.objectId isEqualToString:trip.objectId])
        {
            isOnThisMap = YES;
            
            [self.hotDots removeObject:trip.city];
            [self.tripsToCheck removeObject:address];
            
            CLLocation *deleteLoc = [[CLLocation alloc]init];
            for (CLLocation *loc in self.haventSeens)
            {
                if (trunk.lat == loc.coordinate.latitude && trunk.longitude == loc.coordinate.longitude)
                {
                    deleteLoc = loc;
                }
            }
            [self.haventSeens removeObject:deleteLoc];
            
            for (Trip *tripSaved in self.parseLocations)
            {
                if (trip.longitude == tripSaved.longitude && trip.lat == tripSaved.lat)
                {
                    count += 1;
                    NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:tripSaved.publicTripDetail.mostRecentPhoto];
                    
                    BOOL color = 0;
                    if (tripInterval < 86400)
                    {
                        color = 1;
                    } else{
                        color = 0;
                    }
                    
                    [self addTripToMap:tripSaved dot:color isMostRecent:NO needToDelete:YES];
                }
            }
        }
    }
    
}

@end










