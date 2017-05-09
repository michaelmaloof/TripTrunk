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
#import "UIImageView+AFNetworking.h"
#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "TTUtility.h"
#import "TTUsernameSort.h"

#define USER_CELL @"user_table_view_cell"

@interface AddTripFriendsViewController () <UserTableViewCellDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (strong, nonatomic) NSMutableArray *friends;
@property (nonatomic) BOOL isFollowing;
@property (strong, nonatomic) PFUser *thisUser;
// Array of PFUser objects that are already part of the trip
@property (strong, nonatomic) NSMutableArray *existingMembers;
@property BOOL isNext;
@property NSMutableArray *membersToAdd;
@property BOOL isSearching;
@property NSMutableArray *friendsObjectIds;
@property BOOL didTapCreated;
@property (strong, nonatomic) IBOutlet UITableView *followingTableView;
@property (strong, nonatomic) IBOutlet UICollectionView *membersCollectionView;


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
    
    self.membersToAdd = [[NSMutableArray alloc]init];
    if (!self.existingMembers) {
        self.existingMembers = [[NSMutableArray alloc] init]; // init so no crash
    }
    
    self.friendsObjectIds = [[NSMutableArray alloc]init];
    
    self.title = NSLocalizedString(@"Add Members",@"Add Members");
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    
    // During trip creation flow we want a Next button, otherwise it's a Done button
    if (self.isTripCreation) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Create Trunk",@"Create Trunk")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(saveFriendsAndClose)];
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [TTColor tripTrunkBlue], NSForegroundColorAttributeName,
                                                                        [TTFont tripTrunkFontBold14], NSFontAttributeName, nil] forState:UIControlStateNormal];
                UIBarButtonItem *newBackButton =
        [[UIBarButtonItem alloc] initWithTitle:@""
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
        [[self navigationItem] setBackBarButtonItem:newBackButton];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update",@"Update") style:UIBarButtonItemStylePlain target:self action:@selector(saveFriendsAndClose)];
  
    
    }
    
    _thisUser = [PFUser currentUser];
    
    // Create nested arrays to populate the table view
    NSMutableArray *following = [[NSMutableArray alloc] init];
    NSMutableArray *followers = [[NSMutableArray alloc] init];
    _friends = [[NSMutableArray alloc] initWithObjects:following, followers, nil];

    self.tableView.multipleTouchEnabled = YES;
    self.tableView.allowsMultipleSelection = YES;
    [self initSearchController];
    
    // Get the users for the list
    [self loadFollowing];
    [self loadFollowers];
    
    // Add keyboard notifications so that the keyboard won't cover the table when searching
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.isNext = YES;
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
    
    [[self.searchController searchBar] setValue:NSLocalizedString(@"Done",@"Done" )forKey:@"_cancelButtonText"];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;

}



- (void)loadFollowing
{
    
    [SocialUtility followingUsers:_thisUser block:^(NSArray *users, NSError *error) {
        if (!error) {
            
            NSMutableArray *friendsToAdd = [[NSMutableArray alloc]init];
            
            for (PFUser *user in users){
                if (![self.friendsObjectIds containsObject:user.objectId]){
                    [self.friendsObjectIds addObject:user.objectId];
                    [friendsToAdd addObject:user];
                }
            }
            
            [[_friends objectAtIndex:0] addObjectsFromArray:friendsToAdd];

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
            
            NSMutableArray *friendsToAdd = [[NSMutableArray alloc]init];

            for (PFUser *user in users){
                if (![self.friendsObjectIds containsObject:user.objectId]){
                    [self.friendsObjectIds addObject:user.objectId];
                    [friendsToAdd addObject:user];
                }
            }
            
            [[_friends objectAtIndex:1] addObjectsFromArray:friendsToAdd];


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
    return 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // Search Controller and the regular table view have different data sources
    if (!self.searchController.active)
    {
    
        switch (section) {
            case 0:
                return NSLocalizedString(@"Following",@"Following");
                break;
            case 1:
                return NSLocalizedString(@"Followers",@"Followers");
            default:
                break;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor = [TTColor tripTrunkRed];
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[TTColor tripTrunkWhite]];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Search Controller and the regular table view have different data sources
    if (!self.searchController.active) {
        return [[_friends objectAtIndex:section] count];
    } else if (self.isNext == NO && self.isSearching == YES){
        return self.searchResults.count;
    } else {
        return [[_friends objectAtIndex:section] count];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    
    if (self.isEditing){
        [self.navigationController.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Done",@"Done")];
    } else if (self.isNext == YES){
        if (self.didTapCreated == YES){
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update",@"Update") style:UIBarButtonItemStylePlain target:self action:@selector(saveFriendsAndClose)];

        }else if (self.isTripCreation){
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Create Trunk",@"Create Trunk") style:UIBarButtonItemStylePlain target:self action:@selector(saveFriendsAndClose)];

        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update",@"Update") style:UIBarButtonItemStylePlain target:self action:@selector(saveFriendsAndClose)];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    PFUser *possibleFriend;
    NSString *searchString = [self.searchController.searchBar.text lowercaseString];
    // The search controller uses it's own table view, so we need this to make sure it renders the cell properly.
    if (self.searchController.active && ![searchString isEqualToString:@""] && self.isNext == NO && self.isSearching == YES) {
        possibleFriend = [self.searchResults objectAtIndex:indexPath.row];
    }
    else {
        possibleFriend = [[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    }
    UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
    cell.profilePicImageView.image = nil;
    [cell.followButton setHidden:YES]; // Hide the follow button - this screen isn't about following people.
    [cell setUser:possibleFriend];
    [cell setDelegate:self];
    
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:possibleFriend[@"profilePicUrl"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    __weak UserTableViewCell *weakCell = cell;
    [cell.profilePicImageView setImageWithURLRequest:request
                                    placeholderImage:nil
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 
                                                 [weakCell.profilePicImageView setImage:image];
                                                 [weakCell setNeedsLayout];
                                                 
                                             } failure:nil];
    
    return weakCell;

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.membersToAdd.count + self.existingMembers.count >= 199){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Someone is Popular",@"Someone is Popular")
                                                        message:NSLocalizedString(@"Unfortunately, only 200 users can be members of one Trunk. We apologize for the inconvenience.",@"Unfortunately, only 200 users can be members of one Trunk. We apologize for the inconvenience.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
       [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [alert show];
    }
    
    else if (self.membersToAdd.count < 50){
        if (self.isNext == YES && self.isSearching == NO){
            [self.membersToAdd addObject:[[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
        } else if (self.isSearching == YES){
            [self.membersToAdd addObject:[self.searchResults objectAtIndex:indexPath.row]];
        } else {
            [self.membersToAdd addObject:[[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
        }

                
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Someone is Popular",@"Someone is Popular")
                                                        message:NSLocalizedString(@"Unfortunately, only 50 users can be added to a Trunk at once. We apologize for the inconvenience.",@"Unfortunately, only 50 users can be added to a Trunk at once. We apologize for the inconvenience.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [alert show];
    }
    
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    if (self.isNext == YES && self.isSearching == NO ){
        [self.membersToAdd removeObject:[[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
    } else if (self.isSearching == YES){
        PFUser *user = [self.searchResults objectAtIndex:indexPath.row];
        BOOL delete = false;
        for (PFUser *deleteUser in self.membersToAdd){
            if ([user.objectId isEqualToString:deleteUser.objectId])
            {
                delete = YES;
                user = deleteUser;
                break;
            }
        }
        
        if (delete == YES){
            [self.membersToAdd removeObject:user];
        }
    } else {
        [self.membersToAdd removeObject:[[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
    }
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UserTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set selection of existing members
    if ([self userExists:cell.user inArray:self.existingMembers] == YES){
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else if ([self userExists:cell.user inArray:self.membersToAdd] == YES){
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}



- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}


#pragma mark - UserTableViewCellDelegate

- (void)cell:(UserTableViewCell *)cellView didPressFollowButton:(PFUser *)user;
{
    
    if ([cellView.followButton isSelected]) {
        // Unfollow
        [cellView.followButton setSelected:NO]; // change the button for immediate user feedback
        [SocialUtility unfollowUser:user block:^(BOOL succeeded, NSError *error) {
            //
        }];
    }
    else {
        // Follow
        [cellView.followButton setSelected:YES];
        [SocialUtility followUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
            }
            if (!succeeded) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Follow Failed",@"Follow Failed")
                                                                message:NSLocalizedString(@"Please try again",@"Please try again")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
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

- (NSDictionary *)addToTripFunctionParamsForUser:(PFUser *)user onTrip:(Trip *)trip {
    // Create the params dictionary of all the info we need in the Cloud Function
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            user.objectId, @"toUserId",
                            [PFUser currentUser].objectId, @"fromUserId",
                            trip.objectId, @"tripId",
                            trip.creator.objectId, @"tripCreatorId",
                            [NSString stringWithFormat:@"%@", trip.city], @"content",
                            [NSNumber numberWithDouble:trip.lat], @"latitude",
                            [NSNumber numberWithDouble:trip.longitude], @"longitude",
                            nil];
    return params;
}

- (NSArray *)idsFromUsers:(NSArray *)users
{
    NSMutableArray *idList = [[NSMutableArray alloc] initWithCapacity:users.count];
    for (PFUser *user in users) {
        [idList addObject:user.objectId];
    }
    return idList;
}

/**
 *  Save the selected friends to the trip,
 *  and perform the segue/push/pop based on what the user is doing here.
 */
- (void)saveFriendsAndClose
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.title = @"TripTrunk";
    
    // TODO: If this test is true, and it's the Search Controller, then it'll go back instead of just hiding the search controller.
    // This needs to just go back to the main list.
    if (self.membersToAdd.count == 0 && !self.isTripCreation) {
        // Adding friends to an existing trip, so pop back
        [self.delegate memberWasAdded:self];
        [self.navigationController popViewControllerAnimated:YES];
        
        return; // make sure it doesn't execute further.

    }
    // We have members to add to the trunk - if it's during creation this will just add the creator.
    else {
        // If it's the creation flow, add the creator as a "member" to the trip
        
        NSArray *users = self.isTripCreation ? [[self idsFromUsers:self.membersToAdd] arrayByAddingObject:[PFUser currentUser].objectId] : [self idsFromUsers:self.membersToAdd];
        // Create the params dictionary of all the info we need in the Cloud Function

        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                users, @"users",
                                [PFUser currentUser].objectId, @"fromUserId",
                                self.trip.objectId, @"tripId",
                                self.trip.creator.objectId, @"tripCreatorId",
                                [NSNumber numberWithBool:self.trip.isPrivate], @"private",
                                [NSString stringWithFormat:@"%@", self.trip.city], @"content",
                                [NSNumber numberWithDouble:self.trip.lat], @"latitude",
                                [NSNumber numberWithDouble:self.trip.longitude], @"longitude",
                                self.trip.gpID, @"gpID",
                                nil];
        
        [PFCloud callFunctionInBackground:@"AddMembersToTrip" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
            // Perform the Navigation to the next/previous screen.
            // NOTE: this will happen BEFORE the cloud functions finish saving everything. That's fine. Hopefully.
            if(!error){
                //THIS INCREMENTS THE MEMBER COUNT BY 1number of members added
                //This needs to be moved to AddMembersToTrip in CC
                PublicTripDetail *ptdId = self.trip.publicTripDetail;
                PFQuery *query = [PFQuery queryWithClassName:@"PublicTripDetail"];
                [query getObjectInBackgroundWithId:ptdId.objectId block:^(PFObject *pfObject, NSError *error) {
                    int count = 0;
                    if(pfObject[@"memberCount"])
                        count = [pfObject[@"memberCount"] intValue];
                    
                    count = count+(int)self.membersToAdd.count;
                    [pfObject setObject:[NSNumber numberWithInt:count] forKey:@"memberCount"];
                    [pfObject saveInBackground];
                }];
                ///-----------------------------^
            }
            
            if (!self.isTripCreation) {
                // Adding friends to an existing trip, so pop back
                [self.navigationController popViewControllerAnimated:YES];
            }
            else {
                // Nex trip creation flow, so push forward
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update",@"Update") style:UIBarButtonItemStylePlain target:self action:@selector(saveFriendsAndClose)];
                
                [self performSegueWithIdentifier:@"photos" sender:self];
                self.didTapCreated = YES;
                
            }
        }];
        
    }
    
}



#pragma mark - Search Stuff

- (void)filterResults:(NSString *)searchTerm {
    if (![searchTerm isEqualToString:@""]){
        //[self.searchResults removeAllObjects];
        
        
        //TODO: add NOT IN existingUsers query to both of these
        
        //     Gets all the users who have blocked this user. Hopefully it's 0!
        PFQuery *blockQuery = [PFQuery queryWithClassName:@"Block"];
        [blockQuery whereKey:@"blockedUser" equalTo:[PFUser currentUser]];
        
        PFQuery *usernameQuery = [PFUser query];
        [usernameQuery whereKeyExists:@"username"];  //this is based on whatever query you are trying to accomplish
        [usernameQuery whereKey:@"username" containsString:searchTerm];
        [usernameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]];
        [usernameQuery whereKeyExists:@"completedRegistration"]; // Make sure we don't get half-registered users with the weird random usernames
        
        PFQuery *nameQuery = [PFUser query];
        [nameQuery whereKeyExists:@"lowercaseName"];  //this is based on whatever query you are trying to accomplish
        [nameQuery whereKeyExists:@"completedRegistration"];// Make sure we don't get half-registered users with the weird random usernames
        [nameQuery whereKey:@"lowercaseName" containsString:[searchTerm lowercaseString]];
        [nameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]]; // exclude currentUser
        
        PFQuery *query = [PFQuery orQueryWithSubqueries:@[usernameQuery, nameQuery]];
        query.limit = 10;
        //FIXME SEARCH NEEDS A SKIP OR ITLL KEEP RETURNING THE SAME ONES
        
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            
            if (error){
                [ParseErrorHandlingController handleError:error];
            } else {
                self.searchResults = [[NSMutableArray alloc] init];
                [self.searchResults addObjectsFromArray:objects];
                TTUsernameSort *us = [[TTUsernameSort alloc] init];
                NSArray *sortedArray = [us sortResultsByUsername:self.searchResults searchTerm:searchTerm];
                self.searchResults = [NSMutableArray arrayWithArray:sortedArray];
                self.isSearching = YES;
                [self.tableView reloadData];
                [[TTUtility sharedInstance] internetConnectionFound];
            }
        }];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self filterResults:searchText];
}

/**
 *  Delegate method executed when the "Done" button is pressed
 */
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {    
    self.isSearching = NO;

    if (self.isNext == YES) {
        [self saveFriendsAndClose];
//        [self.tableView reloadData];
    } else {
        self.isNext = YES;
//        [self loadFollowing];
//        [self loadFollowers];
        [self.tableView reloadData];

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

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
//    NSString *searchString = searchController.searchBar.text;
//    if (![searchString isEqualToString:@""]){
//        [self filterResults:searchString];
//    }
}



-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if (![searchBar.text isEqualToString:@""]){
        self.isSearching = YES;
        NSString *searchLower = [searchBar.text lowercaseString];
            [self filterResults:searchLower];
    }
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    self.isNext = NO;
//    self.isSearching = YES;
    [self.navigationController.navigationItem.rightBarButtonItem setTitle:NSLocalizedString(@"Done",@"Done")];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    AddTripPhotosViewController *addTripPhotosViewController = segue.destinationViewController;
    addTripPhotosViewController.trip = self.trip;
    addTripPhotosViewController.trunkMembers = self.membersToAdd;
    addTripPhotosViewController.isTripCreation = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
