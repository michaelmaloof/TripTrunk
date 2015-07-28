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
#import "ActivityListViewController.h"


@interface PhotoViewController () <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextViewDelegate>
// IBOutlets
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *addComment;
@property (weak, nonatomic) IBOutlet UIButton *comments;
@property (weak, nonatomic) IBOutlet UIButton *delete;
@property (strong, nonatomic) IBOutlet UIButton *likeCountButton;
@property (strong, nonatomic) IBOutlet UIButton *likeButton;

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
    self.tableView.hidden = YES;
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    self.tableView.contentInset = UIEdgeInsetsMake(-36, 0, 0, 0);
    
    self.addComment.hidden = YES;
    self.textView.hidden = YES;
    
    self.delete.hidden = YES;
    if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
        self.delete.hidden = NO;
    }
    [self.textView setDelegate:self];
    
    self.commentActivities = [[NSMutableArray alloc] init];
    self.likeActivities = [[NSMutableArray alloc] init];
    [self.likeCountButton setTitle:[NSString stringWithFormat:@"%ld Likes", (long)self.likeActivities.count] forState:UIControlStateNormal];

    // Add swipe gestures
    UISwipeGestureRecognizer * swipeleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeleft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeleft];
    
    UISwipeGestureRecognizer * swiperight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swiperight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swiperight];
    
    self.textView.delegate = self;
    
    
    // Load initial data (photo and comments)
    [self loadImageForPhoto:self.photo];
    
    [self refreshPhotoActivities];

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
            [self.tableView reloadData];
            self.textView.text = nil;
            
            // Update number of likes
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.likeButton setSelected:self.isLikedByCurrentUser];
                [self.likeCountButton setTitle:[NSString stringWithFormat:@"%ld Likes", (long)self.likeActivities.count] forState:UIControlStateNormal];
            });
            
        }
        else {
            NSLog(@"Error loading photo Activities: %@", error);
        }
    }];
}

#pragma mark - Gestures

-(void)swiperight:(UISwipeGestureRecognizer*)gestureRecognizer
{
    // Prevents a crash when the PhotoViewController was presented from a Push Notification--aka it doesn't have a self.photos array
    if (!self.photos || self.photos.count == 0) {
        return;
    }
    
    NSLog(@"check 1 = %ld", (long)self.arrayInt);
    if (self.tableView.hidden == YES && self.arrayInt > 0)
    {
        self.arrayInt = self.arrayInt - 1;
        self.photo = [self.photos objectAtIndex:self.arrayInt];
        [self loadImageForPhoto:self.photo];
        self.title = self.photo.userName;
        
        [self.likeCountButton setTitle:@"0 Likes" forState:UIControlStateNormal];

        
        if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
            self.delete.hidden = NO;
        } else {
            self.delete.hidden = YES;
        }

        [self refreshPhotoActivities];
    }
}

-(void)swipeleft:(UISwipeGestureRecognizer*)gestureRecognizer
{
    if (!self.photos || self.photos.count == 0) {
        return;
    }
    
    if (self.tableView.hidden == YES && self.arrayInt != self.photos.count - 1)
    {
        self.arrayInt = self.arrayInt + 1;
        self.photo = [self.photos objectAtIndex:self.arrayInt];
        [self loadImageForPhoto:self.photo];
        self.title = self.photo.userName;
        
        [self.likeCountButton setTitle:@"0 Likes" forState:UIControlStateNormal];

        if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
            self.delete.hidden = NO;
        } else {
            self.delete.hidden = YES;
        }
        
        [self refreshPhotoActivities];

    }
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
    self.tableView.hidden = !self.tableView.hidden;
    self.addComment.hidden = !self.addComment.hidden;
    self.textView.hidden = !self.textView.hidden;
    self.likeCountButton.hidden = !self.likeCountButton.hidden;
    self.likeButton.hidden = !self.likeButton.hidden;
    
    if ([self.comments.titleLabel.text isEqualToString:@"Comments"]){
        [self.comments setTitle:@"Dismiss" forState:UIControlStateNormal];

    }
    
    else if ([self.comments.titleLabel.text isEqualToString:@"Dismiss"]){
        [self.comments setTitle:@"Comments" forState:UIControlStateNormal];
        [self moveUpTextBox];

    }

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
        [self.likeButton setSelected:NO];
        [SocialUtility unlikePhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            self.likeButton.enabled = YES;
            
            if (succeeded) {
                self.photo.favorite = NO;
                [self refreshPhotoActivities];
            }
        }];
    }
    
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
            
            [self.photo deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded)
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
            
        }
        // Download Photo
        else if (alertView.tag == 1) {
            [[TTUtility sharedInstance] downloadPhoto:self.photo];
        }
    }
}

#pragma mark - UITableView Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.commentActivities.count +1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = self.photo.userName;
        cell.detailTextLabel.text = self.photo.caption;
        if (self.photo.caption == nil){
            cell.hidden = YES;
        }
    }
    
    else if (indexPath.row > 0) {
    
        PFObject *commentActivity = [self.commentActivities objectAtIndex:indexPath.row -1];
        
        cell.textLabel.text = [[commentActivity valueForKey:@"fromUser"] valueForKey:@"username"];
        cell.detailTextLabel.text = [commentActivity valueForKey:@"content"];
    }

    
    return  cell;
}

#pragma mark - UITableView Delegate
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > 0) {
        
        PFObject *commentActivity = [self.commentActivities objectAtIndex:indexPath.row -1];
        // You can delete comments if you're the commenter, photo creator
        // TODO: or trip creator
        if ([[[commentActivity valueForKey:@"fromUser"] objectId] isEqualToString:[[PFUser currentUser] objectId]]
            || [[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
            return YES;
        }
    }
    return NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [SocialUtility deleteComment:[self.commentActivities objectAtIndex:indexPath.row - 1] forPhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error deleting comment: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't delete comment, try again" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert show];
                    [self refreshPhotoActivities]; // reload the data so we still show the attempted-to-delete comment
                });
            }
            else {
                NSLog(@"Comment Deleted");
            }
        }];
        
        // Remove from the array and reload the data separately from actually deleting so that we can give a responsive UI to the user.
        [self.commentActivities removeObjectAtIndex:indexPath.row - 1];
        [tableView reloadData];
        
    }
    else {
        NSLog(@"Unhandled Editing Style: %ld", (long)editingStyle);
    }
}

#pragma mark - Comments View

- (IBAction)onAddCommentsTapped:(id)sender {
    
    if(![self.textView.text isEqualToString:@""])
    {
        [SocialUtility addComment:self.textView.text forPhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            if(error)
            {
                UIAlertView *alertView = [[UIAlertView alloc] init];
                alertView.delegate = self;
                alertView.title = @"Check internet connection.";
                alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                [alertView addButtonWithTitle:@"OK"];
                [alertView show];
            }
            else {
                [self refreshPhotoActivities];
            }
        }];
        
        [self moveUpTextBox];
        
    }
}

-(void)moveUpTextBox{
    
    if (self.viewMoved == YES) {
            [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationBeginsFromCurrentState:YES];
        self.view.frame = CGRectMake(self.view.frame.origin.x , (self.view.frame.origin.y + 230), self.view.frame.size.width, self.view.frame.size.height);
        self.comments.hidden = NO;
        self.addComment.hidden = NO;
        [UIView commitAnimations];
        self.viewMoved = NO;
        [self.textView endEditing:YES];

    }

}

#pragma mark - Text View Editing

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSRange resultRange = [text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch];
    if ([text length] == 1 && resultRange.location != NSNotFound) {
        [textView resignFirstResponder];
        [self onAddCommentsTapped:self];
        return NO;
    }
    
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self textViewDidEndEditing:self.textView];
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView == self.textView)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationBeginsFromCurrentState:YES];
        self.view.frame = CGRectMake(self.view.frame.origin.x , (self.view.frame.origin.y - 230), self.view.frame.size.width, self.view.frame.size.height);
        self.comments.hidden = NO;
        self.addComment.hidden = NO;
        self.viewMoved = YES;
        [UIView commitAnimations];
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView == self.textView)
    {
        [self.textView endEditing:YES];
        [self moveUpTextBox];
    }
}

@end
