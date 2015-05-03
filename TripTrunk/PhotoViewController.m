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


@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.photo.userName;
    PFFile *file = self.photo.imageFile;
    self.imageView.file = file;
    self.tableView.hidden = YES;
    self.addComment.hidden = YES;
    self.textView.hidden = YES;
    [self.imageView loadInBackground];

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
    return 4; //FIXME ME TEMP
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", self.photo.userName, self.photo.caption];
    
    return  cell;
}
- (IBAction)onAddCommentsTapped:(id)sender {
    NSLog((@"hey girl"));
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

@end
