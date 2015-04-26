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

@interface TrunkListViewController () <UITableViewDelegate, UITableViewDataSource>
@property NSMutableArray *parseLocations;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
@implementation TrunkListViewController

-(void)viewDidLoad {
    self.parseLocations = [[NSMutableArray alloc]init];
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
    cell.detailTextLabel.text = trip.user;
    self.title = trip.city;

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


@end
