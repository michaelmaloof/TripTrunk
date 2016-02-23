//
//  TTSuggestionTableViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/19/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTSuggestionTableViewController.h"
#import "SocialUtility.h"
#import "PhotoViewController.h"

@interface TTSuggestionTableViewController()

@end

@implementation TTSuggestionTableViewController
@synthesize delegate;

-(void)viewDidLoad{
    [super viewDidLoad];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.displayFriendsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [self.suggestionsTable dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    PFUser *userToAdd = self.displayFriendsArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"@%@",userToAdd.username];
    NSLog(@"mention text: %@",self.mentionText);
    return cell;
}

-(void)buildFriendsList:(void (^)(BOOL, NSError *))completionBlock{
    self.friendsArray = [[NSMutableArray alloc] init];
    [SocialUtility followers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if(!error){
            [self.friendsArray addObjectsFromArray:users];
            [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error){
                if(!error){
                    for(PFUser *user in users){
                        if(![self.friendsArray containsObject:user]){
                            [self.friendsArray addObject:user];
                        }
                    }
                    
                    if(self.friendsArray.count > 0)
                        [self.suggestionsTable reloadData];
                    
                    NSLog(@"COUNT: %lu",(unsigned long)self.friendsArray.count);
                    completionBlock(YES, error);
                    
                }else{
                    NSLog(@"Error: %@",error);
                    completionBlock(NO, error);
                }
            }];
        }else{
            NSLog(@"Error: %@",error);
            completionBlock(NO, error);
        }
    }];
}

-(void)updateAutocompleteTableView{
    self.displayFriendsArray = [[NSArray alloc] init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username beginswith %@", [self.mentionText substringFromIndex:1]];
    self.displayFriendsArray = [self.friendsArray filteredArrayUsingPredicate:predicate];

    NSLog(@"PRED: %@",predicate);
    NSLog(@"DISPLAY COUNT: %lu",(unsigned long)self.displayFriendsArray.count);
    
    if(self.displayFriendsArray.count == 0 || self.displayFriendsArray == nil || isnan(self.displayFriendsArray.count)){
        if([self.delegate respondsToSelector:@selector(popoverViewControllerShouldDissmissWithNoResults)])
            [self.delegate popoverViewControllerShouldDissmissWithNoResults];
    }else{
        [self.suggestionsTable reloadData];
    }
}



@end
