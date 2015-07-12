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
#import "HomeMapViewController.h"

@interface ProfileViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
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
//- (IBAction)seeUsersMapTapped:(id)sender {
//    HomeMapViewController *vc = [[HomeMapViewController alloc]init];
//    vc.user = [PFUser currentUser];
//    [self.navigationController pushViewController:vc animated:YES];
//}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"globe"]) {
        HomeMapViewController *vc = segue.destinationViewController;
        vc.user = [PFUser currentUser];
    }
}

- (IBAction)profileImageTapped:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    picker.navigationController.title = @"Select profile picture.";
    [picker.navigationController setTitle:@"Select profile picture."];

    picker.navigationBar.tintColor = [UIColor whiteColor];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self presentViewController:picker animated:YES completion:NULL];}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //    Photo *photo = [Photo object];
    //    photo.image = info[UIImagePickerControllerOriginalImage];
    //
    //    // set the reference URL now so we have it for uploading the raw image data
    //    photo.imageUrl = [NSString stringWithFormat:@"%@", info[UIImagePickerControllerReferenceURL]];
    //
    //    // Set all the generic trip info on the Photo object
    //    PFUser *user = [PFUser currentUser];
    //    photo.likes = 0;
    //    photo.trip = self.trip;
    //    photo.userName = user.username;
    //    photo.user = user;
    //    photo.usersWhoHaveLiked = [[NSMutableArray alloc] init];
    //    photo.tripName = self.trip.name;
    //    photo.city = self.trip.city;
    //
    //
    //    [self.photos addObject:photo];
    //
    //    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    //    [picker dismissViewControllerAnimated:YES completion:NULL];
    //    [self.tripCollectionView reloadData];
    
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [viewController.navigationItem setTitle:@"Select Profile Image"];
}



@end

































