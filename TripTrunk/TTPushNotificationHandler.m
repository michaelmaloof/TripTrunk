//
//  TTPushNotificationHandler.m
//  TripTrunk
//
//  Created by Michael Cannell on 3/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTPushNotificationHandler.h"
#import "CommentListViewController.h"
#import "SocialUtility.h"
#import "TrunkViewController.h"
#import "PhotoViewController.h"
#import "UserProfileViewController.h"

@implementation TTPushNotificationHandler


+(void)handleMentionPush:(NSDictionary*)payload controller:(UINavigationController*)controller{
    NSString *photoId = [payload objectForKey:@"pid"];
    //load photo bu photoId into Photo* photo object
    PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
    [query getObjectInBackgroundWithId:photoId block:^(PFObject *photo, NSError *error) {
        if (!error) {
            PFQuery *query = [SocialUtility queryForActivitiesOnPhoto:(Photo*)photo cachePolicy:kPFCachePolicyNetworkOnly];
            [query setLimit:1000];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    NSMutableArray *comments = [[NSMutableArray alloc] init];
                    for (PFObject *activity in objects) {
                        if ([[activity objectForKey:@"type"] isEqualToString:@"comment"] && [activity objectForKey:@"fromUser"]) {
                            [comments addObject:activity];
                        }
                    }
                    
                    CommentListViewController *vc = [[CommentListViewController alloc] initWithComments:comments forPhoto:(Photo*)photo];
//                    UITabBarController *tabbarcontroller = (UITabBarController *)self.window.rootViewController;
//                    UINavigationController *homeNavController = [[tabbarcontroller viewControllers] objectAtIndex:0];
//                    [homeNavController setSelectedIndex:0];
                    Photo *myPhoto = (Photo *)photo;
                    NSArray *trunkMembers = [[NSArray alloc] init];
                    vc.trip = myPhoto.trip;
                    vc.trunkMembers = trunkMembers;
                    [controller pushViewController:vc animated:YES];
                    
                }else {
                    NSLog(@"Error loading photo Activities: %@", error);
                }
            }];
        }
    }];
}

+(void)handlePhotoPush:(NSDictionary *)payload controller:(UINavigationController*)controller{
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
                [controller pushViewController:trunkViewController animated:NO];
                
                if (photoId && photoId.length != 0) {
                    NSLog(@"GOT PHOTO ADDED PUSH NOTIFICATION: %@", payload);
                    
                    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
                    [photoQuery getObjectInBackgroundWithId:photoId block:^(PFObject *photo, NSError *error) {
                        if (!error) {
                            Photo *myPhoto = (Photo *)photo;
                            NSArray *trunkMembers = [[NSArray alloc] init];
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                            PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
                            photoViewController.photo = myPhoto;
                            photoViewController.trip = myPhoto.trip;
                            photoViewController.trunkMembers = trunkMembers;
                            photoViewController.fromNotification = YES;
                            
                            [controller pushViewController:photoViewController animated:YES];
                        }
                    }];
                }
            }
        }];
        
    }
}

+(void)handleActivityPush:(NSDictionary *)payload controller:(UINavigationController*)controller{
    
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
                    [controller pushViewController:trunkViewController animated:YES];
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
                    [controller pushViewController:profileViewController animated:YES];
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
                    photoViewController.fromNotification = YES;
                    [controller pushViewController:photoViewController animated:YES];
                }
            }];
        }
        
    }
}



@end
