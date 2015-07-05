//
//  FindFriendsViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/7/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "FindFriendsViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

#import "UIImageView+AFNetworking.h"
#import "UserTableViewCell.h"
#import "SocialUtility.h"
#import "UserProfileViewController.h"

@interface FindFriendsViewController() <UserTableViewCellDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, strong) NSMutableArray *searchResults;

@property (strong, nonatomic) NSMutableArray *friends;

@end

@implementation FindFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:@"FriendCell"];

    [self getFacebookFriendList];
    _friends = [[NSMutableArray alloc] init];

    self.searchResults = [NSMutableArray array];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    [self.searchController.searchBar sizeToFit];

    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    


}


- (void)getFacebookFriendList {

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
                
                // Now get the TripTrunk user objects
                PFQuery *friendsQuery = [PFUser query];
                [friendsQuery whereKey:@"fbid" containedIn:friendList];
                
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
        }];
    }
    else {
        NSLog(@"No Facebook Access Token");
    }
}

- (void)filterResults:(NSString *)searchTerm {
    
    [self.searchResults removeAllObjects];
    
    PFQuery *usernameQuery = [PFUser query];
    [usernameQuery whereKeyExists:@"username"];  //this is based on whatever query you are trying to accomplish
    [usernameQuery whereKey:@"username" containsString:searchTerm];
    [usernameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]];
    
    PFQuery *nameQuery = [PFUser query];
    [nameQuery whereKeyExists:@"name"];  //this is based on whatever query you are trying to accomplish
    [nameQuery whereKey:@"name" containsString:searchTerm];
    [nameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]]; // exclude currentUser

    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[usernameQuery, nameQuery]];
    
    
    NSArray *results  = [query findObjects];
    
    [self.searchResults addObjectsFromArray:results];
}


#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    [self filterResults:searchString];
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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
        return self.searchResults.count;
    } else {
        return _friends.count;
    }
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *possibleFriend;
    UserTableViewCell *cell;
    
    // The search controller uses it's own table view, so we need this to make sure it renders the cell properly.
    if (self.searchController.active) {
        possibleFriend = [self.searchResults objectAtIndex:indexPath.row];
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
    }
    else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"FriendCell" forIndexPath:indexPath];
        possibleFriend = [_friends objectAtIndex:indexPath.row];
    }
    
    [cell setDelegate:self];
    [cell.followButton setSelected:NO];

    [cell setUser:possibleFriend];
    
    cell.tag = indexPath.row; // set the tag so that we make sure we don't set the follow status on the wrong cell
    
    // Determine the follow status of the user
    PFQuery *isFollowingQuery = [PFQuery queryWithClassName:@"Activity"];
    [isFollowingQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [isFollowingQuery whereKey:@"type" equalTo:@"follow"];
    [isFollowingQuery whereKey:@"toUser" equalTo:possibleFriend];
    [isFollowingQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (cell.tag == indexPath.row) {
            [cell.followButton setHidden:NO];
            [cell.followButton setSelected:(!error && number > 0)];
        }
    }];

    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURL *picUrl = [NSURL URLWithString:possibleFriend[@"profilePicUrl"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    __weak UserTableViewCell *weakCell = cell;
    
    [cell.profilePicImageView setImageWithURLRequest:request
                                    placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 
                                                 [weakCell.profilePicImageView setImage:image];
                                                 [weakCell setNeedsLayout];
                                                 
                                             } failure:nil];
    return weakCell;
    
    return cell;
}


#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *possibleFriend;
    
    if (self.searchController.active) {
        possibleFriend = [self.searchResults objectAtIndex:indexPath.row];
    }
    else {
        possibleFriend = [_friends objectAtIndex:indexPath.row];
    }
    
    
    if (possibleFriend) {
        UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:possibleFriend];
        
        [self.navigationController pushViewController:vc animated:YES];
    }

    
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
        
        [SocialUtility followUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
            }
            if (!succeeded) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Follow Failed"
                                                                message:@"Please try again"
                                                               delegate:self
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil, nil];
                
                [cellView.followButton setSelected:NO];
                [alert show];
            }
            else
            {
            }
        }];
    }
}


#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



@end
