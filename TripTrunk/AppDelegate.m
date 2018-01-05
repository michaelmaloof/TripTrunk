//
//  AppDelegate.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "TTPushNotificationHandler.h"
#import "UserProfileViewController.h"
#import "TrunkViewController.h"
#import "Trip.h"
#import "FindFriendsViewController.h"
#import "ActivityListViewController.h"
#import "TTCache.h"
#import "Cloudinary.h"
#import <AWSCore/AWSCore.h>
#import <AWSSNS/AWSSNS.h>
#import "AWSMobileClient.h"
@import GooglePlaces;
#import <GoogleMaps/GoogleMaps.h>
#define kGOOGLE_API_KEY @"AIzaSyAgAXkTYFHm3MPQKJSoEYup17iUwi_OC4M"
#import "TTAnalytics.h"
#import "TTUtility.h"
#import "TTOnboardingViewController.h"


//TripTrunk Parse Keys
#define kPARSE_APP_ID @"hgAFtnU5haxHqyFnupsASx6MwZmEQs0wY0E43uwI"
#define kPARSE_CLIENT_KEY @"NvbwXKFHZ2cp7F4Fc9ipXNNybviqGboCwiinIoVa"

//TripTrunk-DEV
#define kPARSE_SERVER_KEY @"https://api-dev.triptrunkapp.com/parse/" // This is the DEV URL

//TripTrunk-PROD
//#define kPARSE_SERVER_KEY @"https://api.triptrunkapp.com/parse/" // This is the PRODUCTION URL

//TripTrunk Local
//#define kPARSE_SERVER_KEY @"http://localhost:3000/parse/" // This is your LOCALHOST URL
//#define kPARSE_SERVER_KEY @"http://10.0.1.6:3000/parse/" // This is Mike's Local IP Address
//#define kPARSE_SERVER_KEY @"http://192.168.0.100:3000/parse/" // This is Matt's Local IP Address

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.applicationId = kPARSE_APP_ID;
        configuration.clientKey = kPARSE_CLIENT_KEY;
        configuration.server = kPARSE_SERVER_KEY;
    }]];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self handleDatabaseAndConsoleLog];
//    [self setNavbarAndTabbarColors];
//    [self checkForShortCutItems:launchOptions];
    [self handleFontOutput];
    
    // Initialize Google Places for the Location Search
    [GMSPlacesClient provideAPIKey:kGOOGLE_API_KEY];
    NSString *GoogleMapsAPI = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GoogleMapsAPIKey"];
    [GMSServices provideAPIKey:GoogleMapsAPI];
    
    //Intiate google analytics for all non-dev users
    if(![[PFUser currentUser].objectId isEqualToString:@"B6xgcsV7lL"] && //Austin
       ![[PFUser currentUser].objectId isEqualToString:@"mzITFRYJjy"] && //Mike: appdever
       ![[PFUser currentUser].objectId isEqualToString:@"H00sH608n2"]){  //Mike: altrius
            BOOL env = YES;
            if([kPARSE_SERVER_KEY isEqualToString:@"https://api-dev.triptrunkapp.com/parse/"])
                env = NO;
            [TTAnalytics initAnalyticsOnStart:env];
    }    
    
    NSLog( @"### running FB sdk version: %@", [FBSDKSettings sdkVersion] );
    
    if(![PFUser currentUser]){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        TTOnboardingViewController *viewController = (TTOnboardingViewController *)[storyboard instantiateViewControllerWithIdentifier:@"LoginNavigationController"];
        [self.window makeKeyAndVisible];
        [self.window.rootViewController presentViewController:viewController
                                                     animated:YES
                                                   completion:nil];
    }

    return YES;
}

-(void)launchWithoutQuickAction:(NSDictionary*)launchOptions{
    
    [PFUser enableRevocableSessionInBackground];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFImageView class];
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
//REPAIR: This needs to be fixed for new design
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Timeline" bundle:nil];
//    UITabBarController *rootViewController = (UITabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"ttTabBarController"];
//    [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
//
//    [self handlePush:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]]; // Call the handle push method with the payload. It won't do anything if there's no payload
//    [self setupSearchTabBar];
//    [self setupActivityTabBar];
//    [self setupProfileTabBar];
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    PFUser *user = [PFUser currentUser];
    [user setValue:[NSDate date] forKeyPath:@"lastUsed"];
    [user saveInBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
//        [currentInstallation saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
//            NSLog(@"Red Badge Cleared");
//        }];
        [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            NSLog(@"Red Badge Cleared");
        }];
        //tabbar number here
    } else {
        //normal tab here
    }
    
    PFUser *user = [PFUser currentUser];
    if(user[@"lastUsed"]){
        NSDictionary *params = @{
                                 @"date" : user[@"lastUsed"]
                                 };
        [PFCloud callFunctionInBackground:@"queryForActivityNotifications" withParameters:params block:^(NSString *response, NSError *error) {
            if (!error) {
                [self setActivityBadgeIcon:[response intValue]];
            }else{
                [self setActivityBadgeIcon:0];
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"queryForActivityNotifications:"];
            }
        }];
    }

}

- (void)applicationWillTerminate:(UIApplication *)application {
    PFUser *user = [PFUser currentUser];
    user[@"lastUsed"] = [NSDate date];
    [user saveInBackground];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                    annotation:annotation];
}

- (void)logout {
    //TODO: clear any cached data, clear userdefaults, and display loginViewController
    // clear cache
    [[TTCache sharedCache] clear];
    
    // Unsubscribe from push notifications by removing the user association from the current installation.
    [[PFInstallation currentInstallation] removeObjectForKey:@"user"];
    [[PFInstallation currentInstallation] saveInBackground];
    [PFQuery clearAllCachedResults];
    [PFUser logOut];
    
    // This pushes the user back to the map view, on the map tab, which should then show the loginview
    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
    UINavigationController *homeNavController = [[tabbarcontroller viewControllers] objectAtIndex:0];
    [homeNavController dismissViewControllerAnimated:YES completion:nil];
    [homeNavController popToRootViewControllerAnimated:YES];
    [tabbarcontroller setSelectedIndex:0];
    NSLog(@"User has logged out");
}

#pragma mark - Tab Bar

/**
 *  Creates the Search Tab in the tab bar.
 *  This is necessary because the FindFriendsViewController does not use the storyboard, and so does not work correctly in a storyboard-managed tab bar
 */
- (void)setupSearchTabBar {
    // Set up search tab
    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
    FindFriendsViewController *ffvc = [[FindFriendsViewController alloc] init];
    UINavigationController *searchNavController = [[UINavigationController alloc] initWithRootViewController:ffvc];
    UITabBarItem *searchItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"searchGlass_tabIcon"] tag:3];
    [searchItem setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
    [searchNavController setTabBarItem:searchItem];
    NSMutableArray *vcs = [[NSMutableArray alloc] initWithArray:[tabbarcontroller viewControllers]];
    
    if (vcs.count == 2) {
        // While we still have 2 tabs created in Storyboard, then this is the one that SHOULD always be true. The other 2 if-cases are just in case.
        [vcs insertObject:searchNavController atIndex:1];
    }
    else if (vcs.count > 2) {
        [vcs replaceObjectAtIndex:2 withObject:searchNavController];
    }
    else {
        [vcs addObject:searchNavController];
    }
    [tabbarcontroller setViewControllers:vcs];
    
}

- (void)setupActivityTabBar {
    // Set up Activity tab
    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
    ActivityListViewController *avc = [[ActivityListViewController alloc] initWithActivities:[NSArray array]];
    UINavigationController *activityNavController = [[UINavigationController alloc] initWithRootViewController:avc];
    UITabBarItem *activityItem = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"comment_tabIcon"] tag:3];
    [activityItem setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
    
    [activityNavController setTabBarItem:activityItem];
    NSMutableArray *vcs = [[NSMutableArray alloc] initWithArray:[tabbarcontroller viewControllers]];
    if (vcs.count > 3) {
        [vcs replaceObjectAtIndex:3 withObject:activityNavController];
    }
    else {
        [vcs addObject:activityNavController];
    }
    [tabbarcontroller setViewControllers:vcs];
}

- (void)setupProfileTabBar {
    // Set up search tab
    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
    UserProfileViewController *viewController = [[UserProfileViewController alloc] initWithUser:[PFUser currentUser]];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:nil image:[UIImage imageNamed:@"profile_tabIcon"] tag:3];
    [item setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
    item.title = @"";
    [navController setTabBarItem:item];
    NSMutableArray *vcs = [[NSMutableArray alloc] initWithArray:[tabbarcontroller viewControllers]];
    if (vcs.count > 4) {
        [vcs replaceObjectAtIndex:4 withObject:navController];
    }
    else {
        [vcs addObject:navController];
    }
    [tabbarcontroller setViewControllers:vcs];
    
}

#pragma mark - Remote Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    if ([PFUser currentUser]) {
        [currentInstallation setObject:[PFUser currentUser] forKey:@"user"];
    }
    [currentInstallation saveInBackground];
    
}

-(void)setActivityBadgeIcon:(int)increment{
    NSUInteger internalBadge = [[[NSUserDefaults standardUserDefaults] valueForKey:@"internalBadge"] integerValue] + increment;
    [[NSUserDefaults standardUserDefaults] setInteger:internalBadge forKey:@"internalBadge"];
    if(internalBadge>0){
        UIImage *image = [UIImage imageNamed:@"redComment"];
        UIImage *render = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UITabBarItem *searchItem = [[UITabBarItem alloc] initWithTitle:nil image:render tag:3];
        [searchItem setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
        searchItem.badgeValue = [NSString stringWithFormat:@"%ld",(long)internalBadge];
//REPAIR: This needs to be fixed for new design
//        [[[(UITabBarController*)(UINavigationController*)self.window.rootViewController viewControllers]objectAtIndex:3] setTabBarItem:searchItem];
        
    }
}

//For when app is in background
//-(void)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler{
//
//    [UIApplication sharedApplication].applicationIconBadgeNumber = [[userInfo objectForKey:@"badge"] integerValue];
//    
//    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
////    if(state == UIApplicationStateActive)
////        NSLog(@"STATE: (%li) - Active",(long)state);
////    if(state == UIApplicationStateInactive)
////        NSLog(@"STATE: (%li) - Inactive",(long)state);
////    if(state == UIApplicationStateBackground)
////        NSLog(@"STATE: (%li) - Background",(long)state);
//    
//    if(state != UIApplicationStateInactive){
//        [self setActivityBadgeIcon:1];
//    }
//    
//    if (completionHandler) {
//        completionHandler(UIBackgroundFetchResultNewData);
//    }
//}

//For when app is in foreground
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = [[userInfo objectForKey:@"badge"] integerValue];
    
    [self setActivityBadgeIcon:1];
    
    if (application.applicationState == UIApplicationStateActive ) {
        // Let Parse handle the push notificatin -- they'll display a popup
        if (userInfo[@"aps"]) {
            NSString *alertText = [userInfo[@"aps"] valueForKey:@"alert"];
            if (alertText && ![alertText isEqualToString:@""]) {
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TripTrunk" message:alertText delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay") otherButtonTitles:nil, nil];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [alert show];
//                });
                
//            UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"unseenBlueCircle"]];
//            imageView.frame = (CGRectMake(self.window.frame.size.width*.8, self.window.frame.origin.y + self.window.frame.size.height - 15, 10, 10));
//            [self.window addSubview:imageView];
                
            }
        }
        //TODO: Present an Alert with the notification and let the user choose to "view" it.
    }else{
        //This pushes to the notification's screen, but if the app is open then we don't want to do that.
        //We just want to tell the user they got a notification
        [self handlePush:userInfo];
    }

}

#pragma mark - Push Notification Handler
- (void)handlePush:(NSDictionary *)launchOptions {
    // Extract the notification payload dictionary
    NSDictionary *payload = launchOptions;
    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
    [tabbarcontroller setSelectedIndex:0];
    UINavigationController *homeNavController = [[tabbarcontroller viewControllers] objectAtIndex:0];
    
    // Check if the app was open from a notification and a user is logged in
    if (payload && [PFUser currentUser]) {
        
        // Activity notification
        if ([[payload objectForKey:@"p"] isEqualToString:@"a"]) {
            if([[payload objectForKey:@"t"] isEqualToString:@"m"])
                [TTPushNotificationHandler handleMentionPush:payload controller:homeNavController];
            else [TTPushNotificationHandler handleActivityPush:payload controller:homeNavController];
        }
        // Photo notification
        else if ([[payload objectForKey:@"p"] isEqualToString:@"p"]) {
            [TTPushNotificationHandler handlePhotoPush:payload controller:homeNavController];
        }
    }
}

/**
 *  @brief handle shortcut item depend on its type
 *
 *  @param shortcutItem shortcutItem  selected shortcut item with quick action.
 *
 *  @return return BOOL description
 */
- (BOOL)handleShortCutItem : (UIApplicationShortcutItem *)shortcutItem launch:(NSDictionary*)launchOptions{
    
    BOOL handled = NO;
    
    NSString *shortcutSearch = @"Search";
    NSString *shortcutActivity = @"Activity";
    NSString *shortcutTrunk = @"Trunk";
    NSString *shortcutRecent = @"Recent";

    [PFUser enableRevocableSessionInBackground];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFImageView class];
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
//REPAIR: This needs to be fixed for new design
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Timeline" bundle:nil];
    UITabBarController *rootViewController = (UITabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"ttTabBarController"];
    [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
    
    [self handlePush:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]]; // Call the handle push method with the payload. It won't do anything if there's no payload
    
    [self setupSearchTabBar];
    [self setupActivityTabBar];
    [self setupProfileTabBar];


    if ([shortcutItem.type isEqualToString:shortcutSearch]) {
        handled = YES;
        
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:1];

    }
    
    else if ([shortcutItem.type isEqualToString:shortcutActivity]) {
        handled = YES;
        
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:3];

    }
    
    else if ([shortcutItem.type isEqualToString:shortcutTrunk]) {
        handled = YES;
        
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:2];

    }
    
    else if ([shortcutItem.type isEqualToString:shortcutRecent]) {
        
        handled = YES;
        
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:0];



    }

    
    return handled;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    
    NSString *shortcutSearch = @"Search";
    NSString *shortcutActivity = @"Activity";
    NSString *shortcutTrunk = @"Trunk";
    NSString *shortcutRecent = @"Recent";

    
    if ([shortcutItem.type isEqualToString:shortcutSearch]) {
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:1];
    }
    
    else if ([shortcutItem.type isEqualToString:shortcutActivity]) {
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:3];
    }
    
    else if ([shortcutItem.type isEqualToString:shortcutTrunk]) {
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:2];
    }
    
    else if ([shortcutItem.type isEqualToString:shortcutRecent]) {

        UITabBarController *tabControl = (UITabBarController*)self.window.rootViewController;
        UINavigationController *nav = tabControl.viewControllers[0];
        //        UIViewController *vc = nav.viewControllers[0];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
        
        [(UITabBarController*)self.window.rootViewController setSelectedIndex:0];
        //Build an array to send up to CC
        NSMutableArray *friendsObjectIds = [[NSMutableArray alloc] init];
        //we only have a single user but we still need to add it to an array and send up the params
        [friendsObjectIds addObject:[PFUser currentUser].objectId];
        
        NSDictionary *params = @{
                                 @"objectIds" : friendsObjectIds,
                                 @"limit" : @"5"
                                 };
        [PFCloud callFunctionInBackground:@"queryForUniqueTrunks" withParameters:params block:^(NSArray *response, NSError *error) {
            if (!error) {
                __block BOOL pushed;
                pushed = NO;
                for (PFObject *act in response){
                    Trip *trip = act[@"trip"];
                    trunkViewController.trip = trip;
                    
                    if (trunkViewController.trip != nil && pushed == NO){
                        pushed = YES;
                        [nav pushViewController:trunkViewController animated:YES];
                        break;
                        
                    }
                }
            }else{
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"performActionForShortcutItem:"];
            }
        }];

    }
}

-(void)setNavbarAndTabbarColors{
    [[UINavigationBar appearance] setBackgroundColor:[TTColor tripTrunkWhite]];
    [[UINavigationBar appearance] setBarTintColor:[TTColor tripTrunkWhite]];
    [[UINavigationBar appearance] setTintColor: [TTColor tripTrunkBlue]];
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [TTColor tripTrunkBlue], NSForegroundColorAttributeName,
                                                           [TTFont tripTrunkFontBold38], NSFontAttributeName, nil]];
    
    [[UITabBar appearance] setTintColor:[TTColor tripTrunkBlue]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)handleDatabaseAndConsoleLog{
    NSString *appName = @"DEV";
    if([kPARSE_SERVER_KEY isEqualToString:@"https://api.triptrunkapp.com/parse/"])
        appName = @"PROD";
    else appName = @"DEV";
    NSLog(@"%@ ENVIRONMENT",appName);
    NSLog(@"Cloudinary Version: %@",[CLCloudinary version]);
    NSLog(@"Parse version: %@",PARSE_VERSION);
    NSLog(@"App Version: %@ (%@)",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]);
    NSLog(@"Is this version out of date? %@",([TTUtility checkForUpdate] ? @"YES" : @"NO"));
}

-(void)checkForShortCutItems:(NSDictionary*)launchOptions{
    // UIApplicationShortcutItem is available in iOS 9 or later.
    if([[UIApplicationShortcutItem class] respondsToSelector:@selector(new)]){
        // If a shortcut was launched, display its information and take the appropriate action
        UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKeyedSubscript:UIApplicationLaunchOptionsShortcutItemKey];
        if(shortcutItem)
        {
            // When the app launch at first time, this block can not called.
            [self handleShortCutItem:shortcutItem launch:launchOptions];
            
        }else{
            // normal app launch process without quick action
            [self launchWithoutQuickAction:launchOptions];
        }
    }else{
        // Less than iOS9 or later
        [self launchWithoutQuickAction:launchOptions];
    }
}

-(void)handleFontOutput{
    //    //Font name console output. Fonts can be tricky. You need to know the exact name to reference them.
    //    for (NSString* family in [UIFont familyNames]){
    //        NSLog(@"%@", family);
    //        for (NSString* name in [UIFont fontNamesForFamilyName: family]){
    //            NSLog(@"  %@", name);
    //        }
    //    }
}

#pragma mark - Allow Landscape
/* Allow Landscape mode for specific ViewControllers */
//Just add -(void)canRotate{} to any view to make it rotate.
//I was going to allow the PhotoViewController to rotate but there is a lot more involved in getting this to work properly
/*-(UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    UIViewController* topVC = [self topViewControllerWith: self.window.rootViewController];
    if ([topVC respondsToSelector:@selector(canRotate)]) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskPortrait;
}

// get the top ViewController
- (UIViewController*) topViewControllerWith:(UIViewController *)rootViewController {
    if (rootViewController == nil) { return nil; }
    if ([rootViewController isKindOfClass: [UITabBarController class]]) {
        return [self topViewControllerWith: ((UITabBarController*) rootViewController).selectedViewController];
    }
    else if ([rootViewController isKindOfClass: [UINavigationController class]]) {
        return [self topViewControllerWith: ((UINavigationController*) rootViewController).visibleViewController];
    }
    else if (rootViewController.presentedViewController != nil) {
        return [self topViewControllerWith: [rootViewController presentedViewController]];
    }
    return rootViewController;
}*/


@end
