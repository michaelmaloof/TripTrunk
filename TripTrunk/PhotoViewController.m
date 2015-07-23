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


@interface PhotoViewController () <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *comments;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addComment;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property NSArray *commentsArray;
@property BOOL viewMoved;
@property (weak, nonatomic) IBOutlet UIButton *delete;
@property (weak, nonatomic) IBOutlet UIButton *like;

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
    
    NSString *likeString = [NSString stringWithFormat:@"%ld", (long)self.photo.likes];
    [self.like setTitle:likeString forState:UIControlStateNormal];
    
    self.commentsArray = [[NSArray alloc]init];


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
    
    [self queryParseMethod];

}

- (void)loadImageForPhoto: (Photo *)photo {
    
    NSString *urlString = [[TTUtility sharedInstance] mediumQualityScaledDownImageUrl:photo.imageUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    UIImage *placeholderImage = photo.image;
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [self.imageView setImageWithURLRequest:request
                      placeholderImage:placeholderImage
                               success:nil failure:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSRange resultRange = [text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch];
    if ([text length] == 1 && resultRange.location != NSNotFound) {
        [textView resignFirstResponder];
        [self onAddCommentsTapped:self];
        return NO;
    }
    
    return YES;
}


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
        
        NSString *string = [NSString stringWithFormat:@"%ld", (long)self.photo.likes];
        [self.like setTitle:string forState:UIControlStateNormal];
        
        if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
            self.delete.hidden = NO;
        } else {
            self.delete.hidden = YES;
        }

        [self queryParseMethod];
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
        
        NSString *string = [NSString stringWithFormat:@"%ld", (long)self.photo.likes];
        [self.like setTitle:string forState:UIControlStateNormal];
        
        if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
            self.delete.hidden = NO;
        } else {
            self.delete.hidden = YES;
        }
        
        [self queryParseMethod];

    }
}


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
    self.like.hidden = !self.like.hidden;
    
    if ([self.comments.titleLabel.text isEqualToString:@"Comments"]){
        [self.comments setTitle:@"Dismiss" forState:UIControlStateNormal];

    }
    
    else if ([self.comments.titleLabel.text isEqualToString:@"Dismiss"]){
        [self.comments setTitle:@"Comments" forState:UIControlStateNormal];
        [self moveUpTextBox];

    }

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.commentsArray.count +1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = self.photo.userName;
        cell.detailTextLabel.text = self.photo.caption;
        if (self.photo.caption == nil){
            cell.hidden = YES;
        }
    }
    
    else if (indexPath.row > 0) {
    
        PFObject *commentActivity = [self.commentsArray objectAtIndex:indexPath.row -1];
        
        cell.textLabel.text = [[commentActivity valueForKey:@"fromUser"] valueForKey:@"username"];
        cell.detailTextLabel.text = [commentActivity valueForKey:@"content"];
    }

    
    return  cell;
}
- (IBAction)onAddCommentsTapped:(id)sender {
    
    if(![self.textView.text isEqualToString:@""])
    {
        [self parseComment];
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

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self textViewDidEndEditing:self.textView];

}

-(void)parseComment {
    
    [SocialUtility addComment:self.textView.text forPhoto:self.photo block:^(BOOL succeeded, NSError *error) {
        if(error)
        {
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.title = @"No internet connection.";
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:@"OK"];
            [alertView show];
        }
        else {
            [self queryParseMethod];
        }
    }];
}

-(void)queryParseMethod {

    [SocialUtility getCommentsForPhoto:self.photo block:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            self.commentsArray = [NSArray arrayWithArray:objects];
            [self.tableView reloadData];
            self.textView.text = nil;
            
        }else
        {
            NSLog(@"Error: %@",error);
        }

    }];
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
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationDelegate:self];
//        [UIView setAnimationDuration:0.5];
//        [UIView setAnimationBeginsFromCurrentState:YES];
//        self.view.frame = CGRectMake(self.view.frame.origin.x , (self.view.frame.origin.y + 230), self.view.frame.size.width, self.view.frame.size.height);
//        self.comments.hidden = NO;
//        self.addComment.hidden = NO;
//        self.viewMoved = NO;
//        [UIView commitAnimations];
        [self.textView endEditing:YES];
        [self moveUpTextBox];

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

- (IBAction)onLikeTapped:(id)sender {
    
    NSMutableArray *likesArray = [[NSMutableArray alloc]init];
    NSString *objectID = [PFUser currentUser].objectId;
    
    if (self.like.tag == 0)
    {
        self.like.tag = 1;
        self.photo.favorite = YES;
        self.photo.likes ++;
        [likesArray addObject:objectID];
        [self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        }];
        NSString *string = [NSString stringWithFormat:@"%ld", (long)self.photo.likes];
        [self.like setTitle:string forState:UIControlStateNormal];

    }

    else if (self.like.tag == 1){
    
    self.like.tag = 0;
    self.photo.likes --;
    if (self.photo.likes == 0)
    {
        self.photo.favorite = NO;
    }
    
    [likesArray removeObject:objectID];
    [self.photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
        {
        }];
    NSString *string = [NSString stringWithFormat:@"%ld", (long)self.photo.likes];
    [self.like setTitle:string forState:UIControlStateNormal];
    
}


}








@end



















































