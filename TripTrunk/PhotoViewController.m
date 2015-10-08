//
//  PhotoViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/29/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "PhotoViewController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "UIImageView+AFNetworking.h"
#import "Comment.h"
#import "TTUtility.h"
#import "SocialUtility.h"
#import "UserProfileViewController.h"
#import "ActivityListViewController.h"
#import "CommentListViewController.h"
#import "TTCache.h"
#import "TrunkViewController.h"


@interface PhotoViewController () <UIAlertViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate>
// IBOutlets
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *topButtonWrapper;
@property (weak, nonatomic) IBOutlet UIView *bottomButtonWrapper;
@property (weak, nonatomic) IBOutlet UIButton *comments;
@property (strong, nonatomic) IBOutlet UIButton *likeCountButton;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *photoTakenBy;
@property (weak, nonatomic) IBOutlet UIButton *trunkNameButton;

// Data Properties
@property NSMutableArray *commentActivities;
@property NSMutableArray *likeActivities;
@property BOOL isLikedByCurrentUser;
@property BOOL viewMoved;

@property BOOL shouldShowTrunkNameButton;

@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    // Tab Bar Initializiation
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:4] setTitle:@""];
    

    
    // Set initial UI
    self.photoTakenBy.adjustsFontSizeToFitWidth = YES;
    //FIXME: if I self.photo.user.username it crashes thee app
    self.photoTakenBy.text = self.photo.userName;
    
    // Decide if we should show the trunkNameButton
    // - If we're on the Activity tab, then we want the user to be able to get to the Trunk from the Photo view
    // Any other tab, we already know the trunk (we can go back!).
    // Tab Index 3 is the Activity Tab.
    // NOTE: just because shouldShowTrunkNameButton = YES, the button may still be hidden if the user toggles it of.
    self.shouldShowTrunkNameButton = NO;
    UITabBarController *tabbarcontroller = (UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    if (tabbarcontroller.selectedIndex == 3) {
        self.shouldShowTrunkNameButton = YES;
    }
    [self.trunkNameButton setHidden:YES];
    
    self.commentActivities = [[NSMutableArray alloc] init];
//    [self.comments setTitle:[NSString stringWithFormat:@"%ld Comments", (long)self.commentActivities.count] forState:UIControlStateNormal];
    
    self.likeActivities = [[NSMutableArray alloc] init];
//    [self.likeCountButton setTitle:[NSString stringWithFormat:@"%ld Likes", (long)self.likeActivities.count] forState:UIControlStateNormal];
    
    [self addGestureRecognizers];
    
    // Load initial data (photo and comments)
    [self loadImageForPhoto:self.photo];
    
    [self refreshPhotoActivities];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshPhotoActivities)
                                                 name:@"commentUpdatedOnPhoto"
                                               object:nil];
    
    
    
    
    
    self.scrollView.delegate = self;
    [self.scrollView setClipsToBounds:YES];
    // Setup the scroll view - needed for Zooming
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 6.0;
    self.scrollView.zoomScale = 1.0;
    [self.scrollView setContentMode:UIViewContentModeScaleAspectFit];

}

- (CAGradientLayer*) greyGradientForTop:(BOOL)isTop {
    
    UIColor *colorOne = [UIColor colorWithWhite:0.0 alpha:0.3];
    UIColor *colorTwo = [UIColor colorWithWhite:0.0 alpha:0.2];
    UIColor *colorThree     = [UIColor colorWithWhite:0.0 alpha:0.0];
    
    NSArray *colors;
    NSNumber *stopTwo;
    if (isTop) {
        colors =  [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, colorThree.CGColor, nil];
        stopTwo = [NSNumber numberWithFloat:0.3];
    }
    else {
        colors =  [NSArray arrayWithObjects:(id)colorThree.CGColor, colorTwo.CGColor, colorOne.CGColor, nil];
        stopTwo = [NSNumber numberWithFloat:0.6];

    }
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];

    NSNumber *stopThree     = [NSNumber numberWithFloat:0.9];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, stopThree, nil];
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
    
}

-(void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:4] setTitle:@""];

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    
    [self.comments setTitle:[NSString stringWithFormat:@"%@ Comments", [[TTCache sharedCache] commentCountForPhoto:self.photo]] forState:UIControlStateNormal];
    [self.likeCountButton setTitle:[NSString stringWithFormat:@"%@ Likes", [[TTCache sharedCache] likeCountForPhoto:self.photo]] forState:UIControlStateNormal];
    [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
}



-(void)viewDidLayoutSubviews {
    [self.imageView setFrame:[[UIScreen mainScreen] bounds]];

    [self.scrollView setContentSize:CGSizeMake(_imageView.frame.size.width, _imageView.frame.size.height)];
    
    

    [self centerScrollViewContents];
    
    // Set up gradients for top and bottom button wrappers
    CAGradientLayer *gradient = [self greyGradientForTop:YES];
    gradient.frame = self.topButtonWrapper.bounds;
    CAGradientLayer *bottomGradient = [self greyGradientForTop:NO];
    bottomGradient.frame = self.bottomButtonWrapper.bounds;
    [self.topButtonWrapper.layer insertSublayer:gradient atIndex:0];
    [self.bottomButtonWrapper.layer insertSublayer:bottomGradient atIndex:0];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    self.navigationController.navigationBarHidden = NO;
    self.tabBarController.tabBar.hidden = NO;
}

- (void)centerScrollViewContents {
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    
    self.imageView.frame = contentsFrame;
    
    
}

- (void)addGestureRecognizers {
    // Add swipe gestures
    UISwipeGestureRecognizer *swipeleft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeleft:)];
    swipeleft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeleft];
    
    UISwipeGestureRecognizer *swiperight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    swiperight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swiperight];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeUp:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)toggleButtonVisibility {
    
    [UIView transitionWithView:self.view duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void){
        self.topButtonWrapper.hidden = !self.topButtonWrapper.hidden;
        self.bottomButtonWrapper.hidden = !self.bottomButtonWrapper.hidden;
    } completion:nil];

}

- (void)tripLoaded:(Trip *)trip {
    if (self.shouldShowTrunkNameButton) {
        [self.trunkNameButton setTitle:trip.name forState:UIControlStateNormal];
        [self.trunkNameButton setHidden:NO];
    }
}

#pragma mark - Photo Data

- (void)loadImageForPhoto: (Photo *)photo {
    
    NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    UIImage *placeholderImage = photo.image;
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [self.imageView setImageWithURLRequest:request
                      placeholderImage:placeholderImage
                               success:nil failure:nil];
}

-(void)refreshPhotoActivities {
    
    if (self.shouldShowTrunkNameButton) {
        // Populate the photo's trip reference so we can allow linking to the Trunk from the photo view.
        // If we aren't going to show the button, dont' worry about populating self.photo.trip
        [self.photo.trip fetchInBackgroundWithTarget:self selector:@selector(tripLoaded:)];
    }

    
    self.likeActivities = [[NSMutableArray alloc] init];
    self.commentActivities = [[NSMutableArray alloc] init];
    
    self.isLikedByCurrentUser = NO;
    
    // Get Activities for Photo
    PFQuery *query = [SocialUtility queryForActivitiesOnPhoto:self.photo cachePolicy:kPFCachePolicyNetworkOnly];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *activity in objects) {
                // Separate the Activities into Likes and Comments
                if ([[activity objectForKey:@"type"] isEqualToString:@"like"] && [activity objectForKey:@"fromUser"]) {
                    [self.likeActivities addObject: activity];
                }
                else if ([[activity objectForKey:@"type"] isEqualToString:@"comment"] && [activity objectForKey:@"fromUser"]) {
                    [self.commentActivities addObject:activity];
                }
                
                if ([[[activity objectForKey:@"fromUser"] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                    if ([[activity objectForKey:@"type"] isEqualToString:@"like"]) {
                        self.isLikedByCurrentUser = YES;
                    }
                }
            }
            
//            [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.isLikedByCurrentUser];
            
            //TODO: update cached photo attributes, i.e. likers, commenters, etc.
            [[TTCache sharedCache] setAttributesForPhoto:self.photo likers:self.likeActivities commenters:self.commentActivities likedByCurrentUser:self.isLikedByCurrentUser];
            
            
            // Update number of likes & comments
            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.likeButton setSelected:self.isLikedByCurrentUser];
//                [self.likeCountButton setTitle:[NSString stringWithFormat:@"%ld Likes", (long)self.likeActivities.count] forState:UIControlStateNormal];
//                
//                [self.comments setTitle:[NSString stringWithFormat:@"%ld Comments", (long)self.commentActivities.count] forState:UIControlStateNormal];
//            
                [self.comments setTitle:[NSString stringWithFormat:@"%@ Comments", [[TTCache sharedCache] commentCountForPhoto:self.photo]] forState:UIControlStateNormal];
                [self.likeCountButton setTitle:[NSString stringWithFormat:@"%@ Likes", [[TTCache sharedCache] likeCountForPhoto:self.photo]] forState:UIControlStateNormal];
                [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
            });
            
        }
        else {
            NSLog(@"Error loading photo Activities: %@", error);
        }
    }];
}

#pragma mark - Gestures

- (void)swiperight:(UISwipeGestureRecognizer*)gestureRecognizer
{
    // Prevents a crash when the PhotoViewController was presented from a Push Notification--aka it doesn't have a self.photos array
    if (!self.photos || self.photos.count == 0) {
        return;
    }
    
    NSLog(@"check 1 = %ld", (long)self.arrayInt);
    if (self.arrayInt > 0)
    {
        self.arrayInt = self.arrayInt - 1;
        self.photo = [self.photos objectAtIndex:self.arrayInt];
        [self loadImageForPhoto:self.photo];
//        self.title = self.photo.userName;
        self.photoTakenBy.text = self.photo.userName;

        
        [self.comments setTitle:[NSString stringWithFormat:@"%@ Comments", [[TTCache sharedCache] commentCountForPhoto:self.photo]] forState:UIControlStateNormal];
        [self.likeCountButton setTitle:[NSString stringWithFormat:@"%@ Likes", [[TTCache sharedCache] likeCountForPhoto:self.photo]] forState:UIControlStateNormal];
        [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];

        [self refreshPhotoActivities];
    }
}

- (void)swipeleft:(UISwipeGestureRecognizer*)gestureRecognizer
{
    if (!self.photos || self.photos.count == 0) {
        return;
    }
    
    if (self.arrayInt != self.photos.count - 1)
    {
        self.arrayInt = self.arrayInt + 1;
        self.photo = [self.photos objectAtIndex:self.arrayInt];
        [self loadImageForPhoto:self.photo];
//        self.title = self.photo.userName;
        self.photoTakenBy.text = self.photo.userName;

        
        [self.comments setTitle:[NSString stringWithFormat:@"%@ Comments", [[TTCache sharedCache] commentCountForPhoto:self.photo]] forState:UIControlStateNormal];
        [self.likeCountButton setTitle:[NSString stringWithFormat:@"%@ Likes", [[TTCache sharedCache] likeCountForPhoto:self.photo]] forState:UIControlStateNormal];
        [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
        
        [self refreshPhotoActivities];

    }
}

- (void)swipeUp:(UISwipeGestureRecognizer*)gestureRecognizer
{
    CommentListViewController *vc = [[CommentListViewController alloc] initWithComments:self.commentActivities forPhoto:self.photo];
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
//    [self presentViewController:navController animated:YES completion:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)swipeDown:(UISwipeGestureRecognizer*)gestureRecognizer
{
//    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleTap:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self toggleButtonVisibility];
}

#pragma mark - Button Actions

- (IBAction)onSavePhotoTapped:(id)sender {

    UIActionSheet *actionSheet;
    if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:@"Delete Photo"
                                         otherButtonTitles:@"Report Inappropriate", @"Download Photo", nil];
    }
    else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:@"Report Inappropriate", @"Download Photo", nil];
    }

    
    [actionSheet showInView:self.view];
}

- (IBAction)onCommentsTapped:(id)sender {
    
    
    CommentListViewController *vc = [[CommentListViewController alloc] initWithComments:self.commentActivities forPhoto:self.photo];
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
//    [self presentViewController:navController animated:YES completion:nil];
    [self.navigationController pushViewController:vc animated:YES];

}

- (IBAction)likeCountButtonPressed:(id)sender {
    
    ActivityListViewController *vc = [[ActivityListViewController alloc] initWithLikes:self.likeActivities];
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
//    [self presentViewController:navController animated:YES completion:nil];
    [self.navigationController pushViewController:vc animated:YES];

}

- (IBAction)likeButtonPressed:(id)sender {
    
//    self.likeButton.enabled = NO;
    
    // Like Photo
    if (!self.likeButton.selected)
    {
        [[TTCache sharedCache] incrementLikerCountForPhoto:self.photo];
        
        [self.likeButton setSelected:YES];
        [SocialUtility likePhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            self.likeButton.enabled = YES;
            if (succeeded) {
                [self refreshPhotoActivities];
            }
            else {
                NSLog(@"Error liking photo: %@", error);
            }
        }];
    }
    // Unlike Photo
    else if (self.likeButton.selected) {
        
        [[TTCache sharedCache] decrementLikerCountForPhoto:self.photo];

        [self.likeButton setSelected:NO];
        [SocialUtility unlikePhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            self.likeButton.enabled = YES;
            
            if (succeeded) {
                [self refreshPhotoActivities];
            }
            else {
                NSLog(@"Error unliking photo: %@", error);
            }
        }];
    }
    
    [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.likeButton.selected];
    [self.comments setTitle:[NSString stringWithFormat:@"%@ Comments", [[TTCache sharedCache] commentCountForPhoto:self.photo]] forState:UIControlStateNormal];
    [self.likeCountButton setTitle:[NSString stringWithFormat:@"%@ Likes", [[TTCache sharedCache] likeCountForPhoto:self.photo]] forState:UIControlStateNormal];
    [self.likeButton setSelected:[[TTCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
    
}
- (IBAction)trunkNameButtonPressed:(id)sender {
        
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
    trunkViewController.trip = (Trip *)self.photo.trip;
    
    //FIXME NOT SURE WHATS HAPPENING HERE MATT
    
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Photo View DIsmissed");
        
        UITabBarController *tabbarcontroller = (UITabBarController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        UINavigationController *activityNavController = [[tabbarcontroller viewControllers] objectAtIndex:3];
        if (tabbarcontroller.selectedIndex == 3) {
            [activityNavController pushViewController:trunkViewController animated:YES];
        }
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Delete
        if (alertView.tag == 0) {
            
            //TODO: What if they're deleting the only photo in the trunk?
            
            [[TTUtility sharedInstance] deletePhoto:self.photo];

            // dismiss the view
            [self.navigationController popViewControllerAnimated:YES];
            
        }
        // Download Photo
        else if (alertView.tag == 1) {
            [[TTUtility sharedInstance] downloadPhoto:self.photo];
        }
        // Report Photo
        else if (alertView.tag == 2) {
            NSString *reason = [alertView textFieldAtIndex:0].text;
            [[TTUtility sharedInstance] reportPhoto:self.photo withReason:reason];
        }
    }
}
- (IBAction)closeButtonPressed:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // if the user is the photo owner, they have the Delete option
    if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
        if (buttonIndex == 0) {
            NSLog(@"Delete Photo");
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.title = @"Are you sure you want to delete this photo?";
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:@"No"];
            [alertView addButtonWithTitle:@"Yes"];
            alertView.tag = 0;
            [alertView show];
            
        }
        else if (buttonIndex == 1) {
            NSLog(@"Report Photo");
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Report Photo" message:@"What is inappropriate about this photo?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField * alertTextField = [alert textFieldAtIndex:0];
            alertTextField.keyboardType = UIKeyboardTypeAlphabet;
            alertTextField.placeholder = @"Enter photo's violation.";
            alert.tag = 2;
            [alert show];
        }
        else if (buttonIndex == 2 ){
            NSLog(@"Download Photo");
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.title = @"Save photo to phone?";
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:@"No"];
            [alertView addButtonWithTitle:@"Download"];
            alertView.tag = 1;
            [alertView show];
            
        }
        
    }
    // Not photo owner, they can't delete.
    else {
        if (buttonIndex == 0) {
            NSLog(@"Report Photo");
            NSLog(@"Report Photo");
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Report Photo" message:@"What is inappropriate about this photo?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            UITextField * alertTextField = [alert textFieldAtIndex:0];
            alertTextField.keyboardType = UIKeyboardTypeAlphabet;
            alertTextField.placeholder = @"Enter photo's violation.";
            alert.tag = 2;
            [alert show];
        }
        else if (buttonIndex == 1) {
            NSLog(@"Download Photo");
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.title = @"Save photo to phone?";
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:@"No"];
            [alertView addButtonWithTitle:@"Download"];
            alertView.tag = 1;
            [alertView show];
            
        }
    }
    
}

#pragma mark - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
//    CGFloat offsetX = (self.scrollView.bounds.size.width > self.scrollView.contentSize.width)?
//    (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0;
//    CGFloat offsetY = (self.scrollView.bounds.size.height > self.scrollView.contentSize.height)?
//    (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0;
//    self.imageView.center = CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX,
//                                   self.scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    if (scale > 1.0) {
        _scrollView.scrollEnabled = YES;
    }
    else {
        _scrollView.scrollEnabled = NO;
        [self centerScrollViewContents];
    }
}
//-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    [self centerScrollViewContents];
//}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [_scrollView frame].size.height / scale;
    zoomRect.size.width  = [_scrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
