//
//  TTEditTripFriendsViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 6/2/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTEditTripFriendsViewController.h"
#import "AddTripPhotosViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "UIImageView+AFNetworking.h"

#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "TTUtility.h"
#import "TTTrunkMemberViewCell.h"

#define USER_CELL @"user_table_view_cell"

@interface TTEditTripFriendsViewController () <UserTableViewCellDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) UISearchController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (strong, nonatomic) NSMutableArray *friends;
@property (nonatomic) BOOL isFollowing;
@property (strong, nonatomic) PFUser *thisUser;
// Array of PFUser objects that are already part of the trip
//@property (strong, nonatomic) NSMutableArray *existingMembers;
@property BOOL isNext;
@property NSMutableArray *membersToAdd;
@property BOOL isSearching;
@property NSMutableArray *friendsObjectIds;
@property BOOL didTapCreated;
@property (strong, nonatomic) IBOutlet UITableView *followingTableView;
@property (strong, nonatomic) IBOutlet UICollectionView *membersCollectionView;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scrollViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *viewHeightConstraint;


@end

@implementation TTEditTripFriendsViewController

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
    self.title = NSLocalizedString(@"Edit Members",@"Edit Members");
    [self.followingTableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
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
    self.followingTableView.multipleTouchEnabled = YES;
    self.followingTableView.allowsMultipleSelection = YES;
    [self initSearchController];
    // Get the users for the list
    [self loadFollowing];
//    [self loadFollowers];
  
    self.isNext = YES;
    
    if(self.existingMembers.count < 5)
        self.membersCollectionView.scrollEnabled = NO;
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
    self.searchController.searchBar.showsCancelButton = NO;
    [[self.searchController searchBar] setValue:NSLocalizedString(@"Done",@"Done" )forKey:@"_cancelButtonText"];
    self.searchController.searchBar.tintColor = [TTColor tripTrunkWhite];
    self.searchController.searchBar.frame = CGRectMake(0, 0, [[UIScreen mainScreen]applicationFrame].size.width, 44);
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    [self.mainView addSubview:self.searchController.searchBar];
//    self.followingTableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
}



- (void)loadFollowing{
    
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
            
//            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.followingTableView reloadData];
//            });
            
            [self loadFollowers];
        }
        else {
            NSLog(@"Error: %@",error);
        }
    }];
    
}

- (void)loadFollowers{
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
            
            self.scrollViewHeightConstraint.constant = 215+([[_friends objectAtIndex:0] count]*66);
            self.viewHeightConstraint.constant = self.scrollViewHeightConstraint.constant;
            
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.followingTableView reloadData];
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
    }else{
        return NSLocalizedString(@"Search Results",@"Search Results");
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor = [TTColor tripTrunkRed];
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[TTColor tripTrunkWhite]];
    [header.textLabel setFont:[TTFont tripTrunkFontBold16]];
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
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Update",@"Update") style:UIBarButtonItemStylePlain target:self action:@selector(saveFriendsAndClose)];
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
    UserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(80, 80);
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.existingMembers.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    __weak TTTrunkMemberViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.userName.text = nil;
    cell.profilePhoto.image = nil;
    //***** things Michae Maloof Added >>>
    cell.profilePhoto.frame = CGRectMake(cell.profilePhoto.frame.origin.x, cell.profilePhoto.frame.origin.y, cell.frame.size.width - 20, cell.frame.size.height - 20);
    cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, 80, 80);
    [cell.profilePhoto setContentMode:UIViewContentModeScaleAspectFill];
    //**** things Michae Maloof Added ^^
    PFUser *member = self.existingMembers[indexPath.row];
    cell.userName.text = member[@"name"];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:member[@"profilePicUrl"]]];
        [cell.profilePhoto setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            [cell.profilePhoto setImage:image];
            [cell setNeedsLayout];
        } failure:nil];
    
    [cell layoutIfNeeded];
    return cell;
}

- (CGFloat)collectionView:(UICollectionView *) collectionView
                   layout:(UICollectionViewLayout *) collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger) section {
    return 1.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    // Add inset to the collection view if there are not enough cells to fill the width.
    CGFloat cellSpacing = ((UICollectionViewFlowLayout *) collectionViewLayout).minimumLineSpacing;
    CGFloat cellWidth = ((UICollectionViewFlowLayout *) collectionViewLayout).itemSize.width;
    NSInteger cellCount = [collectionView numberOfItemsInSection:section];
    CGFloat inset = (collectionView.bounds.size.width - (cellCount * (cellWidth + cellSpacing))) * 0.5;
    inset = MAX(inset, 0.0);
    return UIEdgeInsetsMake(0.0, inset, 0.0, 1.0);
}


#pragma mark -

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

/**
 *  Save the selected friends to the trip,
 *  and perform the segue/push/pop based on what the user is doing here.
 */
- (void)saveFriendsAndClose
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.title = @"TripTrunk";
    
    //    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    
    if (self.isTripCreation) {
        // It's the creation flow, so add the creator as a "member" to the trip
        NSDictionary *params = [self addToTripFunctionParamsForUser:[PFUser currentUser] onTrip:self.trip];
        [PFCloud callFunctionInBackground:@"addToTrip" withParameters:params];
    }
    
    // TODO: If this test is true, and it's the Search Controller, then it'll go back instead of just hiding the search controller.
    // This needs to just go back to the main list.
    if (self.membersToAdd.count == 0 && !self.isTripCreation) {
        // Adding friends to an existing trip, so pop back
        [self.delegate memberWasAdded:self];
        [self.navigationController popViewControllerAnimated:YES];
        
        
        
        return; // make sure it doesn't execute further.
        
    }
    else if (self.membersToAdd.count > 0)
    {
        
        for (PFUser *user in self.membersToAdd) {
            
            // Create the params dictionary of all the info we need in the Cloud Function
            NSDictionary *params = [self addToTripFunctionParamsForUser:user onTrip:self.trip];
            
            // Call the cloud function. We have no result block, so errors will NOT be reported back to the app...uh oh?
            //            [PFCloud callFunctionInBackground:@"addToTrip" withParameters:params];
            [self.delegate memberWasAddedTemporary:user];
            [PFCloud callFunctionInBackground:@"addToTrip" withParameters:params block:
             ^(id  _Nullable object, NSError * _Nullable error) {
                 if (self.delegate) {
                     
                     if (!error){
                         [self.delegate memberWasAdded:self];
                     } else {
                         [self.delegate memberFailedToLoad:user];
                     }
                 }
             }];
            
            
            // Update the Trip's ACL if it's a private trip.
            if (self.trip.isPrivate) {
                [self.trip.ACL setReadAccess:YES forUser:user];
                [self.trip.ACL setWriteAccess:YES forUser:user];
            }
        }
    }
    
    if (self.trip.isPrivate) {
        [self.trip saveInBackground]; // Save the trip because it's ACL has been updated for the new members.
    }
    
    // Re-enable bar button and let the delegate know that things were updated.
    self.navigationItem.rightBarButtonItem.enabled = YES;
    //    if (self.delegate) {
    //        [self.delegate memberWasAdded:self];
    //    }
    
    // Perform the Navigation to the next/previous screen.
    // NOTE: this will happen BEFORE the cloud functions finish saving everything. That's fine. Hopefully.
    
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
    
}



#pragma mark - Search Stuff

- (void)filterResults:(NSString *)searchTerm {
    if (![searchTerm isEqualToString:@""]){
        [self.searchResults removeAllObjects];
        
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
                [self.searchResults addObjectsFromArray:objects];
                [self.followingTableView reloadData];
                [[TTUtility sharedInstance] internetConnectionFound];
                
                self.scrollViewHeightConstraint.constant = 215+(self.searchResults.count*66);
                self.viewHeightConstraint.constant = self.scrollViewHeightConstraint.constant;
            }
        }];
    }
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController{

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