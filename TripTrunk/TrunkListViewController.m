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

@end
@implementation TrunkListViewController

-(void)viewDidLoad {
    self.parseLocations = [[NSMutableArray alloc]init];
    self.today = [NSDate date];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    self.title = self.city;

    
     [self queryParseMethod];

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.parseLocations.count;
}

-(TrunkTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath

{
    TrunkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TripCell" forIndexPath:indexPath];
    Trip *trip = [self.parseLocations objectAtIndex:indexPath.row];
    cell.trip = trip;
    cell.textLabel.text = trip.name;
    if (cell.trip.isPrivate == NO)
    {
        cell.detailTextLabel.text = @"";
    } else
    {
       cell.detailTextLabel.text = @"private";
    }

    NSTimeInterval tripInterval = [self.today timeIntervalSinceDate:trip.mostRecentPhoto];
    if (tripInterval < 86400) {
        cell.backgroundColor = [UIColor redColor];
    }
    
    else
    {
        cell.backgroundColor = [UIColor blueColor];
    }

    return cell;
}

-(void)queryParseMethod
{
    
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
