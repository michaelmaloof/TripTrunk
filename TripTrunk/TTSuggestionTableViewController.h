//
//  TTSuggestionTableViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 2/19/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTSuggestionTableViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *suggestionsTable;

-(void)dismissThisStupidEffingViewController;
@end
