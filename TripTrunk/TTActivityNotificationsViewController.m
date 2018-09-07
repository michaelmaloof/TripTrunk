//
//  TTActivityNotificationsViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 1/29/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTActivityNotificationsViewController.h"
#import "TTRoundedImage.h"
#import "TTUtility.h"
#import "SocialUtility.h"
#import "TTActivityNotificationViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "TTHashtagMentionColorization.h"
#import "TTPopoverProfileViewController.h"
#import "TTUserProfileImage.h"
#import "TTActivitySectionsViewCell.h"
#import "TTOnboardingTextField.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "TTOnboardingButton.h"
#import <ParseFacebookUtilsV4/ParseFacebookUtilsV4.h>
#import "TTAnalytics.h"
#import "TTFindFriendsViewCell.h"
#import "TTUsernameSort.h"

enum TTActivityViewType : NSUInteger {
    TTActivityViewAllActivities = 1,
    TTActivityViewLikes = 2
};

@interface TTActivityNotificationsViewController () <UICollectionViewDelegate,UICollectionViewDataSource,UIPopoverPresentationControllerDelegate,UIGestureRecognizerDelegate> //<ActivityTableViewCellDelegate>
@property (weak, nonatomic) IBOutlet UILabel *headline;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraintForFacebookConnect;
@property (strong, nonatomic) NSMutableArray *activities;
@property (strong, nonatomic) NSMutableArray *followingActivities;
@property NSUInteger viewType;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (strong, nonatomic) Photo *photo;
@property BOOL activitySearchComplete;
@property BOOL isLikes;
@property NSMutableArray *trips;
@property BOOL needToRefresh;
@property BOOL isLoading;
@property UIBarButtonItem *filter;
//@property NSMutableArray *friends;
//@property NSMutableArray *facebookFriends;
@property NSMutableArray *facebookFriendsOriginalArray;
@property UIRefreshControl *refreshController;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTPopoverProfileViewController *popoverProfileViewController;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *findFriendsView;
@property (weak, nonatomic) IBOutlet TTOnboardingTextField *searchTextField;
@property (weak, nonatomic) IBOutlet UILabel *connectToFacebookLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet TTOnboardingButton *facebookButton;
@property (weak, nonatomic) IBOutlet UITableView *friendsTableView;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property BOOL isSearching;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *findFriendsLeadingConstraint;
@end

@implementation TTActivityNotificationsViewController

- (id)initWithLikes:(NSArray *)likes;
{
    self = [super init];
    if (self) {
        self.activities = [[NSMutableArray alloc] initWithArray:likes];
        self.isLikes = YES;
        self.activitySearchComplete = NO;
        self.title = NSLocalizedString(@"Likers",@"Likers");
        self.viewType = TTActivityViewLikes;
    }
    return self;
}

- (id)initWithActivities:(NSArray *)activities;
{
    self = [super init];
    if (self) {
        self.activities = [[NSMutableArray alloc] initWithArray:activities];
        self.activitySearchComplete = NO;
        self.title = self.title = NSLocalizedString(@"Activity",@"Activity");
        self.viewType = TTActivityViewAllActivities;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //TEMPORARY
    self.viewType = TTActivityViewAllActivities; //<--- temp
    self.activities = [[NSMutableArray alloc] init];
    self.followingActivities = [[NSMutableArray alloc] init];
    self.trips = [[NSMutableArray alloc] init];
    self.friends = [[NSMutableArray alloc] init];
    self.facebookFriends = [[NSMutableArray alloc] init];
    self.facebookFriendsOriginalArray = [[NSMutableArray alloc] init];
    [self loadTrips];
    [self loadFriends];
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.findFriendsLeadingConstraint.constant = kScreenWidth;
    self.tabBarController.tabBar.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setUpRefreshController{
    self.refreshController = [[UIRefreshControl alloc] init];
    [self.refreshController addTarget:self.tableView
                               action:@selector(refresh:)
                     forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview: self.refreshController];
    self.refreshController.tintColor = [UIColor whiteColor];
    [self.refreshController endRefreshing];
}

//-(void)setUpFilter{
//    self.filter.tag = 0;
//    UIImage *image = [UIImage imageNamed:@"all_mine_2"];
//    CGRect buttonFrame = CGRectMake(0, 0, 80, 20);
//    UIButton *bttn = [[UIButton alloc] initWithFrame:buttonFrame];
//    [bttn setImage:image forState:UIControlStateNormal];
//    [bttn setImage:image forState:UIControlStateHighlighted];
//    [bttn setImage:image forState:UIControlStateSelected];
//    [bttn addTarget:self action:@selector(toggleWasTapped) forControlEvents:UIControlEventTouchUpInside];
//    self.filter= [[UIBarButtonItem alloc] initWithCustomView:bttn];
//    [[self navigationItem] setRightBarButtonItem:self.filter animated:NO];
//    self.navigationItem.rightBarButtonItem.enabled = NO;
//
//}

#pragma mark - Refresh
- (void)refresh:(UIRefreshControl *)refreshControl{

    if (self.isLikes == NO){
        // Query for activities for user
        if (self.isLoading == NO){
            self.navigationItem.rightBarButtonItem.enabled = NO;
            self.isLoading = YES;
            if (self.filter.tag == 0){
                [SocialUtility queryForAllActivities:0 trips:self.trips activities:self.activities isRefresh:YES query:^(NSArray *activities, NSError *error){
                    int index = 0;
                    for (PFObject *obj in activities)
                    {
                        index += 1;
                        PFUser *toUser = obj[@"toUser"];
                        PFUser *fromUser = obj[@"fromUser"];
                        if (obj[@"trip"] && toUser != nil && fromUser != nil)
                        {
                            [self.activities insertObject:obj atIndex:index-1];
                        } else if ([obj[@"type"] isEqualToString:@"follow"] || [obj[@"type"] isEqualToString:@"pending_follow"])
                        {
                            if (toUser != nil && fromUser != nil){
                                [self.activities insertObject:obj atIndex:index-1];
                            }
                            
                        }
                    }
                    //        _activities = [NSMutableArray arrayWithArray:activities];
                    dispatch_async(dispatch_get_main_queue(), ^
                                   {
                                       // End the refreshing & update the timestamp
                                       if (refreshControl)
                                       {
                                           NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                           [formatter setDateFormat:@"MMM d, h:mm a"];
                                           NSString *lastUpdate = NSLocalizedString(@"Last update",@"Last update");
                                           NSString *title = [NSString stringWithFormat:@"%@: %@", lastUpdate, [formatter stringFromDate:[NSDate date]]];
                                           title = @"";
                                           NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[TTColor tripTrunkWhite]
                                                                                                       forKey:NSForegroundColorAttributeName];
                                           NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
                                           refreshControl.attributedTitle = attributedTitle;
                                           
                                           [refreshControl endRefreshing];
                                       }
                                       self.isLoading = NO;
                                       self.navigationItem.rightBarButtonItem.enabled = YES;
                                       [self.tableView reloadData];
                                   });
                    
                    if (error)
                    {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                        self.isLoading = NO;
                    }
                }];
            } else if (self.filter.tag ==1) {
                [SocialUtility queryForFollowingActivities:0 friends:self.friends activities:self.followingActivities isRefresh:YES query:^(NSArray *activities, NSError *error) {
                    int index = 0;
                    for (PFObject *obj in activities)
                    {
                        index += 1;
                        PFUser *toUser = obj[@"toUser"];
                        PFUser *fromUser = obj[@"fromUser"];
                        if (obj[@"trip"] && toUser != nil && fromUser != nil)
                        {
                            [self.followingActivities insertObject:obj atIndex:index-1];
                        } else if ([obj[@"type"] isEqualToString:@"follow"] || [obj[@"type"] isEqualToString:@"pending_follow"])
                        {
                            if (toUser != nil && fromUser != nil){
                                [self.followingActivities insertObject:obj atIndex:index-1];
                            }
                            
                        }
                    }
                    
                    //        _activities = [NSMutableArray arrayWithArray:activities];
                    dispatch_async(dispatch_get_main_queue(), ^
                                   {
                                       // End the refreshing & update the timestamp
                                       if (refreshControl)
                                       {
                                           NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                           [formatter setDateFormat:@"MMM d, h:mm a"];
                                           NSString *lastUpdate = NSLocalizedString(@"Last update",@"Last update");
                                           NSString *title = [NSString stringWithFormat:@"%@: %@", lastUpdate, [formatter stringFromDate:[NSDate date]]];
                                           title = @"";
                                           NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[TTColor tripTrunkWhite]
                                                                                                       forKey:NSForegroundColorAttributeName];
                                           NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
                                           refreshControl.attributedTitle = attributedTitle;
                                           
                                           [refreshControl endRefreshing];
                                       }
                                       self.isLoading = NO;
                                       self.navigationItem.rightBarButtonItem.enabled = YES;
                                       [self.tableView reloadData];
                                       
                                   });
                    if (error)
                    {
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                        self.isLoading = NO;
                    }
                }];
                
            }
        }
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(tableView == self.tableView){
        if (self.filter.tag == 0)
            return self.activities.count;
        else return self.followingActivities.count;
    }else{
        return self.facebookFriends.count;
    }
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView == self.tableView){
        TTActivityNotificationViewCell *activityCell = [self.tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        activityCell.profilePic.image = nil;
        activityCell.firstLastName.text = @"";
        activityCell.activityStatus.text = @"";
        activityCell.selectionStyle = UITableViewCellSelectionStyleNone;
//        activityCell.photoImageView.image = nil;
//        [activityCell setDelegate:self];
        NSDictionary *activity = [[NSDictionary alloc] init];
        
        if (self.filter.tag == 0)
            activity = self.activities[indexPath.row];
        else activity = self.followingActivities[indexPath.row];
    
        // We assume fromUser contains the full PFUser object
        PFUser *user;
        if ([activity[@"type"] isEqualToString:@"follow"] || [activity[@"type"] isEqualToString:@"like"]){
            
            PFUser *check = activity[@"toUser"];
            if (![[PFUser currentUser].objectId isEqualToString:check.objectId]){
                if (self.filter.tag == 1){
                    PFUser *toUser;
                    toUser = [[self.followingActivities objectAtIndex:indexPath.row] valueForKey:@"toUser"];
                }
            }
        }
        
        if (self.filter.tag == 0)
            user = [[self.activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        else user = [[self.followingActivities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        
        NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
        __weak TTActivityNotificationViewCell *weakCell = activityCell;
        weakCell.profilePic.image = nil;
        weakCell.firstLastName.text = user[@"name"];
    
        NSString *activityMessage;
    
        if([activity[@"type"] isEqualToString:@"addedPhoto"])
            activityMessage = NSLocalizedString(@"Added a photo", @"Added a photo");
    
        if([activity[@"type"] isEqualToString:@"like"])
            activityMessage = NSLocalizedString(@"Liked one of your photos", @"Liked one of your photos");
    
        if([activity[@"type"] isEqualToString:@"addToTrip"])
            activityMessage = NSLocalizedString(@"Added a photo to a trip", @"Added a photo to a trip");
    
        if([activity[@"type"] isEqualToString:@"follow"])
            activityMessage = NSLocalizedString(@"Started following you", @"Started following you");
    
        if([activity[@"type"] isEqualToString:@"pending_follow"])
            activityMessage = NSLocalizedString(@"Requested to follow you", @"Requested to follow you");
    
        if([activity[@"type"] isEqualToString:@"comment"])
            activityMessage = NSLocalizedString(@"Commented on your photo", @"Commented on your photo");
    
        if([activity[@"type"] isEqualToString:@"mention"])
            activityMessage = NSLocalizedString(@"Mentioned you in a comment", @"Mentioned you in a comment");
            
        weakCell.activityStatus.text = activityMessage;
        weakCell.profilePic.tag = indexPath.row;
        weakCell.tag = indexPath.row;
//        weakCell.photoImageView.image = nil;
        
        [activityCell.profilePic setImageWithURLRequest:request
                                                placeholderImage:nil
                                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                             
                                                             [weakCell.profilePic setImage:image];
                                                             [weakCell setNeedsLayout];
                                                             
                                                         } failure:nil];

        return weakCell;
    }else{
        __weak TTFindFriendsViewCell *friendCell = [self.friendsTableView dequeueReusableCellWithIdentifier:@"friendCell" forIndexPath:indexPath];
        [friendCell bringSubviewToFront:friendCell.followButton];
        friendCell.firstLastName.text = @"";
//        [friendCell.followButton setTitle:@"" forState:UIControlStateNormal];
        friendCell.profilePic.image = [UIImage imageNamed:@"tt_square_placeholder"];
        
        PFUser *friend = self.facebookFriends[indexPath.row];
        friendCell.firstLastName.text = friend[@"name"];
        if(friend[@"friend"]==0){
            friendCell.followButton.userInteractionEnabled = YES;
//            [friendCell.followButton setTitle:@"FOLLOW" forState:UIControlStateNormal];
            [friendCell.followButton setSelected:NO];
        }else{
            friendCell.followButton.userInteractionEnabled = NO;
//            [friendCell.followButton setTitle:@"FOLLOWING" forState:UIControlStateNormal];
            [friendCell.followButton setSelected:YES];
        }
        [friendCell.profilePic setImageWithURL:[NSURL URLWithString:friend[@"profilePicUrl"]]];
        friendCell.profilePic.tag = indexPath.row;
        friendCell.tag = indexPath.row;
        
        return friendCell;
    }
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

- (void)activityCell:(TTActivityNotificationViewCell *)cellView didPressUsernameForUser:(PFUser *)user{
    
}

#pragma mark - UIButtons
- (IBAction)backButtonWasPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)longPressGestureToPreviewProfile:(UILongPressGestureRecognizer *)sender {
    if(sender.state == UIGestureRecognizerStateBegan){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
        self.popoverProfileViewController = (TTPopoverProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ProfilePopoverView"];
        CGPoint touchPoint = [sender locationInView:self.view];
        UIView* touchedView = [self.view hitTest:touchPoint withEvent:nil];
        if([touchedView isKindOfClass:[TTUserProfileImage class]]){
            NSDictionary *activity = [[NSDictionary alloc] init];
            if (self.filter.tag == 0)
                activity = self.activities[touchedView.tag];
            else activity = self.followingActivities[touchedView.tag];
            
            self.popoverProfileViewController.user = activity[@"fromUser"];
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

- (IBAction)longPressGesturetoPreviewFriendsProfile:(UILongPressGestureRecognizer *)sender {
    if(sender.state == UIGestureRecognizerStateBegan){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
        self.popoverProfileViewController = (TTPopoverProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ProfilePopoverView"];
        CGPoint touchPoint = [sender locationInView:self.view];
        UIView* touchedView = [self.view hitTest:touchPoint withEvent:nil];
        if([touchedView isKindOfClass:[TTUserProfileImage class]]){
            
            self.popoverProfileViewController.user = self.facebookFriends[touchedView.tag];
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

- (IBAction)connectToFacebookWasTapped:(TTOnboardingButton *)sender {
//    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
//    [login
//     logInWithReadPermissions: @[@"public_profile",@"email",@"user_friends",@"read_custom_friendlists"]
//     fromViewController:self
//     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
//         if (error) {
//             NSLog(@"Process error");
//         } else if (result.isCancelled) {
//             NSLog(@"Cancelled");
//         } else {
//             NSLog(@"Logged in");
//         }
//     }];
    
    
    //List of permissions we want from the user's facebook to link tp the parse user. We don't need the email since we won't be changing their current email to their facebook email.
    NSArray *permissionsArray = @[ @"email", @"public_profile", @"user_friends"];
    
    //Make sure the user isnt already linked with facebook
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
        [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withReadPermissions:permissionsArray block:^(BOOL succeeded, NSError * _Nullable error){
            if (error){
                //ERROR HANDLE: User Was Unable to link with facebook please try again or contact austin
                UIAlertView *alertView = [[UIAlertView alloc] init];
                alertView.delegate = self;
                alertView.title = NSLocalizedString(@"Something went wrong",@"Something went wrong");
                alertView.message = NSLocalizedString(@"Please try again or contact austinbarnard@triptrunkapp.com.",@"Please try again or contact austinbarnard@triptrunkapp.com.");
                alertView.backgroundColor = [TTColor tripTrunkLightBlue];
                [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                [alertView show];
                
            }else{ //succesfully connected the parse user to their facebook account
                
                //we need to logout the user and log them back in for the fbid in parse to update. Its annoying and we should see if we can fix it.
                [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error){
                    if (error){
                        //ERROR HANDLE: tell the user we linked the acccount succefully but you need to log back in with the login with facebook option for the link to go into effect
                        [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                            UIAlertView *alertView = [[UIAlertView alloc] init];
                            alertView.delegate = self;
                            alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                            alertView.backgroundColor = [TTColor tripTrunkLightBlue];
                            [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                            [alertView show];
                        }];
                        
                    } else {
                        [self loginWithFacebook];
                    }
                    
                }];
            }
        }];
    }
}

-(void)loginWithFacebook{
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"email", @"public_profile", @"user_friends"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error){
        if (error){
            //ERROR HANDLE: tell the user we linked the acccount but we need them to relogin, then take them to the login screen
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"%@",errorString);
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loginWithFacebook:"];
            
            [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                UIAlertView *alertView = [[UIAlertView alloc] init];
                alertView.delegate = self;
                alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                alertView.backgroundColor = [TTColor tripTrunkLightBlue];
                [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                [alertView show];
                
                [self.tabBarController setSelectedIndex:0];
            }];
            return;
        }
        
        if (!user){
            [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                UIAlertView *alertView = [[UIAlertView alloc] init];
                alertView.delegate = self;
                alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                alertView.backgroundColor = [TTColor tripTrunkLightBlue];
                [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                [alertView show];
                
                [self.tabBarController setSelectedIndex:0];
            }];
            
        } else{
            
            if ([user objectForKey:@"fbid"] == nil){
                FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/v2.12/me/" parameters:@{@"fields": @"id"}];
                [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                    if (!error){
                        // result is a dictionary with the user's Facebook data
                        NSDictionary *userData = (NSDictionary *)result;
                        PFUser *user = [PFUser currentUser];
                        NSString *fbid = [userData objectForKey:@"id"];
                        if (fbid){
                            [user setObject:fbid forKey:@"fbid"];
                            [user saveInBackground];
                        }
                    }else{
                        //ERROR HANDLE: tell the user we linked the acccount but we need them to relogin, then take them to the login screen
                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loginWithFacebook:"];
                        
                        [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                            UIAlertView *alertView = [[UIAlertView alloc] init];
                            alertView.delegate = self;
                            alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                            alertView.backgroundColor = [TTColor tripTrunkLightBlue];
                            [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                            [alertView show];
                        }];
                    }
                }];
                
            }
        }
    }];
    
}

#pragma mark - UIModalPopoverDelegate
- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController: (UIPresentationController * ) controller {
    return UIModalPresentationNone;
}

#pragma mark - ActivityTableViewCellDelegate
-(void)trunkWasDeleted:(Trip*)trip{
    NSMutableArray *objs = [[NSMutableArray alloc]init];
    for (PFObject *obj in self.activities){
        Trip *tripObj = obj[@"trip"];
        if ([tripObj.objectId isEqualToString:trip.objectId])
        {
            [objs addObject:obj];
        }
    }
    
    for (PFObject *obj in objs){
        [self.activities removeObject:obj];
    }
    
    [self.tableView reloadData];
}

-(void)photoWasDeleted:(Photo*)photo{
    NSMutableArray *objs = [[NSMutableArray alloc]init];
    for (PFObject *obj in self.activities){
        Photo *tripObj = obj[@"photo"];
        if ([tripObj.objectId isEqualToString:photo.objectId])
        {
            [objs addObject:obj];
        }
    }
    
    for (PFObject *obj in objs){
        [self.activities removeObject:obj];
    }
    
    [self.tableView reloadData];
}


-(void)toggleWasTapped{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.filter.tag == 0) {
        self.filter = nil;
        UIImage *image = [UIImage imageNamed:@"all_mine_1"];
        CGRect buttonFrame = CGRectMake(0, 0, 80, 20);
        UIButton *bttn = [[UIButton alloc] initWithFrame:buttonFrame];
        [bttn setImage:image forState:UIControlStateNormal];
        [bttn setImage:image forState:UIControlStateHighlighted];
        [bttn setImage:image forState:UIControlStateSelected];
        [bttn addTarget:self action:@selector(toggleWasTapped) forControlEvents:UIControlEventTouchUpInside];
        self.filter= [[UIBarButtonItem alloc] initWithCustomView:bttn];
        [[self navigationItem] setRightBarButtonItem:self.filter animated:NO];
        self.filter.tag = 1;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        if (self.friends.count > 0){
            self.navigationItem.rightBarButtonItem.enabled = YES;
            [self.tableView reloadData];
        } else {
            [self loadFriends];
        }
    } else  {
        self.filter = nil;
        UIImage *image = [UIImage imageNamed:@"all_mine_2"];
        CGRect buttonFrame = CGRectMake(0, 0, 80, 20);
        UIButton *bttn = [[UIButton alloc] initWithFrame:buttonFrame];
        [bttn setImage:image forState:UIControlStateNormal];
        [bttn setImage:image forState:UIControlStateHighlighted];
        [bttn setImage:image forState:UIControlStateSelected];
        [bttn addTarget:self action:@selector(toggleWasTapped) forControlEvents:UIControlEventTouchUpInside];
        self.filter= [[UIBarButtonItem alloc] initWithCustomView:bttn];
        [[self navigationItem] setRightBarButtonItem:self.filter animated:NO];
        [self.tableView reloadData];
    }
    
}

#pragma mark - load activity data
-(void)loadFriends{
    // TODO: Make this work for > 100 users since parse default limits 100.
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if (!error) {
            for (PFUser *user in users) {
                [self.friends addObject:user];
            }
            
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadUserActivities];
            });
            
        }else {
//            self.navigationItem.rightBarButtonItem.enabled = YES;
            self.isLoading = NO;
            [ParseErrorHandlingController handleError:error];
            self.activitySearchComplete = YES;
            NSLog(@"error %@", error);
//            [self.tableView reloadData];
        }
        
        if ([FBSDKAccessToken currentAccessToken])
            [self setupViewForFriendsList];
        else [self setupViewForFacebookLogin];
    }];
}

-(void)loadUserActivities{
    
    if (self.followingActivities.count == 0 && _viewType == TTActivityViewAllActivities) {
        // Query for activities for user
        if (self.isLoading == NO){
            self.isLoading = YES;
            [SocialUtility queryForFollowingActivities:0 friends:self.friends activities:nil isRefresh:NO query:^(NSArray *activities, NSError *error) {
                
                for (PFObject *obj in activities){
                    PFUser *toUser = obj[@"toUser"];
                    PFUser *fromUser = obj[@"fromUser"];
                    if (obj[@"trip"]){
                        Trip *trip = obj[@"trip"];//FIXME Should be cloud code && ![toUser.objectId isEqualToString:fromUser.objectId]
                        if (trip.name != nil  && toUser != nil && fromUser != nil){
                            [self.followingActivities addObject:obj];
                        }
                    }
                    else if ([obj[@"type"] isEqualToString:@"follow"]){
                        if (toUser != nil && fromUser != nil){
                            [self.followingActivities addObject:obj];
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.activitySearchComplete = YES;
                    self.isLoading = NO;
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                    [self.tableView reloadData];
                });
            }];
        }
    }
}

-(void)loadTrips{
    
    self.trips = [[NSMutableArray alloc]init];
    PFQuery *trips = [PFQuery queryWithClassName:@"Activity"];
    [trips whereKeyExists:@"trip"];
    [trips whereKeyExists:@"fromUser"];
    [trips whereKeyExists:@"toUser"];
    [trips whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [trips whereKey:@"type" equalTo:@"addToTrip"];
    [trips setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [trips includeKey:@"trip"];
    [trips setLimit:1000];
    [trips findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error)
     {
         if (!error)
         {
             [[TTUtility sharedInstance] internetConnectionFound];
             for (PFObject *activity in objects)
             {
                 Trip *trip = activity[@"trip"];
                 if (trip.name != nil && trip.publicTripDetail != nil)
                 {
                     [self.trips addObject:trip];
                 }
             }
             if ((!self.activities || self.activities.count == 0) && self.viewType == TTActivityViewAllActivities) {
                 // Query for activities for user
                 if (self.isLoading == NO){
                     self.isLoading = YES;
                     [SocialUtility queryForAllActivities:0 trips:self.trips activities:nil isRefresh:NO query:^(NSArray *activities, NSError *error) {
                         
                         if (error){
                             self.navigationItem.rightBarButtonItem.enabled = YES;
                             self.isLoading = NO;
                             [ParseErrorHandlingController handleError:error];
                             self.activitySearchComplete = YES;
                             [self.tableView reloadData];
                             NSLog(@"error %@", error);
                         } else {
                             for (PFObject *obj in activities){
                                 PFUser *toUser = obj[@"toUser"];
                                 PFUser *fromUser = obj[@"fromUser"];//FIXME Should be cloud code && ![toUser.objectId isEqualToString:fromUser.objectId]
                                 if (obj[@"trip"] && toUser != nil && fromUser != nil){
                                     [self.activities addObject:obj];
                                 } else if ([obj[@"type"] isEqualToString:@"follow"] || [obj[@"type"] isEqualToString:@"pending_follow"]){
                                     
                                     if (toUser != nil && fromUser != nil){
                                         [self.activities addObject:obj];
                                     }
                                     
                                 }
                             }
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 self.activitySearchComplete = YES;
                                 self.isLoading = NO;
                                 self.navigationItem.rightBarButtonItem.enabled = YES;
                                 [self.tableView reloadData];
                             });
                         }
                     }];
                 }
                 
             }
             
         } else {
             if (error.code != 120){
                 self.navigationItem.rightBarButtonItem.enabled = YES;
                 self.isLoading = NO;
                 [ParseErrorHandlingController handleError:error];
                 self.activitySearchComplete = YES;
                 NSLog(@"error %@", error);
                 [self.tableView reloadData];
             }
         }
     }];
}

#pragma mark - UICollectionViewDelegate
- (TTActivitySectionsViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    TTActivitySectionsViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.sectionLabel.text = @"";
    if(indexPath.row == 0){
        cell.sectionLabel.text = @"Notifications";
        cell.tag = 1;
    }else{
        cell.sectionLabel.text = @"Find Friends";
        cell.tag = 2;
    }
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

#pragma mark - scrollViewDelegate
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGFloat cellWidth = 125;
    CGFloat cellPadding = 50;
    
    NSInteger page = (scrollView.contentOffset.x - cellWidth / 2) / (cellWidth + cellPadding) + 1;
    
    if (velocity.x > 0) page++;
    if (velocity.x < 0) page--;
    page = MAX(page,0);
    
    CGFloat newOffset = page * (cellWidth + cellPadding);
    targetContentOffset->x = newOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    for (TTActivitySectionsViewCell *cell in [self.collectionView visibleCells]) {
        
//        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        CGPoint convertedPoint=[self.collectionView convertPoint:cell.frame.origin toView:self.collectionView.superview];
        int amountVisible = convertedPoint.x + cell.frame.size.height < cell.frame.size.width ? convertedPoint.x + cell.frame.size.width : cell.frame.size.width;
        amountVisible = kScreenWidth-convertedPoint.y < amountVisible ? kScreenWidth-convertedPoint.x : amountVisible;
        
        if(convertedPoint.x > 0 && convertedPoint.x < kScreenWidth/2 ){
            if(cell.tag == 1){
                self.headline.text = @"Activity";
                [self animateFindFriendsView:NO];
            }else{
                self.headline.text = @"People";
                [self animateFindFriendsView:YES];
            }
            break;
        }
    }
}

#pragma mark - FindFriendsViewAnimation
-(void)animateFindFriendsView:(BOOL)enter{
    if(enter){
        //show view
        self.leadingConstraintForFacebookConnect.constant = 0;
        self.tableView.userInteractionEnabled = NO;
        self.findFriendsView.userInteractionEnabled = YES;
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.searchTextField.hidden = NO;
        }];
        
    }else{
        //hide view
        self.leadingConstraintForFacebookConnect.constant = kScreenWidth;
        self.tableView.userInteractionEnabled = YES;
        self.findFriendsView.userInteractionEnabled = NO;
        self.searchTextField.hidden = YES;

        [UIView animateWithDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            //nada
        }];
    }
}


#pragma mark - Facebook View setup
-(void)setupViewForFriendsList{
    self.friendsTableView.hidden = NO;
    self.connectToFacebookLabel.hidden = YES;
    self.infoLabel.hidden = YES;
    self.facebookButton.hidden = YES;
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"/v2.12/me/friends"
                                  parameters:@{@"fields": @"id, name, photo"}
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        
        __block int i=0;
        NSMutableArray* data = result[@"data"];
        for(id res in data){
//            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//            [dict setObject:res[@"id"] forKey:@"fbid"];
//            [dict setObject:res[@"name"] forKey:@"name"];
//
//            if([self amIAlreadyFollowingThisUser:res[@"id"]])
//                [dict setObject:@"1" forKey:@"friend"];
//            else [dict setObject:@"0" forKey:@"friend"];
//
//            [self.facebookFriends addObject:dict];
            
            [SocialUtility queryForUserFromFBID:res[@"id"] block:^(PFUser *user, NSError *error) {
                if(!error && user!=nil){
                    if([self.friends containsObject:user])
                        [user setObject:@"1" forKey:@"friend"];
                    else [user setObject:@"0" forKey:@"friend"];
                
                    [self.facebookFriends addObject:user];
                }
                i++;
                
                self.facebookFriendsOriginalArray = self.facebookFriends;
                
                if(i == data.count)
                    [self.friendsTableView reloadData];
            }];
        }
        
    }];
}

-(void)setupViewForFacebookLogin{
    self.friendsTableView.hidden = YES;
    self.connectToFacebookLabel.hidden = NO;
    self.infoLabel.hidden = NO;
    self.facebookButton.hidden = NO;
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

-(void)setFollowStatus:(UIButton *)sender {
    if ([sender isSelected] == YES) {
        // Unfollow
        [sender setSelected:NO]; // change the button for immediate user feedback
        //        [sender setTitle:@"Follow" forState:UIControlStateNormal];
        //        sender.backgroundColor = [UIColor whiteColor];
        //        sender.titleLabel.textColor = [TTColor tripTrunkRed];
        //        [sender setTitleColor:[TTColor tripTrunkRed] forState:UIControlStateNormal];
        //        [self.currentUserFriends removeObject:user.objectId];
        [SocialUtility unfollowUser:self.facebookFriends[sender.tag] block:^(BOOL succeeded, NSError *error) {
            if(error){
                NSLog(@"Error: %@", error);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unfollow Failed"
                                                                message:@"Please try again"
                                                               delegate:self
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil, nil];
                [sender setSelected:YES];
                [alert show];
            }else{
                NSLog(@"User unfollowed");
            }
        }];
    }
    else {
        // Follow
        [sender setSelected:YES];
        sender.titleLabel.textColor = [UIColor whiteColor];
        [sender setTitleColor:[TTColor tripTrunkWhite] forState:UIControlStateNormal];
        //        [self.currentUserFriends addObject:user.objectId];
        [SocialUtility followUserInBackground:self.facebookFriends[sender.tag] block:^(BOOL succeeded, NSError *error) {
            if (error) {
                //                sender.titleLabel.textColor = [TTColor tripTrunkRed];
                //                [sender setTitleColor:[TTColor tripTrunkRed] forState:UIControlStateNormal];
                NSLog(@"Error: %@", error);
                //                [self.currentUserFriends removeObject:user.objectId];
                NSLog(@"Follow failed");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Follow Failed"
                                                                message:@"Please try again"
                                                               delegate:self
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil, nil];
                [sender setSelected:NO];
                [alert show];
            }else{
                NSLog(@"User followed");
            }
        }];
    }
}

- (IBAction)tapGestureRecognizerForFollowButton:(UITapGestureRecognizer *)sender {
    CGPoint touchPoint = [sender locationInView:self.view];
    UIView* touchedView = [self.view hitTest:touchPoint withEvent:nil];
    CGPoint touchPointInCell = [sender locationInView:touchedView];
    NSArray *views = [touchedView subviews];
    for(id view in views){
        if([view isKindOfClass:[UIButton class]]){
            UIButton *buttonView = (UIButton*)view;
            if(CGRectContainsPoint(buttonView.frame, touchPointInCell))
                [self setFollowStatus:(UIButton*)view];
            break;
        }
    }
}

-(NSString*)getInitialsForMissingProfilePictureFromUser:(PFUser*)user{
    return [NSString stringWithFormat:@"%@%@",[user[@"firstName"] substringToIndex:1],[user[@"lastName"] substringToIndex:1]];;
}

#pragma mark - Friend Search
- (void)filterResults:(NSString *)searchTerm {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissKeyboard) object:nil];
    self.facebookFriends = self.facebookFriendsOriginalArray;
    
    if (![searchTerm isEqualToString:@""]){
        TTUsernameSort *us = [[TTUsernameSort alloc] init];
        NSArray *sortedArray = [us sortResultsByUsername:self.facebookFriends searchTerm:searchTerm];
        self.searchResults = [NSMutableArray arrayWithArray:sortedArray];
        self.isSearching = YES;
        self.facebookFriends = [NSMutableArray arrayWithArray:sortedArray];
        [self.friendsTableView reloadData];
        [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:4.0];
        [[TTUtility sharedInstance] internetConnectionFound];
    }else{
        [self.friendsTableView reloadData];
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

-(void)dismissKeyboard{
    [self.searchTextField resignFirstResponder];
    if([self.searchTextField.text isEqualToString:@""]){
        [self.view layoutIfNeeded];
    }
}



//-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    if(![event touchesForView:self.searchTextField]){
//        [self dismissKeyboard];
//    }
//}
//
//-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    NSLog(@"touch ended");
//}

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
