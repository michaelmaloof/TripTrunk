//
//  FriendsListViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/14/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "FriendsListViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "UIImageView+AFNetworking.h"
#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "UserProfileViewController.h"
#import "TTUtility.h"
#import "TTCache.h"
#import "UIScrollView+EmptyDataSet.h"


#define USER_CELL @"user_table_view_cell"

@interface FriendsListViewController () <UserTableViewCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (strong, nonatomic) NSMutableArray *friends;
@property (strong, nonatomic) NSMutableArray *currentUserFriends;
@property (nonatomic) BOOL isFollowing;
@property (strong, nonatomic) PFUser *thisUser;
@property NSMutableArray *friendObjectIds;

@end

@implementation FriendsListViewController

- (id)initWithUser:(PFUser *)user andFollowingStatus:(BOOL)isFollowing
{
    self = [super initWithNibName:@"FriendsListViewController" bundle:nil]; // nil is ok if the nib is included in the main bundle
    if (self) {
        _isFollowing = isFollowing;
        _thisUser = user;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.friendObjectIds = [[NSMutableArray alloc]init];
    // Register Cell Classes
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    self.tableView.sectionHeaderHeight = 0;
    //fixme, caching flashes random users sometimes when you view multiple following lists in one app sitting
    if (_isFollowing) {
        if ([self.thisUser.objectId isEqual:[PFUser currentUser].objectId]){
            _friends = [[NSMutableArray alloc] initWithArray:[[TTCache sharedCache] following]];
        } else {
            _friends = [[NSMutableArray alloc]init];
        }
        [self loadFollowing];
        self.title = @"Following";
    }
    else
    {
        if ([self.thisUser.objectId isEqual:[PFUser currentUser].objectId]){
            _friends = [[NSMutableArray alloc] initWithArray:[[TTCache sharedCache] followers]];
        }else {
            _friends = [[NSMutableArray alloc]init];
        }
        [self loadFollowers];
        self.title = @"Followers";
    }
    self.currentUserFriends = [[NSMutableArray alloc]init];
    NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:[[TTCache sharedCache] following]];
    for (PFUser *user in temp){
        [self.currentUserFriends addObject:user.objectId];
    }

    
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
}

- (void)loadFollowing
{
    [SocialUtility followingUsers:_thisUser block:^(NSArray *users, NSError *error) {
        if (!error) {
            _friends = nil;
            _friends = [[NSMutableArray alloc] init];
            for (PFUser *user in users){
                if (![self.friendObjectIds containsObject:user.objectId]){
                    [self.friendObjectIds addObject:user.objectId];
                    [self.friends addObject:user];
                }
            }
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
            _friends = nil;
            _friends = [[NSMutableArray alloc] init];
            for (PFUser *user in users){
                if (![self.friendObjectIds containsObject:user.objectId]){
                    [self.friendObjectIds addObject:user.objectId];
                    [self.friends addObject:user];
                }
            }
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
    else {
        return @"Followers";
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _friends.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *possibleFriend = [_friends objectAtIndex:indexPath.row];
    UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
    [cell setUser:possibleFriend];
    [cell setDelegate:self];
    cell.profilePicImageView.image = nil;
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
    weakCell.followButton.hidden = NO;
    
    if ([possibleFriend.objectId isEqualToString:[PFUser currentUser].objectId]){
        cell.followButton.hidden = YES;
    } else {
        cell.followButton.hidden = NO;
    }

    if ([self.currentUserFriends containsObject:possibleFriend.objectId]){
        [cell.followButton setSelected:_isFollowing];
        [cell.followButton setTitle:@"Following" forState:UIControlStateNormal];
        weakCell.followButton.backgroundColor = [TTColor tripTrunkBlue];
        [weakCell.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [cell.followButton setSelected:NO]; // change the button for immediate user feedback
        [cell.followButton setTitle:@"Follow" forState:UIControlStateNormal];
        weakCell.followButton.backgroundColor = [UIColor whiteColor];
        [weakCell.followButton setTitleColor:[TTColor tripTrunkBlue] forState:UIControlStateNormal];
    }
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
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UserTableViewCellDelegate

- (void)cell:(UserTableViewCell *)cellView didPressFollowButton:(PFUser *)user;
{
    if ([cellView.followButton isSelected] == YES) {
        // Unfollow
        [cellView.followButton setSelected:NO]; // change the button for immediate user feedback
        [cellView.followButton setTitle:@"Follow" forState:UIControlStateNormal];
        cellView.followButton.backgroundColor = [UIColor whiteColor];
        cellView.followButton.titleLabel.textColor = [TTColor tripTrunkBlue];
        [cellView.followButton setTitleColor:[TTColor tripTrunkBlue] forState:UIControlStateNormal];
        [self.currentUserFriends removeObject:user.objectId];
        [SocialUtility unfollowUser:user block:^(BOOL succeeded, NSError *error) {
        }];
    }
    else {
        // Follow
        [cellView.followButton setSelected:YES];
        [cellView.followButton setTitle:@"Following" forState:UIControlStateNormal];
        cellView.followButton.backgroundColor = [TTColor tripTrunkBlue];
        cellView.followButton.titleLabel.textColor = [UIColor whiteColor];
        [self.currentUserFriends addObject:user.objectId];
        [SocialUtility followUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
                [self.currentUserFriends removeObject:user.objectId];
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
            }
        }];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Users Found";
    
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFontBold18],
                                 NSForegroundColorAttributeName: [TTColor tripTrunkBlack]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"";
    
    if ([_thisUser.objectId isEqualToString:[PFUser currentUser].objectId]) {
        if (_isFollowing) {
            text = @"Follow some users to see what other people are sharing";
        }
        else {
            text = @"You have no followers. Invite some friends to TripTrunk";
        }
    }
    else {
        
        NSString *name;
        if (_thisUser[@"firstName"] == nil || _thisUser[@"lastName"] == nil){
            name = [NSString stringWithFormat:@"%@",_thisUser[@"name"]];
        } else {
            name = [NSString stringWithFormat:@"%@ %@",_thisUser[@"firstName"],_thisUser[@"lastName"]];
        }
        
        if (_isFollowing) {
            text = [NSString stringWithFormat:@"%@ is not following anyone yet.",name];
        }
        else {
            text = [NSString stringWithFormat:@"%@, they have no followers yet. :( You could be their first!", name];
        }
    }
    

    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFont14],
                                 NSForegroundColorAttributeName: [TTColor tripTrunkLightGray],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    
    //TODO: Implement a facebook invite button - commented out code creates a button
    
    //    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFontBold16],
    //                                 NSForegroundColorAttributeName: [TTColor tripTrunkWhite]};
    //
    //    return [[NSAttributedString alloc] initWithString:@"Create Trunk" attributes:attributes];
    return nil;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [TTColor tripTrunkWhite];
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
    if (self.friends.count == 0) {
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
}


@end
