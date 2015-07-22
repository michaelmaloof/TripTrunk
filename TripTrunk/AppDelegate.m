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

#import "UserProfileViewController.h"
#import "PhotoViewController.h"
#import "TrunkViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:(95.0/255.0) green:(148.0/255.0) blue:(172.0/255.0) alpha:1]];
    
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           [UIFont fontWithName:@"American Typewritter" size:40.0], NSFontAttributeName, nil]];
    
    
    [Parse setApplicationId:@"jyNLO5QRwCCapLfNiTulIDuatHFsBrPkx31xtSGS"
                  clientKey:@"aQnBH0OLcCwOhuIZGuBGIqYwW6M5bL4oW6xVze1P"];
    [PFUser enableRevocableSessionInBackground];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFImageView class];
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    [self handlePush:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]]; // Call the handle push method with the payload. It won't do anything if there's no payload
    
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
    [PFPush handlePush:userInfo];
    //TODO: Don't push if app is running
    // this pushes to the notification's screen, but if the app is open then we don't want to do that. We just want to tell the user they got a notification
    [self handlePush:userInfo];
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
    
    // TODO: do we actually need tripId at all?
//    NSString *tripId = [payload objectForKey:@"tid"];
    
    if (photoId && photoId.length != 0) {
        NSLog(@"GOT PHOTO ADDED PUSH NOTIFICATION: %@", payload);
        
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
}

@end
