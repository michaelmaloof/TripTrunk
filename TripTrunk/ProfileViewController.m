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

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profilePicImageView;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *pictureURL = [NSURL URLWithString:[[PFUser currentUser] valueForKey:@"profilePicUrl"]];
    [self setProfilePic:pictureURL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)followersButtonPressed:(id)sender {
    NSLog(@"Followers Button Pressed");
}
- (IBAction)findFriendsButtonPressed:(id)sender {
    NSLog(@"Find Friends Button Pressed");

}
- (IBAction)followingButtonPressed:(id)sender {
    NSLog(@"Following Button Pressed");

}
- (IBAction)logOutButtonPressed:(id)sender {
    NSLog(@"Logout Button Pressed");
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
