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

#import "FriendTableViewCell.h"
#import "SocialUtility.h"

@interface FindFriendsViewController () <UITableViewDelegate, UITableViewDataSource, FriendTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *friends;

@end

@implementation FindFriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self getFacebookFriendList];
    _friends = [[NSMutableArray alloc] init];
}


- (void)getFacebookFriendList {

    if ([FBSDKAccessToken currentAccessToken]) {
        
        // Get the user's Facebook Friends who are already on TripTrunk
        // Facebook doesn't allow us to get the whole friends list, only friends on the app.
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/friends" parameters:nil] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                NSLog(@"fetched friends:%@", result);
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




#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Facebook Friends on TripTrunk";
            break;
    }
    
    return @"";
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _friends.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FriendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell" forIndexPath:indexPath];
    [cell setDelegate:self];
    [cell.followButton setSelected:NO];

    PFUser *possibleFriend = [_friends objectAtIndex:indexPath.row];
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
            [cell.followButton setSelected:(!error && number > 0)];
        }
    }];

    return cell;
}


#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - FriendsTableViewCellDelegate

- (void)cell:(FriendTableViewCell *)cellView didPressFollowButton:(PFUser *)user;
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
