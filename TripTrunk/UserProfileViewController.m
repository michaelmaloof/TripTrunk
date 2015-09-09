//
//  UserProfileViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "UserProfileViewController.h"
#import <Photos/Photos.h>

#import "AppDelegate.h"
#import "FriendsListViewController.h"
#import "SocialUtility.h"
#import "TTUtility.h"
#import "TTCache.h"
#import "HomeMapViewController.h"

@interface UserProfileViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *hometownLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profilePicImageView;
@property (weak, nonatomic) IBOutlet UITextView *bioTextView;
@property (strong, nonatomic) IBOutlet UIButton *mapButton;
@property (strong, nonatomic) PFUser *user;
@end

@implementation UserProfileViewController

- (id)initWithUser:(PFUser *)user
{
    self = [super initWithNibName:@"UserProfileViewController" bundle:nil]; // nil is ok if the nib is included in the main bundle
    if (self) {
        _user = user;
    }
    return self;
}

- (id)initWithUserId:(NSString *)userId;
{
    self = [super initWithNibName:@"UserProfileViewController" bundle:nil]; // nil is ok if the nib is included in the main bundle
    if (self) {
        _user = [PFUser user];
        [_user setObjectId:userId];
;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self.scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    // Make sure we don't have a nil user -- if that happens it's probably because we're going to the profile tab right after logging in.
    if (!_user) {
        _user = [PFUser currentUser];
    }
    
    // If the user hasn't been fully loaded (aka init with ID), fetch the user before moving on.
    [_user fetchIfNeeded];
    self.title = _user.username;
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    

    [self.nameLabel setText:_user[@"name"]];
    [self.usernameLabel setText:[NSString stringWithFormat:@"@%@",_user[@"username"]]];
    
    [self setProfilePic:[_user valueForKey:@"profilePicUrl"]];
    
    if (_user[@"bio"]) {
        [self.bioTextView setText:_user[@"bio"]];
    }
    else {
        [self.bioTextView setText:@"A true world traveler"];
    }

    [self.logoutButton setHidden:YES];

    // If it's the current user, set up their profile a bit differently.
    if ([[_user objectId] isEqual: [[PFUser currentUser] objectId]]) {
        [self.followButton setHidden:YES];
        [self.logoutButton setHidden:NO];

        // Set Edit button
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                               target:self
                                                                                               action:@selector(editButtonPressed:)];
        
        UITapGestureRecognizer *picTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageViewTapped:)];
        picTap.numberOfTapsRequired = 1;
        self.profilePicImageView.userInteractionEnabled = YES;
        [self.profilePicImageView addGestureRecognizer:picTap];

    }
    

    

}

- (void)viewWillAppear:(BOOL)animated {
    
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:4] setTitle:@""];

    
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

- (void)viewDidAppear:(BOOL)animated {
    // ADD LAYOUT CONSTRAINT FOR MAKING THE CONTENT VIEW AND SCROLL VIEW THE RIGHT SIZE
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1
                                                           constant:0]];

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

- (IBAction)followingButtonPressed:(id)sender {
    NSLog(@"Following Button Pressed");
    
    FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:YES];
    [self.navigationController pushViewController:vc animated:YES];
    
}
- (IBAction)logOutButtonPressed:(id)sender {
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] logout];
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

- (void)editButtonPressed:(id)sender {

    //TODO: display an Edit Profile modal view controller
    
//    // Selected means we're IN editing mode.
//    if (self.editButton.selected) {
//        [self.bioTextView setEditable:NO];
//        [self.bioTextView setSelectable:NO];
//        
//        // Save it to parse
//        [self updateUserBio:self.bioTextView.text];
//    }
//    else {
//        [self.bioTextView setEditable:YES];
//        [self.bioTextView setSelectable:YES];
//        [self.bioTextView becomeFirstResponder];
//
//    }
//    // Toggle selection
//    [_editButton setSelected:!self.editButton.selected];

    
}

- (void)updateUserBio:(NSString *)bio {
    // Ensure it's the current user so we don't accidentally let people change other people's bios
    if ([_user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        if (![_user[@"bio"] isEqualToString:bio]) {
            [_user setValue:bio forKey:@"bio"];
            [_user saveInBackground];
            NSLog(@"Bio Updated");
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesBegan:withEvent:");
    [self.bioTextView resignFirstResponder];
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

- (void)setProfilePic:(NSString *)urlString {
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

#pragma mark - Profile Pic Selector

- (void)profileImageViewTapped:(UIGestureRecognizer *)gestureRecognizer {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    picker.navigationController.title = @"Select profile picture.";
    [picker.navigationController setTitle:@"Select profile picture."];
    
    picker.navigationBar.tintColor = [UIColor whiteColor];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self presentViewController:picker animated:YES completion:NULL];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.profilePicImageView.image = info[UIImagePickerControllerOriginalImage];
    [self.profilePicImageView setClipsToBounds:YES];
    
    // set the reference URL now so we have it for uploading the raw image data
    
    NSString *imageUrl = [NSString stringWithFormat:@"%@", info[UIImagePickerControllerReferenceURL]];
    NSURL *assetUrl = [NSURL URLWithString:imageUrl];
    NSArray *urlArray = [[NSArray alloc] initWithObjects:assetUrl, nil];
    PHAsset *imageAsset = [[PHAsset fetchAssetsWithALAssetURLs:urlArray options:nil] firstObject];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    [options setVersion:PHImageRequestOptionsVersionOriginal];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
    
    [[PHImageManager defaultManager] requestImageDataForAsset:imageAsset
                                                      options:options
                                                resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                    // Calls the method to actually upload the image and save the User to parse
                                                    [[TTUtility sharedInstance] uploadProfilePic:imageData forUser:[PFUser currentUser]];
                                                }];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
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
