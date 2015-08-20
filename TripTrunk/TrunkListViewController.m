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

#import "UIScrollView+EmptyDataSet.h"

@interface TrunkListViewController () <UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@property NSMutableArray *parseLocations;
@property NSMutableArray *meParseLocations;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSIndexPath *path;
@property NSDate *today;
@property UIBarButtonItem *filter;
@property NSMutableArray *friends;
@property NSMutableArray *objectIDs;

@end
@implementation TrunkListViewController

-(void)viewDidLoad {
    
    self.today = [NSDate date];
    
    self.title = self.city;
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"night"]];
    [tempImageView setFrame:self.tableView.frame];
    
    self.tableView.backgroundView = tempImageView;
    
    self.objectIDs = [[NSMutableArray alloc]init];
    
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    
    if (self.user == nil) {
    
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
        [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
        [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
        [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
        
        UIBarButtonItem *newBackButton =
        [[UIBarButtonItem alloc] initWithTitle:@""
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
        [[self navigationItem] setBackBarButtonItem:newBackButton];
        
        self.filter =
        [[UIBarButtonItem alloc] initWithTitle:@"My Trunks"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(rightBarItemWasTapped)];
        [[self navigationItem] setRightBarButtonItem:self.filter animated:NO];
        
        self.filter.tag = 1;
        [self rightBarItemWasTapped];

        
    } else {
        [self loadUserTrunks];
    }
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    // Setup Empty Datasets
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.emptyDataSetSource = self;
}

-(void)loadUserTrunks
{
    if (self.meParseLocations == nil) {
        
        PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
        [query whereKey:@"toUser" equalTo:self.user];
        [query whereKey:@"type" equalTo:@"addToTrip"];
        [query whereKey:@"content" equalTo:self.city];
        [query includeKey:@"trip"];
        [query orderByDescending:@"mostRecentPhoto"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(error)
            {
                NSLog(@"Error: %@",error);
            }
            else
            {
                int count = 0;
                self.meParseLocations = [[NSMutableArray alloc]init];
                for (PFObject *activity in objects){
                    
                    Trip *trip = activity[@"trip"];
                    if (trip.name != nil){
                        [self.meParseLocations addObject:trip];
                        
                    }
                    count += 1;
                    if(count == objects.count){
                        self.filter.tag = 1;
                        [self.tableView reloadData];
                    }
                }
            }
            
        }];
    } else
    {
        [self.tableView reloadData];
    }
}

-(void)rightBarItemWasTapped {
    if (self.filter.tag == 0) {
        [self.filter setTitle:@"All Trunks"];
        [self queryParseMethodMe];
    } else if (self.filter.tag == 1) {
        [self.filter setTitle:@"My Trunks"];
        [self queryParseMethodEveryone];
    }
}

#pragma mark - Parse Queries

-(void)queryParseMethodMe
{
    if (self.meParseLocations == nil) {
        PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
        [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
        [query whereKey:@"type" equalTo:@"addToTrip"];
        [query whereKey:@"content" equalTo:self.city];
        [query includeKey:@"trip"];
        [query orderByDescending:@"mostRecentPhoto"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(error)
            {
                NSLog(@"Error: %@",error);
            }
            else
            {
                int count = 0;
                self.meParseLocations = [[NSMutableArray alloc]init];
                for (PFObject *activity in objects){
                    
                    Trip *trip = activity[@"trip"];
                    if (trip.name != nil){
                        [self.meParseLocations addObject:trip];

                    }
                    count += 1;
                    if(count == objects.count){
                            self.filter.tag = 1;
                            [self.tableView reloadData];
                    }
                }
            }
            
        }];
    } else{
        self.filter.tag = 1;
        [self.tableView reloadData];
    }
}

-(void)queryParseMethodEveryone{
    
    if (self.parseLocations == nil)
    {
        self.friends = [[NSMutableArray alloc]init];
        
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
        self.filter.tag = 0;
        [self.tableView reloadData];
    }

}

- (void)queryForTrunks{

    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" containedIn:self.friends];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query whereKey:@"content" equalTo:self.city];
    [query includeKey:@"trip"];
    [query includeKey:@"toUser"];
    [query orderByDescending:@"mostRecentPhoto"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            int count = 0;
            self.parseLocations = [[NSMutableArray alloc] init];
            for (PFObject *activity in objects)
            {
                Trip *trip = activity[@"trip"];


                if (trip.name != nil && ![self.objectIDs containsObject:trip.objectId])
                {
                    if (trip.isPrivate == YES)
                    {
                        PFUser *user = activity[@"toUser"];
                        if ([user.objectId isEqualToString:[PFUser currentUser].objectId])
                        {
                            [self.parseLocations addObject:trip];
                            [self.objectIDs addObject:trip.objectId];
                        }
                    
                    } else {
                        [self.parseLocations addObject:trip];
                        [self.objectIDs addObject:trip.objectId];

                    }
  
                }
                count += 1;
                if(count == objects.count){
                    self.filter.tag = 0;
                    [self.tableView reloadData];
                }
            }
        }
        else {
            NSLog(@"Error: %@",error);
        }
        
    }];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TrunkView"])
    {
        TrunkViewController *trunkView = segue.destinationViewController;
        
        if (self.parseLocations) {
            Trip *trip = [self.parseLocations objectAtIndex:self.path.row];
            trunkView.trip =trip;
        } else if (self.meParseLocations){
            Trip *trip = [self.meParseLocations objectAtIndex:self.path.row];
            trunkView.trip =trip;
        }
        self.path = nil;
    }
}

#pragma mark - UITableView Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.filter.tag == 0 && self.parseLocations !=nil) {
        return self.parseLocations.count;
    }else if (self.filter.tag == 1 && self.meParseLocations !=nil){
        return self.meParseLocations.count;
    }
    else  if (self.user != nil){
        return self.meParseLocations.count;
    } else {
        return 0;
    }
}

-(TrunkTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath

{
    TrunkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TripCell" forIndexPath:indexPath];
    Trip *trip = [[Trip alloc]init];
    
    if (self.filter.tag == 0 && self.user == nil) {
        trip = [self.parseLocations objectAtIndex:indexPath.row];
        
    } else {
        trip = [self.meParseLocations objectAtIndex:indexPath.row];
        
    }
    cell.trip = trip;
    cell.textLabel.text = trip.name;
    
    cell.detailTextLabel.text = cell.trip.user;
    
    
    NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:trip.mostRecentPhoto];
    
    
    if (tripInterval < 86400 && trip.mostRecentPhoto != NULL) {
        cell.backgroundColor = [UIColor colorWithRed:(228.0/255.0) green:(117.0/255.0) blue:(98.0/255.0) alpha:1];
    }
    else
    {
        cell.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
    }
    
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.path = indexPath;
    [self performSegueWithIdentifier:@"TrunkView" sender:self];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Trunks Here";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Have you visited this city? Create a trunk now!";
    
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
    
    return [[NSAttributedString alloc] initWithString:@"Create Trunk" attributes:attributes];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor colorWithWhite:0.0 alpha:0.5];
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
    if (self.filter.tag == 0 && self.parseLocations.count == 0) {
        // A little trick for removing the cell separators
        self.tableView.tableFooterView = [UIView new];
        return YES;
    }else if (self.filter.tag == 1 && self.meParseLocations.count == 0){
        // A little trick for removing the cell separators
        self.tableView.tableFooterView = [UIView new];
        return YES;
    }
    else  if (self.user == nil){
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
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tabBarController setSelectedIndex:1];
        
    });

}


- (void)dealloc
{
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}


@end
