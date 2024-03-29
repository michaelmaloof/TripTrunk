//
//  AppDelegate.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <ParseCrashReporting/ParseCrashReporting.h>
#import <ParseUI/ParseUI.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "UserProfileViewController.h"
#import "PhotoViewController.h"
#import "TrunkViewController.h"
#import "FindFriendsViewController.h"
#import "ActivityListViewController.h"
#import "TTCache.h"

#if DEBUG == 0 // CHANGE TO 0
// DEBUG is not defined or defined to be 0
// THIS IS PROD MODE
#define kPARSE_APP_ID @"oiRCeawMKf4HoGD4uCRIaOS1qWFh6lUW7oBuhJ5H"
#define kPARSE_CLIENT_KEY @"1VpyJmOuzm1qCnVApigB9CGR0B6Yz3cAxfICdGsY"
#else
// THIS IS DEBUG MODE

#define kPARSE_APP_ID @"xBZ7gyGIuTMLluZeVO0SxAsBdEFSzBe6wJwKt19z"
#define kPARSE_CLIENT_KEY @"1BW54t5ZC2lRJHgFlZrcdkSLhoFz2XCSFcJ8agXl"
#endif

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:(95.0/255.0) green:(148.0/255.0) blue:(172.0/255.0) alpha:1]];
    
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           [UIFont fontWithName:@"American Typewritter" size:40.0], NSFontAttributeName, nil]];
    

    [ParseCrashReporting enable];
    
    [Parse setApplicationId:kPARSE_APP_ID
                  clientKey:kPARSE_CLIENT_KEY];
    [PFUser enableRevocableSessionInBackground];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFImageView class];
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UITabBarController *rootViewController = (UITabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"tabBarController"];
    [[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
    
    [self handlePush:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]]; // Call the handle push method with the payload. It won't do anything if there's no payload
    [self setupSearchTabBar];
    [self setupActivityTabBar];
    [self setupProfileTabBar];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    PFUser *user = [PFUser currentUser];
    [user setValue:[NSDate date] forKeyPath:@"lastUsed"];

    [user saveInBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [FBSDKAppEvents activateApp];

    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

}

- (void)applicationWillTerminate:(UIApplication *)application {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
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
    [homeNavController popToRootViewControllerAnimated:YES];
    [tabbarcontroller setSelectedIndex:0];
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

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    if (application.applicationState == UIApplicationStateActive ) {
        // Let Parse handle the push notificatin -- they'll display a popup
        if (userInfo[@"aps"]) {
            NSString *alertText = [userInfo[@"aps"] valueForKey:@"alert"];
            if (alertText && ![alertText isEqualToString:@""]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TripTrunk" message:alertText delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay") otherButtonTitles:nil, nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert show];
                });
            }
        }
        //TODO: Present an Alert with the notification and let the user choose to "view" it.
    }
    else {
        // this pushes to the notification's screen, but if the app is open then we don't want to do that. We just want to tell the user they got a notification
        [self handlePush:userInfo];
    }

}

#pragma mark - Push Notification Handler

- (void)handlePush:(NSDictionary *)launchOptions {
    // Extract the notification payload dictionary
    NSDictionary *payload = launchOptions;
    
    // Check if the app was open from a notification and a user is logged in
    if (payload && [PFUser currentUser]) {
        
        // Activity notification
        if ([[payload objectForKey:@"p"] isEqualToString:@"a"]) {
            [self handleActivityPush:payload];
        }
        // Photo notification
        else if ([[payload objectForKey:@"p"] isEqualToString:@"p"]) {
            [self handlePhotoPush:payload];
        }
    }
}

- (void)handlePhotoPush:(NSDictionary *)payload {
    // Push the referenced photo/trip into view
    NSString *photoId = [payload objectForKey:@"pid"];
    
    NSString *tripId = [payload objectForKey:@"tid"];
    
    if (tripId && tripId.length != 0) {
        PFQuery *query = [PFQuery queryWithClassName:@"Trip"];
        [query getObjectInBackgroundWithId:tripId block:^(PFObject *trip, NSError *error) {
            if (!error) {
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
                trunkViewController.trip = (Trip *)trip;
                UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
                UINavigationController *homeNavController = [[tabbarcontroller viewControllers] objectAtIndex:0];
                [tabbarcontroller setSelectedIndex:0];
                [homeNavController pushViewController:trunkViewController animated:NO];
                
                if (photoId && photoId.length != 0) {
                    NSLog(@"GOT PHOTO ADDED PUSH NOTIFICATION: %@", payload);
                    
                    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
                    [photoQuery getObjectInBackgroundWithId:photoId block:^(PFObject *photo, NSError *error) {
                        if (!error) {
                            
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                            PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
                            photoViewController.photo = (Photo *)photo;

                            [homeNavController pushViewController:photoViewController animated:YES];
                        }
                    }];
                }
            }
        }];

    }
}

- (void)handleActivityPush:(NSDictionary *)payload {
    
    // it's an addToTrip notification, so display the trip
    if ([[payload objectForKey:@"t"] isEqualToString:@"a"]) {
        NSLog(@"GOT ADD TO TRIP PUSH NOTIFICATION: %@", payload);

        // Push to the referenced trip
        NSString *tripId = [payload objectForKey:@"tid"];
        if (tripId && tripId.length != 0) {
            PFQuery *query = [PFQuery queryWithClassName:@"Trip"];
            [query getObjectInBackgroundWithId:tripId block:^(PFObject *trip, NSError *error) {
                if (!error) {
                    
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
                    trunkViewController.trip = (Trip *)trip;
                    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
                    UINavigationController *homeNavController = [[tabbarcontroller viewControllers] objectAtIndex:0];
                    [tabbarcontroller setSelectedIndex:0];
                    [homeNavController pushViewController:trunkViewController animated:YES];
                }
            }];
        }

    }
    // it's a follow users notification, so display the user profile
    else if ([[payload objectForKey:@"t"] isEqualToString:@"f"]) {
        NSLog(@"GOT FOLLOW USER PUSH NOTIFICATION: %@", payload);
        NSString *userId = [payload objectForKey:@"fu"];
        if (userId && userId.length != 0) {
            PFQuery *query = [PFUser query];
            [query getObjectInBackgroundWithId:userId block:^(PFObject *user, NSError *error) {
                if (!error) {
                    
                    // Push to the user's profile from the home map view tab
                    UserProfileViewController *profileViewController = [[UserProfileViewController alloc] initWithUser:(PFUser *)user];
                    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
                    UINavigationController *homeNavController = [[tabbarcontroller viewControllers] objectAtIndex:0];
                    [tabbarcontroller setSelectedIndex:0];
                    [homeNavController pushViewController:profileViewController animated:YES];
                }
            }];
        }
    }
    // it's a Comment on Photo notification, so display the Photo View
    else if ([[payload objectForKey:@"t"] isEqualToString:@"c"] || [[payload objectForKey:@"t"] isEqualToString:@"l"]) {
        NSLog(@"GOT PHOTO COMMENT OR LIKE PUSH NOTIFICATION: %@", payload);

        // Push to the referenced Photo
        NSString *photoId = [payload objectForKey:@"pid"];
        if (photoId && photoId.length != 0) {
            PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
            [query getObjectInBackgroundWithId:photoId block:^(PFObject *photo, NSError *error) {
                if (!error) {
                    
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
                    photoViewController.photo = (Photo *)photo;
                    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
                    UINavigationController *homeNavController = [[tabbarcontroller viewControllers] objectAtIndex:0];
                    [tabbarcontroller setSelectedIndex:0];
                    [homeNavController pushViewController:photoViewController animated:YES];
                }
            }];
        }

    }
}

@end
