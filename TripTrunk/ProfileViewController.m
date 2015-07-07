//
//  ProfileViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/5/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "ProfileViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Parse/Parse.h>

#import "FriendsListViewController.h"
#import "FindFriendsViewController.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profilePicImageView;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    NSURL *pictureURL = [NSURL URLWithString:[[PFUser currentUser] valueForKey:@"profilePicUrl"]];
    [self setProfilePic:pictureURL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)followersButtonPressed:(id)sender {
    FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:[PFUser currentUser] andFollowingStatus:NO];
    
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)findFriendsButtonPressed:(id)sender {
    
    FindFriendsViewController *vc = [[FindFriendsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];

}
- (IBAction)followingButtonPressed:(id)sender {
    
    FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:[PFUser currentUser] andFollowingStatus:YES];
    [self.navigationController pushViewController:vc animated:YES];

}
- (IBAction)logOutButtonPressed:(id)sender {
    [PFUser logOut];
    
    // This pushes the user back to the map view, which should then show the loginview
    [self.navigationController popViewControllerAnimated:YES];
    
    //TODO: clear any cached data, clear userdefaults, and display loginViewController
}

- (void)setProfilePic:(NSURL *)pictureURL {
    // URL should point to https://graph.facebook.com/{facebookId}/picture?type=large&return_ssl_resources=1

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
