//
//  TTCitySearchResultsTableViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/23/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTCitySearchResultsTableViewController.h"
#import "TTCitySearchResultsTableViewCell.h"
#import "TTPlace.h"

@interface TTCitySearchResultsTableViewController ()
@property (strong, nonatomic) IBOutlet UITableView *resultsTable;
@property unsigned long popoverHeight;
@end

@implementation TTCitySearchResultsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.resultsTable.delegate = self;
    self.resultsTable.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count+1;
}


- (TTCitySearchResultsTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == self.searchResults.count) {
        // Last row - aka Google Attribution
        TTCitySearchResultsTableViewCell *attributionCell = [TTCitySearchResultsTableViewCell new];
        [attributionCell.imageView setImage:[UIImage imageNamed:@"google-attribution"]];
        [attributionCell setBackgroundColor:[UIColor clearColor]];
        [attributionCell.imageView setBackgroundColor:[UIColor clearColor]];
        return attributionCell;
    }

    static NSString *cellIdentifier = @"Cell";
    TTCitySearchResultsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) 
        cell = [[TTCitySearchResultsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    
    TTPlace *place = self.searchResults[indexPath.row];
    cell.name.text = place.name;
    return cell;
}




// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UITableViewDelegate
// On Row Selection, push to the user's profile
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row < self.searchResults.count){
        if (self.srdelegate && [self.srdelegate respondsToSelector:@selector(didSelectTableRow:)]){
            TTPlace *place = self.searchResults[indexPath.row];
            [self.srdelegate didSelectTableRow:place];
        }
    }else{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

-(void)reloadTable{
    [self.resultsTable reloadData];
}



//set the width of the popover
-(NSUInteger)preferredWidthForPopover{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    return screenRect.size.width * .80;
}

//Set the height of the popover
-(NSUInteger)preferredHeightForPopover{
    int cellSize = 44;
    if(self.searchResults.count == 0)
        return self.popoverHeight;
    
    self.popoverHeight = self.searchResults.count < 3 ? self.searchResults.count*cellSize : cellSize*3;
    return self.popoverHeight;
}


@end
