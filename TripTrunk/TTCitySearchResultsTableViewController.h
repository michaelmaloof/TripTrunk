//
//  TTCitySearchResultsTableViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 5/23/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTPlace.h"

@protocol TTCitySearchResultsDelegate;

@interface TTCitySearchResultsTableViewController : UITableViewController <UITableViewDelegate>

@property (nonatomic, weak) id<TTCitySearchResultsDelegate> srdelegate;
@property (strong, nonatomic) NSArray *searchResults;

-(NSUInteger)preferredWidthForPopover;
-(NSUInteger)preferredHeightForPopover;
-(void)reloadTable;

@end

@protocol TTCitySearchResultsDelegate <NSObject>

@required
-(void)didSelectTableRow:(TTPlace*)selectedCity;

@end
