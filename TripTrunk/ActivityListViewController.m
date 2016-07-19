//
//  ActivityListViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 7/27/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "ActivityListViewController.h"
#import "UIImageView+AFNetworking.h"
#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "UserProfileViewController.h"
#import "ActivityTableViewCell.h"
#import "PhotoViewController.h"
#import "TTUtility.h"
#import "UIScrollView+EmptyDataSet.h"
#import "TrunkViewController.h"
#import "MBProgressHUD.h"
#import "TTColor.h"

#define USER_CELL @"user_table_view_cell"
#define ACTIVITY_CELL @"activity_table_view_cell"

enum TTActivityViewType : NSUInteger {
    TTActivityViewAllActivities = 1,
    TTActivityViewLikes = 2
};

@interface ActivityListViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, ActivityTableViewCellDelegate>

@property (strong, nonatomic) NSMutableArray *activities;
@property (strong, nonatomic) NSMutableArray *followingActivities;
@property NSUInteger viewType;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) Photo *photo;
@property BOOL activitySearchComplete;
@property BOOL isLikes;
@property NSMutableArray *trips;
@property BOOL needToRefresh;
@property BOOL isLoading;
@property UIBarButtonItem *filter;
@property NSMutableArray *friends;
@property UIRefreshControl *refreshController;
@property int color;
@property NSTimer *colorTimer;
@end

@implementation ActivityListViewController

#pragma mark - Setup

- (id)initWithLikes:(NSArray *)likes;
{
    self = [super init];
    if (self) {
        _activities = [[NSMutableArray alloc] initWithArray:likes];
        self.isLikes = YES;
        _activitySearchComplete = NO;
        self.title = NSLocalizedString(@"Likers",@"Likers");
        _viewType = TTActivityViewLikes;
    }
    return self;
}

- (id)initWithActivities:(NSArray *)activities;
{
    self = [super init];
    if (self) {
        _activities = [[NSMutableArray alloc] initWithArray:activities];
        _activitySearchComplete = NO;
        self.title = self.title = NSLocalizedString(@"Activity",@"Activity");
        _viewType = TTActivityViewAllActivities;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.trips = [[NSMutableArray alloc]init];
    [self loadTrips];
}

- (void)loadView {
    // Initialize the view, tableview, and refresh controller
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [self.view setBackgroundColor:[TTColor tripTrunkWhite]];
    [self setUpTableView];
    if (_viewType == TTActivityViewAllActivities) {
        self.friends= [[NSMutableArray alloc]init];
        self.followingActivities = [[NSMutableArray alloc]init];
        [self setUpFilter];
        [self setUpRefreshController];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // reload the table every time it appears or we get weird results
    self.tabBarController.tabBar.hidden = NO;
    self.colorTimer = [NSTimer scheduledTimerWithTimeInterval:.3 target:self
                                                     selector:@selector(rotateColors) userInfo:nil repeats:YES];
    NSUInteger internalBadge = [[[NSUserDefaults standardUserDefaults] valueForKey:@"internalBadge"] integerValue];
    
    if (internalBadge > 0 && self.filter.tag == 0){
        [self refresh: self.refreshController];
    }
    [self.tableView reloadData];
}

-(void)viewDidDisappear:(BOOL)animated{
    [self.colorTimer invalidate];
    self.colorTimer = nil;
    if (_viewType == TTActivityViewAllActivities){
        
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"internalBadge"];
        
        UIImage *image = [UIImage imageNamed:@"comment_tabIcon"];
        UITabBarItem *searchItem = [[UITabBarItem alloc] initWithTitle:nil image:image tag:3];
        [searchItem setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
        [self.navigationController setTabBarItem:searchItem];
        
    }
}

-(void)setUpTableView{
    self.tableView = [[UITableView alloc] init];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.tableView.tableFooterView = [UIView new]; // to hide the cell seperators for empty cells
    [self.view addSubview:self.tableView];
    [self setupTableViewConstraints];
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    [self.tableView registerNib:[UINib nibWithNibName:@"ActivityTableViewCell" bundle:nil] forCellReuseIdentifier:ACTIVITY_CELL];
    // Setup tableview delegate/datasource
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
}

-(void)setUpRefreshController{
    self.refreshController = [[UIRefreshControl alloc] init];
    [self.refreshController addTarget:self
                               action:@selector(refresh:)
                     forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview: self.refreshController];
    self.refreshController.tintColor = [UIColor whiteColor];
    
    [ self.refreshController endRefreshing];
}



-(void)setUpFilter{
    self.filter.tag = 0;
    UIImage *image = [UIImage imageNamed:@"all_mine_2"];
    CGRect buttonFrame = CGRectMake(0, 0, 80, 20);
    UIButton *bttn = [[UIButton alloc] initWithFrame:buttonFrame];
    [bttn setImage:image forState:UIControlStateNormal];
    [bttn setImage:image forState:UIControlStateHighlighted];
    [bttn setImage:image forState:UIControlStateSelected];
    [bttn addTarget:self action:@selector(toggleWasTapped) forControlEvents:UIControlEventTouchUpInside];
    self.filter= [[UIBarButtonItem alloc] initWithCustomView:bttn];
    [[self navigationItem] setRightBarButtonItem:self.filter animated:NO];
    self.navigationItem.rightBarButtonItem.enabled = NO;

}

/**
 *  Adds AutoLayout constraints on the tableview
 */
- (void)setupTableViewConstraints {
    
    // Width constraint, full width of view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.view
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:1
                                                      constant:0]];

    
    // Center horizontally
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.view
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    
    // vertical algin top of tableview to view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0
                                                                constant:0.0]];

    // vertical algin bottom to view
    
    if (self.isLikes == YES) {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:-(self.tabBarController.tabBar.frame.size.height)]];
    } else {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0.0]];
    }
    
}

-(void)clearTabbarIconBadge{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"internalBadge"];
    
    UIImage *image = [UIImage imageNamed:@"comment_tabIcon"];
    UITabBarItem *searchItem = [[UITabBarItem alloc] initWithTitle:nil image:image tag:3];
    [searchItem setImageInsets:UIEdgeInsetsMake(5, 0, -5, 0)];
    [self.navigationController setTabBarItem:searchItem];
}

#pragma mark - Load Trips

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
             if (_activities.count == 0 && _viewType == TTActivityViewAllActivities) {
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
             self.navigationItem.rightBarButtonItem.enabled = YES;
             self.isLoading = NO;
             [ParseErrorHandlingController handleError:error];
             self.activitySearchComplete = YES;
             NSLog(@"error %@", error);
             [self.tableView reloadData];
         }
     }];
}

-(void)rotateColors{

    if (self.color == 0){
        self.refreshController.backgroundColor = [TTColor tripTrunkGray];
    } else if (self.color == 1){
        self.refreshController.backgroundColor = [TTColor tripTrunkBlue];
    } else if (self.color == 2){
        self.refreshController.backgroundColor = [TTColor tripTrunkRed];
    } else if (self.color == 3){
        self.refreshController.backgroundColor = [TTColor tripTrunkYellow];
    }
    
    self.color += 1;
    
    if (self.color == 4){
        self.color = 0;
    }
}

#pragma mark - Refresh


- (void)refresh:(UIRefreshControl *)refreshControl
{
    if(refreshControl){
        [self clearTabbarIconBadge];
    }
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

#pragma mark - Scrolling

- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView
                  willDecelerate:(BOOL)decelerate
{
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    
    float reload_distance = -250;
    if(y > h + reload_distance && self.isLikes == NO) {
        
        if (self.isLoading == NO){
            self.navigationItem.rightBarButtonItem.enabled = NO;
            self.isLoading = YES;
            
            if (self.filter.tag == 0){
                
                [SocialUtility queryForAllActivities:self.activities.count trips:self.trips activities:self.activities isRefresh:NO query:^(NSArray *activities, NSError *error) {
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
                        self.isLoading = NO;
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                        [self.tableView reloadData];
                        
                    });
                    
                    if (error){
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                        self.isLoading = NO;
                    }
                }];
            } else if (self.filter.tag == 1){
                [SocialUtility queryForFollowingActivities:self.followingActivities.count friends:self.friends activities:self.followingActivities isRefresh:NO query:^(NSArray *activities, NSError *error) {
                    for (PFObject *obj in activities){
                        PFUser *toUser = obj[@"toUser"];
                        PFUser *fromUser = obj[@"fromUser"];
                        if (obj[@"trip"]){
                            Trip *trip = obj[@"trip"]; //FIXME Should be cloud code && ![toUser.objectId isEqualToString:fromUser.objectId]
                            if (trip.name != nil  && toUser != nil && fromUser != nil){
                                [self.followingActivities addObject:obj];
                                
                            }
                        }
                        else if ([obj[@"type"] isEqualToString:@"follow"] && toUser != nil && fromUser != nil){
                            [self.followingActivities addObject:obj];
                            
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.isLoading = NO;
                        self.navigationItem.rightBarButtonItem.enabled = YES;
                        [self.tableView reloadData];
                        
                    });
                    
                    if (error){
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.filter.tag == 0){
        return _activities.count;
    } else {
        return self.followingActivities.count;
    }
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_viewType == TTActivityViewAllActivities) {
        NSAttributedString *cellText = [[NSAttributedString alloc]init];
        if (self.filter.tag == 0){
            // Get a variable cell height to make sure we can fit long comments
            cellText= [[TTUtility sharedInstance] attributedStringForActivity:[_activities objectAtIndex:indexPath.row]];
        } else {
            // Get a variable cell height to make sure we can fit long comments
            cellText = [[TTUtility sharedInstance] attributedStringForActivity:[self.followingActivities objectAtIndex:indexPath.row]];
        }
        
        CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
        
        CGSize labelSize = [cellText boundingRectWithSize:constraintSize
                                                  options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                  context:nil].size;
        return labelSize.height + 40;
    }
    
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_viewType == TTActivityViewLikes) {
        UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
        cell.profilePicImageView.image = nil;
        
        // We assume fromUser contains the full PFUser object
        PFUser *user;
        if (self.filter.tag == 0){
            user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        } else {
            user = [[self.followingActivities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        }
        NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
        [cell setUser:user];
        [cell.followButton setHidden:YES];
        
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
        __weak UserTableViewCell *weakCell = cell;
        weakCell.profilePicImageView.image = nil;
        
        [cell.profilePicImageView setImageWithURLRequest:request
                                        placeholderImage:nil
                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                     
                                                     [weakCell.profilePicImageView setImage:image];
                                                     [weakCell setNeedsLayout];
                                                     
                                                 } failure:nil];
               return weakCell;
        
    }
    else if (_viewType == TTActivityViewAllActivities) {
        ActivityTableViewCell *activityCell = [self.tableView dequeueReusableCellWithIdentifier:ACTIVITY_CELL forIndexPath:indexPath];
        activityCell.profilePicImageView.image = nil;
        activityCell.photoImageView.image = nil;
        [activityCell setDelegate:self];
        NSDictionary *activity;
        
        if (self.filter.tag == 0) {
           activity = [_activities objectAtIndex:indexPath.row];
        } else {
            activity = [self.followingActivities objectAtIndex:indexPath.row];
        }
        
        [activityCell setActivity:activity];
        
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
        
        if (self.filter.tag == 0) {
            user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        } else {
            user = [[self.followingActivities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        }
        
        NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
        __weak ActivityTableViewCell *weakCell = activityCell;
        weakCell.profilePicImageView.image = nil;
        weakCell.photoImageView.image = nil;
        
        [activityCell.profilePicImageView setImageWithURLRequest:request
                                        placeholderImage:nil
                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                     
                                                     [weakCell.profilePicImageView setImage:image];
                                                     [weakCell setNeedsLayout];
                                                     
                                                 } failure:nil];
        if ([activity valueForKey:@"photo"]) {
            
            NSURL *photoUrl = [NSURL URLWithString:[[TTUtility sharedInstance] thumbnailImageUrl:[[activity valueForKey:@"photo"] valueForKey:@"imageUrl"]]];
            NSURLRequest *photoRequest = [NSURLRequest requestWithURL:photoUrl];
            
            [activityCell.photoImageView setImageWithURLRequest:photoRequest
                                                    placeholderImage:nil
                                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                 
                                                                 [weakCell.photoImageView setImage:image];
                                                                 [weakCell setNeedsLayout];
                                                             } failure:nil];
        }
        return weakCell;
    }
    return [UITableViewCell new];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return NO;
}

#pragma mark - Table view delegate

// On Row Selection, push to the user's profile
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_viewType == TTActivityViewAllActivities) {
        // Don't allow row selection for All Activities--usernames and photos have different links.
        return;
    }
    
    UserProfileViewController *vc;
    
    if (self.filter.tag == 0) {
        
        vc = [[UserProfileViewController alloc] initWithUser:[[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"]];
        
    } else {
        vc = [[UserProfileViewController alloc] initWithUser:[[self.followingActivities objectAtIndex:indexPath.row] valueForKey:@"fromUser"]];
    }
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Dismiss the keyboard when scrolling starts
    [self.view endEditing:YES];
}

#pragma mark - ActivityTableViewCell delegate

-(void)activityCell:(ActivityTableViewCell *)cellView didPressPhoto:(Photo *)photo {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PhotoViewController *photoViewController = (PhotoViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoView"];
    photoViewController.photo = (Photo *)photo;
    photoViewController.trip = (Trip*)photo.trip;
    
    [self.navigationController showViewController:photoViewController sender:self];
        
//    [self.navigationController presentViewController:photoViewController animated:YES completion:nil];
}

- (void)activityCell:(ActivityTableViewCell *)cellView didPressUsernameForUser:(PFUser *)user {
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc && user) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)activityCell:(ActivityTableViewCell *)cellView didPressTrip:(Trip *)trip {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TrunkViewController *trunkViewController = (TrunkViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TrunkView"];
    trunkViewController.trip = (Trip *)trip;
    [self.navigationController pushViewController:trunkViewController animated:YES];
}

- (void)activityCell:(ActivityTableViewCell *)cellView didAcceptFollowRequest:(BOOL)didAccept fromUser:(PFUser *)user {
    __block MBProgressHUD *HUD;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress
    });

    [SocialUtility acceptFollowRequest:didAccept fromUser:user block:^(BOOL succeeded, NSError *error) {
        if (succeeded && !error) {
            // Successfully accepted/rejected, so let's reload the data
            [self refresh:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                // Hide HUD spinner
                [self.activities removeObject:cellView.activity];
                [self.tableView reloadData];
                HUD.labelText = NSLocalizedString(@"Done!",@"Done!");
                [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Hide HUD spinner
                HUD.labelText = NSLocalizedString(@"Error",@"Error!");
                [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
            });
        }
    }];
}
#pragma mark - Dismiss View

- (void)closeView
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"No Activity",@"No Activity");
    if (_viewType == TTActivityViewLikes) {
        text = NSLocalizedString(@"No Likers",@"No Likers");
    }
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFontBold18],
                                 NSForegroundColorAttributeName: [TTColor tripTrunkBlack]};
    if (self.activitySearchComplete == YES){
        return [[NSAttributedString alloc] initWithString:text attributes:attributes];
    } else {
        return [[NSAttributedString alloc] initWithString:@"Looking For Some Action" attributes:attributes];
    }
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"Keep using TripTrunk!", @"Keep using TripTrunk!");
    if (_viewType == TTActivityViewLikes) {
        text = NSLocalizedString(@"You could be the first to like this photo",@"You could be the first to like this photo");
    }
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFont14],
                                 NSForegroundColorAttributeName: [TTColor tripTrunkLightGray],
                                 NSParagraphStyleAttributeName: paragraph};
    if (self.activitySearchComplete == YES){
        return [[NSAttributedString alloc] initWithString:text attributes:attributes];
    } else {
        return [[NSAttributedString alloc] initWithString:@"" attributes:attributes];
    }
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFontBold18],
                                    NSForegroundColorAttributeName: [TTColor tripTrunkBlack]};
    
    if (self.activitySearchComplete == YES){
        return [[NSAttributedString alloc] initWithString:@"Reload" attributes:attributes];
    } else {
        return [[NSAttributedString alloc] initWithString:@"" attributes:attributes];
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [TTColor tripTrunkWhite];
}

- (CGPoint)offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return CGPointMake(0, 20);
}

#pragma mark - DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    return YES;
}

- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView
{
    return YES;
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    if (self.activitySearchComplete == YES){
        if (self.filter.tag == 0){
            [self loadTrips];
        }else {
            [self loadFriends];
        }
    }
}

- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}

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
            self.navigationItem.rightBarButtonItem.enabled = YES;
            self.isLoading = NO;
            [ParseErrorHandlingController handleError:error];
            self.activitySearchComplete = YES;
            NSLog(@"error %@", error);
            [self.tableView reloadData];
        }
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


@end
