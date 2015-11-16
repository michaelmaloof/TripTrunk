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
@property BOOL tutorialComplete;
@property NSMutableArray *needsUpdates;
@property NSMutableArray *haventSeens;


@end

@implementation HomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self designNavBar];
    [self setUpArrays];
    
//This is an old feature that has been removed. It used to let you filter between your trunks and your newsfeeed trunks. We left the code but hide the button in case we ever want this feature
    self.mapFilter.hidden = YES;
    
//TODOSTILL How do I access the hometown property? Also, this should be saved as a geopoint and name
//NSString *hometown = [[PFUser currentUser] objectForKey:@"hometown"];
    
//Require users to agree to the terms and conditions
    [self ensureEULA];
    
}

-(void)viewDidAppear:(BOOL)animated {
//    if(![PFUser currentUser] || ![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
   self.needsUpdates = nil;
    self.needsUpdates = [[NSMutableArray alloc]init];

//Make sure the user is logged in. If not we make them login.
    if([self checkUserRegistration])
    {
        
        //COMMENETED OUT UNTIL AJ MAKES DEISNGS
        //If user has not completed tutorial, show tutorial
//        self.tutorialComplete = [[[PFUser currentUser] valueForKey:@"tutorialViewed"] boolValue];
//        if (self.tutorialComplete == NO)
//        {
//            [self showTutorial];
//        }
        
        if (self.user == nil) {
            
//If self.user is nil then the user is looking at their home/newsfeed map. We want "everyone's" trunks that they follow, including themselves, from parse.
            [self queryParseMethodEveryone];
//We're on the home tab so register the user's notifications
            [self registerNotifications];
            
        } else {
//If self.user is not nil then we are looking at a specific user's map. We just want that specific user's trunks from parse
            [self queryParseMethodForUser:self.user];
        }
    }
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
//TODO We should have TripTrunk blue be in a font class
    [self.tabBarController.tabBar setTintColor:[UIColor colorWithRed:(95.0/255.0) green:(148.0/255.0) blue:(172.0/255.0) alpha:1]];
}

/**
 *  Create the arrays we need for the map
 *
 *
 */
-(void)setUpArrays{
//we locate each trunk thats placed o nthe map here. If a trunk shares the same city as one in this array then we dont put the trunk here. This prevents us dropping multiple pins on the same city
    self.tripsToCheck = [[NSMutableArray alloc]init];
    
//containts map annotations of trips that need a red dot as opposed blue blue. They're red  because a user has added photos to them in the last 24 hours
    self.hotDots = [[NSMutableArray alloc]init];
    
//the locations we place on the map
    self.locations = [[NSMutableArray alloc]init];
    
//the trunks we pull down from parse
    self.parseLocations = [[NSMutableArray alloc]init];
  

//This just contains the trunk that the current user just made. It needs an array for the map to zoom to. Idk why. There is probably a better way to do that.
    self.justMadeTrunk = [[NSMutableArray alloc]init];
    
//the list of trunks we place on the map originally. We compare this to the trunks will pull down on the view did appear to see if we need to place down new pins
    self.originalArray = [[NSMutableArray alloc]init];
    
    self.isNew= NO;
    
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
 *  Load the trunks of a specific user from the trunk since we are looking at a user's profile
 *
 *
 */
-(void)queryParseMethodForUser:(PFUser*)user
{
//We want to know if we have already loaded trunks from parse
    if (self.loadedOnce == NO){
        self.loadedOnce = YES;
    }

//Query to get trunks only from the user whose profile we are on. We get trunks that they made and that they're members of
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query includeKey:@"trip"];
    [query includeKey:@"toUser"];
    [query includeKey:@"creator"];
    [query orderByDescending:@"createdAt"];
    [query setLimit: 10000];
    
    
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
//If we haven't loaded the user's trunks before then we tell the current user that we are loading in the title of the navBar
        if (self.loadedOnce == NO)
        {
            self.title = @"Loading Trunks...";
            self.loadedOnce = YES;
        }
        
        NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];


//If there is an error put the navBar title back to normal so that it isn't still tellign the user we are loading the trunks.
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
        else
        {
            int count = 0;
            self.parseLocations = [[NSMutableArray alloc]init];
            for (PFObject *activity in objects)
            {
                Trip *trip = activity[@"trip"];
//                PFUser *user = activity[@"toUser"];
                
//We make sure the trip has a name. Old trips in the database could be nil for the names. We want to filter these out
                if (trip.name != nil)
                {
                    [self.parseLocations addObject:trip];

                    NSTimeInterval lastTripInterval = [lastOpenedApp timeIntervalSinceDate:trip.createdAt];
                    CLLocation *location = [[CLLocation alloc]initWithLatitude:trip.lat longitude:trip.longitude];
                    if (lastTripInterval < 0)
                    {
                        [self.haventSeens addObject:location];
                    }
                    
                }
                
//If we've finished the for loop then we place the trips we loaded from parse to the map. Honestly the count isnt needed but I left it here.
                count += 1;
                if(count == objects.count){
//                    [self placeTrips];
                }
            }
            
            [self placeTrips];

        }
        
    }];
}


/**
 *  Load the trunks of the user's who the current user is following. We use the self.friends array to store their following.
 *
 *
 */
-(void)queryForTrunks{ //City filter if (trip.name != nil && ![self.objectIDs containsObject:trip.objectId]) should be moved here to place less pins down later
    
    //This is documented in the method above.
    //TODO This method and the one above should be merged into one method during refactoring
    
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" containedIn:self.friends];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query includeKey:@"trip"];
    [query includeKey:@"toUser"];
    [query includeKey:@"creator"];
    [query includeKey:@"createdAt"];
    [query orderByDescending:@"createdAt"];
    [query setLimit: 10000]; // DEFAULT IS 100 so trunks get left off.

    
    NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
    
    
    
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (self.loadedOnce == NO)
        {
            self.title = NSLocalizedString(@"Loading Trunks...",@"Loading Trunks...");
            self.loadedOnce = YES;
        }
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
                
                NSTimeInterval lastTripInterval = [lastOpenedApp timeIntervalSinceDate:trip.createdAt];
                CLLocation *location = [[CLLocation alloc]initWithLatitude:trip.lat longitude:trip.longitude];
                if (lastTripInterval < 0)
                {
                    [self.haventSeens addObject:location];
                }
            }
            
            [self placeTrips];
        }
     }];
}

/**
 *  Load the user's who the current user is following
 *
 *
 */
-(void)queryParseMethodEveryone
{
    if (self.loadedOnce == NO){
        self.loadedOnce = YES;
    }
    
//self.friends will contrain the users that the current user is following.
        self.friends = [[NSMutableArray alloc]init];
//add the current user to self.friends since we want the current user's trunks too
        [self.friends addObject:[PFUser currentUser]];

    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (self.loadedOnce == NO){
            self.title = NSLocalizedString(@"Loading Trunks...",@"Loading Trunks...");
            self.loadedOnce = YES;
        }

        if (!error) {
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

//If the original array of trunks we loaded when viewDidLoad was called then there are no current trunks on the map. We can just display the new trunks.
    if (self.originalArray.count == 0)
    {

//self.parselocations contains the locations we just pulled down from parse
        for (Trip *trip in self.parseLocations)
        {
 
            NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
            
//find the last time a user added a photo to this trunk. If it is less than 24 hours the trunk on the map needs to be red instead of blue
            NSDate *today = [NSDate date];
            NSTimeInterval tripInterval = [today timeIntervalSinceDate:trip.mostRecentPhoto];
            
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
//place the trunk on the map
                
//if this is a user profile we show the most recent trunk on the map
                if (self.user && trip == [self.parseLocations objectAtIndex:0]) {
                    [self addTripToMap:trip dot:color isMostRecent:YES];

                } else{
                    [self addTripToMap:trip dot:color isMostRecent:NO];
                }
//we want to know how many trunks we originally had
                self.originalCount = self.parseLocations.count;
//we then set the orignalarray to parselocations. we use this to compare these trunks with the new ones we pull down from parse later
                self.originalArray = self.parseLocations;
            } else {
//we want a tally of the trunks we dropped and didn't drop on the map
                self.notDropped = self.notDropped +1;
            }
        }
    }
    else
    {
        int indexCount = 0;
//update is for us to see if the map needs to be updated
        BOOL update = NO;

//if the parseLocations or orginalArray differes then update ==YES
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
//if we need to update the map then we remove the current map pins and add new ones. TODO we should just add/remove the correct pins. Not all of them.
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
//this code is described above. TODO We need to refactor it and combine them
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
                    [self addTripToMap:trip dot:color isMostRecent:NO];
                    self.originalCount = self.parseLocations.count;
                    self.originalArray = self.parseLocations;
                } else {
                    self.notDropped = self.notDropped +1;
                }
            }
        }
    }
}


/**
 *  Turn the trunk into a map annotation and place it on the map
 *
 *
 */
-(void)addTripToMap:(Trip*)trip dot:(BOOL)hot isMostRecent:(BOOL)isMostRecent;
{
    
    
    //we do this to make sure we dont place two pins down for a city
    NSString *string = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
    

    
    [self.tripsToCheck addObject:string];
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
    annotation.title = trip.city;
    
    if ([trip.creator.objectId isEqualToString:[PFUser currentUser].objectId]){
        
    }
    
    
    if (trip.longitude != 0 && trip.longitude != 0){
        annotation.coordinate = CLLocationCoordinate2DMake(trip.lat, trip.longitude);
        [self createTripForMap:trip dot:hot isMostRecent:isMostRecent annotation:annotation needToSave:NO];

        
    } else
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
                 [self createTripForMap:trip dot:hot isMostRecent:isMostRecent annotation:annotation needToSave:YES];
             }
             
         }];
    }
}

-(void)createTripForMap:(Trip*)trip dot:(BOOL)hot isMostRecent:(BOOL)isMostRecent annotation:(MKPointAnnotation*)annotation needToSave:(BOOL)isNeeded{
    NSDate *date = trip.createdAt;
    NSTimeInterval interval = [date timeIntervalSinceNow];
    
    //if the trunk was made less than 30 seconds ago and by the current user then we zoom on to this trunk. This gives the effect of the user making a trunk and then immediatly being taken to the city where this trunk was made. However, if were on a user profile then we just show the most recent trunk.
    if (isMostRecent == YES){
        CLLocationCoordinate2D center = annotation.coordinate;
        
        MKCoordinateSpan span;
        span.longitudeDelta = 3.5;
        span.latitudeDelta = 3.5;
        
        MKCoordinateRegion region;
        region.center = center;
        region.span = span;
        self.zoomOut.hidden = NO;
        
        [self.mapView setRegion:region animated:YES];
        
    }
    
    
    else if (interval > -30 && [trip.creator.objectId isEqualToString:[PFUser currentUser].objectId] && self.justMadeTrunk && trip.objectId != self.tripToCheck.objectId) {
        self.isNew = YES;
        self.tripToCheck = trip;
        
        [self.justMadeTrunk addObject:annotation];
    }
    //if hot (meaning the trunk has had a photo added in less than 24 hours) then we place it on the map no matter what
    if (hot == YES)
    {
        [self.hotDots addObject:annotation.title];
        [self.mapView addAnnotation:annotation];
        
    }
    // if hot is no and we haven't already placed a hot trunk down on that city then we add the pin to the map
    else if (hot == NO && ![self.hotDots containsObject:annotation.title]) {
        
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
    
    [self.locations addObject:startAnnotation];

    
    if (self.isNew == YES) {
        self.isNew = NO;
        MKPointAnnotation *ann = [self.justMadeTrunk objectAtIndex:0];
        CLLocationCoordinate2D center = ann.coordinate;
        
        MKCoordinateSpan span;
        span.longitudeDelta = 3.5;
        span.latitudeDelta = 3.5;
        
        MKCoordinateRegion region;
        region.center = center;
        region.span = span;
        self.zoomOut.hidden = NO;
        
        
        [self.mapView setRegion:region animated:YES];

    }
    

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
    view.enabled = NO;
    view.selected = YES;
    
    CLGeocoder *cod = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:view.annotation.coordinate altitude:0 horizontalAccuracy:0 verticalAccuracy:0 timestamp:[NSDate date]];
    [cod reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (!error){
            CLPlacemark *placemark = [placemarks firstObject];
            self.pinCityName = view.annotation.title;
            self.pinStateName = placemark.administrativeArea;
            [self performSegueWithIdentifier:@"Trunk" sender:self];
            self.pinCityName = nil;
            self.pinStateName = nil;
            self.photoPin = view;
            view.enabled = YES;
            view.selected = NO;


        } else {
            view.enabled = YES;
            view.selected = NO;

        }
    }];
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
        trunkView.state = self.pinStateName;
        trunkView.user = self.user;
        self.pinCityName = nil;
    }
}


// no longer supported as a feature but leave in case we add the feature again
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

#pragma mark - Tutorial Management
-(void)showTutorial
{
    //Show Tutorial View Controller to User
    TutorialViewController *tutorialVC = [[TutorialViewController alloc] initWithNibName:@"TutorialViewController" bundle:nil];
    [self.navigationController presentViewController:tutorialVC	 animated:YES completion:nil];
}

// This is needed for the login to work properly
// DO NOT DELETE
-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
}

-(void)updateTrunkColor:(Trip *)trip isHot:(BOOL)isHot{
    NSString *address = [NSString stringWithFormat:@"%@ %@ %@", trip.city, trip.state, trip.country];
    
    if ([self.tripsToCheck containsObject:address]){
        if ([self.hotDots containsObject:address]){
            [self addTripToMap:trip dot:YES isMostRecent:YES];
        } else {
            [self addTripToMap:trip dot:isHot isMostRecent:YES];
        }
    }
}



@end





























