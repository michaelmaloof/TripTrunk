//
//  TrunkListViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/25/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TrunkListViewController.h"
#import <Parse/Parse.h>
#import "Trip.h"
#import "TrunkTableViewCell.h"
#import "TrunkViewController.h"
#import "SocialUtility.h"
#import "TTUtility.h"
#import "UIImageView+AFNetworking.h"
#import "HomeMapViewController.h"
#import "UIScrollView+EmptyDataSet.h"

@interface TrunkListViewController () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSIndexPath *path;
@property NSDate *today;
@property UIBarButtonItem *filter;
@property NSMutableArray *friends;
@property NSMutableArray *objectIDs;
@property NSMutableArray *meObjectIDs;
@property NSMutableArray *haventSeens;
@property int objectsCountTotal;
@property int objectsCountMe;
@property BOOL isMine;
@property BOOL didLoad;
@property NSMutableArray *visitedTrunks;


@end
@implementation TrunkListViewController

-(void)viewDidLoad {
    
    self.today = [NSDate date];
    
    self.parseLocations = [[NSMutableArray alloc]init];
    self.meParseLocations = [[NSMutableArray alloc]init];
    self.haventSeens = [[NSMutableArray alloc]init];
    
    if (self.isList == YES) {
        self.title = self.user.username;
    } else {
        self.title = self.city;

    }
    
    self.isMine = NO;
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nightSkyline_background"]];
    [tempImageView setFrame:self.tableView.frame];
    
    self.tableView.backgroundView = tempImageView;
    
    self.objectIDs = [[NSMutableArray alloc]init];
    self.meObjectIDs = [[NSMutableArray alloc]init];

    
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    
    // Initialize the refresh control.
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl endRefreshing];
    self.tableView.backgroundView.layer.zPosition -= 1; // Needed to make sure the refresh control shows over the background image
    
}

-(void)viewWillAppear:(BOOL)animated{
    self.tabBarController.tabBar.hidden = NO;

}

-(void)viewDidAppear:(BOOL)animated{
    
    self.visitedTrunks = [[NSMutableArray alloc]init];
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (HomeMapViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[HomeMapViewController class]])
            {
                if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                    self.visitedTrunks = view.viewedTrunks;
                }
            }
        }
    }
    
    if (self.isList == YES){
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        [self loadTrunkListBasedOnProfile];
    }
    
    else if (self.user == nil) {
        
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
        self.filter = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"all_mine_1"] style:(UIBarButtonItemStylePlain) target:self action:@selector(rightBarItemWasTapped)];
        
        
        [[self navigationItem] setRightBarButtonItem:self.filter animated:NO];
        

        

        
        self.filter.tag = 0;
        [self queryParseMethodEveryone];
        
        
    } else {
        [self loadUserTrunks];
    }
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
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
        if (self.isMine == YES && self.isList == NO){
            [self loadUserTrunks];
        }else if (self.isList == NO){
            [self queryForTrunks];
        } else {
            [self loadTrunkListBasedOnProfile];
        }
    }
}

/**
 *  Load user's trunks from parse.
 *
 *
 */
-(void)loadUserTrunks
{
    if (self.meParseLocations.count == 0) {
        NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
        PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
        if (!self.user){
            [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
            
        }else{
            [query whereKey:@"toUser" equalTo:self.user];
        }
        [query whereKey:@"type" equalTo:@"addToTrip"];
        [query whereKey:@"latitude" equalTo:[NSNumber numberWithDouble:(double)self.location.coordinate.latitude]];
        [query whereKey:@"longitude" equalTo:[NSNumber numberWithDouble:(double)self.location.coordinate.longitude]];
        [query includeKey:@"trip"];
        [query whereKeyExists:@"trip"];
        [query includeKey:@"trip.creator"];
        [query includeKey:@"trip.publicTripDetail"];
//        [query orderByDescending:@"createdAt"]; //TODO does this actually work?
        query.limit = 50;
        query.skip = self.objectsCountMe;
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(error)
            {
                NSLog(@"Error: %@",error);
            }
            else
            {
                self.didLoad = YES;
                self.objectsCountMe = (int)objects.count + self.objectsCountMe;
                for (PFObject *activity in objects)
                {
                    
                    Trip *trip = activity[@"trip"];
                    
                    if (trip.name != nil && ![self.meObjectIDs containsObject:trip.objectId])
                    {
                        [self.meParseLocations addObject:trip];
                        [self.meObjectIDs addObject:trip.objectId];
                        
                    }
                }
                
                for (Trip *trip in self.meParseLocations)
                {
                    
                    NSTimeInterval lastTripInterval = [lastOpenedApp timeIntervalSinceDate:trip.createdAt];
                    NSTimeInterval lastPhotoInterval = [lastOpenedApp timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];

                    BOOL contains = NO;
                    
                    for (Trip* trunk in self.visitedTrunks){
                        if ([trunk.objectId isEqualToString:trip.objectId]){
                            contains = YES;
                        }
                    }
                    
                    if (self.visitedTrunks.count == 0){
                        contains = NO;
                    }
                    
                    if (lastTripInterval < 0 && contains == NO)
                    {
                        [self.haventSeens addObject:trip];
                    } else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil && contains == NO){
                        [self.haventSeens addObject:trip];
                    }
                }
                
            }
            //                self.filter.tag = 1;
            [self.tableView reloadData];
        }];
    } else
    {
        [self.tableView reloadData];
    }
}

-(void)loadTrunkListBasedOnProfile{
    
    if (self.meParseLocations.count == 0) {
        NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
        PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
        if (!self.user){
            [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
            
        }else{
            [query whereKey:@"toUser" equalTo:self.user];
        }
        [query whereKey:@"type" equalTo:@"addToTrip"];  
        [query includeKey:@"trip"];
        [query includeKey:@"trip.creator"];
        [query whereKeyExists:@"trip"];
        [query includeKey:@"trip.publicTripDetail"];
//        [query orderByDescending:@"createdAt"];
        query.limit = 50;
        query.skip = self.objectsCountMe;
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(error)
            {
                NSLog(@"Error: %@",error);
            }
            {
                self.didLoad = YES;
                self.objectsCountMe = (int)objects.count + self.objectsCountMe;
                for (PFObject *activity in objects)
                {
                    
                    Trip *trip = activity[@"trip"];
                    
                    if (trip.name != nil && ![self.meObjectIDs containsObject:trip.objectId])
                    {
                        [self.meParseLocations addObject:trip];
                        [self.meObjectIDs addObject:trip.objectId];
                        
                    }
                }
                
                for (Trip *trip in self.meParseLocations)
                {
                    
                    NSTimeInterval lastTripInterval = [lastOpenedApp timeIntervalSinceDate:trip.createdAt];
                    NSTimeInterval lastPhotoInterval = [lastOpenedApp timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];
                    
                    BOOL contains = NO;
                    
                    for (Trip* trunk in self.visitedTrunks){
                        if ([trunk.objectId isEqualToString:trip.objectId]){
                            contains = YES;
                        }
                    }
                    
                    if (self.visitedTrunks.count == 0){
                        contains = NO;
                    }
                    
                    if (lastTripInterval < 0 && contains == NO)
                    {
                        [self.haventSeens addObject:trip];
                    } else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil && contains == NO){
                        [self.haventSeens addObject:trip];
                    }
                }
                
            }
            //                self.filter.tag = 1;
            [self.tableView reloadData];
        }];
    } else
    {
        [self.tableView reloadData];
    }
}


/**
 *  Toggle between loading all the trunks at this city and just the users trunks
 *
 *
 */
-(void)rightBarItemWasTapped {
    if (self.filter.tag == 0) {
        [self.filter setImage:[UIImage imageNamed:@"all_mine_2"]];
        self.filter.tag = 1;
        self.isMine = YES;
        [self loadUserTrunks];
    } else if (self.filter.tag == 1) {
        [self.filter setImage:[UIImage imageNamed:@"all_mine_1"]];
        self.filter.tag = 0;
        self.isMine = NO;
        [self queryParseMethodEveryone];

    }
}

/**
 *  Refresh the list of trunks
 *
 *
 */
- (void)refresh:(UIRefreshControl *)refreshControl {
    
    
    if (self.filter.tag == 1 && self.isList == NO) {
        self.filter = 0;
        [self loadUserTrunks];
    } else if (self.filter.tag == 0 && self.isList == NO) {
        self.filter.tag = 1;
        [self queryParseMethodEveryone];
    } else if (self.isList == YES){
        [self loadTrunkListBasedOnProfile];
    }
    
    // TODO: End refreshing when the data actually updates, right now if querying takes awhile, the refresh control will end too early.
    // End the refreshing & update the timestamp
    if (refreshControl) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *update = NSLocalizedString(@"Last update",@"Last update");
        NSString *title = [NSString stringWithFormat:@"%@: %@",update, [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        refreshControl.attributedTitle = attributedTitle;
        
        [refreshControl endRefreshing];
    }

}

#pragma mark - Parse Queries



- (void)queryParseMethodEveryone{ //add the list of users that the user follows to then get their trunks

    if (self.parseLocations.count == 0)
    {

        self.friends = [[NSMutableArray alloc] init];
        
        // Add self to the friends array so that we query for our own trunks
        [self.friends addObject:[PFUser currentUser]];
        
        [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
            if (!error) {
                [self.friends addObjectsFromArray:users];
                [self queryForTrunks];
                
            }
        }];
        
    } else
    {
        [self.tableView reloadData];
    }

}



- (void)queryForTrunks{
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" containedIn:self.friends];
    [query whereKey:@"type" equalTo:@"addToTrip"]; //FIXME, THESE SHOULD BE ENUMS
    [query whereKey:@"latitude" equalTo:[NSNumber numberWithDouble:(double)self.location.coordinate.latitude]];
    [query whereKey:@"longitude" equalTo:[NSNumber numberWithDouble:(double)self.location.coordinate.longitude]];
    //    [query whereKey:@"content" equalTo:self.city];
    [query includeKey:@"trip"];
    [query includeKey:@"trip.creator"];
    [query whereKeyExists:@"trip"];
    [query includeKey:@"trip.publicTripDetail"];
    [query orderByDescending:@"createdAt"];
    query.limit = 100;
    query.skip = self.objectsCountTotal;
    
    NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
            [self.tableView reloadData];
        }
        {
            self.didLoad = YES;
            self.objectsCountTotal = (int)objects.count + self.objectsCountTotal;
            for (PFObject *activity in objects)
            {
                
                Trip *trip = activity[@"trip"];
                
                if (trip.name != nil && ![self.objectIDs containsObject:trip.objectId])
                {
                    [self.parseLocations addObject:trip];
                    [self.objectIDs addObject:trip.objectId];
                    
                }
            }
            
            for (Trip *trip in self.parseLocations)
            {
                
                NSTimeInterval lastTripInterval = [lastOpenedApp timeIntervalSinceDate:trip.createdAt];
                NSTimeInterval lastPhotoInterval = [lastOpenedApp timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];
                
                BOOL contains = NO;
                
                for (Trip* trunk in self.visitedTrunks){
                    if ([trunk.objectId isEqualToString:trip.objectId]){
                        contains = YES;
                    }
                }
                
                if (self.visitedTrunks.count == 0){
                    contains = NO;
                }
                
                if (lastTripInterval < 0 && contains == NO)
                {
                    [self.haventSeens addObject:trip];
                } else if (lastPhotoInterval < 0 && trip.publicTripDetail.mostRecentPhoto != nil && contains == NO){
                    [self.haventSeens addObject:trip];
                }
            }
            
        }
        self.filter.tag = 0;
        [self.tableView reloadData];
        
    }];
}




#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TrunkView"])
    {
        if (self.filter.tag == 0 && self.parseLocations != nil && self.user == nil && self.isList == NO) {
            if (self.path.row < self.parseLocations.count)
            {
                TrunkViewController *trunkView = segue.destinationViewController;
                Trip *trip = [self.parseLocations objectAtIndex:self.path.row];
                trunkView.trip = trip;
            }
        } else if (self.filter.tag == 1 && self.meParseLocations != nil && self.isList == NO){
            if (self.path.row < self.meParseLocations.count)
            {
                TrunkViewController *trunkView = segue.destinationViewController;
                Trip *trip = [self.meParseLocations objectAtIndex:self.path.row];
                trunkView.trip = trip;
            }
        } else if (self.user != nil && self.isList == NO) {
            // This is a User Globe Map, so there is no self.filter.tag, and it uses the meParseLocations object.
            TrunkViewController *trunkView = segue.destinationViewController;
            Trip *trip = [self.meParseLocations objectAtIndex:self.path.row];
            trunkView.trip = trip;
        } else if (self.isList == YES){
            TrunkViewController *trunkView = segue.destinationViewController;
            Trip *trip = [self.meParseLocations objectAtIndex:self.path.row];
            trunkView.trip = trip;
        }
        self.path = nil;
    }
}

#pragma mark - UITableView Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.filter.tag == 0 && self.parseLocations !=nil && self.user == nil && self.isList == NO) {
        return self.parseLocations.count;
    }else if (self.filter.tag == 1 && self.meParseLocations !=nil && self.isList == NO){
        return self.meParseLocations.count;
    }
    else if (self.user != nil && self.isList == NO){
        return self.meParseLocations.count;
    } else if (self.isList == YES){
        return self.meParseLocations.count;
    }else {
        return 0;
    }
}

-(TrunkTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath

{
    TrunkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TripCell" forIndexPath:indexPath];
    Trip *trip = [[Trip alloc]init];
    cell.lockImage.hidden = YES;
    cell.seenLogo.hidden = YES;
    
    if (self.filter.tag == 0 && self.user == nil && self.isList == NO) {
        trip = [self.parseLocations objectAtIndex:indexPath.row];
        
    } else {
        trip = [self.meParseLocations objectAtIndex:indexPath.row];
    }
    
    if (trip.isPrivate == YES){
        cell.lockImage.hidden = NO;
    } else {
        cell.lockImage.hidden = YES;
    }
    
    if ([self.haventSeens containsObject:trip]){
        cell.seenLogo.hidden = NO;
    } else {
        cell.seenLogo.hidden = YES;
    }
    
    cell.trip = trip;
    cell.titleLabel.text = trip.name;
    
    NSString *countString;
    if (cell.trip.publicTripDetail.photoCount == 0 || !cell.trip.publicTripDetail.photoCount) {
        countString = @"No Photos";
    }
    else if (cell.trip.publicTripDetail.photoCount == 1) {
        countString = @"1 Photo";
    }
    else {
        NSString *photo = NSLocalizedString(@"Photos",@"Photos");
        countString = [NSString stringWithFormat:@"%i %@", cell.trip.publicTripDetail.photoCount, photo];
    }
    
//    [cell.trip.creator fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
    if (self.isList == NO){
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ (%@)", cell.trip.creator.username, countString];
    } else {
           cell.subtitleLabel.text = [NSString stringWithFormat:@"%@ (%@)", cell.trip.city, countString];
    }
//    }];

    NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];
    
    
    if (tripInterval < 86400 && trip.publicTripDetail.mostRecentPhoto != NULL) {
        cell.backgroundColor = [UIColor colorWithRed:(228.0/255.0) green:(117.0/255.0) blue:(98.0/255.0) alpha:1];
    }
    else
    {
        cell.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
    }
    
    PFUser *possibleFriend = cell.trip.creator;
//    [possibleFriend fetchIfNeeded:nil];
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profilePreviewImageUrl:possibleFriend[@"profilePicUrl"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    __weak TrunkTableViewCell *weakCell = cell;

    [cell.profileImage setImageWithURLRequest:request
                             placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                          
                                          [weakCell.profileImage setImage:image];
                                          [weakCell setNeedsLayout];
                                          
                                      } failure:nil];

    return cell;
    
    return weakCell;




}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.path = indexPath;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.filter.tag == 0 && self.parseLocations != nil && self.user == nil && self.isList == NO) {
        if (self.path.row < self.parseLocations.count)
        {
            [self performSegueWithIdentifier:@"TrunkView" sender:self];

        }
    } else if (self.filter.tag == 1 && self.meParseLocations != nil && self.isList == NO){
        if (self.path.row < self.meParseLocations.count)
        {
            [self performSegueWithIdentifier:@"TrunkView" sender:self];

        }
    } else if (self.user != nil && self.isList == NO) {
            [self performSegueWithIdentifier:@"TrunkView" sender:self];

    } else if (self.isList == YES){
            [self performSegueWithIdentifier:@"TrunkView" sender:self];

    }

}


#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"Opps! These trunks have gone missing!",@"Opps! These trunks have gone missing!");
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text =NSLocalizedString(@"Have you visited this city? Create a trunk now!",@"Have you visited this city? Create a trunk now!");
    
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
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0],
                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Create Trunk",@"Create Trunk") attributes:attributes];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor colorWithWhite:0.0 alpha:0.0];
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
    // Only display the empty dataset view if there's no user trunks AND it's on the user-only toggle
    // They won't even see a city if there are NO trunks in it, and it's not possible to have a user's trunk but nothing in the All Trunks list.
    // Either they can't get to this page, or something is in the All Trunks list, so the user's list is the only possible empty list.
    if (self.user == nil && self.filter.tag == 1 && self.meParseLocations.count == 0 &&self.didLoad == YES){
        // A little trick for removing the cell separators
        self.tableView.tableFooterView = [UIView new];
        return YES;
    } else if (self.user && self.meParseLocations.count == 0 && self.didLoad == YES){
        self.tableView.tableFooterView = [UIView new];
        
        NSMutableArray *locationArray = [[NSMutableArray alloc]init];
        for (UINavigationController *controller in self.tabBarController.viewControllers)
        {
            for (HomeMapViewController *view in controller.viewControllers)
            {
                if ([view isKindOfClass:[HomeMapViewController class]])
                {
                    
                    [locationArray addObject:view];
                    if ([view.user.objectId isEqualToString:self.user.objectId] )
                    {
                        [view dontRefreshMap];
                        [view deleteTrunk:self.location trip:nil];
                    }
                }
            }
        }
        
        return YES;
    }
    
    else  if (self.user == nil && self.parseLocations.count == 0 && self.didLoad == YES){
        // A little trick for removing the cell separators
        self.tableView.tableFooterView = [UIView new];
        
        NSMutableArray *locationArray = [[NSMutableArray alloc]init];
        for (UINavigationController *controller in self.tabBarController.viewControllers)
        {
            for (HomeMapViewController *view in controller.viewControllers)
            {
                if ([view isKindOfClass:[HomeMapViewController class]])
                {
                    
                    [locationArray addObject:view];
                    if (view.user == nil || [view.user.objectId isEqualToString:[PFUser currentUser].objectId] )
                    {
                        [view dontRefreshMap];
                        [view deleteTrunk:self.location trip:nil];
                    }
                }
            }
        }
        
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
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tabBarController setSelectedIndex:2];
        
    });

}

-(void)photoWasAdded:(id)sender{
    
}

- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}

-(void)reloadTrunkList:(Trip *)trip seen:(BOOL)hasSeen{
        for (Trip *tripP in self.parseLocations){
            if ([trip.objectId isEqualToString:tripP.objectId]){
                tripP.publicTripDetail.mostRecentPhoto = trip.publicTripDetail.mostRecentPhoto;
                tripP.publicTripDetail.photoCount += 1;
            }
        }
    //TODO dont need to call this twice just reload once

        for (Trip *tripM in self.meParseLocations){
            if ([trip.objectId isEqualToString:tripM.objectId]){
                tripM.publicTripDetail.mostRecentPhoto = trip.publicTripDetail.mostRecentPhoto;
                tripM.publicTripDetail.photoCount += 1;
            }
        }
    Trip *trunk = [[Trip alloc]init];

    if (hasSeen == YES){
        for (Trip *trunkSeen in self.haventSeens){
            if ([trunkSeen.objectId isEqualToString:trip.objectId])
            {
                trunk = trunkSeen;
            }
        }
    }
    if (hasSeen == YES){
        [self.haventSeens removeObject:trunk];
    }
    
    [self.tableView reloadData];

}

-(void)deleteItemOnTrunkList:(Trip*)trip{
    Trip *tripA = [[Trip alloc]init];
    Trip *tripB = [[Trip alloc]init];
    
    for (Trip *tripP in self.parseLocations){
        if ([trip.objectId isEqualToString:tripP.objectId]){
            tripA = tripP;
        }
    }
    //TODO dont need to call this twice just reload once
    for (Trip *tripM in self.meParseLocations){
        if ([trip.objectId isEqualToString:tripM.objectId]){
            tripB = tripM;
        }
    }
    
    [self.parseLocations removeObject:tripA];
    [self.meParseLocations removeObject:tripB];
    
    [self.tableView reloadData];

}



@end
