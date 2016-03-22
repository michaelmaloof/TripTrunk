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
#import "TTTAttributedLabel.h"
#import "TTSuggestionTableViewController.h"
#import "TTHashtagMentionColorization.h"
#import "TTCache.h"

#define COMMENT_CELL @"comment_table_view_cell"

@interface CommentListViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TTCommentInputViewDelegate, CommentTableViewCellDelegate, UIPopoverPresentationControllerDelegate, TTSuggestionTableViewControllerDelegate, TTCommentInputViewDelegate>

@property (strong, nonatomic) NSMutableArray *activities;
@property (strong, nonatomic) TTCommentInputView *commentInputView;
@property (strong, nonatomic) NSString *comment;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) Photo *photo;

@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTSuggestionTableViewController *autocompletePopover;
@end

@implementation CommentListViewController 

- (id)initWithComments:(NSArray *)comments forPhoto:(Photo *)photo;
{
    self = [super init];
    if (self) {
        _activities = [[NSMutableArray alloc] initWithArray:comments];
        _photo = photo;
        self.title = NSLocalizedString(@"Comments",@"Comments");
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
    _commentInputView.photo = self.photo;
    _commentInputView.trunkMembers = self.trunkMembers;
    _commentInputView.delegate = self;
    [self.view addSubview:_commentInputView];
    [_commentInputView setupConstraintsWithView:self.view];
    
    self.view.backgroundColor = [UIColor colorWithRed:205.0/255.0 green:205.0/255.0 blue:205.0/255.0 alpha:1.0];
    
    [self setupTableViewConstraints];
    
    // Set Done button
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//                                                                                           target:self
//                                                                                           action:@selector(closeView)];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

}

- (void)viewDidLoad { //FIXME PHOTO CAPTION NEEDS TO BE THE FIRST COMMENT
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"CommentTableViewCell" bundle:nil] forCellReuseIdentifier:COMMENT_CELL];
    
    // Setup tableview delegate/datasource
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    
    // Setup Empty Datasets delegate/datasource
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    
    if(!self.trunkMembers || self.trunkMembers.count == 0){
        [SocialUtility trunkMembers:self.trip block:^(NSArray *users, NSError *error) {
            if(!error){
                self.trunkMembers = [NSArray arrayWithArray:users];
                if(![[TTCache sharedCache] mentionUsers] && [[TTCache sharedCache] mentionUsers].count == 0)
                    [self buildMentionUsersCache];
            }else{
                NSLog(@"Error: %@",error);
            }
        }];
    }else{
        if(![[TTCache sharedCache] mentionUsers] && [[TTCache sharedCache] mentionUsers].count == 0)
            [self buildMentionUsersCache];
    }
    
    
}
- (void)viewWillAppear:(BOOL)animated {
//    self.tabBarController.tabBar.hidden = YES;
}
- (void)viewDidAppear:(BOOL)animated {
    
    // reload the table every time it appears or we get weird results
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = NO;
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
    commentCell.delegate = self;
    NSDictionary *activity = [_activities objectAtIndex:indexPath.row];
    [commentCell setCommentActivity:activity];
    
    // We assume fromUser contains the full PFUser object
    PFUser *user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    __weak CommentTableViewCell *weakCell = commentCell;
    weakCell.delegate = self;
    
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
        PFObject *object = [self.activities objectAtIndex:indexPath.row];
        [SocialUtility deleteComment:object forPhoto:self.photo block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error deleting comment: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error") message:NSLocalizedString(@"Couldn't delete comment, try again",@"Couldn't delete comment, try again") delegate:self cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay") otherButtonTitles:nil, nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert show];
                });
            }
            else {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                self.autocompletePopover = [storyboard instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
                [self.autocompletePopover removeMentionFromDatabase:object comment:@"" previousComment:object[@"content"]];
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
    NSString *text = NSLocalizedString(@"No Comments",@"No Comments");
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor blackColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"You could be the first to comment on this photo",@"You could be the first to comment on this photo");

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
            [SocialUtility addComment:comment forPhoto:_photo isCaption:NO
                                block:^(BOOL succeeded, PFObject *object, PFObject *commentObject, NSError *error) {
                                    
                if (!error) {
                    [self.activities addObject:commentObject];
                    [self.tableView reloadData];
                    self.comment = comment;
                    [self updateMentionsInDatabase:commentObject];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"commentUpdatedOnPhoto" object:_photo];
                }
                else {
                    UIAlertView *alertView = [[UIAlertView alloc] init];
                    alertView.delegate = self;
                    alertView.title = NSLocalizedString(@"Error adding comment. Please try again",@"Error adding comment. Please try again");
                    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                    [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                    [alertView show];
                }
            }];
            
        }
    }
}


//############################################# MENTIONS ##################################################
-(void)updateMentionsInDatabase:(PFObject*)object{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.autocompletePopover = [storyboard instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
    [self.autocompletePopover saveMentionToDatabase:object comment:self.comment previousComment:@"" photo:self.photo members:self.trunkMembers];
}

-(void)displayAutocompletePopoverFromView:(NSString *)text{
    if([self displayAutocompletePopover:text]){
        if(!self.autocompletePopover.delegate){
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            self.autocompletePopover = [storyboard instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
            self.autocompletePopover.modalPresentationStyle = UIModalPresentationPopover;
            
            //force the popover to display like an iPad popover otherwise it will be full screen
            self.popover  = self.autocompletePopover.popoverPresentationController;
            self.popover.delegate = self;
            self.popover.sourceView = self.commentInputView.commentField;
            self.popover.sourceRect = [self.commentInputView bounds];
            self.popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
            
            if([[TTCache sharedCache] mentionUsers] && [[TTCache sharedCache] mentionUsers].count > 0){
                
                self.autocompletePopover.friendsArray = [NSMutableArray arrayWithArray:[[TTCache sharedCache] mentionUsers]];
                
                self.autocompletePopover.mentionText = text;
                [self.autocompletePopover updateAutocompleteTableView];
                //If there are friends to display, now show the popup on the screen
                if(self.autocompletePopover.displayFriendsArray.count > 0 || self.autocompletePopover.displayFriendsArray != nil){
                    self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], [self.autocompletePopover preferredHeightForPopover]);
                    self.autocompletePopover.delegate = self;
                    [self presentViewController:self.autocompletePopover animated:YES completion:nil];
                }
                
            }else{
                
                if(!self.trunkMembers)
                    self.trunkMembers = [[NSArray alloc] init];
                
                //Build the friends list for the table view in the popover and wait
                NSDictionary *data = @{
                                       @"trunkMembers" : self.trunkMembers,
                                       @"trip" : self.trip,
                                       @"photo" : self.photo
                                       };
                [self.autocompletePopover buildPopoverList:data block:^(BOOL succeeded, NSError *error){
                    if(succeeded){
                        [[TTCache sharedCache] setMentionUsers:self.autocompletePopover.friendsArray];
                        //send the current word to the Popover to use for comparison
                        NSLog(@"text: %@",text);
                        self.autocompletePopover.mentionText = text;
                        [self.autocompletePopover updateAutocompleteTableView];
                        //If there are friends to display, now show the popup on the screen
                        if(self.autocompletePopover.displayFriendsArray.count > 0 || self.autocompletePopover.displayFriendsArray != nil){
                            self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], [self.autocompletePopover preferredHeightForPopover]);
                            self.autocompletePopover.delegate = self;
                            [self presentViewController:self.autocompletePopover animated:YES completion:nil];
                        }
                    }else{
                        NSLog(@"Error: %@",error);
                    }
                }];
                
            }
        }
    }
    
    //Update the table view in the popover but only if it is currently displayed
    if([self updateAutocompletePopover:text]){
        self.autocompletePopover.mentionText = text;
        [self.autocompletePopover updateAutocompleteTableView];
    }
    
    //Remove the popover if a space is typed
    if([self dismissAutocompletePopover:text]){
        [self dismissViewControllerAnimated:YES completion:nil];
        self.popover.delegate = nil;
        self.autocompletePopover = nil;
    }
}

//Only true if user has typed an @ and a letter and if the popover is not showing
-(BOOL)displayAutocompletePopover:(NSString*)lastWord{
    return [lastWord containsString:@"@"] && ![lastWord isEqualToString:@"@"] && !self.popover.delegate;
}

//Only true if the popover is showing and the user typed a space
-(BOOL)dismissAutocompletePopover:(NSString*)lastWord{
    return self.popover.delegate && ([lastWord hasSuffix:@" "] || [lastWord isEqualToString:@""]);
}

//Only true if the popover is showing and there are friends to show in the table view and the @mention isn't broken
-(BOOL)updateAutocompletePopover:(NSString*)lastWord{
    return self.popover.delegate && self.autocompletePopover.displayFriendsArray.count > 0 && ![lastWord isEqualToString:@""];
}

#pragma mark - UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

- (void)popoverViewControllerShouldDissmissWithNoResults{
    [self removeAutocompletePopoverFromSuperview];
}

//Dismiss the popover and reset the delegates
-(void)removeAutocompletePopoverFromSuperview{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.popover.delegate = nil;
    self.autocompletePopover = nil;
}

- (void)insertUsernameAsMention:(NSString*)username{
    //Get the currently typed word
    UITextRange* selectedRange = [self.commentInputView.commentField selectedTextRange];
    NSInteger cursorOffset = [self.commentInputView.commentField offsetFromPosition:self.commentInputView.commentField.beginningOfDocument toPosition:selectedRange.start];
    NSString* substring = [self.commentInputView.commentField.text substringToIndex:cursorOffset];
    NSString* lastWord = [[substring componentsSeparatedByString:@" "] lastObject];
    //get a mutable copy of the current caption
    NSMutableString *caption = [NSMutableString stringWithString:self.commentInputView.commentField.text];
    //create the replacement range of the typed mention
    NSRange mentionRange = NSMakeRange(cursorOffset-[lastWord length], [lastWord length]);
    //replace that typed @mention with the user name of the user they want to mention
    NSString *mentionString = [caption stringByReplacingCharactersInRange:mentionRange withString:[NSString stringWithFormat:@"%@ ",username]];
    
    //display the new caption
    self.commentInputView.commentField.text = mentionString;
    //dismiss the popover
    [self removeAutocompletePopoverFromSuperview];
    //reset the font colors and make sure the cursor is right after the mention. +1 to add a space
    //FIXME: Cursor position is not being used here, refactor!
    self.commentInputView.commentField.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.commentInputView.commentField.text];
    UITextPosition *newPosition = [self.commentInputView.commentField positionFromPosition:self.commentInputView.commentField.beginningOfDocument offset:cursorOffset-[lastWord length]+[username length]+1];
    UITextRange *newRange = [self.commentInputView.commentField textRangeFromPosition:newPosition toPosition:newPosition];
    [self.commentInputView.commentField setSelectedTextRange:newRange];
    self.autocompletePopover.delegate = nil;
}

//Adjust the height of the popover to fit the number of usernames in the tableview
-(void)adjustPreferredHeightOfPopover:(NSUInteger)height{
    self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], height);
}

- (NSString*)getUsernameFromLink:(NSString*)link{
    return [link substringFromIndex:1];
}

-(NSString*)separateMentions:(NSString*)comment{
    if(![comment containsString:@"@"])
        return comment;
    
    NSArray *array = [comment componentsSeparatedByString:@"@"];
    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
    return [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
}

#pragma mark - UIPopoverControllerDelegate
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController{
    self.popover.delegate = nil;
    self.autocompletePopover = nil;
}

-(void)buildMentionUsersCache{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.autocompletePopover = [storyboard instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
    
    //This is the prevent a crash
    if(!self.trunkMembers)
        self.trunkMembers = [[NSArray alloc] init];
    
    //Added this to prevent a crash but may want to use fetchIfNeeded
    if(!self.trip)
        self.trip = [[Trip alloc] init];
    
    //Added this to prevent a crash but may want to use fetchIfNeeded
    if(!self.photo)
        self.photo = [[Photo alloc] init];
    
    //Build the friends list for the table view in the popover and wait
    NSDictionary *data = @{
                           @"trunkMembers" : self.trunkMembers,
                           @"trip" : self.trip,
                           @"photo" : self.photo
                           };
    [self.autocompletePopover buildPopoverList:data block:^(BOOL succeeded, NSError *error){
        if(succeeded){
            [[TTCache sharedCache] setMentionUsers:self.autocompletePopover.friendsArray];
        }else{
            NSLog(@"Error: %@",error);
        }
    }];
}


//############################################# MENTIONS ##################################################

#pragma mark -
- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}


@end
