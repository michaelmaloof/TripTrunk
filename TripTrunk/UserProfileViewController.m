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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.nameLabel setText:_user[@"name"]];
    [self.usernameLabel setText:_user[@"username"]];
    
    NSURL *pictureURL = [NSURL URLWithString:[_user valueForKey:@"profilePicUrl"]];
    [self setProfilePic:pictureURL];
    
    // Disable the find friends button and hide the logout button
    // These buttons still exist in case we want to just use this one viewcontroller for MY profile or a FRIEND profile
    [self.findFriendsButton setEnabled:NO];
    [self.findFriendsButton setTitle:@"" forState:UIControlStateNormal];
    [self.logoutButton setHidden:YES];
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


@end
