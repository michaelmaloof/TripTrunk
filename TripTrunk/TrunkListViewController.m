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

@interface TrunkListViewController () <UITableViewDelegate, UITableViewDataSource>
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
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    self.filter =
    [[UIBarButtonItem alloc] initWithTitle:@"Me"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(rightBarItemWasTapped)];
    [[self navigationItem] setRightBarButtonItem:self.filter animated:NO];
    

    self.today = [NSDate date];

    self.title = self.city;
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"night"]];
    [tempImageView setFrame:self.tableView.frame];
    
    self.tableView.backgroundView = tempImageView;
    
    self.filter.tag = 1;
    
    self.objectIDs = [[NSMutableArray alloc]init];
    
    [self rightBarItemWasTapped];
    
}

-(void)viewDidAppear:(BOOL)animated{
    NSLog(@"%@", self.city);
}

-(void)rightBarItemWasTapped {
    if (self.filter.tag == 0) {
        [self.filter setTitle:@"Everyone"];
        [self queryParseMethodMe];
    } else if (self.filter.tag == 1) {
        [self.filter setTitle:@"Me"];
        [self queryParseMethodEveryone];
    }
}



-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.filter.tag == 0 && self.parseLocations !=nil) {
        return self.parseLocations.count;
    }else if (self.filter.tag == 1 && self.meParseLocations !=nil){
        return self.meParseLocations.count;
    }
    else {
        return 0;
    }
}

-(TrunkTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath

{
    TrunkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TripCell" forIndexPath:indexPath];
    Trip *trip = [[Trip alloc]init];
    
    if (self.filter.tag == 0) {
        trip = [self.parseLocations objectAtIndex:indexPath.row];

    } else {
        trip = [self.meParseLocations objectAtIndex:indexPath.row];

    }
    cell.detailTextLabel.hidden = YES;
    cell.trip = trip;
    cell.lockPhoto.hidden = YES;
    cell.textLabel.text = trip.name;
    

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

-(void)queryParseMethodMe
{
    if (self.meParseLocations == nil) {
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [followingQuery whereKey:@"type" equalTo:@"addToTrip"];
//    [followingQuery whereKey:@"content" equalTo:self.city];
    [followingQuery includeKey:@"trip"];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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
        [self.friends addObject:[PFUser currentUser]];
        PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
        [followingQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
        [followingQuery whereKey:@"type" equalTo:@"follow"];
//        [followingQuery whereKey:@"content" equalTo:self.city];
        [followingQuery includeKey:@"toUser"];
        [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
        }
        else if (!error)
        {
            int count = 0;
            for (PFObject *activity in objects)
            {
                PFUser *user = activity[@"toUser"];
                [self.friends addObject:user];
                count += 1;
                
                if(count == objects.count){
                    [self queryForTrunks];
                }
            }
        }
    }];
        
    } else
    {
        self.filter.tag = 0;
        [self.tableView reloadData];
    }

}

-(void)queryForTrunks{
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKey:@"toUser" containedIn:self.friends];
    [followingQuery whereKey:@"type" equalTo:@"addToTrip"];
    [followingQuery whereKey:@"content" equalTo:self.city];
    [followingQuery includeKey:@"trip"];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
        }
        else
        {
            int count = 0;
            self.parseLocations = [[NSMutableArray alloc]init];
            for (PFObject *activity in objects)
            {
                Trip *trip = activity[@"trip"];
                if (trip.name != nil && ![self.objectIDs containsObject:trip.objectId])
                {
                    [self.parseLocations addObject:trip];
                    [self.objectIDs addObject:trip.objectId];
  
                }
                count += 1;
                if(count == objects.count){
                    self.filter.tag = 0;
                    [self.tableView reloadData];
                }
            }
        }
        
    }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TrunkView"])
    {
        TrunkViewController *trunkView = segue.destinationViewController;
        Trip *trip = [self.parseLocations objectAtIndex:self.path.row];
        trunkView.trip =trip;
        self.path = nil;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.path = indexPath;
    [self performSegueWithIdentifier:@"TrunkView" sender:self];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
