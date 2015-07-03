//
//  FriendsListViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "FriendsListViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "UIImageView+AFNetworking.h"

#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "UserProfileViewController.h"

#define USER_CELL @"user_table_view_cell"

@interface FriendsListViewController () <UserTableViewCellDelegate>

@property (strong, nonatomic) NSMutableArray *friends;
@property (nonatomic) BOOL isFollowing;
@property (strong, nonatomic) PFUser *thisUser;

@end

@implementation FriendsListViewController

- (id)initWithUser:(PFUser *)user andFollowingStatus:(BOOL)isFollowing
{
    self = [super initWithNibName:@"FriendsListViewController" bundle:nil]; // nil is ok if the nib is included in the main bundle
    if (self) {
        _friends = [[NSMutableArray alloc] init];
        _isFollowing = isFollowing;
        _thisUser = user;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Register Cell Classes
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    self.tableView.sectionHeaderHeight = 0;
    
    if (_isFollowing) {
        [self loadFollowing];
        self.title = @"Following";
    }
    else
    {
        [self loadFollowers];
        self.title = @"Followers";
    }
    
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
                [_friends addObject: user];
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
                [_friends addObject: user];
            }
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_isFollowing) {
        return @"Following";
    }
    else
    {
        return @"Followers";
    }
    
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"NUMBER OF ROWS %lu", (unsigned long)_friends.count);

    return _friends.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *possibleFriend = [_friends objectAtIndex:indexPath.row];
    UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
    [cell setUser:possibleFriend];
    [cell setDelegate:self];
    
    [cell.followButton setSelected:_isFollowing];
    
    
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
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    PFUser *user = [_friends objectAtIndex:indexPath.row];
    
    if (user) {
        UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:user];
        
        [self.navigationController pushViewController:vc animated:YES];
    }

}

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



@end
