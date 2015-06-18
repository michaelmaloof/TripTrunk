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
#import "Comment.h"


@interface PhotoViewController () <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>
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
    self.title = self.photo.userName;
    [self.textView setDelegate:self];
    self.commentsArray = [[NSArray alloc]init];
    PFFile *file = self.photo.imageFile;
    self.imageView.file = file;
    self.tableView.hidden = YES;
    self.addComment.hidden = YES;
    self.textView.hidden = YES;
    
    //mattschoch 6/10 - setting the image on the imageview directly
//    [self.imageView loadInBackground];
    self.imageView.image = self.image;
    
    
    [self queryParseMethod];
    self.delete.hidden = YES;
    
    NSString *string = [NSString stringWithFormat:@"%ld", (long)self.photo.likes];
    [self.like setTitle:string forState:UIControlStateNormal];

    NSLog(@"user = %@",[PFUser currentUser].objectId);
    NSLog(@"user photo = %@",self.photo.user.objectId);

    if ([[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
        self.delete.hidden = NO;
    } else {
        self.delete.hidden = YES;
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
        [self.comments setTitle:@"Done" forState:UIControlStateNormal];

    }
    
    else if ([self.comments.titleLabel.text isEqualToString:@"Done"]){
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
    }
    
    else if (indexPath.row > 0) {
    
        Comment *comment = [self.commentsArray objectAtIndex:indexPath.row -1];
        cell.textLabel.text = comment.user;
        cell.detailTextLabel.text = comment.comment;
        
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
    Comment *comment = [[Comment alloc]init];
    comment.comment = self.textView.text;
    comment.user = [PFUser currentUser].username;
    comment.datePosted = [NSDate date];
    comment.photo = self.photo.objectId;
    comment.trip = self.photo.tripName;
    comment.city = self.photo.city;
    
    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if(error)
        {
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.title = @"No internet connection.";
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:@"OK"];
            [alertView show];
        } else if (!error)
        {
            [self queryParseMethod];
        }
    }];

}

-(void)queryParseMethod {
    PFQuery *findPhotosUser = [PFQuery queryWithClassName:@"Comment"];
    [findPhotosUser whereKey:@"trip" equalTo:self.photo.tripName];
    [findPhotosUser whereKey:@"city" equalTo:self.photo.city];
    [findPhotosUser whereKey:@"photo" equalTo:self.photo.objectId];
    [findPhotosUser orderByDescending:@"createdAt"];
    
    [findPhotosUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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
    
    if (alertView.tag == 0)
    {
        if (buttonIndex == 1)
            {
                [self.photo deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                {
                    if (succeeded)
                    {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }];
            }
    }
    
    if (alertView.tag == 1) {
        if (buttonIndex == 1)
        {
        UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.title = @"Photo has been saved";
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:@"Sweet!"];
            [alertView show];
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



















































