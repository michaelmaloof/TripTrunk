//
//  FindFriendsViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/7/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "FindFriendsViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "UIImageView+AFNetworking.h"
#import "UserTableViewCell.h"
#import "SocialUtility.h"
#import "UserProfileViewController.h"
#import "TTUtility.h"
#import "TTCache.h"
#import "UIScrollView+EmptyDataSet.h"
#import "UIColor+HexColors.h"

@interface FindFriendsViewController() <UserTableViewCellDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (strong, nonatomic) UISearchController *searchController;

@property NSString *searchString;

@property (nonatomic, strong) NSMutableArray *searchResults;

@property (strong, nonatomic) NSMutableArray *friends;
@property (strong, nonatomic) NSMutableArray *following; // users this user is already following

@property (strong, nonatomic) NSMutableArray *promoted;

@property BOOL removeResults;


@end

@implementation FindFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Find Friends";

    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:@"FriendCell"];

    _friends = [[NSMutableArray alloc] init];
    _following = [[NSMutableArray alloc] init];

    _promoted = [[NSMutableArray alloc] initWithArray:[[TTCache sharedCache] promotedUsers]];

    [self getFriendsFromFbids:[[TTCache sharedCache] facebookFriends]];
    [self loadPromotedUsers];
    [self loadFollowing];

    self.searchResults = [[NSMutableArray alloc] init];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    [self.searchController.searchBar sizeToFit];
    [self.searchController.searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    // Make the search Cancel button TTBlue
    UIColor *ttBlueColor = [UIColor colorWithHexString:@"76A4B8"];
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                  ttBlueColor,
                                                                                                  NSForegroundColorAttributeName,
                                                                                                  nil] 
                                                                                        forState:UIControlStateNormal];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    

    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

    // Add keyboard notifications so that the keyboard won't cover the table when searching
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

- (void)loadPromotedUsers {
    PFQuery *query = [PFQuery queryWithClassName:@"PromotedUser"];
    [query includeKey:@"user"];
    [query orderByAscending:@"priority"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            _promoted = [NSMutableArray arrayWithArray:objects];
            [[TTCache sharedCache] setPromotedUsers:_promoted];
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else
        {
            NSLog(@"Error: %@",error);
        }
    }];
}

- (void)getFriendsFromFbids:(NSArray *)fbids {
    
    if (fbids.count == 0) {
        [self refreshFacebookFriends];
        return;
    }
    // Get the TripTrunk user objects with the list of cached fbid's
    PFQuery *friendsQuery = [PFUser query];
    [friendsQuery whereKey:@"fbid" containedIn:fbids];
    [friendsQuery whereKeyExists:@"completedRegistration"]; // Make sure we don't get half-registered users with the weird random usernames
    
    [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
        }
        else
        {

            _friends = [NSMutableArray arrayWithArray:objects];
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];

}

- (void)loadFollowing
{
    // TODO: Make this work for > 100 users since parse default limits 100. 
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error) {
            for (PFUser *user in users) {
                [_following addObject:user.objectId];
            }
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else {
            NSLog(@"Error loading following: %@",error);
        }
    }];
    
}

- (void)refreshFacebookFriends {
    if ([FBSDKAccessToken currentAccessToken]) {
        
        // Get the user's Facebook Friends who are already on TripTrunk
        // Facebook doesn't allow us to get the whole friends list, only friends on the app.
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/friends" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // result will contain an array with user's friends in the "data" key
                
                // Loop through the friends list and create a new array of just their fbid's
                NSMutableArray *friendList = [[NSMutableArray alloc] init];
                for (NSDictionary *friend in [result objectForKey:@"data"]) {
                    [friendList addObject:friend[@"id"]];
                }
                
                // Cache the facebook ID's
                [[TTCache sharedCache] setFacebookFriends:friendList];
                
                if (friendList.count != 0) {
                    [self getFriendsFromFbids:friendList];
                }
            }
        }];
    }
    else {
        NSLog(@"No Facebook Access Token");
    }

}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.searchController.active = NO;
    [self.tableView reloadData];

}

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView
                  willDecelerate:(BOOL)decelerate
{
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = -250;
    if(y > h + reload_distance && self.searchString) {
        self.removeResults = NO;
        if (![self.searchController.searchBar.text isEqualToString:@""]){
            [self filterResults:self.searchString];
        }
    }
}

- (void)filterResults:(NSString *)searchTerm {
    
//     Gets all the users who have blocked this user. Hopefully it's 0!
    PFQuery *blockQuery = [PFQuery queryWithClassName:@"Block"];
    [blockQuery whereKey:@"blockedUser" equalTo:[PFUser currentUser]];
    blockQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;

    
    PFQuery *usernameQuery = [PFUser query];
    [usernameQuery whereKeyExists:@"username"];  //this is based on whatever query you are trying to accomplish
    [usernameQuery whereKey:@"username" containsString:searchTerm];
    [usernameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]];
    usernameQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;

    [usernameQuery whereKeyExists:@"completedRegistration"]; // Make sure we don't get half-registered users with the weird random usernames
    
    PFQuery *nameQuery = [PFUser query];
    [nameQuery whereKeyExists:@"lowercaseName"];  //this is based on whatever query you are trying to accomplish
    [nameQuery whereKey:@"lowercaseName" containsString:[searchTerm lowercaseString]];
    [nameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]]; // exclude currentUser
    nameQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;

    [nameQuery whereKeyExists:@"completedRegistration"];// Make sure we don't get half-registered users with the weird random usernames

    PFQuery *query = [PFQuery orQueryWithSubqueries:@[usernameQuery, nameQuery]];
    query.limit = 10;
    
    if (self.removeResults == NO){
        query.skip = self.searchResults.count;
    } else {
        query.skip = 0;
    }
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (self.removeResults == YES) {
            [self.searchResults removeAllObjects];
        }
        [self.searchResults addObjectsFromArray:objects];
        self.searchString = searchTerm;
        [self.tableView reloadData];
    }];
//    if (self.removeResults == YES) {
//        [self.searchResults removeAllObjects];
//    }
//    [self.searchResults addObjectsFromArray:results];
//    self.searchString = searchTerm;
//    [self.tableView reloadData];

}


//FIXME: TEMP UNTILL WE SEARCH AS USERS TYPE


- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    if (![searchBar.text isEqualToString:@""]){
        self.removeResults = YES;
        if (![searchBar.text isEqualToString:@""]){
            [self filterResults:searchBar.text];
        }
    }
    return YES;
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    if (![searchString isEqualToString:self.searchString] && ![self.searchController.searchBar.text isEqualToString:@""]){
        self.removeResults = YES;
//        [self filterResults:searchString];
    } else {
        self.removeResults = NO;
    }
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets.bottom = keyboardSize.height;

    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;

}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets.bottom = 0;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    [self.tableView setNeedsLayout];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchController.active) {
        return 1;
    }
    return 2;
}

//-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
//    CGRect searchBarFrame = self.searchController.searchBar.frame;
//    [self.tableView scrollRectToVisible:searchBarFrame animated:NO];
//    return NSNotFound;
//}



-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{

    // Search Controller and the regular table view have different data sources
    if (!self.searchController.active)
    {
        switch (section) {
            case 0:
                return @"Featured Travelers";
                break;
            case 1:
                return @"Facebook Friends on TripTrunk";
                break;
        }
    }
    return nil;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Search Controller and the regular table view have different data sources
    if (self.searchController.active) {
        if (![self.searchController.searchBar.text isEqualToString:@""]){
            return self.searchResults.count;
        } else {
            return 0;
        }
    }
    else if (section == 0) {
        return _promoted.count;
    }
    else if (section == 1) {
        return _friends.count;
    }
    return 0;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *possibleFriend;
    UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
    __weak UserTableViewCell *weakCell = cell;

    // The search controller uses it's own table view, so we need this to make sure it renders the cell properly.
    if (self.searchController.active && ![self.searchController.searchBar.text isEqualToString:@""]) {
        possibleFriend = [self.searchResults objectAtIndex:indexPath.row];
    }
    else {
        if (indexPath.section == 0) {
            possibleFriend = [[_promoted objectAtIndex:indexPath.row] valueForKey:@"user"];
        }
        else if (indexPath.section == 1) {
            possibleFriend = [_friends objectAtIndex:indexPath.row];
        }
    }
    
    [weakCell setDelegate:self];
    
    [weakCell setUser:possibleFriend];
    
    weakCell.tag = indexPath.row; // set the tag so that we make sure we don't set the follow status on the wrong cell
    
    
    // If we have a cached follow status of YES then just set the follow button. Otherwise, query to see if we're following or not.
    NSNumber *followStatus = [[TTCache sharedCache] followStatusForUser:possibleFriend];
    if (followStatus.intValue > 0) {
        weakCell.followButton.enabled = YES;
        [weakCell.followButton setSelected:YES];
        [weakCell.followButton setHidden:NO];
        if (followStatus.intValue == 2) {
            [weakCell.followButton setTitle:@"Pending" forState:UIControlStateSelected];
        }
    }
    else {
        [weakCell.followButton setSelected:NO];
        [weakCell.followButton setHidden:NO];
        
        if ([_following containsObject:possibleFriend.objectId]) {
            NSLog(@"FOLLOWING");
            [weakCell.followButton setHidden:NO];
            weakCell.followButton.enabled = YES;
            [weakCell.followButton setSelected:YES];
            // Cache the user's follow status
            [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithBool:YES] user:possibleFriend];
        }
        else {
            [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithBool:NO] user:possibleFriend];
        }
        
    }
    
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:possibleFriend[@"profilePicUrl"]]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    
    [cell.profilePicImageView setImageWithURLRequest:request
                                    placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 
                                                 [weakCell.profilePicImageView setImage:image];
                                                 [weakCell setNeedsLayout];
                                                 
                                             } failure:nil];
    
    [weakCell.profilePicImageView.layer setCornerRadius:32.0f];
    [weakCell.profilePicImageView.layer setMasksToBounds:YES];
    [weakCell.profilePicImageView.layer setBorderWidth:10.0f];
    weakCell.profilePicImageView.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);
    
    return weakCell;
    
}


#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *possibleFriend;
    
    if (self.searchController.active) {
        possibleFriend = [self.searchResults objectAtIndex:indexPath.row];
    }
    else {
        if (indexPath.section == 0) {
            possibleFriend = [[_promoted objectAtIndex:indexPath.row] valueForKey:@"user"];
        }
        else if (indexPath.section == 1) {
            possibleFriend = [_friends objectAtIndex:indexPath.row];
        }
    }
    
    
    if (possibleFriend) {
        UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:possibleFriend];
        
        [self.navigationController pushViewController:vc animated:YES];
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

}

#pragma mark - UserTableViewCellDelegate

- (void)cell:(UserTableViewCell *)cellView didPressFollowButton:(PFUser *)user;
{
    
    if ([cellView.followButton isSelected]) {
        // Unfollow
        [cellView.followButton setSelected:NO]; // change the button for immediate user feedback
        [SocialUtility unfollowUser:user];
    }
    else {
        // Follow
        [cellView.followButton setSelected:YES];
        
        // Add the user to the following array so we have a local copy of who they're following.
        [_following addObject:user];
        
        [SocialUtility followUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (error || !succeeded) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Follow Failed"
                                                                message:@"Please try again"
                                                               delegate:self
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil, nil];
                [alert show];
                if (error) {
                    NSLog(@"Error following user: %@", error);
                }
                
            }
        }];
    }
}


#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Users Found";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor blackColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"";
    
    if (self.searchController.active) {
        text = @"Are you sure a user exists with this name?";
    }
    else {
        text = @"Invite some Facebook friends to TripTrunk!";
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

        //TODO: Add a facebook invite button - commented code creates the button
    
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
    if ((self.searchController.active && self.searchResults.count == 0) || (!self.searchController.active && _friends.count == 0 && _promoted.count == 0)) {
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


- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}




@end
