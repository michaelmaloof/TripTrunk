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
#import "ActivityTableViewCell.h"
#import "TTUtility.h"
#import "TTCommentInputView.h"
#import "UIScrollView+EmptyDataSet.h"

#define USER_CELL @"user_table_view_cell"
#define COMMENT_CELL @"comment_table_view_cell"
#define ACTIVITY_CELL @"activity_table_view_cell"

enum TTActivityViewType : NSUInteger {
    TTActivityViewAllActivities = 1,
    TTActivityViewLikes = 2,
    TTActivityViewComments = 3
};

@interface ActivityListViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TTCommentInputViewDelegate, ActivityTableViewCellDelegate>

@property (strong, nonatomic) NSMutableArray *activities;
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
        _activities = [[NSMutableArray alloc] initWithArray:likes];
        self.title = @"Likers";
        _viewType = TTActivityViewLikes;
    }
    return self;
}

- (id)initWithComments:(NSArray *)comments forPhoto:(Photo *)photo;
{
    self = [super init];
    if (self) {
        _activities = [[NSMutableArray alloc] initWithArray:comments];
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
        _activities = [[NSMutableArray alloc] initWithArray:activities];
        self.title = @"Activity";
        _viewType = TTActivityViewAllActivities;
    }
    return self;
}

- (void)loadView {
    
    // Initialize the view & tableview
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [self.view setBackgroundColor:[UIColor whiteColor]]; // make the view bg white to avoid the black glitch if a keyboard appears - for CommentView
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

    if (_viewType != TTActivityViewAllActivities) {
        // Set Done button for all but the All Activity view
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(closeView)];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    [self.tableView registerNib:[UINib nibWithNibName:@"CommentTableViewCell" bundle:nil] forCellReuseIdentifier:COMMENT_CELL];
    [self.tableView registerNib:[UINib nibWithNibName:@"ActivityTableViewCell" bundle:nil] forCellReuseIdentifier:ACTIVITY_CELL];

    
    // Setup tableview delegate/datasource
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    
    if (_activities.count == 0 && _viewType == TTActivityViewAllActivities) {
        // Query for activities for user
        [SocialUtility queryForAllActivities:^(NSArray *activities, NSError *error) {
            _activities = [NSMutableArray arrayWithArray:activities];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }];
    }
    
}

-(void)viewWillAppear:(BOOL)animated {
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    
}

- (void)viewDidAppear:(BOOL)animated {
    // reload the table every time it appears or we get weird results
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *  Adds AutoLayout constraints on the tableview so that it can adjust for the comment box on commentview.
 */
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
    
    if (_viewType == TTActivityViewComments) {
        
        // Get a variable cell height to make sure we can fit long comments
        
        NSString *cellText = [[_activities objectAtIndex:indexPath.row] valueForKey:@"content"];
        UIFont *cellFont = [UIFont boldSystemFontOfSize:12.0];
        CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
        
        NSMutableDictionary *attr = [NSMutableDictionary dictionary];
        NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [attr setObject:paraStyle forKey:NSParagraphStyleAttributeName];
        [attr setObject:cellFont forKey:NSFontAttributeName];
        
        CGSize labelSize = [cellText boundingRectWithSize:constraintSize
                                             options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                          attributes:attr
                                             context:nil].size;

        return labelSize.height + 40;
    }
    
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
        
        //TODO: Add time of comment
        
        NSString *comment = [[_activities objectAtIndex:indexPath.row] valueForKey:@"content"];
        [commentCell.commentLabel setText:comment];
        
        return commentCell;
    }
    else if (_viewType == TTActivityViewAllActivities) {
        ActivityTableViewCell *activityCell = [self.tableView dequeueReusableCellWithIdentifier:ACTIVITY_CELL forIndexPath:indexPath];
        [activityCell setDelegate:self];
        NSDictionary *activity = [_activities objectAtIndex:indexPath.row];
        [activityCell setActivity:activity];
        
        // We assume fromUser contains the full PFUser object
        PFUser *user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
        __weak ActivityTableViewCell *weakCell = activityCell;
        
        [activityCell.profilePicImageView setImageWithURLRequest:request
                                        placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                     
                                                     [weakCell.profilePicImageView setImage:image];
                                                     [weakCell setNeedsLayout];
                                                     
                                                 } failure:nil];
        
        if ([activity valueForKey:@"photo"]) {
            NSURL *photoUrl = [NSURL URLWithString:[[TTUtility sharedInstance] thumbnailImageUrl:[[activity valueForKey:@"photo"] valueForKey:@"imageUrl"]]];
            NSURLRequest *photoRequest = [NSURLRequest requestWithURL:photoUrl];
            
            [activityCell.photoImageView setImageWithURLRequest:photoRequest
                                                    placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                 
                                                                 [weakCell.photoImageView setImage:image];
                                                                 [weakCell setNeedsLayout];
                                                                 
                                                             } failure:nil];
        }
        
        return weakCell;

        
    }
    
    return [UITableViewCell new];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //TODO: swipe pushes over the full table view, not just the editing cell. Probably due to layout constraint.

    // Only comment lists can be deleted, Likes and such don't allow deleting
    if (_viewType != TTActivityViewComments) {
        return NO;
    }
    
    PFObject *commentActivity = [self.activities objectAtIndex:indexPath.row];
    // You can delete comments if you're the commenter, photo creator
    // TODO: or trip creator
    if ([[[commentActivity valueForKey:@"fromUser"] objectId] isEqualToString:[[PFUser currentUser] objectId]]
        || [[PFUser currentUser].objectId isEqualToString:self.photo.user.objectId]) {
        return YES;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {

                [SocialUtility deleteComment:[self.activities objectAtIndex:indexPath.row] forPhoto:self.photo block:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        NSLog(@"Error deleting comment: %@", error);
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Couldn't delete comment, try again" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [alert show];
                        });
                    }
                    else {
                        NSLog(@"Comment Deleted");
                        // Post a notification so that the data is reloaded in the Photo View
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"commentUpdatedOnPhoto" object:_photo];
        
                    }
                }];
        
                // Remove from the array and reload the data separately from actually deleting so that we can give a responsive UI to the user.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_activities removeObjectAtIndex:indexPath.row];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
        
    }
    else {
        NSLog(@"Unhandled Editing Style: %ld", (long)editingStyle);
    }
}


#pragma mark - Table view delegate

// On Row Selection, push to the user's profile
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_viewType == TTActivityViewAllActivities) {
        // Don't allow row selection for All Activities--usernames and photos have different links.
        return;
    }
    
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:[[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"]];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Dismiss the keyboard when scrolling starts
    [self.view endEditing:YES];
}

#pragma mark - ActivityTableViewCell delegate

-(void)activityCell:(ActivityTableViewCell *)cellView didPressPhoto:(Photo *)photo {
    NSLog(@"cell did press photo");
}

- (void)activityCell:(ActivityTableViewCell *)cellView didPressUsernameForUser:(PFUser *)user {
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
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
    
    //TODO: commented out code creates a button
    
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
            [_activities addObject:activity];
            [self.tableView reloadData];
            
            [SocialUtility addComment:comment forPhoto:_photo block:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"Comment Saved Success");
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"commentUpdatedOnPhoto" object:_photo];
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
