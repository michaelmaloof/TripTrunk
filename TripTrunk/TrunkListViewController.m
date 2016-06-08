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
@property UIBarButtonItem *trunkListToggle;
@property NSMutableArray *friends;
@property NSMutableArray *objectIDs;
@property NSMutableArray *meObjectIDs;
@property NSMutableArray *haventSeens;
@property int objectsCountTotal;
@property int objectsCountMe;
@property BOOL isMine;
@property BOOL didLoad;
@property NSMutableArray *visitedTrunks;
@property NSMutableArray *mutualTrunks;
@property UIImage *flame;
@property BOOL wasError;
@property BOOL attemptedToLoad;
@end

@implementation TrunkListViewController

#pragma mark - Setup

-(void)viewDidLoad {
    [self displayTitle];
    [self displayFlameImage];
    [self prepareForLoadingTrips];
    [self setupTableViewAndRefresh];
}

-(void)viewWillAppear:(BOOL)animated{
    //because we hide the tab bar on the PhotoViewController we make sure its still not hidden here
    self.tabBarController.tabBar.hidden = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    [self displayTitle];
    self.visitedTrunks = [[NSMutableArray alloc]init];
    [self handleVisitedTrunks];
    [self beginLoadingTrunks];
    [self removeTextFromBackButton];
}

-(void)displayTitle{
    if (self.isList == YES) {
        self.title = self.user.username;
    } else {
        self.title = self.city;
    }
}

-(void)displayFlameImage{
    UIImage *flame = [UIImage imageNamed:@"flame"];
    CGRect rect = CGRectMake(0,0,15,20);
    UIGraphicsBeginImageContext( rect.size );
    [flame drawInRect:rect];
    UIImage *picture1 = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *imageData = UIImagePNGRepresentation(picture1);
    self.flame = [UIImage imageWithData:imageData];

}

-(void)removeTextFromBackButton{
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
}

-(void)prepareForLoadingTrips{
    self.today = [NSDate date];
    self.parseLocations = [[NSMutableArray alloc]init];
    self.meParseLocations = [[NSMutableArray alloc]init];
    self.mutualTrunks = [[NSMutableArray alloc]init];
    self.haventSeens = [[NSMutableArray alloc]init];
    self.objectIDs = [[NSMutableArray alloc]init];
    self.meObjectIDs = [[NSMutableArray alloc]init];
    self.mutualTrunks = [[NSMutableArray alloc]init];
    self.isMine = NO;
}

-(void)handleVisitedTrunks{
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
}

-(void)setupTableViewAndRefresh{
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
    // Initialize the refresh control.
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refresh:)
             forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    refreshControl.tintColor = [TTColor tripTrunkBlue];
    [refreshControl endRefreshing];
    self.tableView.backgroundView.layer.zPosition -= 1; // Needed to make sure the refresh control shows over the background image
}

#pragma mark - TableView


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

#pragma mark - Scrolling


- (void)scrollViewDidEndDragging:(UIScrollView *)aScrollView
                  willDecelerate:(BOOL)decelerate
{
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = (offset.y + bounds.size.height - inset.bottom)*.9;
    float h = size.height;
    float reload_distance = 10;
    if(y > h + reload_distance) {
        if (self.isMine == YES && self.isList == NO){
            self.navigationItem.rightBarButtonItem.enabled = NO;
            [self loadUserTrunks:NO];
        }else if (self.isList == NO){
            self.navigationItem.rightBarButtonItem.enabled = NO;
            [self queryForTrunks:NO];
        } else if (self.isList == YES && self.trunkListToggle.tag == 0){
            self.navigationItem.rightBarButtonItem.enabled = NO;
            [self loadTrunkListBasedOnProfile:NO];
        } else if (self.isList == YES && self.trunkListToggle.tag == 1){
            //fixme: load mutual trunks but for now idk if we need to since there wont be more than 1000 trips combined. once this is a service method we can do this
        }
    }
}

#pragma mark - Loading Trunks

-(void)beginLoadingTrunks{
    //FIXME self.filter.tag amd self.trunkListToggle.tag logic needs to be used in viewDidAppear on if statements to not reset the current tag the user is on
    if (self.isList == YES && ![self.user.objectId isEqualToString:[PFUser currentUser].objectId]){
        self.trunkListToggle = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"all_mine_1"] style:(UIBarButtonItemStylePlain) target:self action:@selector(rightBarItemWasTapped)];
        [[self navigationItem] setRightBarButtonItem:self.trunkListToggle animated:NO];
        self.trunkListToggle.tag = 0;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self loadTrunkListBasedOnProfile:NO];
    } else if (self.isList == YES){
        self.trunkListToggle.tag = 0;
        [self loadTrunkListBasedOnProfile:NO];
    }
    [self queryParseMethodEveryone:NO];
}

/**
 *  Load user's trunks from parse.
 *
 *
 */
-(void)loadUserTrunks:(BOOL)isRefresh
{
    if (self.meParseLocations.count == 0 || self.meParseLocations.class == nil || isRefresh == YES) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
        //Build an array to send up to CC
        NSMutableArray *friendsObjectIds = [[NSMutableArray alloc] init];
        //we only have a single user but we still need to add it to an array and send up the params
        if (!self.user){
            [friendsObjectIds addObject:[PFUser currentUser].objectId];
            
        }else{
            [friendsObjectIds addObject:self.user.objectId];
        }
        int limit;
        int skip;
        if (isRefresh == NO){
            limit = 100;
            skip = self.objectsCountMe;
        } else {
            if (self.objectsCountMe == 0)
                limit = 100;
            else limit = self.objectsCountMe;
            skip = 0;
            self.objectsCountMe = 0;
        }
        NSDictionary *params = @{
                                 @"objectIds" : friendsObjectIds,
                                 @"limit" : [NSString stringWithFormat:@"%d",limit],
                                 @"skip" : [NSString stringWithFormat:@"%d",skip],
                                 @"latitude" : [NSNumber numberWithDouble:(double)self.location.coordinate.latitude],
                                 @"longitude" : [NSNumber numberWithDouble:(double)self.location.coordinate.longitude]
                                 };
        self.attemptedToLoad = NO;
        [PFCloud callFunctionInBackground:@"queryForUniqueTrunks" withParameters:params block:^(NSArray *response, NSError *error) {
            self.attemptedToLoad = YES;
            if(error)
            {
                [ParseErrorHandlingController handleError:error];
                self.wasError = YES;
                [self reloadTable];
                NSLog(@"Error: %@",error);
            }
            else
            {
                self.wasError = NO;
                if (isRefresh == YES){
                    self.meParseLocations = [[NSMutableArray alloc]init];
                    self.meObjectIDs = [[NSMutableArray alloc]init];;
                }
                [[TTUtility sharedInstance] internetConnectionFound];
                self.didLoad = YES;
                self.objectsCountMe = (int)response.count + self.objectsCountMe;
                for (PFObject *activity in response)
                {
                    Trip *trip = activity[@"trip"];
                    if (trip.name != nil && ![self.meObjectIDs containsObject:trip.objectId] && trip.publicTripDetail != nil)
                    {
                        [self.meParseLocations addObject:trip];
                        [self.meObjectIDs addObject:trip.objectId];
                        
                    } else if (trip.name != nil && ![self.meObjectIDs containsObject:trip.objectId] && [trip.creator.objectId isEqualToString:[PFUser currentUser].objectId])
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
            [self reloadTable];
        }];
    } else
    {
        [self reloadTable];
    }
}

-(void)loadTrunkListBasedOnProfile:(BOOL)isRefresh{
    
    if (self.meParseLocations.count == 0 || isRefresh == YES) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
        //Build an array to send up to CC
        NSMutableArray *friendsObjectIds = [[NSMutableArray alloc] init];
        //we only have a single user but we still need to add it to an array and send up the params
        if (!self.user){
            [friendsObjectIds addObject:[PFUser currentUser].objectId];
        }else{
            [friendsObjectIds addObject:self.user.objectId];
        }
        int limit;
        int skip;
        if (isRefresh == NO){
            limit = 50;
            skip = self.objectsCountMe;
        } else {
            if (self.objectsCountMe == 0)
                limit = 50;
            else limit = self.objectsCountMe;
            skip = 0;
            self.objectsCountMe = 0;
        }
        NSDictionary *params = @{
                                 @"objectIds" : friendsObjectIds,
                                 @"limit" : [NSString stringWithFormat:@"%d",limit],
                                 @"skip" : [NSString stringWithFormat:@"%d",skip]
                                 };
        self.attemptedToLoad = NO;
        [PFCloud callFunctionInBackground:@"queryForUniqueTrunks" withParameters:params block:^(NSArray *response, NSError *error) {
            self.attemptedToLoad = YES;
            if(error)
            {
                self.wasError = YES;
                NSLog(@"Error: %@",error);
                [ParseErrorHandlingController handleError:error];
                [self reloadTable];
            }
            else if (!error)
            {
                self.wasError = NO;
                [[TTUtility sharedInstance] internetConnectionFound];
            }
            {
                if (isRefresh == YES){
                    self.meObjectIDs = [[NSMutableArray alloc]init];;
                    self.meParseLocations = [[NSMutableArray alloc]init];
                }
                self.didLoad = YES;
                self.objectsCountMe = (int)response.count + self.objectsCountMe;
                for (PFObject *activity in response)
                {
                    Trip *trip = activity[@"trip"];
                    if (trip.name != nil && ![self.meObjectIDs containsObject:trip.objectId] && trip.publicTripDetail != nil)
                    {
                        [self.meParseLocations addObject:trip];
                        [self.meObjectIDs addObject:trip.objectId];
                    } else if (trip.name != nil && ![self.meObjectIDs containsObject:trip.objectId] && [trip.creator.objectId isEqualToString:[PFUser currentUser].objectId])
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
            [self reloadTable];
        }];
    } else
    {
        [self reloadTable];
    }
}

-(void)loadMutualTrunkList:(BOOL)isRefresh{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.mutualTrunks.count == 0 || isRefresh == YES) {
        NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
        NSString *user;
        if (!self.user)
            user = [PFUser currentUser].objectId;
        else user = self.user.objectId;
        NSDictionary *params = @{
                                 @"user1" : user,
                                 @"user2" : [PFUser currentUser].objectId,
                                 @"limit" : @"1000"
                                 };
        self.attemptedToLoad = NO;
        [PFCloud callFunctionInBackground:@"queryForMutualTrunks" withParameters:params block:^(NSArray *response, NSError *error) {
            self.attemptedToLoad = YES;
            if(error)
            {
                self.wasError = YES;
                [ParseErrorHandlingController handleError:error];
                [self reloadTable];
                NSLog(@"Error: %@",error);
            }
            {
                if (!error){
                    self.wasError = NO;
                    [[TTUtility sharedInstance] internetConnectionFound];
                }
                self.didLoad = YES;
                for (PFObject *activity in response){
                    [self.mutualTrunks addObject:activity[@"trip"]];
                }
                for (Trip *trip in self.mutualTrunks)
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
            [self reloadTable];
        }];
        } else
    {
        [self reloadTable];
        
    }
}

#pragma mark - Nav Bar Toggle


/**
 *  Toggle between loading all the trunks at this city and just the users trunks
 *
 *
 */
-(void)rightBarItemWasTapped {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.filter.tag == 0 && self.isList == NO) {
        [self.filter setImage:[UIImage imageNamed:@"all_mine_2"]];
        self.filter.tag = 1;
        self.isMine = YES;
        [self loadUserTrunks:NO];
    } else if (self.filter.tag == 1 && self.isList == NO) {
        [self.filter setImage:[UIImage imageNamed:@"all_mine_1"]];
        self.filter.tag = 0;
        self.isMine = NO;
        [self queryParseMethodEveryone:NO];
    } else if (self.isList == YES && self.trunkListToggle.tag == 0){ //switch to mutual
        [self.trunkListToggle setImage:[UIImage imageNamed:@"all_mine_2"]];
        self.trunkListToggle.tag = 1;
        self.isMine = YES;
        [self loadMutualTrunkList:NO];
// fixme: method to load mutual
    } else if (self.isList == YES && self.trunkListToggle.tag == 1){ //switch to all list
        [self.trunkListToggle setImage:[UIImage imageNamed:@"all_mine_1"]];
        self.trunkListToggle.tag = 0;
        self.isMine = NO;
        [self loadTrunkListBasedOnProfile:NO];

    }
}

#pragma mark - Refresh

/**
 *  Refresh the list of trunks
 *
 *
 */
- (void)refresh:(UIRefreshControl *)refreshControl {
    
    if (self.user && self.isList == NO){
        [self loadUserTrunks:YES];
    }
    else if (self.filter.tag == 1 && self.isList == NO) {
        [self loadUserTrunks:YES];
    } else if (self.filter.tag == 0 && self.isList == NO) {
        [self queryParseMethodEveryone:YES];
    } else if (self.isList == YES  && self.trunkListToggle.tag == 0){
        [self loadTrunkListBasedOnProfile:YES];
    } else if (self.isList == YES && self.trunkListToggle.tag == 1){
        [self loadMutualTrunkList:YES];
    }

    // TODO: End refreshing when the data actually updates, right now if querying takes awhile, the refresh control will end too early.
    // End the refreshing & update the timestamp
    if (refreshControl) {
        [refreshControl endRefreshing];
    }

}

#pragma mark - Parse Queries

- (void)queryParseMethodEveryone:(BOOL)isRefresh{ //add the list of users that the user follows to then get their trunks

    if (self.parseLocations.count == 0 || isRefresh == YES)
    {
        self.friends = [[NSMutableArray alloc] init];
        
        // Add self to the friends array so that we query for our own trunks
        [self.friends addObject:[PFUser currentUser]];
        self.attemptedToLoad = NO;
        [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
            self.attemptedToLoad = YES;
            if (!error) {
                [self.friends addObjectsFromArray:users];
                [self queryForTrunks:isRefresh];
                
            } else {
                self.wasError = YES;
                [ParseErrorHandlingController handleError:error];
                [self reloadTable];
                NSLog(@"Error: %@",error);
            }
        }];
    } else
    {
        [self reloadTable];
    }

}

- (void)queryForTrunks:(BOOL)isRefresh{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
    
    //Build an array to send up to CC
    NSMutableArray *friendsObjectIds = [[NSMutableArray alloc] init];
    for(PFUser *friendObjectId in self.friends){
        // add just the objectIds to the array, no PFObjects can be sent as a param
        [friendsObjectIds addObject:friendObjectId.objectId];
    }
    int limit;
    int skip;
    if (isRefresh == NO){
        limit = 100;
        skip = self.objectsCountMe;
    } else {
        if (self.objectsCountMe == 0)
            limit = 100;
        else limit = self.objectsCountMe;
        skip = 0;
        self.objectsCountMe = 0;
    }
    NSDictionary *params = @{
                             @"objectIds" : friendsObjectIds,
                             @"limit" : [NSString stringWithFormat:@"%d",limit],
                             @"skip" : [NSString stringWithFormat:@"%d",skip],
                             @"latitude" : [NSNumber numberWithDouble:(double)self.location.coordinate.latitude],
                             @"longitude" : [NSNumber numberWithDouble:(double)self.location.coordinate.longitude]
                             };
    self.attemptedToLoad = NO;
    [PFCloud callFunctionInBackground:@"queryForUniqueTrunks" withParameters:params block:^(NSArray *response, NSError *error) {
        self.attemptedToLoad = YES;
        if(error)
        {
            self.wasError = YES;
            [ParseErrorHandlingController handleError:error];
            NSLog(@"Error: %@",error);
            [self reloadTable];
        }
        {
            if (!error){
                self.wasError = NO;
                [[TTUtility sharedInstance] internetConnectionFound];
            }
            
            if (isRefresh == YES){
                self.parseLocations = [[NSMutableArray alloc]init];
                self.objectIDs = [[NSMutableArray alloc]init];;
            }
            
            self.didLoad = YES;
            self.objectsCountTotal = (int)response.count + self.objectsCountTotal;
            for (PFObject *activity in response)
            {
                
                Trip *trip = activity[@"trip"];
                
                if (trip.name != nil && ![self.objectIDs containsObject:trip.objectId] && trip.publicTripDetail != nil)
                {
                    [self.parseLocations addObject:trip];
                    [self.objectIDs addObject:trip.objectId];
                    
                } else if ( trip.name != nil && ![self.objectIDs containsObject:trip.objectId] && [trip.creator.objectId isEqualToString:[PFUser currentUser].objectId]){
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
        [self reloadTable];
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
        } else if (self.isList == YES && self.trunkListToggle.tag == 0){
            TrunkViewController *trunkView = segue.destinationViewController;
            Trip *trip = [self.meParseLocations objectAtIndex:self.path.row];
            trunkView.trip = trip;
        } else if (self.isList == YES && self.trunkListToggle.tag == 1){
            TrunkViewController *trunkView = segue.destinationViewController;
            Trip *trip = [self.mutualTrunks objectAtIndex:self.path.row];
            trunkView.trip = trip;
        }
        self.path = nil;
    }
}

#pragma mark - UITableView Data Source

-(void)reloadTable{
    
    NSMutableArray *copiedTrunks = [[NSMutableArray alloc] init];
    NSMutableArray *tempArray1 = [[NSMutableArray alloc] init];
    NSArray *tempArray2 = [[NSArray alloc] init];
    NSMutableArray *sortedTrunks = [[NSMutableArray alloc] init];
    
    if (self.filter.tag == 0 && self.user == nil && self.isList == NO) {
        copiedTrunks = self.parseLocations;
    } else if (self.trunkListToggle.tag == 1 && self.isList == YES){
        copiedTrunks = self.mutualTrunks;
    } else {
        copiedTrunks = self.meParseLocations;
    }
    
    // sort by recent photos
    for (Trip *aTrip in copiedTrunks) {
        NSDate *photoTimeStamp = aTrip.publicTripDetail.mostRecentPhoto;
        if (!photoTimeStamp) {
            photoTimeStamp = aTrip.publicTripDetail.createdAt;
        }
        double timeDiff =[photoTimeStamp timeIntervalSinceNow];
        
        NSDictionary *aTripDict = [[NSDictionary alloc]initWithObjectsAndKeys:aTrip,@"trip",@(fabs(timeDiff)),@"timeValue", nil];
        
        [tempArray1 addObject:aTripDict];
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"timeValue"  ascending:YES];
    tempArray2 = [[NSArray arrayWithArray:tempArray1] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    
    for (NSDictionary *aTripDict in tempArray2) {
        [sortedTrunks addObject:aTripDict[@"trip"]];
    }
    
    if (self.filter.tag == 0 && self.user == nil && self.isList == NO) {
        self.parseLocations = sortedTrunks;
    } else if (self.trunkListToggle.tag == 1 && self.isList == YES){
        self.mutualTrunks = sortedTrunks;
    } else {
        self.meParseLocations = sortedTrunks;
    }
    
    //reload
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem.enabled = YES;

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.filter.tag == 0 && self.parseLocations !=nil && self.user == nil && self.isList == NO) {
        return self.parseLocations.count;
    }else if (self.filter.tag == 1 && self.meParseLocations !=nil && self.isList == NO){
        return self.meParseLocations.count;
    }
    else if (self.user != nil && self.isList == NO){
        return self.meParseLocations.count;
    } else if (self.isList == YES && self.trunkListToggle.tag == 0){
        return self.meParseLocations.count;
    }else if (self.isList == YES && self.trunkListToggle.tag == 1){
        return self.mutualTrunks.count;
    } else {
         return 0;
    }
}

-(TrunkTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TrunkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TripCell" forIndexPath:indexPath];
    Trip *trip = [[Trip alloc]init];
    cell.seenLogo.hidden = YES;
    cell.seenLogo.image = nil;
    cell.profileImage.image = nil;
    
    if (self.filter.tag == 0 && self.user == nil && self.isList == NO) {
        trip = [self.parseLocations objectAtIndex:indexPath.row];
    } else if (self.trunkListToggle.tag == 1 && self.isList == YES){
        trip = [self.mutualTrunks objectAtIndex:indexPath.row];
    } else {
        trip = [self.meParseLocations objectAtIndex:indexPath.row];
    }
    cell.trip = trip;
    if (trip.isPrivate == YES){
        NSString *namePlusSpace = [NSString stringWithFormat:@"%@  ",cell.trip.name];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:namePlusSpace];
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        textAttachment.image = [UIImage imageNamed:@"lock_small_gray"];
        NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
        [attributedString replaceCharactersInRange:NSMakeRange(namePlusSpace.length-1, 1) withAttributedString:attrStringWithImage];
        cell.titleLabel.attributedText = attributedString;
    } else {
        cell.titleLabel.text = trip.name;
    }
    
    NSString *countString;
    if (cell.trip.publicTripDetail.photoCount == 0 || !cell.trip.publicTripDetail.photoCount) {
        countString = @"";
    }
    else if (cell.trip.publicTripDetail.photoCount == 1) {
        countString = @"(1 Photo)";
    }
    else {
        NSString *photos = NSLocalizedString(@"Photos",@"Photos");
        countString = [NSString stringWithFormat:@"(%i %@)", cell.trip.publicTripDetail.photoCount, photos];
    }
    
    NSString *subtitle;
    if (self.isList == NO){
        subtitle = [NSString stringWithFormat:@"%@ %@", cell.trip.creator.username, countString];
    } else {
        subtitle = [NSString stringWithFormat:@"%@ %@", cell.trip.city, countString];
    }
    if (cell.trip.publicTripDetail.totalLikes > 49){
        
        
        CGFloat offsetY = -7.0;
        NSString *subtitlePlusSpace = [NSString stringWithFormat:@"%@  ",subtitle];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:subtitlePlusSpace];
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        textAttachment.image = self.flame;
         textAttachment.bounds = CGRectMake(0, offsetY, textAttachment.image.size.width, textAttachment.image.size.height);
        NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
        [attributedString replaceCharactersInRange:NSMakeRange(subtitlePlusSpace.length-1, 1) withAttributedString:attrStringWithImage];
        cell.subtitleLabel.attributedText = attributedString;
    } else{
        cell.subtitleLabel.text = subtitle;
    }
    NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:trip.publicTripDetail.mostRecentPhoto];
    if (tripInterval < 86400 && trip.publicTripDetail.mostRecentPhoto != NULL) {
        cell.titleLabel.textColor = [TTColor tripTrunkRed];
        if ([self.haventSeens containsObject:trip]){
            cell.seenLogo.image = [UIImage imageNamed:@"paw_red_list"];
            cell.seenLogo.hidden = NO;
        } else {
            cell.seenLogo.hidden = YES;
        }
    }
    else
    {
        cell.titleLabel.textColor = [TTColor tripTrunkBlue];
        if ([self.haventSeens containsObject:trip]){
            cell.seenLogo.image = [UIImage imageNamed:@"paw_blue_list"];
            cell.seenLogo.hidden = NO;
        } else {
            cell.seenLogo.hidden = YES;
        }
    }
    PFUser *possibleFriend = cell.trip.creator;
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profilePreviewImageUrl:possibleFriend[@"profilePicUrl"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    __weak TrunkTableViewCell *weakCell = cell;
    weakCell.profileImage.image = nil;

    [cell.profileImage setImageWithURLRequest:request
                             placeholderImage:nil
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
        
    } else if (self.isList == YES && self.trunkListToggle.tag == 0){
        [self performSegueWithIdentifier:@"TrunkView" sender:self];
        
    } else if (self.isList == YES && self.trunkListToggle.tag == 1){
        [self performSegueWithIdentifier:@"TrunkView" sender:self];
        
    }
    
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = [[NSString alloc]init];
    if (self.wasError == NO && self.attemptedToLoad == NO){
        text = NSLocalizedString(@"Looking for Trunks",@"Looking for Trunks");
    }
    else if (self.wasError == NO && self.meParseLocations.count < 1 && self.attemptedToLoad == YES) { //looking for your trips returned 0
        text = NSLocalizedString(@"You Haven't Been Here :/",@"You Haven't Been Here :/");
    } else if (self.wasError == NO && self.parseLocations.count < 1 && self.attemptedToLoad == YES){ //looking for all trips returned 0
        text = NSLocalizedString(@"No One Has Been Here :/",@"No One Has Been Here :/");
    } else if (self.wasError == NO && self.mutualTrunks.count < 1 && self.attemptedToLoad == YES){ //looking for mutual trips returned 0
        text = NSLocalizedString(@"You have no common trunks :/",@"You have no common trunks :/");
    }
    else if (self.wasError == YES){ //error finding trips
        text = NSLocalizedString(@"Error Loading Trunks. Please Try Again :/",@"Error Loading Trunks. Please Try Again :/");
    }
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFontBold18],
                                 NSForegroundColorAttributeName: [TTColor tripTrunkBlack]};
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFontBold16],
                                 NSForegroundColorAttributeName: [TTColor tripTrunkWhite]};
    if (self.attemptedToLoad == YES && self.wasError == YES){
        return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Reload",@"Reload") attributes:attributes];
    } else {
          return [[NSAttributedString alloc] initWithString:@"" attributes:attributes];
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [TTColor tripTrunkClear];
}

- (CGPoint)offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return CGPointMake(0, 20);
}

#pragma mark - DZNEmptyDataSetDelegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView //fixme: change the message to "you share no trunks"
{
    //if were on the user's profile and their are on trunks on a city it doesnt make sense that there are 0 trunks so we delete the trunk from the map.
    if (self.user && self.meParseLocations.count == 0 && self.didLoad == YES && self.wasError == NO){
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
    }
    //if were on the home map  and their are on trunks on a city it doesnt make sense that there are 0 trunks so we delete the trunk from the map.
    else  if (self.user == nil && self.parseLocations.count == 0 && self.didLoad == YES && self.wasError == NO){
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
    }
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
    return NO;
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.attemptedToLoad == YES && self.wasError == YES){
            if (self.user && self.isList == NO){
                [self loadUserTrunks:YES];
            }
            else if (self.filter.tag == 1 && self.isList == NO) {
                [self loadUserTrunks:YES];
            } else if (self.filter.tag == 0 && self.isList == NO) {
                [self queryParseMethodEveryone:YES];
            } else if (self.isList == YES  && self.trunkListToggle.tag == 0){
                [self loadTrunkListBasedOnProfile:YES];
            } else if (self.isList == YES && self.trunkListToggle.tag == 1){
                [self loadMutualTrunkList:YES];
            }
        }
    });
}

-(void)photoWasAdded:(id)sender{
    
}

- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}

-(void)reloadTrunkList:(Trip *)trip seen:(BOOL)hasSeen addPhoto:(BOOL)added photoRemoved:(BOOL)removed{
        for (Trip *tripP in self.parseLocations){
            if ([trip.objectId isEqualToString:tripP.objectId]){
                tripP.publicTripDetail.mostRecentPhoto = trip.publicTripDetail.mostRecentPhoto;
                
                if (added == YES){
                    tripP.publicTripDetail.photoCount += 1;
                } else if (removed == YES){
                    tripP.publicTripDetail.photoCount -= 1;
                }
            }
        }
    
        for (Trip *tripM in self.meParseLocations){
            if ([trip.objectId isEqualToString:tripM.objectId]){
                tripM.publicTripDetail.mostRecentPhoto = trip.publicTripDetail.mostRecentPhoto;
                if (added == YES){
                    tripM.publicTripDetail.photoCount += 1;
                } else if (removed == YES){
                    tripM.publicTripDetail.photoCount -= 1;
                }
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
    [self reloadTable];

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
    [self reloadTable];
}



@end
