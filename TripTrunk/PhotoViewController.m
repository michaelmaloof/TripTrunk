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

@interface PhotoViewController () <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet PFImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *comments;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addComment;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property NSArray *commentsArray;

@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.photo.userName;
    self.commentsArray = [[NSArray alloc]init];
    PFFile *file = self.photo.imageFile;
    self.imageView.file = file;
    self.tableView.hidden = YES;
    self.addComment.hidden = YES;
    self.textView.hidden = YES;
    [self.imageView loadInBackground];
    [self queryParseMethod];

}


- (IBAction)onSavePhotoTapped:(id)sender {
    
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = @"Saved photo to phone";
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"OK"];
    [alertView show];
}

- (IBAction)onCommentsTapped:(id)sender {
    self.tableView.hidden = !self.tableView.hidden;
    self.addComment.hidden = !self.addComment.hidden;
    self.textView.hidden = !self.textView.hidden;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.commentsArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
    Comment *comment = [self.commentsArray objectAtIndex:indexPath.row];
    cell.textLabel.text = comment.comment;
    return  cell;
}
- (IBAction)onAddCommentsTapped:(id)sender {
    [self parseComment];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
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

@end



















































