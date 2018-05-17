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

@interface TTSearchViewController () <UserTableViewCellDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIAlertViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UIPopoverPresentationControllerDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet TTOnboardingTextField *searchTextField;
@property (strong, nonatomic) NSMutableArray *promoted;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTPopoverProfileViewController *popoverProfileViewController;
@property NSString *searchString;
@property PFUser *user;
@property BOOL loadedOnce;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (strong, nonatomic) NSMutableArray *friends;
@property (strong, nonatomic) NSMutableArray *following; // users this user is already following
@property (strong, nonatomic) NSMutableArray *pending; // users this user has requested to follow
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
    // Do any additional setup after loading the view.
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.promoted = [NSMutableArray arrayWithArray:[[TTCache sharedCache] promotedUsers]];
    if(self.promoted.count == 0)
        [self loadPromotedUsers];;
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
                [self.tableView reloadData];
//                if ([PFUser currentUser][@"fbid"]){
//                    [self getFriendsFromFbids:[[TTCache sharedCache] facebookFriends]];
//                }
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
                _friends = [NSMutableArray arrayWithArray:objects];
                // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isLoadingFacebook = NO;
                    [self.tableView reloadData];
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
                else if (error){
                    if (error.code != 120){
                        NSLog(@"Error loading pending: %@",error);
                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadFollowing:"];
                        self.isLoadingPending = NO;
                    }
                } else {
                    self.isLoadingPending = NO;
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
            [facebookRequest appendString:@"/v2.12/me/friends"];
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


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    self.searchString = nil;
    self.searchController.active = NO;
    [self.tableView reloadData];
    
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
    [friendCell.followButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
    friendCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PFUser *user;
    if(self.searchResults){
        user = self.searchResults[indexPath.row];
    }else{
        id promotedUser = self.promoted[indexPath.row];
//        if([promotedUser isKindOfClass:[PFUser class]])
//            user = promotedUser;
//        else
        user = promotedUser[@"user"];
    }
    
    friendCell.firstLastName.text = [NSString stringWithFormat:@"%@ %@",user[@"firstName"], user[@"lastName"]];
    
        if(user[@"friend"]==0){ //this doesn't work on promoted users
            friendCell.followButton.userInteractionEnabled = YES;
            [friendCell.followButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
            [friendCell.followButton setSelected:NO];
        }else{
            friendCell.followButton.userInteractionEnabled = NO;
            [friendCell.followButton setTitle:@"FOLLOWING" forState:UIControlStateNormal];
            [friendCell.followButton setSelected:YES];
        }
    
        [friendCell.profilePic setImageWithURL:[NSURL URLWithString:user[@"profilePicUrl"]]];
        friendCell.profilePic.tag = indexPath.row;
        friendCell.tag = indexPath.row;
        
        return friendCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - Table view delegate
// On Row Selection, push to the user's profile
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //    if (_viewType == TTActivityViewAllActivities) {
    //        // Don't allow row selection for All Activities--usernames and photos have different links.
    //        return;
    //    }
    
    //    UserProfileViewController *vc;
    //
    //    if (self.filter.tag == 0) {
    //
    //        vc = [[UserProfileViewController alloc] initWithUser:[[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"]];
    //
    //    } else {
    //        vc = [[UserProfileViewController alloc] initWithUser:[[self.followingActivities objectAtIndex:indexPath.row] valueForKey:@"fromUser"]];
    //    }
    //    if (vc) {
    //        [self.navigationController pushViewController:vc animated:YES];
    //    }
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

//-(void)setFollowStatus:(UIButton *)sender {
//    if ([sender isSelected] == YES) {
//        // Unfollow
//        [sender setSelected:NO]; // change the button for immediate user feedback
//        //        [sender setTitle:@"Follow" forState:UIControlStateNormal];
//        //        sender.backgroundColor = [UIColor whiteColor];
//        //        sender.titleLabel.textColor = [TTColor tripTrunkRed];
//        //        [sender setTitleColor:[TTColor tripTrunkRed] forState:UIControlStateNormal];
//        //        [self.currentUserFriends removeObject:user.objectId];
//        [SocialUtility unfollowUser:self.facebookFriends[sender.tag] block:^(BOOL succeeded, NSError *error) {
//            if(error){
//                NSLog(@"Error: %@", error);
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unfollow Failed"
//                                                                message:@"Please try again"
//                                                               delegate:self
//                                                      cancelButtonTitle:@"Okay"
//                                                      otherButtonTitles:nil, nil];
//                [sender setSelected:YES];
//                [alert show];
//            }else{
//                NSLog(@"User unfollowed");
//            }
//        }];
//    }
//    else {
//        // Follow
//        [sender setSelected:YES];
//        sender.titleLabel.textColor = [UIColor whiteColor];
//        [sender setTitleColor:[TTColor tripTrunkWhite] forState:UIControlStateNormal];
//        //        [self.currentUserFriends addObject:user.objectId];
//        [SocialUtility followUserInBackground:self.facebookFriends[sender.tag] block:^(BOOL succeeded, NSError *error) {
//            if (error) {
//                //                sender.titleLabel.textColor = [TTColor tripTrunkRed];
//                //                [sender setTitleColor:[TTColor tripTrunkRed] forState:UIControlStateNormal];
//                NSLog(@"Error: %@", error);
//                //                [self.currentUserFriends removeObject:user.objectId];
//                NSLog(@"Follow failed");
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Follow Failed"
//                                                                message:@"Please try again"
//                                                               delegate:self
//                                                      cancelButtonTitle:@"Okay"
//                                                      otherButtonTitles:nil, nil];
//                [sender setSelected:NO];
//                [alert show];
//            }else{
//                NSLog(@"User followed");
//            }
//        }];
//    }
//}

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
    return [NSString stringWithFormat:@"%@%@",[user[@"firstName"] substringToIndex:1],[user[@"lastName"] substringToIndex:1]];;
}

#pragma mark - Friend Search
- (void)filterResults:(NSString *)searchTerm {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissKeyboard) object:nil];
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

@end
