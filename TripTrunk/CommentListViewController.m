//
//  CommentListViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/3/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "CommentListViewController.h"
#import "UIImageView+AFNetworking.h"

#import "SocialUtility.h"
#import "UserProfileViewController.h"
#import "CommentTableViewCell.h"
#import "TTUtility.h"
#import "TTCommentInputView.h"
#import "UIScrollView+EmptyDataSet.h"

#define COMMENT_CELL @"comment_table_view_cell"

@interface CommentListViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TTCommentInputViewDelegate, CommentTableViewCellDelegate>

@property (strong, nonatomic) NSMutableArray *activities;
@property (strong, nonatomic) TTCommentInputView *commentInputView;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) Photo *photo;

@end

@implementation CommentListViewController 

- (id)initWithComments:(NSArray *)comments forPhoto:(Photo *)photo;
{
    self = [super init];
    if (self) {
        _activities = [[NSMutableArray alloc] initWithArray:comments];
        _photo = photo;
        self.title = @"Comments";
    }
    return self;
}


- (void)loadView {
    
    // Initialize the view & tableview
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [self.view setBackgroundColor:[UIColor whiteColor]]; // make the view bg white to avoid the black glitch if a keyboard appears
    self.tableView = [[UITableView alloc] init];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.tableView.tableFooterView = [UIView new]; // to hide the cell seperators for empty cells
    [self.view addSubview:self.tableView];
    
    // Setup the comment input overlay
    _commentInputView = [[TTCommentInputView alloc] init];
    [self.view addSubview:_commentInputView];
    [_commentInputView setupConstraintsWithView:self.view];
    _commentInputView.delegate = self;
    
    [self setupTableViewConstraints];
    
    // Set Done button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(closeView)];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"CommentTableViewCell" bundle:nil] forCellReuseIdentifier:COMMENT_CELL];
    
    // Setup tableview delegate/datasource
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    // Setup Empty Datasets delegate/datasource
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
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
    
    // vertical algin bottom to comment box
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.commentInputView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0.0]];

    
}

#pragma mark - Dismiss View

- (void)closeView
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _activities.count;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    // Get a variable cell height to make sure we can fit long comments
    NSAttributedString *cellText = [[TTUtility sharedInstance] attributedStringForCommentActivity:[_activities objectAtIndex:indexPath.row]];
    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
    
    CGSize labelSize = [cellText boundingRectWithSize:constraintSize
                                              options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                              context:nil].size;
    return labelSize.height + 40;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CommentTableViewCell *commentCell = [self.tableView dequeueReusableCellWithIdentifier:COMMENT_CELL forIndexPath:indexPath];
    [commentCell setDelegate:self];
    NSDictionary *activity = [_activities objectAtIndex:indexPath.row];
    [commentCell setCommentActivity:activity];
    
    // We assume fromUser contains the full PFUser object
    PFUser *user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    __weak CommentTableViewCell *weakCell = commentCell;
    
    [commentCell.profilePicImageView setImageWithURLRequest:request
                                            placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                         
                                                         [weakCell.profilePicImageView setImage:image];
                                                         [weakCell setNeedsLayout];
                                                         
                                                     } failure:nil];

    
    return weakCell;
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
    // Intentionally not implemented -- we don't want anything to happen on selection of the cell.
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Dismiss the keyboard when scrolling starts
    [self.view endEditing:YES];
}

#pragma mark - CommentTableViewCell delegate

- (void)commentCell:(CommentTableViewCell *)cellView didPressUsernameForUser:(PFUser *)user {
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Comments";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor blackColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"You could be the first to comment on this photo";

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
