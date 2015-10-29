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
#import "UIColor+HexColors.h"
#import "MBProgressHUD.h"

#define USER_CELL @"user_table_view_cell"
#define ACTIVITY_CELL @"activity_table_view_cell"

enum TTActivityViewType : NSUInteger {
    TTActivityViewAllActivities = 1,
    TTActivityViewLikes = 2
};

@interface ActivityListViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, ActivityTableViewCellDelegate>

@property (strong, nonatomic) NSMutableArray *activities;
@property NSUInteger viewType;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) Photo *photo;
@property BOOL activitySearchComplete;

@end

@implementation ActivityListViewController

- (id)initWithLikes:(NSArray *)likes;
{
    self = [super init];
    if (self) {
        _activities = [[NSMutableArray alloc] initWithArray:likes];
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

- (void)loadView {
    
    // Initialize the view & tableview
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.tableView = [[UITableView alloc] init];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.tableView.tableFooterView = [UIView new]; // to hide the cell seperators for empty cells
    [self.view addSubview:self.tableView];

    [self setupTableViewConstraints];
    

    if (_viewType != TTActivityViewAllActivities) {
        // Set Done button for all but the All Activity view
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
//                                                                                               target:self
//                                                                                               action:@selector(closeView)];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    }
    // Else, it's the All Activities list
    else {
        // Initialize the refresh control.
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self
                           action:@selector(refresh:)
                 forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:refreshControl];
        UIColor *ttBlueColor = [UIColor colorWithHexString:@"76A4B8"];

        refreshControl.tintColor = ttBlueColor;
        [refreshControl endRefreshing];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    

    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    [self.tableView registerNib:[UINib nibWithNibName:@"ActivityTableViewCell" bundle:nil] forCellReuseIdentifier:ACTIVITY_CELL];
    
    
    // Setup tableview delegate/datasource
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    if (_activities.count == 0 && _viewType == TTActivityViewAllActivities) {
        // Query for activities for user
        [SocialUtility queryForAllActivities:0 query:^(NSArray *activities, NSError *error) {
            _activities = [NSMutableArray arrayWithArray:activities];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.activitySearchComplete = YES;
                [self.tableView reloadData];
            });
        }];
    }
    
}


- (void)viewDidAppear:(BOOL)animated {
    // reload the table every time it appears or we get weird results
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    
    // Query for activities for user
    [SocialUtility queryForAllActivities:0 query:^(NSArray *activities, NSError *error) {
        _activities = [NSMutableArray arrayWithArray:activities];
        dispatch_async(dispatch_get_main_queue(), ^{
            // End the refreshing & update the timestamp
            if (refreshControl) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"MMM d, h:mm a"];
                NSString *lastUpdate = NSLocalizedString(@"Last update",@"Last update");
                NSString *title = [NSString stringWithFormat:@"%@: %@", lastUpdate, [formatter stringFromDate:[NSDate date]]];
                NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                            forKey:NSForegroundColorAttributeName];
                NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
                refreshControl.attributedTitle = attributedTitle;
                
                [refreshControl endRefreshing];
            }
            
            [self.tableView reloadData];

        });
    }];
    
}
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
    if(y > h + reload_distance) {
        [SocialUtility queryForAllActivities:self.activities.count query:^(NSArray *activities, NSError *error) {
            //        _activities = [NSMutableArray arrayWithArray:activities];
            [self.activities addObjectsFromArray:activities];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                
            });
        }];
    }
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _activities.count;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_viewType == TTActivityViewAllActivities) {
        
        // Get a variable cell height to make sure we can fit long comments
        NSAttributedString *cellText = [[TTUtility sharedInstance] attributedStringForActivity:[_activities objectAtIndex:indexPath.row]];
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
    //    [cell setDelegate:self];
        
        // We assume fromUser contains the full PFUser object
        PFUser *user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
        [cell setUser:user];
        
        [cell.followButton setHidden:YES];
        
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
        __weak UserTableViewCell *weakCell = cell;
        
        
        
        [cell.profilePicImageView setImageWithURLRequest:request
                                        placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                     
                                                     [weakCell.profilePicImageView setImage:image];
                                                     [weakCell setNeedsLayout];
                                                     
                                                 } failure:nil];
        
        
        [weakCell.profilePicImageView.layer setCornerRadius:20.0f];
        [weakCell.profilePicImageView.layer setMasksToBounds:YES];
        [weakCell.profilePicImageView.layer setBorderWidth:2.0f];
        weakCell.profilePicImageView.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);
        
        return weakCell;
        
    }
    else if (_viewType == TTActivityViewAllActivities) {
        ActivityTableViewCell *activityCell = [self.tableView dequeueReusableCellWithIdentifier:ACTIVITY_CELL forIndexPath:indexPath];
        [activityCell setDelegate:self];
        NSDictionary *activity = [_activities objectAtIndex:indexPath.row];
        [activityCell setActivity:activity];
        
        // We assume fromUser contains the full PFUser object
        PFUser *user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
        NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
        __weak ActivityTableViewCell *weakCell = activityCell;
        
        [activityCell.profilePicImageView setImageWithURLRequest:request
                                        placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                     
                                                     [weakCell.profilePicImageView setImage:image];
                                                     [weakCell setNeedsLayout];
                                                     
                                                 } failure:nil];
        
        if ([activity valueForKey:@"photo"]) {
            
            NSURL *photoUrl = [NSURL URLWithString:[[TTUtility sharedInstance] thumbnailImageUrl:[[activity valueForKey:@"photo"] valueForKey:@"imageUrl"]]];
            NSURLRequest *photoRequest = [NSURLRequest requestWithURL:photoUrl];
            
            [activityCell.photoImageView setImageWithURLRequest:photoRequest
                                                    placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                 
                                                                 [weakCell.photoImageView setImage:image];
                                                                 [weakCell setNeedsLayout];
                                                                 
                                                             } failure:nil];
        }
        
        [weakCell.profilePicImageView.layer setCornerRadius:20.0f];
        [weakCell.profilePicImageView.layer setMasksToBounds:YES];
        [weakCell.profilePicImageView.layer setBorderWidth:2.0f];
        weakCell.profilePicImageView.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);
        
        //currently its a square but just change the radius to make it a circle
        [activityCell.photoImageView.layer setCornerRadius:1.0f];
        [activityCell.photoImageView.layer setMasksToBounds:YES];
        [activityCell.photoImageView.layer setBorderWidth:2.0f];
        activityCell.photoImageView.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);
        
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
    
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:[[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"]];
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
    
    [self.navigationController showViewController:photoViewController sender:self];
    
//    [self.navigationController presentViewController:photoViewController animated:YES completion:nil];
}

- (void)activityCell:(ActivityTableViewCell *)cellView didPressUsernameForUser:(PFUser *)user {
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser: user];
    if (vc) {
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
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor blackColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
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
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    
    //TODO: commented out code creates a button
    
    //    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0],
    //                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
    //
    //    return [[NSAttributedString alloc] initWithString:@"Create Trunk" attributes:attributes];
    return nil;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor colorWithWhite:1.0 alpha:1.0];
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
    if (self.activities.count == 0 && self.activitySearchComplete) {
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
    return YES;
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    //TODO: Implement this
}

#pragma mark -
- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}




@end
