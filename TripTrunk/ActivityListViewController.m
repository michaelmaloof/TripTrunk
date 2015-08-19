//
//  ActivityListViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 7/27/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "ActivityListViewController.h"
#import "UIImageView+AFNetworking.h"

#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "UserProfileViewController.h"
#import "CommentTableViewCell.h"
#import "TTUtility.h"
#import "TTCommentInputView.h"
#import "UIScrollView+EmptyDataSet.h"

#define USER_CELL @"user_table_view_cell"
#define COMMENT_CELL @"comment_table_view_cell"

enum TTActivityViewType : NSUInteger {
    TTActivityViewAllActivities = 1,
    TTActivityViewLikes = 2,
    TTActivityViewComments = 3
};

@interface ActivityListViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TTCommentInputViewDelegate>

@property (strong, nonatomic) NSArray *activities;
@property NSUInteger viewType;

@property (strong, nonatomic) TTCommentInputView *commentInputView;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) Photo *photo;


@end

@implementation ActivityListViewController

- (id)initWithLikes:(NSArray *)likes;
{
    self = [super init];
    if (self) {
        _activities = [[NSArray alloc] initWithArray:likes];
        self.title = @"Likers";
        _viewType = TTActivityViewLikes;
    }
    return self;
}

- (id)initWithComments:(NSArray *)comments forPhoto:(Photo *)photo;
{
    self = [super init];
    if (self) {
        _activities = [[NSArray alloc] initWithArray:comments];
        _photo = photo;
        self.title = @"Comments";
        _viewType = TTActivityViewComments;
    }
    return self;
}

- (id)initWithActivities:(NSArray *)activities;
{
    self = [super init];
    if (self) {
        _activities = [[NSArray alloc] initWithArray:activities];
        self.title = @"Activity";
        _viewType = TTActivityViewAllActivities;
    }
    return self;
}

- (void)loadView {
    
    // Initialize the view & tableview
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.tableView = [[UITableView alloc] init];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.tableView.tableFooterView = [UIView new]; // to hide the cell seperators for empty cells
    [self.view addSubview:self.tableView];
    
    // Setup the comment overlay if it's the Comments view
    if (_viewType == TTActivityViewComments) {
        _commentInputView = [[TTCommentInputView alloc] init];
        [self.view addSubview:_commentInputView];
        [_commentInputView setupConstraintsWithView:self.view];
        _commentInputView.delegate = self;
    }

    [self setupTableViewConstraints];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    [self.tableView registerNib:[UINib nibWithNibName:@"CommentTableViewCell" bundle:nil] forCellReuseIdentifier:COMMENT_CELL];

    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                             
                                                                                           action:@selector(closeView)];
    // Setup tableview delegate/datasource
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;

    // Add a gesture recognizer so we can dismiss the keyboard on taps.
//    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
}

- (void)viewDidAppear:(BOOL)animated {
    // reload the table every time it appears or we get weird results
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTableViewConstraints {
    
    // Width constraint, full width of view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.view
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1
                                                      constant:0]];

    
    // Center horizontally
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.view
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    
    // vertical algin top of tableview to view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0
                                                                constant:0.0]];
    
    if (_viewType == TTActivityViewComments) {
        // vertical algin bottom to comment box
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.commentInputView
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0.0]];
        
        //TODO: black shows when keyboard opens because this constraint isn't animated
        // The CommentBox constraint animates with the keyboard, so there's a glitch.
        // This should either animate, or better
    }
    else {
        // vertical algin bottom to view
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
    }
    

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _activities.count;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_viewType == TTActivityViewLikes) {
        
    
        UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
    //    [cell setDelegate:self];
        
        // We assume fromUser contains the full PFUser object
        PFUser *user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
        [cell setUser:user];
        
        [cell.followButton setHidden:YES];

        
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
        __weak UserTableViewCell *weakCell = cell;
        
        [cell.profilePicImageView setImageWithURLRequest:request
                                        placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                     
                                                     [weakCell.profilePicImageView setImage:image];
                                                     [weakCell setNeedsLayout];
                                                     
                                                 } failure:nil];
        return weakCell;
    }
    else if (_viewType == TTActivityViewComments) {
        CommentTableViewCell *commentCell = [self.tableView dequeueReusableCellWithIdentifier:COMMENT_CELL forIndexPath:indexPath];
        // We assume fromUser contains the full PFUser object
        PFUser *user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
//        NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
        [commentCell setUser:user];
        
        NSString *comment = [[_activities objectAtIndex:indexPath.row] valueForKey:@"content"];
        [commentCell.commentLabel setText:comment];
    }
    
    return [UITableViewCell new];
}
//-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    if (_viewType == TTActivityViewComments) {
//        return _commentInputView.frame.size.height;
//    }
//    return 0;
//}
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    // set up comment input box view
//    _commentInputView = [[UIView alloc] init];
//    [_commentInputView setTranslatesAutoresizingMaskIntoConstraints:NO];
//    _commentInputView.backgroundColor = [UIColor redColor];
//    
//    return _commentInputView;
//}

#pragma mark - Table view delegate

// On Row Selection, push to the user's profile
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:[[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"]];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Dismiss the keyboard when scrolling starts
    [self.view endEditing:YES];
}

-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //TODO: swipe pushes over the full table view, not just the editing cell. Probably due to layout constraint.
    
    // Only comment lists can be deleted, Likes and such don't allow deleting
    if (_viewType != TTActivityViewComments) {
        return NO;
    }
    
    if (indexPath.row > 0) {
        
        PFObject *commentActivity = [self.activities objectAtIndex:indexPath.row];
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
        
        // TODO: refresh the activities from the server after comment is deleted

        [SocialUtility deleteComment:[self.activities objectAtIndex:indexPath.row] forPhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error deleting comment: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't delete comment, try again" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert show];
                    
//                    [super refreshPhotoActivities]; // reload the data so we still show the attempted-to-delete comment
                });
            }
            else {
                NSLog(@"Comment Deleted");
            }
        }];
        
        // Remove from the array and reload the data separately from actually deleting so that we can give a responsive UI to the user.
        NSMutableArray *updated = [NSMutableArray arrayWithArray:_activities];
        [updated removeObjectAtIndex:indexPath.row];
        _activities = [NSArray arrayWithArray:updated];
        [self.tableView reloadData];
        
    }
    else {
        NSLog(@"Unhandled Editing Style: %ld", (long)editingStyle);
    }
}

#pragma mark - Dismiss View

- (void)closeView
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Activity";
    if (_viewType == TTActivityViewComments) {
        text = @"No Comments";
    }
    else if (_viewType == TTActivityViewLikes) {
        text = @"No Likers";
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor blackColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"You could be the first to like or comment on this photo";
    if (_viewType == TTActivityViewComments) {
        text = @"You could be the first to comment on this photo";
    }
    else if (_viewType == TTActivityViewLikes) {
        text = @"You could be the first to like this photo";
    }
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    
    //TODO: Implement a facebook invite button - commented out code creates a button
    
    //    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0],
    //                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
    //
    //    return [[NSAttributedString alloc] initWithString:@"Create Trunk" attributes:attributes];
    return nil;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor colorWithWhite:1.0 alpha:1.0];
}

//- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView
//{
//    return [UIImage imageNamed:@"ticketIcon"];
//}

- (CGPoint)offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return CGPointMake(0, 20);
}

#pragma mark - DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    
    // Search Controller and the regular table view have different data sources
    if (self.activities.count == 0) {
        // A little trick for removing the cell separators
        self.tableView.tableFooterView = [UIView new];
        return YES;
    }
    
    return NO;
}

- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return NO;
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    //TODO: Implement this
}

#pragma mark - TTCommentInputViewDelegate

- (void)commentSubmitButtonPressedWithComment:(NSString *)comment {
    if (comment && ![comment isEqualToString: @""] ) {
        if (_photo) {
            NSDictionary *activity = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [PFUser currentUser], @"fromUser",
                                      comment, @"content",
                                      _photo, @"photo",
                                      nil];
            NSMutableArray *updated = [NSMutableArray arrayWithArray:_activities];
            [updated addObject:activity];
            _activities = [NSArray arrayWithArray:updated];
            [self.tableView reloadData];
            [SocialUtility addComment:comment forPhoto:_photo block:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"Comment Saved Success");
                }
                else {
                    UIAlertView *alertView = [[UIAlertView alloc] init];
                    alertView.delegate = self;
                    alertView.title = @"Error adding comment. Please try again";
                    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                    [alertView addButtonWithTitle:@"OK"];
                    [alertView show];
                }
            }];
            
        }
    }
}

#pragma mark -
- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}




@end
