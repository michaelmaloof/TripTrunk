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
#import "TrunkListViewController.h"

@interface UserProfileViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, EditProfileViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *hometownLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profilePicImageView;
@property (strong, nonatomic) IBOutlet UITextView *bioTextView;
@property (strong, nonatomic) IBOutlet UIButton *mapButton;
@property BOOL isFollowing;
@property UIImageView *privateAccountImageView;
@property int privateCount;
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
    self.privateCount = 0;
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
    [self tabBarTitle];
    
    [self.nameLabel setText:_user[@"name"]];
    [self.usernameLabel setText:[NSString stringWithFormat:@"@%@",_user[@"username"]]];
    [self.hometownLabel setText:_user[@"hometown"]];
    
    [self.profilePicImageView setClipsToBounds:YES];
    
    [self setProfilePic:[_user valueForKey:@"profilePicUrl"]];
    
    if (_user[@"bio"]) {
        [self.bioTextView setText:_user[@"bio"]];
    }
    else {
        [self.bioTextView setText:NSLocalizedString(@"Traveling the world, one trunk at a time.",@"Traveling the world, one trunk at a time.")];
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

    //Check whether user account is private
    self.privateAccountImageView.hidden = YES;
    //Add private account icon to user profile pic
    self.privateAccountImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"locked"]];
    [self.profilePicImageView addSubview:self.privateAccountImageView];
    [self.privateAccountImageView setContentMode:UIViewContentModeScaleAspectFill];
    [self.privateAccountImageView setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.privateAccountImageView setFrame: CGRectMake(self.profilePicImageView.frame.origin.x + self.profilePicImageView.image.size.width,
                                                       self.profilePicImageView.frame.origin.y + self.profilePicImageView.image.size.height,
                                                       25.0,
                                                       25.0)];
    if ([[self.user valueForKey:@"private"] boolValue])
    {
        self.privateAccountImageView.hidden = NO;
    } else {
        self.privateAccountImageView.hidden = YES;

    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.followButton.enabled = NO;
    self.followersButton.enabled = NO;
    self.followingButton.enabled = NO;
    self.mapButton.userInteractionEnabled = NO;
    self.followersButton.enabled = NO;

    // Don't show the follow button if it's the current user's profile
    if ([[_user objectId] isEqual: [[PFUser currentUser] objectId]]) {
        self.followButton.enabled = YES;
        [self.followButton setHidden:YES];
        self.followersButton.enabled = YES;
        self.followingButton.enabled = YES;
        self.mapButton.userInteractionEnabled = YES;
        self.followersButton.enabled = YES;
        
    }
    else {
        // Get the followStatus from the cache so it may be updated already
        NSNumber *followStatus = [[TTCache sharedCache] followStatusForUser:self.user];
        if (followStatus.intValue == 2){
            [self.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateSelected];
        }
        
        if (followStatus.intValue > 0) {
            // We have the following status, so update the Selected status and enable the button
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.followButton setEnabled:YES];
                [self.followButton setSelected:YES];
                
                if (followStatus.intValue == 2) {
                    if ((BOOL)self.user[@"private"] == 1){
                        self.isFollowing = NO;
                        self.followButton.enabled = YES;
                        self.followersButton.enabled = YES;
                        self.followingButton.enabled = YES;
                        self.mapButton.userInteractionEnabled = YES;
                        self.followersButton.enabled = NO;
                    } else {
                        self.isFollowing = NO;
                        self.followButton.enabled = YES;
                        self.followersButton.enabled = YES;
                        self.followingButton.enabled = YES;
                        self.mapButton.userInteractionEnabled = YES;
                        self.followersButton.enabled = YES;
                    }

                    [self.followButton setTitle:NSLocalizedString(@"Pending",@"Pending") forState:UIControlStateSelected];
                }
                else if (followStatus.intValue == 1) {
                    [self.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateSelected];
                    if ((BOOL)self.user[@"private"] == 1){
                        self.isFollowing = YES;
                        self.followButton.enabled = YES;
                        self.followersButton.enabled = YES;
                        self.followingButton.enabled = YES;
                        self.mapButton.userInteractionEnabled = YES;
                        self.followersButton.enabled = YES;
                    } else {
                        self.isFollowing = YES;
                        self.followButton.enabled = YES;
                        self.followersButton.enabled = YES;
                        self.followingButton.enabled = YES;
                        self.mapButton.userInteractionEnabled = YES;
                        self.followersButton.enabled = YES;
                    }
                }
            });
        }
        else
        {
            // Not following this user in CACHE, enable the button and set the selected status
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.followButton setSelected:NO];
            });
        }
        
        // Now update the followStatus from Parse to ensure it actually is updated
        [SocialUtility followingStatusFromUser:[PFUser currentUser] toUser:self.user block:^(NSNumber *followingStatus, NSError *error) {
            if (!error) {
                if (followingStatus.intValue > 0)
                {
                    // We have the following status, so update the Selected status and enable the button
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.followButton setEnabled:YES];
                        [self.followButton setSelected:YES];
                        if (followingStatus.intValue == 2) {
                            if ((BOOL)self.user[@"private"] == 1){
                                self.isFollowing = NO;
                                self.followButton.enabled = YES;
                                self.followersButton.enabled = YES;
                                self.followingButton.enabled = YES;
                                self.mapButton.userInteractionEnabled = YES;
                                self.followersButton.enabled = YES;
                            } else {
                                self.isFollowing = NO;
                                self.followButton.enabled = YES;
                                self.followersButton.enabled = YES;
                                self.followingButton.enabled = YES;
                                self.mapButton.userInteractionEnabled = YES;
                                self.followersButton.enabled = YES;
                            }
                            
                            [self.followButton setTitle:NSLocalizedString(@"Pending",@"Pending") forState:UIControlStateSelected];
                        }
                        else if (followStatus.intValue == 1){
                            self.isFollowing = YES;
                            self.followButton.enabled = YES;
                            self.followersButton.enabled = YES;
                            self.followingButton.enabled = YES;
                            self.mapButton.userInteractionEnabled = YES;
                            self.followersButton.enabled = YES;
                            [self.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateSelected];
                        }
                    });
                }
                else {
                    // Not following this user, enable the button and set the selected status
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.followButton setEnabled:YES];
                        [self.followButton setSelected:NO];
                        if ((BOOL)self.user[@"private"] == 1){
                            self.isFollowing = NO;
                            self.followButton.enabled = YES;
                            self.followersButton.enabled = YES;
                            self.followingButton.enabled = YES;
                            self.mapButton.userInteractionEnabled = YES;
                            self.followersButton.enabled = YES;
                        } else {
                            self.isFollowing = NO;
                            self.followButton.enabled = YES;
                            self.followersButton.enabled = YES;
                            self.followingButton.enabled = YES;
                            self.mapButton.userInteractionEnabled = YES;
                            self.followersButton.enabled = YES;
                        }

                    });
                }
            }
            else {
                NSLog(@"Error: %@",error);
            }
        }];
        
        
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
        NSString *followers = NSLocalizedString(@"Followers",@"Followers");
        NSString *following = NSLocalizedString(@"Following",@"Following");

        [self.followersButton setTitle:[NSString stringWithFormat:@"%lu %@",(unsigned long)followersCount,followers] forState:UIControlStateNormal];
        [self.followingButton setTitle:[NSString stringWithFormat:@"%lu %@",(unsigned long)followingCount,following] forState:UIControlStateNormal];
        



    }
    
    [SocialUtility followerCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *followers = NSLocalizedString(@"Followers",@"Followers");
            [self.followersButton setTitle:[NSString stringWithFormat:@"%i %@",count,followers] forState:UIControlStateNormal];
        });
    }];
    
    [SocialUtility followingCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *following = NSLocalizedString(@"Following",@"Following");
            [self.followingButton setTitle:[NSString stringWithFormat:@"%i %@",count,following] forState:UIControlStateNormal];
        });
    }];
    
    [SocialUtility trunkCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (count == 0){
                [self.mapButton setTitle:@"" forState:UIControlStateNormal];
            }else {
                     [self.mapButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateNormal];

                 }
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)followersButtonPressed:(id)sender {
    NSLog(@"Followers Button Pressed");
    if ((BOOL)self.user[@"private"]  == 0){
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ((BOOL)self.user[@"private"] == 1 && self.isFollowing == YES){
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [self increaseLockSize];
    }
}

- (IBAction)followingButtonPressed:(id)sender {
    NSLog(@"Following Button Pressed");
    if ((BOOL)self.user[@"private"] == 0){
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:YES];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ((BOOL)self.user[@"private"] == 1 && self.isFollowing == YES){
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:YES];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:YES];
        [self.navigationController pushViewController:vc animated:YES];

    } else {
        [self increaseLockSize];
    }
    

    
}
- (IBAction)logOutButtonPressed:(id)sender {
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] logout];
}

- (IBAction)followButtonPressed:(id)sender {
    
    if ([self.followButton isSelected]) {
        // Unfollow
        NSLog(@"Attempt to unfollow %@",_user.username);
        [self.followButton setSelected:NO]; // change the button for immediate user feedback
        
        if (self.user[@"private"] == NO){
            [SocialUtility unfollowUser:_user];
        } else if (self.isFollowing == YES){
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.tag = 11;
            NSString *youSure = NSLocalizedString(@"Are you sure you want to unfollow",@"Are you sure you want to unfollow");
            alertView.title = [NSString stringWithFormat:@"%@ %@?",youSure, self.user.username];
            alertView.message = NSLocalizedString(@"Their account is private so you will no longer be able to see any photos they've posted. You will still have access to photos they've posted in trunks that you are a member.",@"Their account is private so you will no longer be able to see any photos they've posted. You will still have access to photos they've posted in trunks that you are a member of.");
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:NSLocalizedString(@"Cancel",@"Cancel")];
            [alertView addButtonWithTitle:NSLocalizedString(@"Unfollow",@"Unfollow")];
            [alertView show];

        }
    }
    else {
        // Follow
        NSLog(@"Attempt to follow %@",_user.username);
        [self.followButton setSelected:YES];
        [self.followButton setTitle:NSLocalizedString(@"Pending",@"Pending") forState:UIControlStateSelected]; // Set the title to pending, and if it's successful then it'll be set to Following
        
        [SocialUtility followUserInBackground:_user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
            }
            if (!succeeded) {
                NSLog(@"Follow NOT success");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Follow Failed",@"Follow Failed")
                                                                message:NSLocalizedString(@"Please try again",@"Please try again")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                      otherButtonTitles:nil, nil];
                
                [self.followButton setSelected:NO];
                [alert show];
            }
            else if ((BOOL)_user[@"private"] == 0)
            {
                [self.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateSelected];
            }
        }];
    }
    
}

-(void)increaseLockSize{
    if (self.privateCount < 3){
        self.privateAccountImageView.frame = CGRectMake(self.privateAccountImageView.frame.origin.x - 10, self.privateAccountImageView.frame.origin.y - 10, self.privateAccountImageView.frame.size.width + 10, self.privateAccountImageView.frame.size.width + 10);
        self.privateCount = self.privateCount + 1;
    }
}

- (IBAction)mapButtonPressed:(id)sender {
    if (![self.mapButton.titleLabel.text isEqualToString:@""]){
        if ((BOOL)self.user[@"private"] == 0){
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            HomeMapViewController *vc = (HomeMapViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HomeMapView"];
            vc.user = self.user;
            [self.navigationController pushViewController:vc animated:YES];
        } else if ((BOOL)self.user[@"private"] == 1 && self.isFollowing == YES){
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            HomeMapViewController *vc = (HomeMapViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HomeMapView"];
            vc.user = self.user;
            [self.navigationController pushViewController:vc animated:YES];
        } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            HomeMapViewController *vc = (HomeMapViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HomeMapView"];
            vc.user = self.user;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            [self increaseLockSize];
        }
    } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && [self.mapButton.titleLabel.text isEqualToString:@""]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You Haven't Created Any Trunks",@"You Haven't Created Any Trunks")
                                                        message:NSLocalizedString(@"Go create some memories and we will store them here for you.",@"Go create some memories and we will store them here for you.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        
        alert.tag = 11;
        [alert show];
    }
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
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
                                               destructiveButtonTitle:NSLocalizedString(@"Block User",@"Block User")
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

-(void)privacyChanged:(PFUser *)user{
    if ([[user valueForKey:@"private"] boolValue])
    {
        self.privateAccountImageView.hidden = NO;
    } else {
        self.privateAccountImageView.hidden = YES;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        NSLog(@"Block User");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are You Sure?",@"Are You Sure?")
                                                            message:NSLocalizedString(@"This user will no longer see your profile or be able to follow you",@"This user will no longer see your profile or be able to follow you")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"No",@"No")
                                                  otherButtonTitles:NSLocalizedString(@"Yes",@"Yes"), nil];
        alertView.tag = 1;
        [alertView show];
        
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && alertView.tag == 1) {
        // BLOCK USER
        [SocialUtility blockUser:_user];
    } else if (alertView.tag == 11 && buttonIndex == 1){
        [SocialUtility unfollowUser:_user];
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
    picker.navigationController.title =NSLocalizedString( @"Select profile picture.",@"Select profile picture.");
    [picker.navigationController setTitle:NSLocalizedString( @"Select profile picture.",@"Select profile picture.")];
    
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
    [viewController.navigationItem setTitle:NSLocalizedString( @"Select Profile Image",@"Select Profile Image")];
}

- (IBAction)trunkListTapped:(id)sender {
    if (![self.mapButton.titleLabel.text isEqualToString:@""]){
        if ((BOOL)self.user[@"private"] == 0){
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            TrunkListViewController *vc = (TrunkListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkList"];
            vc.user = self.user;
            vc.isList = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else if ((BOOL)self.user[@"private"] == 1 && self.isFollowing == YES){
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            TrunkListViewController *vc = (TrunkListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkList"];
            vc.user = self.user;
            vc.isList = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            TrunkListViewController *vc = (TrunkListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkList"];
            vc.user = self.user;
            vc.isList = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            [self increaseLockSize];
        }
    } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && [self.mapButton.titleLabel.text isEqualToString:@""]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You Haven't Created Any Trunks",@"You Haven't Created Any Trunks")
                                                        message:NSLocalizedString(@"Go create some memories and we will store them here for you.",@"Go create some memories and we will store them here for you.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        
        alert.tag = 11;
        [alert show];
    }

}

@end
