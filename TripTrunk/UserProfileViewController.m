
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
#import "UIImageView+AFNetworking.h"
#import "TTUtility.h"
#import "TTCache.h"
#import "HomeMapViewController.h"
#import "EditProfileViewController.h"
#import "TrunkListViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TTUserProfileViewCell.h"
#import "TTUserProfileCollectionView.h"
#import "PhotoViewController.h"

@interface UserProfileViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, EditProfileViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource, PhotoDelegate>
@property (weak, nonatomic) IBOutlet UIButton *trunkCountButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *listButton;
@property (weak, nonatomic) IBOutlet UIButton *hideThisButtonAlways;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *hometownLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profilePicImageView;
@property (strong, nonatomic) IBOutlet UITextView *bioTextView;
@property (strong, nonatomic) IBOutlet UIButton *mapButton;
@property (weak, nonatomic) IBOutlet UIImageView *privateAccountImageView;
@property BOOL isFollowing;
@property int privateCount;
@property int trunkCount;
@property (strong, nonatomic) IBOutlet UIView *bottomMargainView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scrollViewHeightConstraint;
@property (strong, nonatomic) NSMutableArray *myPhotos;
@property int numberOfImagesPerRow;
@property BOOL isFirstLoad;
@property NSMutableArray *photosSeen;
@property (weak, nonatomic) IBOutlet UILabel *trunkCountLabel;
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
    self.trunkCountButton.hidden = YES;
    [self.trunkCountButton setTitle:@"" forState:UIControlStateNormal];
    self.followButton.tag = 0;
    [self setButtonColor];
    
    //hide the follow button until we know if the current user follows them or not
    self.followButton.hidden = YES;
    
    self.myPhotos = [[NSMutableArray alloc] init];
    //round the profile image
    [self.profilePicImageView.layer  setCornerRadius:50.0];
    [self.profilePicImageView.layer  setMasksToBounds:YES];


    
    self.hideThisButtonAlways.hidden = YES;
    
    self.logoutButton.hidden = YES;
    self.listButton.hidden = YES;
    
    self.numberOfImagesPerRow = 3;
    
    //FIXME MOVE THIS LOGIC ALL TO A UTILITY
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (HomeMapViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[HomeMapViewController class]])
            {
                if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                    if (view == (HomeMapViewController*)controller.viewControllers[0]){
                        self.photosSeen = [[NSMutableArray alloc]init];
                        self.photosSeen = view.viewedPhotos;
                    }
                }
            }
        }
    }
    

    self.privateCount = 0;
    [self.scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;

    // Make sure we don't have a nil user -- if that happens it's probably because we're going to the profile tab right after logging in.
    if (!_user) {
        _user = [PFUser currentUser];
    }
    
    // If the user hasn't been fully loaded (aka init with ID), fetch the user before moving on.
    [self.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if(!error){
            self.user = (PFUser*)object;
            [self displayUsername];
            [self displayHometown];
            [self.profilePicImageView setClipsToBounds:YES];
            [self setProfilePic:[_user valueForKey:@"profilePicUrl"]];
        
            if (self.user[@"bio"]) {
                [self.bioTextView setText:self.user[@"bio"]];
            }else {
            [self.bioTextView setText:NSLocalizedString(@"Traveling the world, one trunk at a time.",@"Traveling the world, one trunk at a time.")];
            }

            [self.logoutButton setHidden:YES];

            // If it's the current user, set up their profile a bit differently.
            if ([[self.user objectId] isEqual: [[PFUser currentUser] objectId]]) {
                [self.followButton setHidden:YES];
                [self setEditButton];
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
            
            if ([[PFUser currentUser].objectId isEqualToString:self.user.objectId]){
                [self loadUserImages];
                
                if ([[self.user valueForKey:@"private"] boolValue]){
                    self.privateAccountImageView.hidden = NO;
                } else {
                    self.privateAccountImageView.hidden = YES;
                }
            }
            
            else if ([[self.user valueForKey:@"private"] boolValue]){
                self.privateAccountImageView.hidden = NO;
            } else {
                self.privateAccountImageView.hidden = YES;
                [self loadUserImages];
            }
            
            
        }else{
            NSLog(@"Error: %@",error);
        }
        
    }];
    
}

-(void)displayUsername{
    //set the navBar title to the username
    self.title  = [NSString stringWithFormat:@"%@",self.user[@"username"]];
    //prevent username from becoming tabbar title
    [self tabBarTitle];
    //combine first and last name to full name to display. If they don't have a first and last name, show "name" (the old way we tracked user's name)
    NSString *name;
    if (self.user[@"lastName"] == nil && self.user[@"firstName"] != nil){
        name = [NSString stringWithFormat:@"%@",self.user[@"firstName"]];
    } else if (self.user[@"firstName"] != nil &&  self.user[@"firstName"] == nil){
        name = [NSString stringWithFormat:@"%@ %@",self.user[@"firstName"],self.user[@"lastName"]];
    } else {
        name = self.user[@"name"];
    }
    //add the privacy lock next to the user's name if that user is private
    if ([[self.user valueForKey:@"private"] boolValue] == 1){
        NSString *namePlusSpace = [NSString stringWithFormat:@"%@  ",name];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:namePlusSpace];
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        textAttachment.image = [UIImage imageNamed:@"lock_small gray"];
        NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
        [attributedString replaceCharactersInRange:NSMakeRange(namePlusSpace.length-1, 1) withAttributedString:attrStringWithImage];
        self.nameLabel.attributedText = attributedString;
    } else {
        self.nameLabel.text = name;
    }
}

-(void)displayHometown{
    NSString *hometownPlusSpace = [NSString stringWithFormat:@"  %@",self.user[@"hometown"]];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:hometownPlusSpace];
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    textAttachment.image = [UIImage imageNamed:@"location"];
    NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
    [attributedString replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:attrStringWithImage];
    self.hometownLabel.attributedText = attributedString;
}

-(void)setEditButton{
    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [editButton setFrame:CGRectMake(0.0f, 0.0f, 25.0f, 25.0f)];
    [editButton addTarget:self action:@selector(editButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [editButton setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
    UIBarButtonItem *editBarButton = [[UIBarButtonItem alloc] initWithCustomView:editButton];
    self.navigationItem.rightBarButtonItem = editBarButton;
}

-(void)loadUserImages{
    PFQuery *findPhotosUser = [PFQuery queryWithClassName:@"Photo"];
    [findPhotosUser whereKey:@"user" equalTo:self.user];
    [findPhotosUser orderByDescending:@"createdAt"];
    [findPhotosUser includeKey:@"trip.creator"];
    [findPhotosUser includeKey:@"trip"];
    [findPhotosUser includeKey:@"user"];
    [findPhotosUser setLimit:1000];
    
    [findPhotosUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            [[TTUtility sharedInstance] internetConnectionFound];
            // Objects is an array of Parse Photo objects
            self.myPhotos = [NSMutableArray arrayWithArray:objects];
            //update photo count when it is not right
            [self.collectionView reloadData];
 
            CGPoint collectionViewPosition = [self.scrollView convertPoint:CGPointZero fromView:self.collectionView];
            NSInteger imageHeight = self.view.frame.size.width/self.numberOfImagesPerRow;
            NSInteger numOfRows = self.myPhotos.count/self.numberOfImagesPerRow;
            if(self.myPhotos.count % self.numberOfImagesPerRow != 0)
                numOfRows++;
            NSInteger heightOfScroll = imageHeight*numOfRows+collectionViewPosition.y;
            
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, heightOfScroll);
            self.scrollViewHeightConstraint.constant = heightOfScroll;
            self.contentViewHeightConstraint.constant = heightOfScroll;
            
        } else {
            [ParseErrorHandlingController handleError:error];
        }
        
    }];

}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *vc = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    vc.photo = (Photo*)[self.myPhotos objectAtIndex:indexPath.row];
    vc.trip = (Trip*)vc.photo.trip;
    vc.arrayInt = (int)indexPath.row;
    vc.photos = self.myPhotos;
    vc.delegate = self;
    vc.fromProfile = YES;
    [self.navigationController showViewController:vc sender:self];
}


-(void)setButtonColor{
    
    if (self.followButton.tag == 1){
        [self.followButton setTitleColor:[TTColor tripTrunkWhite] forState:UIControlStateNormal];
        self.followButton.backgroundColor = [TTColor tripTrunkLightBlue];
        [[self.followButton layer] setBorderColor:[TTColor tripTrunkLightBlue].CGColor];
        [[self.followButton layer] setBorderWidth:0.0f];
    } else {
        [self.followButton setTitleColor:[TTColor tripTrunkLightBlue] forState:UIControlStateNormal];
        self.followButton.backgroundColor = [TTColor tripTrunkWhite];
        [[self.followButton layer] setBorderColor:[TTColor tripTrunkLightBlue].CGColor];
        [[self.followButton layer] setBorderWidth:2.0f];

    }
    
}


- (void)viewWillAppear:(BOOL)animated {
    self.trunkCountButton.hidden = YES;
    [self.trunkCountButton setTitle:@"" forState:UIControlStateNormal];
    [self.followButton setHidden:YES];
    self.followersButton.enabled = NO;
    self.followingButton.enabled = NO;
    self.mapButton.userInteractionEnabled = NO;
    self.trunkCountButton.userInteractionEnabled = NO;
    
    // Don't show the follow button if it's the current user's profile
    if ([[_user objectId] isEqual: [[PFUser currentUser] objectId]]) {
        [self.followButton setHidden:YES];
        self.followersButton.enabled = YES;
        self.followingButton.enabled = YES;
        self.mapButton.userInteractionEnabled = YES;
        self.trunkCountButton.userInteractionEnabled = YES;
    }
    else {
        // Get the followStatus from the cache so it may be updated already
        NSNumber *followStatus = [[TTCache sharedCache] followStatusForUser:self.user];
        //        }
        
        if (followStatus.intValue > 0) {
            // We have the following status, so update the Selected status and enable the button
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (followStatus.intValue == 2) { //Pending
                    if ([[self.user valueForKey:@"private"] boolValue] == 1){
                        self.isFollowing = NO;
                        self.followersButton.enabled = NO;
                        self.followingButton.enabled = NO;
                        self.mapButton.userInteractionEnabled = NO;
                        self.trunkCountButton.userInteractionEnabled = NO;
                    } else {
                        self.isFollowing = NO;
                        self.followersButton.enabled = YES;
                        self.followingButton.enabled = YES;
                        self.mapButton.userInteractionEnabled = YES;
                        self.trunkCountButton.userInteractionEnabled = YES;
                    }
                    
                    self.followButton.tag = 1;
                    [self setButtonColor];
                    
                    [self.followButton setTitle:NSLocalizedString(@"Pending",@"Pending") forState:UIControlStateNormal];
                    [self.followButton setHidden:NO];
                }
                else if (followStatus.intValue == 1) { //following
                    self.followButton.tag = 1;
                    [self setButtonColor];
                    [self.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateNormal];
                    [self.followButton setHidden:NO];
                    self.isFollowing = YES;
                    self.followersButton.enabled = YES;
                    self.followingButton.enabled = YES;
                    self.mapButton.userInteractionEnabled = YES;
                    self.trunkCountButton.userInteractionEnabled = YES;
                    if (self.isFirstLoad == NO){
                        [self loadUserImages];
                        self.isFirstLoad = YES;
                    }
                }
            });
        }
        else
        {
            // Not following this user in CACHE, enable the button and set the selected status
            dispatch_async(dispatch_get_main_queue(), ^{
                self.followButton.tag = 0;
                [self.followButton setTitle:NSLocalizedString(@"Follow",@"Follow") forState:UIControlStateNormal];
                [self setButtonColor];
            });
        }
        
        // Now update the followStatus from Parse to ensure it actually is updated
        [SocialUtility followingStatusFromUser:[PFUser currentUser] toUser:self.user block:^(NSNumber *followingStatus, NSError *error) {
            if (!error) {
                
                if (followingStatus.intValue > 0)
                {
                    // We have the following status, so update the Selected status and enable the button
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (followingStatus.intValue == 2) {
                            if ([[self.user valueForKey:@"private"] boolValue] == 1){
                                self.isFollowing = NO;
                                self.followersButton.enabled = YES;
                                self.followingButton.enabled = YES;
                                self.mapButton.userInteractionEnabled = YES;
                                self.trunkCountButton.userInteractionEnabled = YES;
                            } else {
                                self.isFollowing = NO;
                                self.followersButton.enabled = YES;
                                self.followingButton.enabled = YES;
                                self.mapButton.userInteractionEnabled = YES;
                                self.trunkCountButton.userInteractionEnabled = YES;
                            }
                            [self.followButton setTitle:NSLocalizedString(@"Pending",@"Pending") forState:UIControlStateNormal];
                            self.followButton.tag = 1;
                            [self setButtonColor];
                            [self.followButton setHidden:NO];
                            [self.followButton setEnabled:YES];
                            
                            
                        }
                        else if (followingStatus.intValue == 1){
                            self.isFollowing = YES;
                            self.followersButton.enabled = YES;
                            self.followingButton.enabled = YES;
                            self.mapButton.userInteractionEnabled = YES;
                            self.trunkCountButton.userInteractionEnabled = YES;
                            self.followButton.tag = 1;
                            [self setButtonColor];
                            [self.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateNormal];
                            [self.followButton setHidden:NO];
                            [self.followButton setEnabled:YES];
                            if (self.isFirstLoad == NO){
                                [self loadUserImages];
                                self.isFirstLoad = YES;
                            }
                        }
                    });
                }
                else {
                    // Not following this user, enable the button and set the selected status
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.followButton setEnabled:YES];
                        
                        
                        if ([[self.user valueForKey:@"private"] boolValue] == 1){
                            self.isFollowing = NO;
                            self.followersButton.enabled = YES;
                            self.followingButton.enabled = YES;
                            self.mapButton.userInteractionEnabled = YES;
                            self.trunkCountButton.userInteractionEnabled = YES;
                        } else {
                            self.isFollowing = NO;
                            self.followersButton.enabled = YES;
                            self.followingButton.enabled = YES;
                            self.mapButton.userInteractionEnabled = YES;
                            self.trunkCountButton.userInteractionEnabled = YES;
                        }
                        
                        self.followButton.tag = 0;
                        [self.followButton setTitle:NSLocalizedString(@"Follow",@"Follow") forState:UIControlStateNormal];
                        [self setButtonColor];
                        [self.followButton setHidden:NO];
                        
                        
                    });
                }
            }
            else {
                NSLog(@"Error: %@",error);
            }
        }];
        
        
    }
    
    [self refreshFollowCounts];
}

- (void)refreshFollowCounts {
    
    // If it's the user's profile, then we may have their follow lists cached.
    if ([[_user objectId] isEqual: [[PFUser currentUser] objectId]]) {
        NSUInteger followersCount = [[TTCache sharedCache] followers].count;
        NSUInteger followingCount = [[TTCache sharedCache] following].count;

        
        if (followersCount < 1){ //FOLLOWERS
            [self.followersButton setTitle:@"" forState:UIControlStateNormal];
            [self.followersButton setTitle:@"" forState:UIControlStateDisabled];
        } else {
            [self.followersButton setTitle:[NSString stringWithFormat:@"%lu",(unsigned long)followersCount] forState:UIControlStateNormal];
            [self.followersButton setTitle:[NSString stringWithFormat:@"%lu",(unsigned long)followersCount] forState:UIControlStateDisabled];
        }
        
        if (followingCount < 1){ //FOLLOWING
            [self.followingButton setTitle:@"" forState:UIControlStateNormal];
            [self.followingButton setTitle:@"" forState:UIControlStateDisabled];
            
        } else {
            [self.followingButton setTitle:[NSString stringWithFormat:@"%lu",(unsigned long)followingCount] forState:UIControlStateNormal];
            [self.followingButton setTitle:[NSString stringWithFormat:@"%lu",(unsigned long)followingCount] forState:UIControlStateDisabled];
        }
        
    }
    
    [SocialUtility followerCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.followersButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateNormal];
            [self.followersButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateDisabled];
        });
    }];
    
    [SocialUtility followingCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.followingButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateNormal];
            [self.followingButton setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateDisabled];
        });
    }];
    
    [SocialUtility trunkCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.trunkCount= count;
            
            if (count == 0){
                self.trunkCountButton.hidden = YES;
                [self.trunkCountButton setTitle:@"" forState:UIControlStateNormal];
                self.listButton.hidden = YES;
                self.trunkCountButton.hidden = NO;

            }else {
                self.trunkCountButton.hidden = YES;
                [self.trunkCountButton   setTitle:[NSString stringWithFormat:@"%i",count] forState:UIControlStateNormal];
                self.trunkCountButton.hidden = NO;
            }
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)followersButtonPressed:(id)sender {
    if ([[self.user valueForKey:@"private"] boolValue]  == 0){
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:NO];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([[self.user valueForKey:@"private"] boolValue] == 1 && self.isFollowing == YES){
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
    if ([[self.user valueForKey:@"private"] boolValue] == 0){
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:YES];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([[self.user valueForKey:@"private"] boolValue] == 1 && self.isFollowing == YES){
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:YES];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        FriendsListViewController *vc = [[FriendsListViewController alloc] initWithUser:_user andFollowingStatus:YES];
        [self.navigationController pushViewController:vc animated:YES];

    } else {
        [self increaseLockSize];
    }
    

    
}


- (IBAction)followButtonPressed:(id)sender {
    
    self.followButton.enabled = NO;

    
    BOOL isPrivate = [[self.user valueForKey:@"private"] boolValue];
    
    if (self.followButton.tag == 1) {
        // Unfollow
        
        if (isPrivate == NO){
            [SocialUtility unfollowUser:_user];
            [self.followButton setTitle:NSLocalizedString(@"Follow",@"Follow") forState:UIControlStateNormal];
            self.followButton.tag = 0;
            [self setButtonColor];
            self.followButton.enabled = YES;


        } else if (self.isFollowing == YES){
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.tag = 11;
            NSString *youSure = NSLocalizedString(@"Are you sure you want to unfollow",@"Are you sure you want to unfollow");
            alertView.title = [NSString stringWithFormat:@"%@ %@?",youSure, self.user.username];
            alertView.message = NSLocalizedString(@"Their account is private so you will no longer be able to see any photos they've posted. You will still have access to photos they've posted in trunks that you are a member.",@"Their account is private so you will no longer be able to see any photos they've posted. You will still have access to photos they've posted in trunks that you are a member of.");
            alertView.backgroundColor = [TTColor tripTrunkLightBlue];
            [alertView addButtonWithTitle:NSLocalizedString(@"Cancel",@"Cancel")];
            [alertView addButtonWithTitle:NSLocalizedString(@"Unfollow",@"Unfollow")];
            [alertView show];

        }
    }
    else {
        // Follow
        
        [self.followButton setTitle:NSLocalizedString(@"Pending",@"Pending") forState:UIControlStateNormal]; // Set the title to pending, and if it's successful then it'll be set to Following
        self.followButton.tag = 1;
        [self setButtonColor];
        
        
        
        [SocialUtility followUserInBackground:_user block:^(BOOL succeeded, NSError *error) {
            
            self.followButton.enabled = YES;

            
            if (error) {
                NSLog(@"Error: %@", error);
                self.followButton.tag = 0;
                [self.followButton setTitle:NSLocalizedString(@"Follow",@"Follow") forState:UIControlStateNormal];
                [self setButtonColor];
            }
            if (!succeeded) {
                self.followButton.tag = 0;
                [self setButtonColor];
                NSLog(@"Follow NOT success");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Follow Failed",@"Follow Failed")
                                                                message:NSLocalizedString(@"Please try again",@"Please try again")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                      otherButtonTitles:nil, nil];
                

            
                [alert show];
            }
            else if (isPrivate == 0)
            {
                self.followButton.tag = 1;
                [self setButtonColor];
                self.followButton.enabled = YES;
                [self.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateNormal];
            
            }
        }];
    }
    
}

-(void)increaseLockSize{
    if (self.privateCount < 3){
        self.privateAccountImageView.frame = CGRectMake(self.privateAccountImageView.frame.origin.x - 5, self.privateAccountImageView.frame.origin.y - 5, self.privateAccountImageView.frame.size.width + 5, self.privateAccountImageView.frame.size.width + 5);
        self.privateCount = self.privateCount + 1;
    }
}

- (IBAction)trunkCountPressed:(id)sender {
    [self handleTrunkTap];
}

- (IBAction)mapButtonPressed:(id)sender {
    [self handleTrunkTap];
}

-(void)handleTrunkTap{
    if (self.trunkCount >0){
        if ([[self.user valueForKey:@"private"] boolValue] == 0)
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            HomeMapViewController *vc = (HomeMapViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HomeMapView"];
            vc.user = self.user;
            [self.navigationController pushViewController:vc animated:YES];
        } else if ([[self.user valueForKey:@"private"] boolValue] == 1 && self.isFollowing == YES)
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            HomeMapViewController *vc = (HomeMapViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HomeMapView"];
            vc.user = self.user;
            [self.navigationController pushViewController:vc animated:YES];
        } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId])
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            HomeMapViewController *vc = (HomeMapViewController *)[storyboard instantiateViewControllerWithIdentifier:@"HomeMapView"];
            vc.user = self.user;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            [self increaseLockSize];
        }
    } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && self.trunkCount == 0){
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
    [nav.navigationBar setBarTintColor:[TTColor tripTrunkWhite]];
    
    [nav.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [TTColor tripTrunkBlue], NSForegroundColorAttributeName,
                                                           [UIFont fontWithName:@"American Typewritter" size:40.0], NSFontAttributeName, nil]];
    [self presentViewController:nav animated:YES completion:nil];

}

- (void)moreButtonPressed:(id)sender {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
                                               destructiveButtonTitle:NSLocalizedString(@"Block User",@"Block User")
                                                    otherButtonTitles:nil];
    
    [actionSheet showInView:self.view];
    
}
//FIXME What is this
-(void)shouldSaveUserAndClose:(PFUser *)user {
    // Ensure it's the current user so we don't accidentally let people change other people's info. 
    if ([user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [_user saveInBackground];
        self.bioTextView.text = user[@"bio"];
        self.hometownLabel.text = user[@"hometown"];
        NSString *name;
        if (user[@"firstName"] == nil || user[@"lastName"] == nil){
            name = [NSString stringWithFormat:@"%@",user[@"name"]];
        } else {
            name = [NSString stringWithFormat:@"%@ %@",user[@"firstName"],user[@"lastName"]];
        }
        self.nameLabel.text = name;
        
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
        self.followButton.tag = 0;
        [self setButtonColor];
        [self.followButton setTitle:NSLocalizedString(@"Follow",@"Follow") forState:UIControlStateNormal];
        [SocialUtility unfollowUser:_user];
        self.followButton.enabled = YES;

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
    picker.navigationController.title =NSLocalizedString( @"Select profile picture.",@"Select profile picture.");
    [picker.navigationController setTitle:NSLocalizedString( @"Select profile picture.",@"Select profile picture.")];
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
    if (self.trunkCount >0){
        if ([[self.user valueForKey:@"private"] boolValue] == 0){
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            TrunkListViewController *vc = (TrunkListViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkList"];
            vc.user = self.user;
            vc.isList = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else if ([[self.user valueForKey:@"private"] boolValue] == 1 && self.isFollowing == YES){
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
    } else if ([self.user.objectId isEqualToString:[PFUser currentUser].objectId] && self.trunkCount == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You Haven't Created Any Trunks",@"You Haven't Created Any Trunks")
                                                        message:NSLocalizedString(@"Go create some memories and we will store them here for you.",@"Go create some memories and we will store them here for you.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        
        alert.tag = 11;
        [alert show];
    }

}

#pragma mark - UICollectionVireDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.myPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    UINib *nib = [UINib nibWithNibName:@"TTUserProfileViewCell" bundle: nil];
    [collectionView registerNib:nib forCellWithReuseIdentifier:@"myImagesCell"];
    
    TTUserProfileViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"myImagesCell" forIndexPath:indexPath];
    Photo *photo = [self.myPhotos objectAtIndex:indexPath.item];
    
    NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
    
    NSTimeInterval lastPhotoInterval = [lastOpenedApp timeIntervalSinceDate:photo.createdAt];
    if (lastPhotoInterval < 0)
    {
        if (![self.photosSeen containsObject:photo.objectId]){
            cell.logo.hidden = NO;
        } else {
            cell.logo.hidden = YES;
        }
        
    } else {
        cell.logo.hidden = YES;
    }

    
    [cell.image setContentMode:UIViewContentModeScaleAspectFill];
    //        cell.photo.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, self.view.frame.size.width/3, self.view.frame.size.width/3);
    cell.image.clipsToBounds = YES;
    cell.image.translatesAutoresizingMaskIntoConstraints = NO;
    cell.image.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSString *urlString = [[TTUtility sharedInstance] thumbnailImageUrl:photo.imageUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    UIImage *placeholderImage = [UIImage imageNamed:@"Load"];
    __weak TTUserProfileViewCell *weakCell = cell;
    [weakCell.image setContentMode:UIViewContentModeScaleAspectFill];
    weakCell.image.clipsToBounds = YES;
    weakCell.image.translatesAutoresizingMaskIntoConstraints = NO;
    weakCell.image.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    NSInteger index = indexPath.item;
    
    [cell.image setImageWithURLRequest:request
                      placeholderImage:placeholderImage
                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                [(Photo *)[self.myPhotos objectAtIndex:index] setImage:image];
                                weakCell.image.image = image;
                                [weakCell layoutIfNeeded];
                                   
                               } failure:nil];
    return weakCell;
    return cell;
}

#pragma mark - UICollectionViewDelegate


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.frame.size.width/self.numberOfImagesPerRow, self.view.frame.size.width/self.numberOfImagesPerRow);

}

#pragma  Photo Delegate

-(void)photoWasLiked:(BOOL)isFromError{
    
}

-(void)photoWasDisliked:(BOOL)isFromError{

}

-(void)photoWasViewed:(Photo *)photo{
    [self.photosSeen addObject:photo.objectId];
    [self.collectionView reloadData];
}


-(void)photoWasDeleted:(NSNumber *)likes photo:(Photo *)photo{
    [self.myPhotos removeObject:photo];
    [self.collectionView reloadData];
}

-(void)textViewDidChange:(UITextView *)textView{
    if ([textView.text length] > 1){

    NSString *code = [textView.text substringFromIndex: [textView.text length] - 2];
    if ([code isEqualToString:@" "]){
        [textView setKeyboardType:UIKeyboardTypeDefault];
    }
    }
}



@end
