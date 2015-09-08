//
//  CitySearchViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/8/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "CitySearchViewController.h"
#import "TTUtility.h"

@interface CitySearchViewController () <UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) UISearchController *searchController;

@property (strong, nonatomic) NSMutableArray *locations;

@end

@implementation CitySearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Pick Location";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"LocationCell"];

    _locations = [[NSMutableArray alloc] init];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    [self.searchController.searchBar sizeToFit];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;

    // Set Done button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(closeView)];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Dismiss View

- (void)closeView
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [_locations removeAllObjects];
    
    NSString *searchString = searchController.searchBar.text;

    [[TTUtility sharedInstance] locationsForSearch:searchString block:^(NSArray *objects, NSError *error) {
        NSLog(@"Reponse Object Count: %lu", (unsigned long)objects.count);

        if (objects && objects.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_locations addObjectsFromArray: objects];
                [self.tableView reloadData];
            });
        }
    }];
}

/**
 *  Delegate method executed when the "Done" button is pressed
 */
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self closeView];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    return @"Suggestions";
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // When there's no results, it returns %s
    if (_locations.count == 1 && [[_locations objectAtIndex:0] isEqualToString:@"%s"]) {
        return 0;
    }
    
    return _locations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"LocationCell"];
    
    NSString *location = [_locations objectAtIndex:indexPath.row];
    
    if (![location isEqualToString:@"%s"]) {
        [cell.textLabel setText:location];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *location = [_locations objectAtIndex:indexPath.row];
    
    if (location) {
        NSLog(@"location chosen: %@", location);
        if (self.delegate && [self.delegate respondsToSelector:@selector(citySearchDidSelectLocation:)]) {
            [self.delegate citySearchDidSelectLocation:location];
        }
    }
}


@end
