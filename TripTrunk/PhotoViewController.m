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
#import "TTCache.h"


@interface PhotoViewController () <UIAlertViewDelegate, UIScrollViewDelegate>
// IBOutlets
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *comments;
@property (weak, nonatomic) IBOutlet UIButton *delete;
@property (strong, nonatomic) IBOutlet UIButton *likeCountButton;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;

// Data Properties
@property NSMutableArray *commentActivities;
@property NSMutableArray *likeActivities;
@property BOOL isLikedByCurrentUser;
@property BOOL viewMoved;

@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Tab Bar Initializiation
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    
    // Set initial UI
    self.title = self.photo.userName;
    
    self.delete.hidden = YES;
    if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
        self.delete.hidden = NO;
    }
    
    self.commentActivities = [[NSMutableArray alloc] init];
    [self.comments setTitle:[NSString stringWithFormat:@"%ld Comments", (long)self.commentActivities.count] forState:UIControlStateNormal];
    
    self.likeActivities = [[NSMutableArray alloc] init];
    [self.likeCountButton setTitle:[NSString stringWithFormat:@"%ld Likes", (long)self.likeActivities.count] forState:UIControlStateNormal];
    
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

-(void)viewWillAppear:(BOOL)animated {
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

}



-(void)viewDidLayoutSubviews {
    [self.imageView setFrame:[[UIScreen mainScreen] bounds]];

    [self.scrollView setContentSize:CGSizeMake(_imageView.frame.size.width, _imageView.frame.size.height)];

    [self centerScrollViewContents];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
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
    UISwipeGestureRecognizer * swipeleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeleft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeleft];
    
    UISwipeGestureRecognizer * swiperight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swiperight];
    
    UISwipeGestureRecognizer *swipeDown =[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeVertical:)];
    swipeDown.direction=UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    UITapGestureRecognizer *tapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)toggleButtonVisibility {
    
    [UIView transitionWithView:self.view duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^(void){
        _closeButton.hidden = !_closeButton.hidden;
        _saveButton.hidden = !_saveButton.hidden;
        _likeButton.hidden = !_likeButton.hidden;
        _likeCountButton.hidden = !_likeCountButton.hidden;
        _comments.hidden = !_comments.hidden;
        
        if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
            self.delete.hidden = !self.delete.hidden;
        }
        

        
    } completion:nil];

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
            
            [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.isLikedByCurrentUser];
            
            //TODO: update cached photo attributes, i.e. likers, commenters, etc.
            
            
            // Update number of likes & comments
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.likeButton setSelected:self.isLikedByCurrentUser];
                [self.likeCountButton setTitle:[NSString stringWithFormat:@"%ld Likes", (long)self.likeActivities.count] forState:UIControlStateNormal];
                
                [self.comments setTitle:[NSString stringWithFormat:@"%ld Comments", (long)self.commentActivities.count] forState:UIControlStateNormal];
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
        self.title = self.photo.userName;
        
        [self.likeCountButton setTitle:@"0 Likes" forState:UIControlStateNormal];
        [self.comments setTitle:@"0 Comments" forState:UIControlStateNormal];
        
        // Only show the delete button if the user is the photo owner AND the close button isn't hidden, meaning we aren't in pic-only
        if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId] && !self.closeButton.hidden) {
            self.delete.hidden = NO;
        } else {
            self.delete.hidden = YES;
        }

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
        self.title = self.photo.userName;
        
        [self.likeCountButton setTitle:@"0 Likes" forState:UIControlStateNormal];
        [self.comments setTitle:@"0 Comments" forState:UIControlStateNormal];

        // Only show the delete button if the user is the photo owner AND the close button isn't hidden, meaning we aren't in pic-only
        if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId] && !self.closeButton.hidden) {
            self.delete.hidden = NO;
        } else {
            self.delete.hidden = YES;
        }
        
        [self refreshPhotoActivities];

    }
}

- (void)swipeVertical:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleTap:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self toggleButtonVisibility];
}

#pragma mark - Button Actions

- (IBAction)onSavePhotoTapped:(id)sender {
    
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = @"Save photo to phone?";
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"No"];
    [alertView addButtonWithTitle:@"Download"];
    alertView.tag = 1;
    [alertView show];
}



- (IBAction)onCommentsTapped:(id)sender {
    
    
    ActivityListViewController *vc = [[ActivityListViewController alloc] initWithComments:self.commentActivities forPhoto:self.photo];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navController animated:YES completion:nil];
}

- (IBAction)likeCountButtonPressed:(id)sender {
    
    ActivityListViewController *vc = [[ActivityListViewController alloc] initWithLikes:self.likeActivities];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navController animated:YES completion:nil];
}

- (IBAction)likeButtonPressed:(id)sender {
    
    self.likeButton.enabled = NO;
    
    // Like Photo
    if (!self.likeButton.selected)
    {
        [[TTCache sharedCache] incrementLikerCountForPhoto:self.photo];
        
        [self.likeButton setSelected:YES];
        [SocialUtility likePhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            self.likeButton.enabled = YES;
            if (succeeded) {
                self.photo.favorite = YES;
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
                self.photo.favorite = NO;
                [self refreshPhotoActivities];
            }
        }];
    }
    
    [[TTCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:self.likeButton.selected];
    
}

- (IBAction)onDeleteWasTapped:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = @"Are you sure you want to delete this photo?";
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"No"];
    [alertView addButtonWithTitle:@"Yes"];
    alertView.tag = 0;
    [alertView show];
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Delete
        if (alertView.tag == 0) {
            
            [[TTUtility sharedInstance] deletePhoto:self.photo];

            // dismiss the view
            [self dismissViewControllerAnimated:YES completion:nil];

            
        }
        // Download Photo
        else if (alertView.tag == 1) {
            [[TTUtility sharedInstance] downloadPhoto:self.photo];
        }
    }
}
- (IBAction)closeButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
