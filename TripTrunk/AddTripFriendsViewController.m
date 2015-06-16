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

#define USER_CELL @"user_table_view_cell"

@interface AddTripFriendsViewController () <UserTableViewCellDelegate>

@property (strong, nonatomic) NSMutableArray *friends;
@property (nonatomic) BOOL isFollowing;
@property (strong, nonatomic) PFUser *thisUser;

@end

@implementation AddTripFriendsViewController

- (id)initWithTrip:(Trip *)trip
{
    self = [super init]; // nil is ok if the nib is included in the main bundle
    if (self) {
        self.trip = trip;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Add Friends";

    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    
    // During trip creation flow we want a Next button, otherwise it's a Done button
    if (self.isTripCreation) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(saveFriendsAndClose)];
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

    
    // Get the users for the list
    [self loadFollowing];
    [self loadFollowers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadFollowing
{
    
    // Query all user's that
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKey:@"fromUser" equalTo:_thisUser];
    [followingQuery whereKey:@"type" equalTo:@"follow"];
    [followingQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [followingQuery includeKey:@"toUser"];
    
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
        }
        else
        {
            NSLog(@"%@", objects);
            
            // These are Activity objects, so loop through and just pull out the "toUser" User objects.
            for (PFObject *activity in objects) {
                PFUser *user = activity[@"toUser"];
                [[_friends objectAtIndex:0] addObject: user];
            }
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
    }];
    
}

- (void)loadFollowers
{
    
    // Query all user's that
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKey:@"toUser" equalTo:_thisUser];
    [followingQuery whereKey:@"type" equalTo:@"follow"];
    [followingQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [followingQuery includeKey:@"fromUser"];
    
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
        }
        else
        {
            NSLog(@"%@", objects);
            
            // These are Activity objects, so loop through and just pull out the "toUser" User objects.
            for (PFObject *activity in objects) {
                PFUser *user = activity[@"fromUser"];
                [[_friends objectAtIndex:1] addObject: user];
            }
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
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
    return @"Users";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[_friends objectAtIndex:section] count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFUser *possibleFriend = [[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
    [cell setEditing:YES animated:YES];
    [cell.followButton setHidden:YES]; // Hide the follow button - this screen isn't about following people.
    [cell setUser:possibleFriend];
    [cell setDelegate:self];
    
    [cell.followButton setSelected:_isFollowing];
    
    
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURL *picUrl = [NSURL URLWithString:possibleFriend[@"profilePicUrl"]];
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
        NSLog(@"Attempt to unfollow %@",user.username);
        [cellView.followButton setSelected:NO]; // change the button for immediate user feedback
        [SocialUtility unfollowUser:user];
    }
    else {
        // Follow
        NSLog(@"Attempt to follow %@",user.username);
        [cellView.followButton setSelected:YES];
        
        [SocialUtility followUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
            }
            if (!succeeded) {
                NSLog(@"Follow NOT success");
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
                NSLog(@"Follow Succeeded");
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

    if (selectedRows.count == 0) {
        NSLog(@"No Friends Selected");
        if (!self.isTripCreation) {
            // Adding friends to an existing trip, so pop back
            [self.navigationController popViewControllerAnimated:YES];
            self.title = @"TripTrunk";

        }
        else {
            // Nex trip creation flow, so push forward
           [self performSegueWithIdentifier:@"photos" sender:self];
            self.title = @"TripTrunk";
            //    AddTripPhotosViewController *vc = [[AddTripPhotosViewController alloc]init];
        //    vc.trip = self.trip;
         //   vc.isTripCreation = YES;
        //    [self.navigationController pushViewController:vc animated:YES];
        }
        return;
    }
    
    for (NSIndexPath *indexPath in selectedRows) {
        PFUser *user = [[_friends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        PFObject *tripUser = [SocialUtility createAddToTripObjectForUser:user onTrip:self.trip];
        [tripUsers addObject:tripUser];
    }
    
    [PFObject saveAllInBackground:tripUsers block:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"Error saving friends to trip: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR"
                                                            message:@"Please try again"
                                                           delegate:self
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil, nil];
            
            [alert show];
            self.title = @"TripTrunk";

        }
        if (!succeeded) {
            NSLog(@"Add Friends to Trip NOT success");
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
            NSLog(@"saveFriends to Trip Succeeded");
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



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {


    AddTripPhotosViewController *addTripPhotosViewController = segue.destinationViewController;
    addTripPhotosViewController.trip = self.trip;
    addTripPhotosViewController.isTripCreation = YES;
    
}


@end
