//
//  TTSuggestionTableViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/19/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTSuggestionTableViewController.h"

@implementation TTSuggestionTableViewController


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [self.suggestionsTable dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = @"Hello World!";
    return cell;
}

-(void)dismissThisStupidEffingViewController{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
