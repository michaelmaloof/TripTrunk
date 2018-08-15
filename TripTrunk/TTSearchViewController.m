//
//  TTSearchViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/11/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTSearchViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "TTOnboardingTextField.h"
#import "TTCache.h"
#import "TTUtility.h"
#import "UIImageView+AFNetworking.h"
#import "UserTableViewCell.h"
#import "SocialUtility.h"
#import "UserProfileViewController.h"
#import "UIScrollView+EmptyDataSet.h"
#import "TTAnalytics.h"
#import "TTUsernameSort.h"
#import "TTFindFriendsViewCell.h"
#import "TTPopoverProfileViewController.h"
#import "TTProfileViewController.h"

@interface TTSearchViewController () <UserTableViewCellDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIAlertViewDelegate,UIPopoverPresentationControllerDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet TTOnboardingTextField *searchTextField;
//@property (strong, nonatomic) NSMutableArray *promoted;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTPopoverProfileViewController *popoverProfileViewController;
@property NSString *searchString;
@property PFUser *user;
@property BOOL loadedOnce;
@property (nonatomic, strong) NSMutableArray *searchResults;
//@property (strong, nonatomic) NSMutableArray *friends;
//@property (strong, nonatomic) NSMutableArray *following; // users this user is already following
//@property (strong, nonatomic) NSArray *pending; // users this user has requested to follow
@property int searchCount;
@property BOOL removeResults;
@property BOOL isSearching;
@property BOOL friendsMaxed;
@property BOOL isLoadingFollowing;
@property BOOL isLoadingPending;
@property BOOL isLoadingFacebook;
@property BOOL isLoadingSearch;
@property int privateUserCellIndex;
@property BOOL facebookRefreshed;
@property NSInteger buttonIndex;
@property NSInteger clickedButtonIndex;
@end

@implementation TTSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.following = [[NSMutableArray alloc] init];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.tabBarController.tabBar.hidden = NO;
    self.promoted = [NSMutableArray arrayWithArray:[[TTCache sharedCache] promotedUsers]];
    if(self.promoted.count == 0)
        [self loadPromotedUsers];
    else [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadPromotedUsers {
    PFQuery *query = [PFQuery queryWithClassName:@"PromotedUser"];
    [query includeKey:@"user"];
    [query orderByAscending:@"priority"];
    self.promoted = [[NSMutableArray alloc] initWithArray:[[TTCache sharedCache] promotedUsers]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            [[TTUtility sharedInstance] internetConnectionFound];
            self.promoted = [NSMutableArray arrayWithArray:objects];
            [[TTCache sharedCache] setPromotedUsers:self.promoted];
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                if([[TTCache sharedCache] following].count == 0 || [[TTCache sharedCache] following] == nil)
                    [self loadFollowing];
                else [self.tableView reloadData];
            });
        }
        else
        {
            if (error.code != 120){
                NSLog(@"Error: %@",error);
                [ParseErrorHandlingController handleError:error];
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadPromotedUsers:"];
            }
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
        BOOL hasFBFriends = NO;
        if (fbids.count > 0){
            hasFBFriends = YES;
        }
        // Get the TripTrunk user objects with the list of cached fbid's
        PFQuery *friendsQuery = [PFUser query];
        [friendsQuery whereKey:@"fbid" containedIn:fbids];
        [friendsQuery whereKeyExists:@"completedRegistration"]; // Make sure we don't get half-registered users with the weird random usernames
        friendsQuery.limit = 200;
        friendsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(error){
                if (error.code != 120){
                    NSLog(@"Error: %@",error);
                    [ParseErrorHandlingController handleError:error];
                    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"getFriendsFromFbids:"];
                    self.isLoadingFacebook = NO;
                }
            }
            else {
                self.friends = [NSMutableArray arrayWithArray:objects];
                // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isLoadingFacebook = NO;
//                    [self.tableView reloadData];
                    [[TTCache sharedCache] setFacebookFriends:(NSMutableArray*)objects];
                    if (self.facebookRefreshed == NO){
                        if ([PFUser currentUser][@"fbid"]){
                            if (hasFBFriends == NO){
                                [self refreshFacebookFriends]; //first
                            }
                        }
                    }
                });
            }
        }];
    }
}

-(void)searchFacebookFriends:(NSArray *)fbids { //FIXME, what is the point of caching the facebook ids?
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
                if (error.code != 120){
                    NSLog(@"Error: %@",error);
                    [ParseErrorHandlingController handleError:error];
                    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"searchFacebookFriends:"];
                    self.isLoadingSearch = NO;
                }
            }
            else
            {
                [[TTUtility sharedInstance] internetConnectionFound];
                [self.friends addObjectsFromArray:objects];
                
                
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
                [self.following addObject:user.objectId];
            }
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                self.isLoadingFollowing = NO;
//                [self.tableView reloadData];
                [[TTCache sharedCache] setFollowing:(NSMutableArray*)users];
            });
            
            
            // Now that we have the array of following, lets also get their Pending..this should be a smaller array.
            [SocialUtility pendingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
                if (!error && users.count > 0) {
                    self.pending = (NSMutableArray*)users;
                    // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.isLoadingPending = NO;
                        if ([PFUser currentUser][@"fbid"]){
                            if([[TTCache sharedCache] facebookFriends].count == 0 || [[TTCache sharedCache] facebookFriends] == nil)
                                [self getFriendsFromFbids:[[TTCache sharedCache] facebookFriends]];
                            else [self.tableView reloadData];
                        }else{
                            [self.tableView reloadData];
                        }
                    });
                }
                else if (error){
                    if (error.code != 120){
                        NSLog(@"Error loading pending: %@",error);
                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadFollowing:"];
                        self.isLoadingPending = NO;
                    }
                    [self.tableView reloadData];
                } else {
                    self.isLoadingPending = NO;
                    [self.tableView reloadData];
                }
            }];
        }
        else {
            if (error.code != 120){
                NSLog(@"Error loading following: %@",error);
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadFollowing:"];
                self.isLoadingPending = NO;
                self.isLoadingFollowing= NO;
            }
            [self.tableView reloadData];
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
            [facebookRequest appendString:@"/v2.12/me/friends"]; //FIXME: This should be in the plist to make it easy to update
            [facebookRequest appendString:@"?limit=1000"];
            self.facebookRefreshed = YES;
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
                }else{
                    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"refreshFacebookFriends:"];
                }
            }];
        }
        else {
            NSLog(@"No Facebook Access Token");
            self.isLoadingFacebook = NO;
        }
    }
    
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(self.searchResults)
        return self.searchResults.count;
    else return self.promoted.count;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (TTFindFriendsViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        __weak TTFindFriendsViewCell *friendCell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
////        [friendCell bringSubviewToFront:friendCell.followButton];
    friendCell.firstLastName.text = @"";
    friendCell.profilePic.image = [UIImage imageNamed:@"square_placeholder"];
    friendCell.followButton.userInteractionEnabled = NO;
    [friendCell.followButton setTitle:@"" forState:UIControlStateNormal];
    friendCell.initialsLabel.hidden = YES;
//    friendCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PFUser *user;
    if(self.searchResults){
        user = self.searchResults[indexPath.row];
    }else{
        id promotedUser = self.promoted[indexPath.row];
        user = promotedUser[@"user"];
    }
    
    friendCell.firstLastName.text = [NSString stringWithFormat:@"%@ %@",user[@"firstName"], user[@"lastName"]];
    
        if(![self.following containsObject:user.objectId]){
            friendCell.followButton.userInteractionEnabled = YES;
            [friendCell.followButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
            [friendCell.followButton setSelected:NO];
//            [friendCell.followButton setTitleColor:[TTColor tripTrunkButtonTextBlue] forState:UIControlStateNormal];
            [friendCell.followButton setBackgroundColor:[UIColor clearColor]];
        }else{
            friendCell.followButton.userInteractionEnabled = YES;
            [friendCell.followButton setTitle:@"FOLLOWING" forState:UIControlStateNormal];
            [friendCell.followButton setSelected:YES];
//            [friendCell.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            [friendCell.followButton setBackgroundColor:[TTColor tripTrunkButtonTextBlue]];
        }
    
    if(user[@"profilePicUrl"]){
        [friendCell.profilePic setImageWithURL:[NSURL URLWithString:user[@"profilePicUrl"]]];
    }else{
        friendCell.profilePic.image = [UIImage imageNamed:@"square_placeholder"];
        friendCell.initialsLabel.text = [self getInitialsForMissingProfilePictureFromUser:user];
        friendCell.initialsLabel.hidden = NO;
    }
        friendCell.profilePic.tag = indexPath.row;
        friendCell.tag = indexPath.row;
        friendCell.followButton.tag = indexPath.row;
        
        return friendCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - Table view delegate
// On Row Selection, push to the user's profile
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFUser *user;
    if(self.searchResults){
        user = self.searchResults[indexPath.row];
    }else{
        id promotedUser = self.promoted[indexPath.row];
        user = promotedUser[@"user"];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    TTProfileViewController *profileViewController = (TTProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTProfileViewController"];
    profileViewController.user = user;
    profileViewController.delegate = self;
    [self.navigationController pushViewController:profileViewController animated:YES];
}

//- (void)activityCell:(UICollectionViewCell *)cellView didPressUsernameForUser:(PFUser *)user{
//
//}

- (IBAction)longPressGestureToPreviewProfile:(UILongPressGestureRecognizer *)sender {
    if(sender.state == UIGestureRecognizerStateBegan){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
        self.popoverProfileViewController = (TTPopoverProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ProfilePopoverView"];
        CGPoint touchPoint = [sender locationInView:self.view];
        UIView* touchedView = [self.view hitTest:touchPoint withEvent:nil];
        if([touchedView isKindOfClass:[TTUserProfileImage class]]){
            PFUser *user;
            if(self.searchResults)
                user = self.searchResults[touchedView.tag];
            else user = self.promoted[touchedView.tag][@"user"];
            
            self.popoverProfileViewController.user = user;
            self.popoverProfileViewController.modalPresentationStyle = UIModalPresentationPopover;
            self.popoverProfileViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            
            //force the popover to display like an iPad popover otherwise it will be full screen
            self.popover  = self.popoverProfileViewController.popoverPresentationController;
            self.popover.delegate = self;
            self.popover.sourceView = self.view;
            self.popover.sourceRect = CGRectMake(27,140,320,380);
            self.popover.permittedArrowDirections = 0;
            
            self.popoverProfileViewController.preferredContentSize = CGSizeMake(320,380);
            self.popoverProfileViewController.popoverPresentationController.sourceView = self.view;
            self.popoverProfileViewController.popoverPresentationController.sourceRect = CGRectMake(27,140,320,380);
            
            //HACK because modalTransitionStyle doesn't work on fade in
            CATransition* transition = [CATransition animation];
            transition.duration = 0.5;
            transition.type = kCATransitionFade;
            [self.view.window.layer addAnimation:transition forKey:kCATransition];
            
            [self presentViewController:self.popoverProfileViewController animated:NO completion:nil];
        }
    }
    
    if(sender.state == UIGestureRecognizerStateEnded){
        [self.popoverProfileViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIModalPopoverDelegate
- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController: (UIPresentationController * ) controller {
    return UIModalPresentationNone;
}

-(BOOL)amIAlreadyFollowingThisUser:(NSString*)fbid{
    for(PFUser* user in self.friends){
        NSString *userFbid = [NSString stringWithFormat:@"%@",user[@"fbid"]];
        if([userFbid isEqualToString:fbid]){
            return YES;
        }
    }
    return NO;
}

-(void)setFollowStatus:(UIButton *)sender withUser:(PFUser *)user{
    if ([sender isSelected]) {
        // Unfollow
        [sender setSelected:NO]; // change the button for immediate user feedback
        [sender setTitle:@"FOLLOW" forState:UIControlStateNormal];
//        [sender setTitleColor:[TTColor tripTrunkButtonTextBlue] forState:UIControlStateNormal];
        [sender setBackgroundColor:[UIColor clearColor]];
        [SocialUtility unfollowUser:user block:^(BOOL succeeded, NSError *error) {
            if(error){
                NSLog(@"Error: %@", error);
                NSString * title = NSLocalizedString(@"Unfollow Failed", @"Unfollow Failed");
                NSString * message = NSLocalizedString(@"Please try again", @"Please try again");
                NSString * button = NSLocalizedString(@"Okay", @"Okay");
                
                [self alertUser:title withMessage:message withYes:@"" withNo:button];
                [sender setSelected:YES];
            }else{
                NSLog(@"User unfollowed");
                //WE NEED TO UPDATE THE CACHE!!!
                NSMutableArray *following = [[TTCache sharedCache] following];
                [following removeObject:user];
                [self.following removeObject:user.objectId];
                [[TTCache sharedCache] setFollowing:following];
            }
        }];
    }
    else {
        // Follow
        [sender setSelected:YES];
        [sender setTitle:@"FOLLOWING" forState:UIControlStateNormal];
//        [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [sender setBackgroundColor:[TTColor tripTrunkButtonTextBlue]];
        [SocialUtility followUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (error) {
//                [self.currentUserFriends removeObject:user.objectId];
                NSLog(@"Follow failed");

                NSLog(@"Error: %@", error);
                NSString * title = NSLocalizedString(@"Follow Failed", @"Follow Failed");
                NSString * message = NSLocalizedString(@"Please try again", @"Please try again");
                NSString * button = NSLocalizedString(@"Okay", @"Okay");
                
                [self alertUser:title withMessage:message withYes:@"" withNo:button];
                [sender setSelected:YES];
            }else{
                NSLog(@"User followed");
                //WE NEED TO UPDATE THE CACHE!!!
                NSMutableArray *following = [[TTCache sharedCache] following];
                [following addObject:user];
                [self.following addObject:user.objectId];
                [[TTCache sharedCache] setFollowing:following];
            }
        }];
    }
}


//- (IBAction)tapGestureRecognizerForFollowButton:(UITapGestureRecognizer *)sender {
//    CGPoint touchPoint = [sender locationInView:self.view];
//    UIView* touchedView = [self.view hitTest:touchPoint withEvent:nil];
//    CGPoint touchPointInCell = [sender locationInView:touchedView];
//    NSArray *views = [touchedView subviews];
//    for(id view in views){
//        if([view isKindOfClass:[UIButton class]]){
//            UIButton *buttonView = (UIButton*)view;
//            if(CGRectContainsPoint(buttonView.frame, touchPointInCell))
//                [self setFollowStatus:(UIButton*)view];
//            break;
//        }
//    }
//}

-(NSString*)getInitialsForMissingProfilePictureFromUser:(PFUser*)user{
    if([user[@"firstName"] isEqualToString:@""] || [user[@"lastName"] isEqualToString:@""])
        return @"";
    
    return [NSString stringWithFormat:@"%@%@",[user[@"firstName"] substringToIndex:1],[user[@"lastName"] substringToIndex:1]];;
}

#pragma mark - Friend Search
- (void)filterResults:(NSString *)searchTerm {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissKeyboard) object:nil];
    if (![searchTerm isEqualToString:@""]){
        //[self.searchResults removeAllObjects];
        
        
        //TODO: add NOT IN existingUsers query to both of these
        
        //     Gets all the users who have blocked this user. Hopefully it's 0!
        PFQuery *blockQuery = [PFQuery queryWithClassName:@"BlockedUsers"];
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
        
        PFQuery *query = [PFQuery orQueryWithSubqueries:@[nameQuery, usernameQuery]];
//        query.limit = 100;
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
                [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:3.0];
                [[TTUtility sharedInstance] internetConnectionFound];
            }
        }];
    }
}

//- (void)keyboardWillShow:(NSNotification *)notification {
//    //move the search field and collectionview up
//    [self.view layoutIfNeeded];
////    self.searchFieldTopConstraint.constant = 117;
////    self.tableViewTopConstraint.constant = 137;
////
////    [UIView animateWithDuration:1.00
////                     animations:^{
////                         [self.view layoutIfNeeded];
////                     }];
//}
//

//-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    if(![event touchesForView:self.searchTextField]){
//        [self dismissKeyboard];
//    }
//}
//
//-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    NSLog(@"touch ended");
//}

-(void)dismissKeyboard{
    [self.searchTextField resignFirstResponder];
    if([self.searchTextField.text isEqualToString:@""]){
        [self.view layoutIfNeeded];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSString *typedText;
    
    if(range.location == textField.text.length)
        typedText = [textField.text stringByAppendingString:string];
    else typedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    [self filterResults:typedText];
    
    return YES;
}

- (void)cell:(UserTableViewCell *)cellView didPressFollowButton:(PFUser *)user {
    
}

- (void)updateSearchResultsForSearchController:(nonnull UISearchController *)searchController {
    
}


- (IBAction)didTapFollowButton:(UIButton *)sender {
    NSLog(@"sender tage: %ld",(long)sender.tag);
    PFUser *user;
    if(self.searchResults){
        user = self.searchResults[sender.tag];
    }else{
        id promotedUser = self.promoted[sender.tag];
        user = promotedUser[@"user"];
    }
    [self setFollowStatus:sender withUser:user];
}


#pragma mark - Gestures
- (IBAction)tapGestureAction:(UITapGestureRecognizer *)sender {
    [self dismissKeyboard];
}

- (IBAction)tableViewTapGestureAction:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self.view];
    UIView* touchedView = [self.view hitTest:touchPoint withEvent:nil];
    PFUser *user;
    if(self.searchResults){
        user = self.searchResults[touchedView.tag];
    }else{
        id promotedUser = self.promoted[touchedView.tag];
        user = promotedUser[@"user"];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    TTProfileViewController *profileViewController = (TTProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTProfileViewController"];
    profileViewController.user = user;
    profileViewController.delegate = self;
    [self.navigationController pushViewController:profileViewController animated:YES];
}
@end
    
    
