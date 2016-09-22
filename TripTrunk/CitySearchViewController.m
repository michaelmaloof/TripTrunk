//
//  CitySearchViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/8/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "CitySearchViewController.h"
#import "TTUtility.h"
#import "TTAnalytics.h"

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
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStylePlain target:self action:@selector(question)];
    
    //Button attributes
    NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFont16]};
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    
    // Add keyboard notifications so that the keyboard won't cover the table when searching
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

-(void)question{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Can't Find The City You Want?",@"Can't Find The City You Want?")
                                                    message:NSLocalizedString(@"For now please select the nearest city to the one you're looking for. We will notifiy users as new cities are added to the list.",@"For now please select the nearest city to the one you're looking for. We will notifiy users as new cities are added to the list.")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                          otherButtonTitles:nil, nil];
    alert.tag = 69;
    [alert show];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets.bottom = keyboardSize.height;
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets.bottom = 0;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    [self.tableView setNeedsLayout];
}

#pragma mark - Dismiss View

- (void)closeView
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    
    NSString *searchString = searchController.searchBar.text;

    [[TTUtility sharedInstance] locationsForSearch:searchString block:^(NSArray *objects, NSError *error) {
        
        if (error){
            [self handleError];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"updateSearchResultsForSearchController:"];
        }
        
        [_locations removeAllObjects];

        if (objects && objects.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_locations addObjectsFromArray: objects];
                [self.tableView reloadData];
            });
        }
    }];
}

-(void)handleError{
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = NSLocalizedString(@"Something Went Wrong :/",@"Something Went Wrong :/");
    alertView.message = NSLocalizedString(@"The search engine seems to have hiccuped. Please try again.",@"The search engine seems to have hiccuped. Please try again.");
    alertView.backgroundColor = [TTColor tripTrunkBlue];
    [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
    alertView.tag = 17;
    [alertView show];
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
        if (self.delegate && [self.delegate respondsToSelector:@selector(citySearchDidSelectLocation:)]) {
            [self.delegate citySearchDidSelectLocation:location];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
