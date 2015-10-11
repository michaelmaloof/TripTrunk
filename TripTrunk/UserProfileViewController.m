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
#import "EditProfileViewController.h"

@interface UserProfileViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, EditProfileViewControllerDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *hometownLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profilePicImageView;
@property (strong, nonatomic) IBOutlet UITextView *bioTextView;
@property (strong, nonatomic) IBOutlet UIButton *mapButton;
@property (strong, nonatomic) PFUser *user;
@end

@implementation UserProfileViewController

- (id)initWithUser:(PFUser *)user
{
    self = [super initWithNibName:@"UserProfileViewController" bundle:nil];
    if (self) {
        _user = user;

    }
    return self;
}

- (id)initWithUserId:(NSString *)userId;
{
    self = [super initWithNibName:@"UserProfileViewController" bundle:nil];
    if (self) {
        _user = [PFUser user];
        [_user setObjectId:userId];
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
//
    [self.scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    
    // Make sure we don't have a nil user -- if that happens it's probably because we're going to the profile tab right after logging in.
    if (!_user) {
        _user = [PFUser currentUser];
    }
    
    // If the user hasn't been fully loaded (aka init with ID), fetch the user before moving on.
    [_user fetchIfNeeded];
    self.title  = _user.username;
    
    [self.nameLabel setText:_user[@"name"]];
    [self.usernameLabel setText:[NSString stringWithFormat:@"@%@",_user[@"username"]]];
    [self.hometownLabel setText:_user[@"hometown"]];
    
    [self.profilePicImageView setClipsToBounds:YES];
    
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
    // It's not the current user profile. So let's give them an "options" button that lets the block a user
    else {
        // Set More button
        UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"moreIcon"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(moreButtonPressed:)];
        
        self.navigationItem.rightBarButtonItem = moreButton;

    }

}

- (void)viewWillAppear:(BOOL)animated {
    
    // Don't show the follow button if it's the current user's profile
    if ([[_user objectId] isEqual: [[PFUser currentUser] objectId]]) {
        [self.followButton setHidden:YES];
    }
    else {
        // Refresh the following status of this user
        NSNumber *followStatus = [[TTCache sharedCache] followStatusForUser:self.user];
        if (followStatus.intValue > 0) {
            // We have the following status, so update the Selected status and enable the button
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.followButton setEnabled:YES];
                [self.followButton setSelected:YES];
                if (followStatus.intValue == 2) {
                    [self.followButton setTitle:@"Pending" forState:UIControlStateSelected];
                }
            });
        }
        else
        {
            // Not following this user, enable the button and set the selected status
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.followButton setSelected:NO];
            });
            
            // No cached follow status, so let's get the follow status from Parse.
            [SocialUtility followingStatusFromUser:[PFUser currentUser] toUser:self.user block:^(NSNumber *followingStatus, NSError *error) {
                if (!error) {
                    if (followingStatus.intValue > 0)
                    {
                        // We have the following status, so update the Selected status and enable the button
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.followButton setEnabled:YES];
                            [self.followButton setSelected:YES];
                            if (followingStatus.intValue == 2) {
                                [self.followButton setTitle:@"Pending" forState:UIControlStateSelected];
                            }
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
    
    [self refreshFollowCounts];
}

- (void)refreshFollowCounts {
    
    // If it's the user's profile, then we may have their follow lists cached.
    if ([[_user objectId] isEqual: [[PFUser currentUser] objectId]]) {
        NSUInteger followersCount = [[TTCache sharedCache] followers].count;
        NSUInteger followingCount = [[TTCache sharedCache] following].count;
        [self.followersButton setTitle:[NSString stringWithFormat:@"%lu Followers",(unsigned long)followersCount] forState:UIControlStateNormal];
        [self.followingButton setTitle:[NSString stringWithFormat:@"%lu Following",(unsigned long)followingCount] forState:UIControlStateNormal];
        



    }
    
    [SocialUtility followerCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.followersButton setTitle:[NSString stringWithFormat:@"%i Followers",count] forState:UIControlStateNormal];
        });
    }];
    
    [SocialUtility followingCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.followingButton setTitle:[NSString stringWithFormat:@"%i Following",count] forState:UIControlStateNormal];
        });
    }];
    
    [SocialUtility trunkCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateNormal];
        });
    }];
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
        [self.followButton setTitle:@"Pending" forState:UIControlStateSelected]; // Set the title to pending, and if it's successful then it'll be set to Following
        
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
            else if (!_user[@"private"])
            {
                [self.followButton setTitle:@"Following" forState:UIControlStateSelected];
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

    EditProfileViewController *vc = [[EditProfileViewController alloc] initWithUser:_user];
    vc.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];

}

- (void)moreButtonPressed:(id)sender {
    
    NSLog(@"More Button Pressed");
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Block User"
                                                    otherButtonTitles:nil];
    
    [actionSheet showInView:self.view];
    
}

-(void)shouldSaveUserAndClose:(PFUser *)user {
    // Ensure it's the current user so we don't accidentally let people change other people's info. 
    if ([user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [_user saveInBackground];
        NSLog(@"Bio Updated");
        self.bioTextView.text = user[@"bio"];
        self.hometownLabel.text = user[@"hometown"];
        self.nameLabel.text = user[@"name"];
    }
    
    [[self presentedViewController] dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        NSLog(@"Block User");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are You Sure?"
                                                            message:@"This user will no longer see your profile or be able to follow you"
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                  otherButtonTitles:@"Yes", nil];
        alertView.tag = 1;
        [alertView show];
        
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView.tag == 1) {
        // BLOCK USER
        [SocialUtility blockUser:_user];
    }
}


#pragma mark - Profile Pic Selector

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
