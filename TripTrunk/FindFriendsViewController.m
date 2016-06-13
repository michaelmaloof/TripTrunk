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

@interface FindFriendsViewController() <UserTableViewCellDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UISearchController *searchController;
@property NSString *searchString;
@property PFUser *user;
@property (strong,nonatomic) UserTableViewCell *friendCell;
@property BOOL loadedOnce;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (strong, nonatomic) NSMutableArray *friends;
@property (strong, nonatomic) NSMutableArray *following; // users this user is already following
@property (strong, nonatomic) NSMutableArray *pending; // users this user has requested to follow
@property (strong, nonatomic) NSMutableArray *promoted;
@property int searchCount;
@property BOOL removeResults;
@property BOOL friendsMaxed;
@property BOOL isLoadingFollowing;
@property BOOL isLoadingPending;
@property BOOL isLoadingFacebook;
@property BOOL isLoadingSearch;
@property int privateUserCellIndex;
@property BOOL facebookRefreshed;

@end

@implementation FindFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Find Friends";
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:@"FriendCell"];
    _friends = [[NSMutableArray alloc] init];
    _following = [[NSMutableArray alloc] init];
    _pending = [[NSMutableArray alloc] init];
    self.loadedOnce = NO;
    [self loadPromotedUsers];
    [self setUpTableViewandSearch];
}

-(void)viewDidAppear:(BOOL)animated{
    [self loadFollowing];
}

-(void)setUpTableViewandSearch{
    self.searchResults = [[NSMutableArray alloc] init];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.tintColor = [TTColor tripTrunkWhite];
    [[self.searchController searchBar] setValue:NSLocalizedString(@"Done",@"Done")forKey:@"_cancelButtonText"];
    [self.searchController.searchBar sizeToFit];
    [self.searchController.searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
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
    _promoted = [[NSMutableArray alloc] initWithArray:[[TTCache sharedCache] promotedUsers]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            [[TTUtility sharedInstance] internetConnectionFound];
            _promoted = [NSMutableArray arrayWithArray:objects];
            [[TTCache sharedCache] setPromotedUsers:_promoted];
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([PFUser currentUser][@"fbid"]){
                    [self getFriendsFromFbids:[[TTCache sharedCache] facebookFriends]];
                }
            });
        }
        else
        {
            NSLog(@"Error: %@",error);
            [ParseErrorHandlingController handleError:error];
        }
    }];
}

- (void)getFriendsFromFbids:(NSArray *)fbids {
    if (self.isLoadingFacebook == NO){
        self.isLoadingFacebook = YES;

    if (fbids.count == 0) {
        self.isLoadingFacebook = NO;
        if (self.facebookRefreshed == NO){
            if ([PFUser currentUser][@"fbid"]){
                [self refreshFacebookFriends];
            }
        }
        return;
    }
    // Get the TripTrunk user objects with the list of cached fbid's
    PFQuery *friendsQuery = [PFUser query];
    [friendsQuery whereKey:@"fbid" containedIn:fbids];
    [friendsQuery whereKeyExists:@"completedRegistration"]; // Make sure we don't get half-registered users with the weird random usernames
    friendsQuery.limit = 200;
    friendsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
            [ParseErrorHandlingController handleError:error];
            self.isLoadingFacebook = NO;
        }
        else
        {
            _friends = [NSMutableArray arrayWithArray:objects];
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isLoadingFacebook = NO;
                [self.tableView reloadData];
                if (self.facebookRefreshed == NO){
                    if ([PFUser currentUser][@"fbid"]){
                        [self refreshFacebookFriends];
                    }
                }
            });
        }
    }];
    }

}

-(void)searchFacebookFriends:(NSArray *)fbids {
    // Get the TripTrunk user objects with the list of cached fbid's
    
    if (self.isLoadingSearch == NO && self.isLoadingFacebook == NO){
        self.isLoadingSearch = YES;
    
    PFQuery *friendsQuery = [PFUser query];
    [friendsQuery whereKey:@"fbid" containedIn:fbids];
    [friendsQuery whereKeyExists:@"completedRegistration"]; // Make sure we don't get half-registered users with the weird random usernames
    friendsQuery.limit = 200;
    friendsQuery.skip = self.friends.count;
    [friendsQuery whereKey:@"objectId" notContainedIn:self.friends];

    
    [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
            [ParseErrorHandlingController handleError:error];
            self.isLoadingSearch = NO;

        }
        else
        {
            [[TTUtility sharedInstance] internetConnectionFound];
            [_friends addObjectsFromArray:objects];
            
            
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                if (objects.count == 0) {
                    self.friendsMaxed = YES;
                }
                self.isLoadingSearch = NO;
                [self.tableView reloadData];
            });
        }
    }];
    }
}

- (void)loadFollowing
{
    self.isLoadingFollowing = YES;
    self.isLoadingPending = YES;
    // TODO: Make this work for > 100 users since parse default limits 100. 
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error) {
            for (PFUser *user in users) {
                [_following addObject:user.objectId];
            }
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isLoadingFollowing = NO;
                [self.tableView reloadData];
            });
            
            
            // Now that we have the array of following, lets also get their Pending..this should be a smaller array.
            [SocialUtility pendingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
                if (!error && users.count > 0) {
                    for (PFUser *user in users) {
                        [_pending addObject:user.objectId];
                    }
                    // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.isLoadingPending = NO;
                        if (self.loadedOnce == NO){
                            self.loadedOnce = YES;
//                            [self getFriendsFromFbids:[[TTCache sharedCache] facebookFriends]];
//                            [self loadPromotedUsers];
                        } else {
                            [self.tableView reloadData];
                        }
                    });
                }
                else {
                    NSLog(@"Error loading pending: %@",error);
                    self.isLoadingPending = NO;

                }
            }];
            
        }
        else {
            NSLog(@"Error loading following: %@",error);
            self.isLoadingPending = NO;
            self.isLoadingFollowing= NO;
        }
    }];
    
}

- (void)refreshFacebookFriends {
    
    if (self.isLoadingFacebook == NO){
        self.isLoadingFacebook = YES;
    if ([FBSDKAccessToken currentAccessToken]) {
        
        // Get the user's Facebook Friends who are already on TripTrunk
        // Facebook doesn't allow us to get the whole friends list, only friends on the app.
        NSMutableString *facebookRequest = [NSMutableString new];
        [facebookRequest appendString:@"/me/friends"];
        [facebookRequest appendString:@"?limit=1000"];
        
        [[[FBSDKGraphRequest alloc] initWithGraphPath:facebookRequest parameters:@{@"fields": @"id"}] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                
                self.facebookRefreshed = YES;
                // result will contain an array with user's friends in the "data" key
                self.isLoadingFacebook = NO;

                // Loop through the friends list and create a new array of just their fbid's
                NSMutableArray *friendList = [[NSMutableArray alloc] init];
                for (NSDictionary *friend in [result objectForKey:@"data"]) {
                    [friendList addObject:friend[@"id"]];
                }
                
                // Cache the facebook ID's
                [[TTCache sharedCache] setFacebookFriends:friendList];
                
                if (friendList.count != 0) {
                    if ([PFUser currentUser][@"fbid"]){
                        [self getFriendsFromFbids:friendList];
                    }
                }
            }
        }];
    }
    else {
        NSLog(@"No Facebook Access Token");
        self.isLoadingFacebook = NO;

    }
    }

}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.searchString = nil;
    self.searchController.active = NO;
    [self.tableView reloadData];

}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor = [TTColor tripTrunkRed];
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[TTColor tripTrunkWhite]];
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
    if(y > h + reload_distance && self.searchString)
    {
        self.removeResults = NO;
        if (![self.searchString isEqualToString:@""])
        {
            [self filterResults:self.searchString isScroll:YES];
        }
    } else if (y > h + reload_distance && self.friendsMaxed == NO){
        if ([PFUser currentUser][@"fbid"]){
            [self searchFacebookFriends:[[TTCache sharedCache] facebookFriends]];
        }
    }
}

- (void)filterResults:(NSString *)searchTerm isScroll:(BOOL)isScroll {
    
    if (self.isLoadingSearch == NO){
        self.isLoadingSearch = YES;
        
        if (self.searchCount > 29){
            self.isLoadingSearch = NO;
        }
        
    if (self.searchCount < 30){
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
    NSMutableArray *objcts = [[NSMutableArray alloc]init];
    if (isScroll == YES)
    {
        for (PFObject *obj in self.searchResults)
        {
            [objcts addObject:[obj objectId]];
        }
        
        [usernameQuery whereKey:@"objectId" notContainedIn:objcts];
        [nameQuery whereKey:@"objectId" notContainedIn:objcts];

    }
        
//FIXME
//better way to paginate and get new content
        
//    [query orderByDescending:@"createdAt"]; [query whereKey:@"createdAt" lessThanOrEqualTo:lastObjectDate]; [query whereKey:@"objectId" notContainedIn:lastSectionObjectsIDs];
        
//        https://www.parse.com/questions/duplicates-objects-in-pfqueryviewcontroller-with-paging-enable-using-a-query-with-ordering-constraint-based-on-date

    PFQuery *query = [PFQuery orQueryWithSubqueries:@[usernameQuery, nameQuery]];
        
    query.limit = 10;
    
    if (self.removeResults == NO){
        self.searchCount = self.searchCount + 10;
        query.skip = self.searchResults.count;
    } else {
        query.skip = 0;
        self.searchCount = 0;

    }
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (error){
            [ParseErrorHandlingController handleError:error];
        } else {
        
        if (self.removeResults == YES) {
            [self.searchResults removeAllObjects];
        }
        [self.searchResults addObjectsFromArray:objects];
        self.searchString = searchTerm;
        self.isLoadingSearch = NO;
        [self.tableView reloadData];
        [[TTUtility sharedInstance] internetConnectionFound];
        }
    }];
//    if (self.removeResults == YES) {
//        [self.searchResults removeAllObjects];
//    }
//    [self.searchResults addObjectsFromArray:results];
//    self.searchString = searchTerm;
//    [self.tableView reloadData];

}
    }
}


//FIXME: TEMP UNTILL WE SEARCH AS USERS TYPE


- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    if (![searchBar.text isEqualToString:@""]){
        self.removeResults = YES;
        self.friendsMaxed  = NO;
        if (![searchBar.text isEqualToString:@""]){
            NSString *searchLower = [searchBar.text lowercaseString];
            [self filterResults:searchLower isScroll:NO];
        }
    }
    return YES;
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = [self.searchController.searchBar.text lowercaseString];
    
    if (![searchString isEqualToString:self.searchString] && ![searchString isEqualToString:@""]){
        self.removeResults = YES;
        self.searchCount = 0;
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
                if (self.promoted.count > 0){
                    return @"Featured Travelers";
                }
                break;
            case 1:
                if (self.friends.count > 0){
                    return @"Facebook Friends on TripTrunk";
                }
                break;
        }
    }
    return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Search Controller and the regular table view have different data sources
    if (self.searchController.active) {
        if (![self.searchString isEqualToString:@""]){
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
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    PFUser *possibleFriend;
    __weak UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
    cell.profilePicImageView.image = nil;
    cell.profilePicImageView.image = nil;
    [cell.followButton.titleLabel setFont:[TTFont tripTrunkFont12]];
    [cell.followButton setHidden:YES];
    [cell.followButton setSelected:NO];
    // The search controller uses it's own table view, so we need this to make sure it renders the cell properly.
    if (self.searchController.active && ![self.searchString isEqualToString:@""] && self.searchResults.count > 0) {
        possibleFriend = [self.searchResults objectAtIndex:indexPath.row];
    }else {
        if (indexPath.section == 0)
            possibleFriend = [[_promoted objectAtIndex:indexPath.row] valueForKey:@"user"];
        else if (indexPath.section == 1)
            possibleFriend = [_friends objectAtIndex:indexPath.row];
    }
    [cell setDelegate:self];
    [cell setUser:possibleFriend];
    cell.tag = indexPath.row; // set the tag so that we make sure we don't set the follow status on the wrong cell
    cell.followButton.tag = indexPath.row;
    if (self.following.count > 0) {
        [cell.followButton setEnabled:YES];
        [cell.followButton setSelected:YES];
        if ([self.pending containsObject:possibleFriend.objectId]){
            [cell.followButton setEnabled:YES];
            [cell.followButton setSelected:YES];
            [cell.followButton setTitle:@"Pending" forState:UIControlStateSelected];
            [cell.followButton setHidden:NO];
        } else if ([self.following containsObject:possibleFriend.objectId]){
            [cell.followButton setSelected:YES];
            [cell.followButton setTitle:@"Following" forState:UIControlStateSelected];
            [cell.followButton setHidden:NO];
        } else if ([[PFUser currentUser].objectId isEqualToString:possibleFriend.objectId]){
            [cell.followButton setHidden:YES];
        } else {
            [cell.followButton setSelected:NO];
            [cell.followButton setTitle:@"Follow" forState:UIControlStateNormal];
            [cell.followButton setTitleColor:[TTColor tripTrunkRed] forState:UIControlStateNormal];
            [cell.followButton setHidden:NO];
        }
    } else {
        [cell.followButton setHidden:NO];
    }
    
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:possibleFriend[@"profilePicUrl"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    [cell.profilePicImageView setImageWithURLRequest:request
                                    placeholderImage:nil
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 [cell.profilePicImageView setImage:image];
                                                 [cell setNeedsLayout];
                                            } failure:nil];
       return cell;
}


#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *possibleFriend;
    if (self.searchController.active) {
        if (self.searchResults.count > 0 && ![self.searchController.searchBar.text isEqualToString:@""])
        {
            possibleFriend = [self.searchResults objectAtIndex:indexPath.row];
        } else {
            possibleFriend = [[_promoted objectAtIndex:indexPath.row] valueForKey:@"user"];
        }
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
    if (self.isLoadingFollowing == NO && self.isLoadingPending == NO){
    if ([cellView.followButton isSelected]) {
        // Unfollow
        //FIXME FOR INTERNATIONAL, USING STRING COMPARISSON
        if ([user[@"private"] boolValue] == YES && ![cellView.followButton.titleLabel.text isEqual:@"Pending"]){
            self.user = user;
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.tag = 11;
            self.friendCell = cellView;
            NSString *youSure = NSLocalizedString(@"Are you sure you want to unfollow",@"Are you sure you want to unfollow");
            alertView.title = [NSString stringWithFormat:@"%@ %@?",youSure, user.username];
            alertView.message = NSLocalizedString(@"Their account is private so you will no longer be able to see any photos they've posted. You will still have access to photos they've posted in trunks that you are a member.",@"Their account is private so you will no longer be able to see any photos they've posted. You will still have access to photos they've posted in trunks that you are a member of.");
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:NSLocalizedString(@"Cancel",@"Cancel")];
            [alertView addButtonWithTitle:NSLocalizedString(@"Unfollow",@"Unfollow")];
            [alertView show];
            
            //FIXME the aboive code is the behavior we want. We want the user to be warned about unfollowing a private user. For now, it is commented out but it needs to be uncommeted and then the bug with it fixed. The bug is that when you unfollow a private user the button doesnt change
//            [cellView.followButton setSelected:NO];
//            [cellView.followButton setTitle:NSLocalizedString(@"Follow",@"Follow") forState:UIControlStateNormal];
//            [self.following removeObject:user.objectId];
//            [SocialUtility unfollowUser:user];
        } else {
            // change the button for immediate user feedback
            [cellView.followButton setSelected:NO];
               [cellView.followButton setTitle:NSLocalizedString(@"Follow",@"Follow") forState:UIControlStateNormal];
            [self.following removeObject:user.objectId];
            [SocialUtility unfollowUser:user];
        }
    }
    else {
        // Follow
        [cellView.followButton setSelected:YES];
        
        // Add the user to the following array so we have a local copy of who they're following.

        if ([user[@"private"] boolValue] == YES) {
            [cellView.followButton setTitle:@"Pending" forState:UIControlStateSelected];
            [_pending addObject:user.objectId];
        } else {
            [_following addObject:user.objectId];
            [cellView.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateSelected];

        }
        
 
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
                      [cellView.followButton setTitle:NSLocalizedString(@"Follow",@"Follow") forState:UIControlStateNormal];
                    [self.following removeObject:user.objectId]; //we lose these
                    [self.pending removeObject:user];
                }
                
            }
            
            if (!error && [user[@"private"] boolValue] == NO){
                [cellView.followButton setTitle:NSLocalizedString(@"Following",@"Following") forState:UIControlStateSelected];
            } else {
                [cellView.followButton setTitle:NSLocalizedString(@"Pending",@"Pending") forState:UIControlStateSelected];
            }
        }];
    }
    }
}


#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text;
    if (self.loadedOnce == YES){
        text = @"No Users Found";
    } else {
        text = @"Looking For Users";
    }
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFontBold16],
                                 NSForegroundColorAttributeName: [TTColor tripTrunkBlack]};
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"";
    
    if (self.searchController.active) {
        text = @"Are you sure a user exists with this name?";
    }
    else if (self.loadedOnce == YES){
        text = @"Invite some Facebook friends to TripTrunk!";
    }
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFont14],
                                 NSForegroundColorAttributeName: [TTColor tripTrunkLightGray],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [TTColor tripTrunkWhite];
}

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


- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag == 11 && buttonIndex == 1){
        [SocialUtility unfollowUser:self.user];
        [self.pending removeObject:self.user];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:self.friendCell];
        NSArray* indexArray = [NSArray arrayWithObjects:indexPath, nil];
        [self.tableView reloadRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadData];
        
    } else {
        self.user = nil;
    }
}




@end
