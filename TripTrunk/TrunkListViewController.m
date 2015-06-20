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
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSIndexPath *path;
@property NSDate *today;
@property UIBarButtonItem *filter;


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
    
    self.filter.tag = 0;
    self.parseLocations = [[NSMutableArray alloc]init];

    [self queryParseMethodMe]; //change to everyone later
    self.filter.tag = 0;

    
}

-(void)viewDidAppear:(BOOL)animated{
    
}

-(void)rightBarItemWasTapped {
    
    if (self.filter.tag == 0) {
        [self.filter setTitle:@"Everyone"];
        self.filter.tag = 1;
        [self queryParseMethodMe];
    } else {
        [self.filter setTitle:@"Me"];
        self.filter.tag = 0;
        [self queryParseMethodEveryone];
        
    }
}



-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.parseLocations.count;
}

-(TrunkTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath

{
    TrunkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TripCell" forIndexPath:indexPath];
    Trip *trip = [self.parseLocations objectAtIndex:indexPath.row];
    NSLog(@"trip name = %@", trip.name);
    NSLog(@"trip most recent photo = %@", trip.mostRecentPhoto);
    cell.detailTextLabel.hidden = YES;
    cell.trip = trip;
    cell.lockPhoto.hidden = YES;
    cell.textLabel.text = trip.name;

    

    NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:trip.mostRecentPhoto];
    NSLog(@"today = %@", self.today);
    NSLog(@"trip interval = %f", tripInterval);

    if (tripInterval < 86400 && trip.mostRecentPhoto != NULL) {
        cell.backgroundColor = [UIColor colorWithRed:(228.0/255.0) green:(117.0/255.0) blue:(98.0/255.0) alpha:1];
    }
    else
    {
        cell.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
    }
    
    NSLog(@"title = %@", cell.textLabel.text);


    return cell;
}

-(void)queryParseMethodMe
{
    NSString *user = [PFUser currentUser].username;
    PFQuery *findTrip = [PFQuery queryWithClassName:@"Trip"];
    [findTrip whereKey:@"user" equalTo:user];
    [findTrip whereKey:@"city" equalTo:self.city];

    [findTrip findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            self.parseLocations = [NSMutableArray arrayWithArray:objects];
//            PFQuery *memberQuery = [PFQuery queryWithClassName:@"Activity"];
//            [memberQuery whereKey:@"city" equalTo:self.city];
//            [memberQuery whereKey:@"type" equalTo:@"addToTrip"];
//            [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
//            [memberQuery includeKey:@"toUser"];
//Need to add City Filter to activity
            [self.tableView reloadData];

        }else
        {
            NSLog(@"Error: %@",error);
        }
        
    }];
    

}

-(void)queryParseMethodEveryone{
    NSString *user = [PFUser currentUser].username;
    PFQuery *findTrip = [PFQuery queryWithClassName:@"Trip"];
    [findTrip whereKey:@"user" equalTo:user];
    [findTrip whereKey:@"city" equalTo:self.city];
    
    [findTrip findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            self.parseLocations = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
            
        }else
        {
            NSLog(@"Error: %@",error);
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
