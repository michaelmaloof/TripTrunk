//
//  UserProfileViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "UserProfileViewController.h"
#import <Parse/Parse.h>

#import "FriendsListViewController.h"
#import "SocialUtility.h"
#import "TTUtility.h"
#import "TTCache.h"
#import "HomeMapViewController.h"

@interface UserProfileViewController ()

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profilePicImageView;
@property (strong, nonatomic) PFUser *user;
@end

@implementation UserProfileViewController

- (id)initWithUser:(PFUser *)user
{
    self = [super initWithNibName:@"ProfileViewController" bundle:nil]; // nil is ok if the nib is included in the main bundle
    if (self) {
        _user = user;
    }
    return self;
}

- (id)initWithUserId:(NSString *)userId;
{
    self = [super initWithNibName:@"ProfileViewController" bundle:nil]; // nil is ok if the nib is included in the main bundle
    if (self) {
        _user = [PFUser user];
        [_user setObjectId:userId];
;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    
    // If the user hasn't been fully loaded (aka init with ID), fetch the user before moving on.
    [_user fetchIfNeeded];
    
    [self.nameLabel setText:_user[@"name"]];
    [self.usernameLabel setText:[NSString stringWithFormat:@"@%@",_user[@"username"]]];
    
    [self setProfilePic:[_user valueForKey:@"profilePicUrl"]];
    
    // Disable the find friends button and hide the logout button
    // These buttons still exist in case we want to just use this one viewcontroller for MY profile or a FRIEND profile
    [self.findFriendsButton setEnabled:NO];
    [self.findFriendsButton setTitle:@"" forState:UIControlStateNormal];
    [self.logoutButton setHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    
    // Don't show the follow button if it's the current user's profile
    if ([[_user objectId] isEqual: [[PFUser currentUser] objectId]]) {
        [self.followButton setHidden:YES];
    }
    else {
        // Refresh the following status of this user
        
        if ([[TTCache sharedCache] followStatusForUser:self.user]) {
            // We have the following status, so update the Selected status and enable the button
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.followButton setEnabled:YES];
                [self.followButton setSelected:YES];
            });
        }
        else
        {
            
            [SocialUtility followingStatusFromUser:[PFUser currentUser] toUser:self.user block:^(BOOL isFollowing, NSError *error) {
                if (!error) {
                    if (isFollowing)
                    {
                        // We have the following status, so update the Selected status and enable the button
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.followButton setEnabled:YES];
                            [self.followButton setSelected:YES];
                        });
                    }
                    else {
                        // Not following this user, enable the button and set the selected status
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.followButton setEnabled:YES];
                            [self.followButton setSelected:NO];
                        });
                    }
                }
                else {
                    NSLog(@"Error: %@",error);
                }

            }];

        }
        
        // Show the button
        [self.followButton setHidden:NO];
        
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)followersButtonPressed:(id)sender {
    NSLog(@"Followers Button Pressed");
    FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:NO];
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)findFriendsButtonPressed:(id)sender {
    NSLog(@"Find Friends Button Pressed");
    
}
- (IBAction)followingButtonPressed:(id)sender {
    NSLog(@"Following Button Pressed");
    
    FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:YES];
    [self.navigationController pushViewController:vc animated:YES];
    
}
- (IBAction)logOutButtonPressed:(id)sender {
    NSLog(@"Logout Button Pressed");
    
    // Unsubscribe from push notifications by removing the user association from the current installation.
    [[PFInstallation currentInstallation] removeObjectForKey:@"user"];
    [[PFInstallation currentInstallation] saveInBackground];
    
    [PFUser logOut];
    
    // This pushes the user back to the map view, on the map tab, which should then show the loginview
    [[[self.tabBarController viewControllers] objectAtIndex:0] popToRootViewControllerAnimated:YES];
    [self.tabBarController setSelectedIndex:0];
    
    //TODO: clear any cached data, clear userdefaults, and display loginViewController
}
- (IBAction)followButtonPressed:(id)sender {
    
    if ([self.followButton isSelected]) {
        // Unfollow
        NSLog(@"Attempt to unfollow %@",_user.username);
        [self.followButton setSelected:NO]; // change the button for immediate user feedback
        [SocialUtility unfollowUser:_user];
    }
    else {
        // Follow
        NSLog(@"Attempt to follow %@",_user.username);
        [self.followButton setSelected:YES];
        
        [SocialUtility followUserInBackground:_user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
            }
            if (!succeeded) {
                NSLog(@"Follow NOT success");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Follow Failed"
                                                                message:@"Please try again"
                                                               delegate:self
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil, nil];
                
                [self.followButton setSelected:NO];
                [alert show];
            }
            else
            {
                NSLog(@"Follow Succeeded");
            }
        }];
    }
    
}

- (IBAction)mapButtonPressed:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    HomeMapViewController *vc = (HomeMapViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HomeMapView"];
    vc.user = self.user;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)setProfilePic:(NSString *)urlString {
    // Facebook Photo should point to https://graph.facebook.com/{facebookId}/picture?type=large&return_ssl_resources=1
    
    NSURL *pictureURL = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:urlString]];

    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:pictureURL];
    
    
    // Run network request asynchronously
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         if (connectionError == nil && data != nil) {
             
             // Set image on the UI thread
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.profilePicImageView setImage:[[UIImage alloc] initWithData:data]];
             });
             
         }
     }];
}




@end
