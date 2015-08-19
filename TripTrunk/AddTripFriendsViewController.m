//
//  AddTripFriendsViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/29/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddTripFriendsViewController.h"
#import "AddTripPhotosViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "UIImageView+AFNetworking.h"

#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "TTUtility.h"

#define USER_CELL @"user_table_view_cell"

@interface AddTripFriendsViewController () <UserTableViewCellDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults;

@property (strong, nonatomic) NSMutableArray *friends;
@property (nonatomic) BOOL isFollowing;
@property (strong, nonatomic) PFUser *thisUser;
// Array of PFUser objects that are already part of the trip
@property (strong, nonatomic) NSMutableArray *existingMembers;

@end

@implementation AddTripFriendsViewController

- (id)initWithTrip:(Trip *)trip andExistingMembers:(NSArray *)members;
{
    self = [super init]; // nil is ok if the nib is included in the main bundle
    if (self) {
        self.trip = trip;
        self.existingMembers = [[NSMutableArray alloc] initWithArray:members];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    
    if (!self.existingMembers) {
        self.existingMembers = [[NSMutableArray alloc] init]; // init so no crash
    }
    
    self.title = @"Add Friends";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    
    // During trip creation flow we want a Next button, otherwise it's a Done button
    if (self.isTripCreation) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(saveFriendsAndClose)];
        
        UIBarButtonItem *newBackButton =
        [[UIBarButtonItem alloc] initWithTitle:@""
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
        [[self navigationItem] setBackBarButtonItem:newBackButton];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(saveFriendsAndClose)];
    }
        
    _thisUser = [PFUser currentUser];
    
    // Create nested arrays to populate the table view
    NSMutableArray *following = [[NSMutableArray alloc] init];
    NSMutableArray *followers = [[NSMutableArray alloc] init];
    _friends = [[NSMutableArray alloc] initWithObjects:following, followers, nil];
    
    [self.tableView setEditing:YES animated:YES];
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    [self.tableView setAllowsSelectionDuringEditing:YES];
    
    
    [self initSearchController];

    
    // Get the users for the list
    [self loadFollowing];
    [self loadFollowers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initSearchController {
    self.searchResults = [NSMutableArray array];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    [self.searchController.searchBar sizeToFit];
    
    [[self.searchController searchBar] setValue:@"Done" forKey:@"_cancelButtonText"];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;

}




- (void)loadFollowing
{
    
    [SocialUtility followingUsers:_thisUser block:^(NSArray *users, NSError *error) {
        if (!error) {
            [[_friends objectAtIndex:0] addObjectsFromArray:users];
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else {
            NSLog(@"Error: %@",error);
        }
    }];
    
}

- (void)loadFollowers
{
    [SocialUtility followers:_thisUser block:^(NSArray *users, NSError *error) {
        if (!error) {
            [[_friends objectAtIndex:1] addObjectsFromArray:users];
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else {
            NSLog(@"Error: %@",error);
        }
    }];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // Search Controller and the regular table view have different data sources
    if (!self.searchController.active)
    {
    
        switch (section) {
            case 0:
                return @"Following";
                break;
            case 1:
                return @"Followers";
            default:
                break;
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Search Controller and the regular table view have different data sources
    if (!self.searchController.active) {
        return [[_friends objectAtIndex:section] count];
    } else {
        return self.searchResults.count;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFUser *possibleFriend;
    
    // The search controller uses it's own table view, so we need this to make sure it renders the cell properly.
    if (self.searchController.active) {
        possibleFriend = [self.searchResults objectAtIndex:indexPath.row];
    }
    else {
        possibleFriend = [[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    
    UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
    [cell setEditing:YES animated:YES];
    [cell.followButton setHidden:YES]; // Hide the follow button - this screen isn't about following people.
    [cell setUser:possibleFriend];
    [cell setDelegate:self];
    
    [cell.followButton setSelected:_isFollowing];
    
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:possibleFriend[@"profilePicUrl"]]];
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

-(void)tableView:(UITableView *)tableView willDisplayCell:(UserTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set selection of existing members
    [cell setSelected:[self userExists:cell.user inArray:self.existingMembers]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleNone;
}

//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    
//}
//
//-(NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//}

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

- (BOOL)userExists:(PFUser *)user inArray:(NSArray *)userList
{
    BOOL exists = NO;
    for (PFUser *existing in userList) {
        if ([[existing objectId] isEqualToString:[user objectId]]) {
            exists = YES;
        }
    }
    return exists;
}

- (void)saveFriends
{
    NSMutableArray *tripUsers = [[NSMutableArray alloc] init];;
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    


    if (selectedRows.count > 0)
    {
        
        for (NSIndexPath *indexPath in selectedRows) {
            PFUser *user = [self.searchResults objectAtIndex:indexPath.row];
            if (![self userExists:user inArray:self.existingMembers]) {
                PFObject *tripUser = [SocialUtility createAddToTripObjectForUser:user onTrip:self.trip];
                [tripUsers addObject:tripUser];
                [self.existingMembers addObject:user];
            }
        }
        [PFObject saveAllInBackground:tripUsers block:^(BOOL succeeded, NSError *error) {
            if (error || !succeeded) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Saving Frinds Failed"
                                                                message:@"Please try again"
                                                               delegate:self
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil, nil];
                [alert show];
                
            }
        }];
    }
}

/**
 *  Save the selected friends to the trip, and close the view so that the map shows again
 */
- (void)saveFriendsAndClose
{
    self.title = @"Saving Friends...";

    NSMutableArray *tripUsers = [[NSMutableArray alloc] init];;
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    if (self.isTripCreation) {
        // It's the creation flow, so add the creator as a "member" to the trip
        PFObject *tripUser = [SocialUtility createAddToTripObjectForUser:[PFUser currentUser] onTrip:self.trip];
        [tripUsers addObject:tripUser];
    }

    if (selectedRows.count == 0 && !self.isTripCreation) {
        // Adding friends to an existing trip, so pop back
        [self.navigationController popViewControllerAnimated:YES];
        self.title = @"TripTrunk";
        return; // make sureit doesn't execute further.

    }
    else if (selectedRows.count > 0)
    {
        
        for (NSIndexPath *indexPath in selectedRows) {
            PFUser *user = [[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            PFObject *tripUser = [SocialUtility createAddToTripObjectForUser:user onTrip:self.trip];
            [tripUsers addObject:tripUser];
        }
    }

    
    [PFObject saveAllInBackground:tripUsers block:^(BOOL succeeded, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR"
                                                            message:@"Please try again"
                                                           delegate:self
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil, nil];
            
            [alert show];
            self.title = @"TripTrunk";

        }
        if (!succeeded) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Saving Frinds Failed"
                                                            message:@"Please try again"
                                                           delegate:self
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil, nil];
            
            [alert show];
            self.title = @"TripTrunk";

        }
        else
        {
            self.title = @"TripTrunk";

        }
        
    }];
    
    
    // Dismiss the view controller
    // We dismiss it outside the save block so that there's no hangup for the user.
    // The downside is, if it fails then they have to redo everything
    //TODO: Should we put up a "loading" spinner and wait to dismiss until we save successfully?
    if (!self.isTripCreation) {
        // Adding friends to an existing trip, so pop back
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        // Nex trip creation flow, so push forward
        [self performSegueWithIdentifier:@"photos" sender:self];

    }
}



#pragma mark - Search Stuff

- (void)filterResults:(NSString *)searchTerm {
    
    [self.searchResults removeAllObjects];
    
    PFQuery *usernameQuery = [PFUser query];
    [usernameQuery whereKeyExists:@"username"];  //this is based on whatever query you are trying to accomplish
    [usernameQuery whereKey:@"username" containsString:searchTerm];
    [usernameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]];
    
    //TODO: add NOT IN existingUsers query to both of these
    
    PFQuery *nameQuery = [PFUser query];
    [nameQuery whereKeyExists:@"name"];  //this is based on whatever query you are trying to accomplish
    [nameQuery whereKey:@"name" containsString:searchTerm];
    [nameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]]; // exclude currentUser
    
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[usernameQuery, nameQuery]];
    
    
    NSArray *results  = [query findObjects];
        
    [self.searchResults addObjectsFromArray:results];
}

/**
 *  Delegate method executed when the "Done" button is pressed
 */
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"cancel button pressed: %lu", (unsigned long)[self.tableView indexPathsForSelectedRows].count);
    [self saveFriends];
    [self.tableView reloadData];
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    [self filterResults:searchString];
    [self.tableView reloadData];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {


    AddTripPhotosViewController *addTripPhotosViewController = segue.destinationViewController;
    addTripPhotosViewController.trip = self.trip;
    addTripPhotosViewController.isTripCreation = YES;
    
}


@end
