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
#import "TTNewsFeedViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TTAnalytics.h"
#import "EditProfileViewController.h"
#import "TrunkViewController.h"
#import "AppDelegate.h"

/**
 HomeViewController displays trips on a map. Can be used on the user's "home" map, where all their friend's trips are shown, or can be used on a profile, which shows just that user's trips.
 */
@interface HomeMapViewController () <MKMapViewDelegate,NewsDelegate>

/**
 The map from Apple that has the trips displayed over it
 */
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

/**
 The trip objects we are given back from the database. They will either be the trips of one user (for their profile) or the trips of all the curren't user's friends
 */
@property NSMutableArray *trips;

/**
 Stores each trip thats placed on the map. If a trunk shares the same city as one in this array then we dont put the trunk here. This prevents us dropping multiple pins on the same city
 */
@property NSMutableArray *tripsOnMap;

/**
 Stores cities with hot trips, meaning they need to be red and a photo has been added their the last 24 hours
 */
@property NSMutableArray *hotTrips;

/**
 City name of the map pin (dot) selected
 */
@property NSString *cityNameFromMapPin; //FIXME this shouldnt be needed

/**
 State name of the map pin (dot) selected
 */
@property NSString *stateNameFromMapPin; //FIXME this shouldnt be needed

/**
 How many trips have been dropped on the map
 */
@property int tripsPlacedOnMapCount; //FIXME This shouldn't be needed

/**
 How many trips have been skipped, not dropping them on the map, due to a pin already being on the map in that city
 */
@property int tripsNotPlacedOnMapCount;

/**
 Today's Date
 */
@property NSDate *today;

/**
 contains the users that the current user is following.
 */
@property NSMutableArray *friends;

/**
list of trips the user hasn't seen since last being in the app
 */
@property NSMutableArray *unseenTrips; //fixme should be in utility class

/**
 location of the pin that has been selected
 */
@property CLLocation *location; //FIXME the way we get this value is hacky, we should take the trips long and lat and pass it here instead of getting the annotations long and lat

/**
 Each viewDidAppear we reload the trunks from parse with a query to get the most recent list of trunks and updates. We leave the old set of map locations in this array. Once we finish placing the new pins, we use this array to remove all the old ones. It prevents the user from ever seeing a blank map (excluding the original load)
 */
@property NSArray<id<MKAnnotation>> *annotationsToDelete;

/**
 we don't want the user querying multiple requests to refresh the map. This bool will prevent that.
 */
@property BOOL isQueryingTrips;

/**
 the limit of how many trips we load from the database
 */
@property int tripLimit;

/**
 The date the user last oppened the app to put the logo on certain trunks
*/
@property NSDate *lastOpenedApp;

/**
 Don't refresh the map. See method "dontRefreshMapOnViewDidAppear" in HomeViewController.h for more info
 */
@property BOOL preventMapRefresh;

/**
 is this the first time the current user has viewed this user profile during this session? We use this BOOL to prevent from zooming in on the most recent trunk every single time this view appears. For example, I click Mike's profile. It zooms me in on his most recent trip in Captiva. If I click a trip in Las Vegas from Mikes map in then click back this BOOL prevents the map from once again zooming in on Captiva.
 */
@property BOOL isFirstTimeViewingProfile;

/**
 the annotation the user selected and that needs to be zoomed in on
 */
@property MKPointAnnotation* annotationPinToZoomOn;

/**
 trunks the user has visited. Not to be confused with viewedTrips.
 */
@property NSMutableArray *visitedTrunks; //FIXME this should be a class method handling this and less confusing

/**
 the list/newsfeed viewcontroller you can toggle to from the map
 */
@property TTNewsFeedViewController *newsVC; //FIXME this should be handlded differenlty

@property BOOL updateNeeded;

@end

@implementation HomeMapViewController

- (void)viewDidLoad {
    
    NSUserDefaults *uploadError = [NSUserDefaults standardUserDefaults];
    NSString *message = [uploadError stringForKey:@"uploadError"];
    
    if(message){
        NSString *continueMessage = NSLocalizedString(@"Would you like to continue uploading?",@"Would you like to continue uploading?");
        message = [NSString stringWithFormat:@"%@ %@",message,continueMessage];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Previous Session Upload" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                AddTripPhotosViewController *vc = (AddTripPhotosViewController *)[storyboard instantiateViewControllerWithIdentifier:@"AddTripViewController"];
            
                [self.navigationController showViewController:vc sender:self];
            }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            [uploadError setObject:nil forKey:@"uploadError"];
            [uploadError setObject:nil forKey:@"currentImageUpload"];
            [uploadError setObject:nil forKey:@"currentTripUpload"];
            [uploadError setObject:nil forKey:@"currentPhotoCaptions"];
            [uploadError synchronize];
        }];
        [alert addAction:yesAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    
    [super viewDidLoad];
    [self setArraysBoolsandDates];
}

-(void)viewDidAppear:(BOOL)animated {
    
    if([TTUtility checkForUpdate]){
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] logout];
    }
    
    if(![PFUser currentUser])
        [self.mapView removeAnnotations:self.mapView.annotations];
    self.visitedTrunks = [[NSMutableArray alloc]init]; //FIXME this should be a class method handling this
    [self setVisitedTrunks]; //FIXME this should be a class method handling this
    [self designNavBar];
    [self implementUserIntoMap];

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
        self.title = [NSString stringWithFormat:@"%@'s Trunks", self.user.username];
    }
    self.tabBarController.tabBar.translucent = false;
}

/**
 *  Sets up the arrays, bools, and dates used in this viewcontroller
 *
 *
 */
-(void)setArraysBoolsandDates{
    self.isFirstTimeViewingProfile = YES;
    self.viewedTrips = [[NSMutableArray alloc]init];
    self.viewedPhotos = [[NSMutableArray alloc]init];
    self.visitedTrunks =  [[NSMutableArray alloc]init];
    //contains map annotations of trips that need a red dot as opposed blue blue. They're red  because a user has added photos to them in the last 24 hours
    //TODO: THIS SHOULD SAVE THE LOCATION AND NOT THE CITY NAME. Possbily applicable to other arrays
    self.hotTrips = [[NSMutableArray alloc]init];
    //the trunks we pull down from parse
    self.trips = [[NSMutableArray alloc]init];
    //list of trunks the user hasn't seen since last being in the app
    self.unseenTrips = [[NSMutableArray alloc]init];
    [self setUpArrays];
    //we don't want the user loading multiple requests to refresh the map. This bool will prevent that.
    self.isQueryingTrips = NO;
    //we load 50 trunks from the database
    self.tripLimit = 50;
    //Each viewDidAppear we reload the trunks from parse with a query to get the most recent list of trunks and updates. We leave the old set of map locations in this array. Once we finish placing the new pins, we use this array to remove all the old ones. It prevents the user from ever seeing a blank map (excluding the original load)
    self.annotationsToDelete = [[NSMutableArray alloc]init];
    self.visitedTrunks = [[NSMutableArray alloc]init];
    //We need this to do the logic in determing if a user has seen a trunk and if a trunk should be red or blue.
    self.today = [NSDate date];
    //we need the date the user last oppened the app to put the logo on certain trunks
    self.lastOpenedApp = [PFUser currentUser][@"lastUsed"];
}

/**
 *  Sets up which trunks have been visited by the user
 *
 *
 */
-(void)setVisitedTrunks{
    for (UINavigationController *controller in self.tabBarController.viewControllers){
        for (HomeMapViewController *view in controller.viewControllers){
            if ([view isKindOfClass:[HomeMapViewController class]]){
                if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                    self.visitedTrunks = view.viewedTrips;
                }
            }
        }
    }
}

/**
 *  Begins loading the map for either the Home Map or a User's Map
 *
 *
 */
-(void)implementUserIntoMap{
    //Make sure the user is logged in. If not we make them login. //FIXME This should be done in every viewcontroller through a parent class method
    if([self checkUserRegistration]){
//If self.user is nil then the user is looking at their home/newsfeed map. We want "everyone's" trunks that they follow, including themselves, from parse.
        if (self.user == nil) {
            //We're on the home taeb so register the user's notifications
                [self registerNotifications]; //fixme should be done in some time of parent class method
                //if were suppose to refresh the trips, then begin downlaoding trips from database
                if (self.preventMapRefresh == NO){
                    [self beginLoadingTrunks];
                } else {
                    if (self.annotationPinToZoomOn){
                        [self zoomInOnNewPin];
                    }
                    self.preventMapRefresh = NO;
            }
        } else {
            //If self.user is not nil then we are looking at a specific user's map. We just want that specific user's trunks from parse
            if (self.preventMapRefresh == NO){
                [self beginLoadingTrunks];
            } else {
                self.preventMapRefresh = NO;
            }
        }
    }
}

/**
 *  Zoom in on a map pin
 *
 *
 */
-(void)zoomInOnNewPin{
    CLLocationCoordinate2D center = self.annotationPinToZoomOn.coordinate;
    MKCoordinateSpan span;
    span.longitudeDelta = 3.5;
    span.latitudeDelta = 3.5;
    MKCoordinateRegion region;
    region.center = center;
    region.span = span;
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
    //we need the date the user last oppened the app to put the logo on certain trunks
    self.lastOpenedApp = [PFUser currentUser][@"lastUsed"];
    //the user doesnt have a query in progress to load the trunks already, so go ahead and load the trunks
    if (self.isQueryingTrips == NO){
        //save the current pins on the map so we can delete them once we place the new ones
        self.annotationsToDelete = self.mapView.annotations;
        [self setUpArrays];
        if (self.user == nil) {
            //If self.user is nil then the user is looking at their home/newsfeed map. We want "everyone's" trunks that they follow, including themselves, from parse.
            self.isQueryingTrips = YES;
            [self queryParseMethodEveryone];
            //We're on the home tab so register the user's notifications
            
        } else {
            //If self.user is not nil then we are looking at a specific user's map. We just want that specific user's trunks from parse
            self.isQueryingTrips = YES;
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
//we locate each trunk thats placed on the map here. If a trunk shares the same city as one in this array then we dont put the trunk here. This prevents us dropping multiple pins on the same city
    self.tripsOnMap = [[NSMutableArray alloc]init];
//the trunks we pull down from parse
    self.trips = [[NSMutableArray alloc]init];
  
}

/**
 *  Make the title the "TripTrunk" image
 *
 *
 */
- (void)setTitleImage {
    UIImageView* logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tripTrunkTitle"]];
    logoView.frame = CGRectMake(logoView.frame.origin.x, logoView.frame.origin.y,logoView.frame.size.width,self.navigationController.navigationBar.frame.size.height*.6);
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    UIView* titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, logoView.frame.size.width, logoView.frame.size.height)];
    logoView.frame = titleView.bounds;
    [titleView addSubview:logoView];
    self.navigationItem.titleView = titleView;
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
    //self.friends will contain the users that the current user is following.
    self.friends = [[NSMutableArray alloc]init];
    //add the current user to self.friends since we want the current user's trunks too
    [self.friends addObject:[PFUser currentUser]];
    
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error) {
            [[TTUtility sharedInstance] internetConnectionFound];
            
            //add the users to self.friends. Now its containing the current user and all the people they are following
            [self.friends addObjectsFromArray:users];
            
            //use parse to download the trunks of the current user and the users they are following
            [self queryForTrunks];
            
            if (users.count == 0) {
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
-(void)queryParseMethodForUser:(PFUser*)user{
    //Build an array to send up to CC
    NSMutableArray *friendsObjectIds = [[NSMutableArray alloc] init];
    //we only have a single user but we still need to add it to an array and send up the params
    [friendsObjectIds addObject:user.objectId];
    
    NSDictionary *params = @{
                             @"objectIds" : friendsObjectIds,
                             @"limit" : [NSString stringWithFormat:@"%d",self.tripLimit]
                             };
    [PFCloud callFunctionInBackground:@"queryForUniqueTrunks" withParameters:params block:^(NSArray *response, NSError *error) {
        if (!error) {
            //we finished loading so switch the bool and renable the refresh icon
            self.isQueryingTrips = NO;
            
            //If there is an error put the navBar title back to normal so that it isn't still telling the user we are loading the trunks.
            if(error)
            {
                NSLog(@"Error: %@",error);
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"queryParseMethodForUser:"];
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
                [[TTUtility sharedInstance] internetConnectionFound];
                self.trips = [[NSMutableArray alloc]init];
                for (PFObject *activity in response)
                {
                    Trip *trip = activity[@"trip"];
                    if (trip.name != nil && trip.publicTripDetail != nil)
                    {
                        [self.trips addObject:trip];
                    }
                    else if (trip.name !=nil && [trip.creator.objectId isEqualToString:[PFUser currentUser].objectId]){
                        [self.trips addObject:trip];
                        
                    }
                }
                [self sortTrips];
                
            }
        }
    }];

}

-(void)sortIntoHotOrNot{
    for (Trip *trip in self.trips)
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
            [self.unseenTrips addObject:location];
        } else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil && contains == NO){
            [self.unseenTrips addObject:location];
        }
    }
    [self placeTrips];
}


/**
 *  Load the trunks of the user's who the current user is following. We use the self.friends array to store their following.
 *
 */
-(void)queryForTrunks{
    //Build an array to send up to CC
    NSMutableArray *friendsObjectIds = [[NSMutableArray alloc] init];
    for(PFUser *friendObjectId in self.friends){
        // add just the objectIds to the array, no PFObjects can be sent as a param
        [friendsObjectIds addObject:friendObjectId.objectId];
    }
    
    NSDictionary *params = @{
                             @"objectIds" : friendsObjectIds,
                             @"limit" : [NSString stringWithFormat:@"%d",self.tripLimit]
                             };
    [PFCloud callFunctionInBackground:@"queryForUniqueTrunks" withParameters:params block:^(NSArray *response, NSError *error) {
        self.isQueryingTrips = NO;
        
        if(error)
        {
            NSLog(@"Error: %@",error);
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"queryForTrunks:"];
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
            [[TTUtility sharedInstance] internetConnectionFound];
            
            self.trips = [[NSMutableArray alloc]init];
            for (PFObject *activity in response)
            {
                Trip *trip = activity[@"trip"];
                if (trip.name != nil && trip.publicTripDetail != nil)
                {
                    [self.trips addObject:trip];
                }
            }
            
            
            [self sortTrips];
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
    //self.trips contains the trips we just pulled down from parse
    for (Trip *trip in self.trips)
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
        if(![self.tripsOnMap containsObject:address] || color == 1)
        {
            //if this is a user profile we zoom to show the most recent trunk on the map
            if (self.user && trip == [self.trips objectAtIndex:0] && self.isFirstTimeViewingProfile == YES) {
                self.isFirstTimeViewingProfile = NO;
                [self addTripToMap:trip dot:color isMostRecent:YES needToDelete:NO];
            } else{
                [self addTripToMap:trip dot:color isMostRecent:NO needToDelete:NO];
            }
        } else {
            //we want a tally of the trunks we dropped and didn't drop on the map, this allows us to know when to zoom out the map
            self.tripsNotPlacedOnMapCount = self.tripsNotPlacedOnMapCount +1;
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
    
    [self.tripsOnMap addObject:string]; //needs to be location not string
    
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
             }else{
                 [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"addTripToMap:"];
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
        
        if (annotation.title != nil){
            [self.hotTrips addObject:annotation.title];
            [self.mapView addAnnotation:annotation];
        }
    }
    // if hot is no and we haven't already placed a hot trunk down on that city then we add the pin to the map
    else if (hot == NO && ![self.hotTrips containsObject:annotation.title]) {
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
    
    self.tripsPlacedOnMapCount = self.tripsPlacedOnMapCount + 1;
    
    //if we placed all the correct pins we're done
    if (self.tripsPlacedOnMapCount + self.tripsNotPlacedOnMapCount == self.trips.count){
        self.tripsPlacedOnMapCount = 0;
        self.tripsNotPlacedOnMapCount = 0;
        if (self.user == nil){
            [self setTitleImage];
            
        } else {
            NSString *trunks = NSLocalizedString(@"Trunks",@"Trunks");
            NSString *s = NSLocalizedString(@"'s",@"'s");
            self.title = [NSString stringWithFormat:@"%@%@ %@", self.user.username, s,trunks];
        }
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
    view.layer.zPosition = 1;
    
    [self.mapView setRegion:region animated:YES];
}



- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *startAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"startpin"];
    startAnnotation.canShowCallout = YES;
    
    BOOL hasSeen = YES;
    for (CLLocation *loc in self.unseenTrips){ //Save trip instead
        if ((float)loc.coordinate.longitude == (float)annotation.coordinate.longitude && (float)loc.coordinate.latitude == (float)annotation.coordinate.latitude){
            hasSeen = NO;
        }
    }
    
    for (Trip *trip in self.visitedTrunks){
        if ((float)trip.longitude == (float)annotation.coordinate.longitude && (float)trip.lat == (float)annotation.coordinate.latitude){
            hasSeen = YES;
        }
    }
    
    
    
    //if the trunk is in the hotTrips (meaning its hot) then make it red
    if ([self.hotTrips containsObject:annotation.title]) {
        if (hasSeen == NO){
            startAnnotation.image = [UIImage imageNamed:@"unseenRedCircle"];
        }else {
            startAnnotation.image = [UIImage imageNamed:@"seenRedCircle"];
            
        }
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, 25, 25);
        startAnnotation.alpha = 1.0;
        //        [[startAnnotation superview] bringSubviewToFront:startAnnotation];
        startAnnotation.layer.zPosition = 1;
        startAnnotation.frame = CGRectMake(startAnnotation.frame.origin.x, startAnnotation.frame.origin.y, startAnnotation.frame.size.width*1.0, startAnnotation.frame.size.height*1.0);
        
    } else {
        if (hasSeen == NO){
            startAnnotation.image = [UIImage imageNamed:@"unseenBlueCircle"];
        }else {
            startAnnotation.image = [UIImage imageNamed:@"seenBlueCircle"];
            
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

//FIXME: Lets use the array of trips here
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    self.location = [[CLLocation alloc] initWithCoordinate:view.annotation.coordinate altitude:0 horizontalAccuracy:0 verticalAccuracy:0 timestamp:self.today];
    
    self.cityNameFromMapPin = view.annotation.title;
    [self performSegueWithIdentifier:@"Trunk" sender:self];
    self.cityNameFromMapPin = nil;
    self.stateNameFromMapPin = nil;
}


#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}

-(void)viewWillAppear:(BOOL)animated{
    if (self.user == nil){
        [self createLeftButtons];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    
    self.navigationItem.leftBarButtonItem = nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Trunk"])
    {
        TrunkListViewController *trunkView = segue.destinationViewController;
        trunkView.city = self.cityNameFromMapPin;
        //        trunkView.state = self.stateNameFromMapPin;
        trunkView.location = self.location;
        trunkView.user = self.user;
        self.cityNameFromMapPin = nil;
    }
}


// This is needed for the login to work properly
// DO NOT DELETE
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}

-(void)updateTripColorOnMap:(Trip *)trip isHot:(BOOL)isHot member:(BOOL)isMember
{
    BOOL isOnThisMap = NO;
    NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
    int count = 0;
    //make sure self.parseLocation contains this trip to avoid adding it to incorrect maps
    for (Trip *trunk in self.trips)
    {
        if ([trunk.objectId isEqualToString:trip.objectId])
        {
            isOnThisMap = YES;
            
            [self.hotTrips removeObject:trip.city];
            [self.tripsOnMap removeObject:address];
            
            CLLocation *deleteLoc = [[CLLocation alloc]init];
            for (CLLocation *loc in self.unseenTrips)
            {
                if (trunk.lat == loc.coordinate.latitude && trunk.longitude == loc.coordinate.longitude)
                {
                    deleteLoc = loc;
                }
            }
            [self.unseenTrips removeObject:deleteLoc];
            
            if (isHot == YES){
                [self addTripToMap:trip dot:YES isMostRecent:YES needToDelete:YES];
            } else {
                
                for (Trip *tripSaved in self.trips)
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
                            [self.unseenTrips addObject:location];
                        }
                        //if the lastPhotoInterval is less than 0 is means the user hasn't seen the new photo because they haven't been in the app since it was added
                        else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil)
                        {
                            [self.unseenTrips addObject:location];
                        }
                        
                        [self addTripToMap:tripSaved dot:color isMostRecent:NO needToDelete:YES];
                    }
                }
            }
        }
    }

        //this trip isn't in self.trips, so we're adding a new trip to the map and not updating one.
        //TODO Currently this only applies to current users map and newsfeed. We should do it to any users also a member of this trunk
        if (isOnThisMap == NO && isMember == YES){
            [self.trips addObject:trip];
            [self addTripToMap:trip dot:isHot isMostRecent:YES needToDelete:YES];
        } else if (isOnThisMap == YES && count == 0){
            [self addTripToMap:trip dot:isHot isMostRecent:YES needToDelete:YES];
        }
    }

-(void)updateCityPinOnMap:(CLLocation *)location trip:(Trip *)trip
{
    //check if this map has this trip
    
    for (Trip *trunk in self.trips){
        if ([trunk.objectId isEqualToString:trip.objectId]){
            
            for (MKPointAnnotation *pin in self.mapView.annotations)
            {
                if (pin.coordinate.latitude == trip.lat && trip.longitude == location.coordinate.longitude){
                    
                    [self.mapView removeAnnotation:pin];
                }
            }
            
            NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
            
            [self.tripsOnMap removeObject:address];
            [self.hotTrips removeObject:trip.city];
            
            CLLocation *deleteLoc = [[CLLocation alloc]init];
            for (CLLocation *loc in self.unseenTrips)
            {
                if (trip.lat == loc.coordinate.latitude && trip.longitude == location.coordinate.longitude)
                {
                    deleteLoc = loc;
                }
            }
            [self.unseenTrips removeObject:deleteLoc];
            
            for (Trip *tripSaved in self.trips)
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
                        [self.unseenTrips addObject:location];
                    }
                    //if the lastPhotoInterval is less than 0 is means the user hasn't seen the new photo because they haven't been in the app since it was added
                    else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil)
                    {
                        [self.unseenTrips addObject:location];
                    }
                    
                    [self addTripToMap:tripSaved dot:color isMostRecent:NO needToDelete:YES];
                }
            }
        }
    }
    
    [self.trips removeObject:trip];
    
}


-(void)removeCityFromMap:(CLLocation *)location trip:(Trip *)trip{
    
    for (MKPointAnnotation *pin in self.mapView.annotations)
    {
        if (pin.coordinate.latitude == location.coordinate.latitude && pin.coordinate.longitude == location.coordinate.longitude){
            
            
            [self.mapView removeAnnotation:pin];
            self.mapView.camera.altitude *= 3.5;
            self.mapView.camera.altitude *= 3.5;
            
        }
    }
}

-(void)dontRefreshMapOnViewDidAppear{
    self.preventMapRefresh = YES;
}

-(void)userHasViewedTrip:(Trip *)trip{
    
    BOOL isOnThisMap = NO;
    NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
    int count = 0;
    //make sure self.parseLocation contains this trip to avoid adding it to incorrect maps
    for (Trip *trunk in self.trips)
    {
        if ([trunk.objectId isEqualToString:trip.objectId])
        {
            isOnThisMap = YES;
            
            [self.hotTrips removeObject:trip.city];
            [self.tripsOnMap removeObject:address];
            
            CLLocation *deleteLoc = [[CLLocation alloc]init];
            for (CLLocation *loc in self.unseenTrips)
            {
                if (trunk.lat == loc.coordinate.latitude && trunk.longitude == loc.coordinate.longitude)
                {
                    deleteLoc = loc;
                }
            }
            [self.unseenTrips removeObject:deleteLoc];
            
            for (Trip *tripSaved in self.trips)
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


//Now creates right
-(void)createLeftButtons{
 
    self.navigationItem.leftBarButtonItem = nil;
    UIImage *image = [UIImage imageNamed:@"newspaper"];
    CGRect buttonFrame = CGRectMake(0, 0, 27, 25);
    
    UIButton *bttn = [[UIButton alloc] initWithFrame:buttonFrame];
    [bttn addTarget:self action:@selector(switchToTimeline) forControlEvents:UIControlEventTouchUpInside];
    [bttn setImage:image forState:UIControlStateNormal];
    [bttn setImage:image forState:UIControlStateHighlighted];
    [bttn setImage:image forState:UIControlStateSelected];
    
    UIBarButtonItem *buttonOne= [[UIBarButtonItem alloc] initWithCustomView:bttn];

    self.navigationItem.rightBarButtonItem = buttonOne;

}

-(void)switchToTimeline{

    if (self.newsVC == nil){
        self.newsVC = [[TTNewsFeedViewController alloc]init];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        TTNewsFeedViewController *news = (TTNewsFeedViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTNews"];
        news.delegate = self;
        [self.navigationController pushViewController:news animated:NO];
    }
     else {
        [self.navigationController pushViewController:self.newsVC animated:NO];

    }
    
    
}

-(void)backWasTapped:(id)sender{
    self.newsVC = (TTNewsFeedViewController*)sender;
}

-(void)sortTrips{
    
    NSMutableArray *copiedTrunks = [[NSMutableArray alloc] init];
    NSMutableArray *tempArray1 = [[NSMutableArray alloc] init];
    NSArray *tempArray2 = [[NSArray alloc] init];
    NSMutableArray *sortedTrunks = [[NSMutableArray alloc] init];
    
    copiedTrunks = self.trips;
    
    // sort by recent photos
    for (Trip *aTrip in copiedTrunks) {
        NSDate *photoTimeStamp = aTrip.publicTripDetail.mostRecentPhoto;
        if (!photoTimeStamp) {
            photoTimeStamp = aTrip.publicTripDetail.createdAt;
        }
        double timeDiff =[photoTimeStamp timeIntervalSinceNow];
        
        NSDictionary *aTripDict = [[NSDictionary alloc]initWithObjectsAndKeys:aTrip,@"trip",@(fabs(timeDiff)),@"timeValue", nil];
        
        [tempArray1 addObject:aTripDict];
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"timeValue"  ascending:YES];
    tempArray2 = [[NSArray arrayWithArray:tempArray1] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    
    for (NSDictionary *aTripDict in tempArray2) {
        [sortedTrunks addObject:aTripDict[@"trip"]];
    }
    
    self.trips = sortedTrunks;
    
    [self sortIntoHotOrNot];
    
}

- (IBAction)luggageWasTapped:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkListViewController *vc = (TrunkListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkList"];
    vc.user = self.user;
    vc.isList = YES;
    [self.navigationController pushViewController:vc animated:YES];

}

@end










