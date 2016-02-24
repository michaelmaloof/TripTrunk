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
                        if(![self array:self.friendsArray containsPFObjectById:user]){
                            [self.friendsArray addObject:user];
                        }
                    }
                    
                    if(self.friendsArray.count > 0){
                        [self.suggestionsTable reloadData];
                    }
                    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([self.delegate respondsToSelector:@selector(insertUsernameAsMention:)]){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self.delegate insertUsernameAsMention:cell.textLabel.text];
    }
}

-(void)updateAutocompleteTableView{
    self.displayFriendsArray = [[NSArray alloc] init];

//    NSMutableArray *partPredicates = [NSMutableArray arrayWithCapacity:3];
//    NSPredicate *usernamePredicate = [NSPredicate predicateWithFormat:@"username beginswith %@", [self.mentionText substringFromIndex:1]];
//    NSPredicate *firstnamePredicate = [NSPredicate predicateWithFormat:@"firstName beginswith %@", [self.mentionText substringFromIndex:1]];
//    NSPredicate *lastnamePredicate = [NSPredicate predicateWithFormat:@"lastName beginswith %@", [self.mentionText substringFromIndex:1]];
//    [partPredicates addObject:usernamePredicate]; [partPredicates addObject:firstnamePredicate]; [partPredicates addObject:lastnamePredicate];
    
    NSMutableArray *partPredicates = [NSMutableArray arrayWithCapacity:2];
    NSPredicate *usernamePredicate = [NSPredicate predicateWithFormat:@"username beginswith %@", [self.mentionText substringFromIndex:1]];
    NSPredicate *firstnamePredicate = [NSPredicate predicateWithFormat:@"lowercaseName contains %@", [self.mentionText substringFromIndex:1]];
    [partPredicates addObject:usernamePredicate]; [partPredicates addObject:firstnamePredicate];


    NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:partPredicates];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"username beginswith %@", [self.mentionText substringFromIndex:1]];
    self.displayFriendsArray = [self.friendsArray filteredArrayUsingPredicate:predicate];
    
    //sort the Array alphabetically
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"username" ascending:YES];
    NSArray *sortedArray=[self.displayFriendsArray sortedArrayUsingDescriptors:@[sort]];
    self.displayFriendsArray = [NSArray arrayWithArray:sortedArray];
    
    //If no users are in the array, tell the delegate to dismiss the Popover
    if([self noUsersFound]){
        if([self.delegate respondsToSelector:@selector(popoverViewControllerShouldDissmissWithNoResults)])
            [self.delegate popoverViewControllerShouldDissmissWithNoResults];
    }else{
        //users are found so reload the table
        [self.suggestionsTable reloadData];
    }
}

- (BOOL) array:(NSArray *)array containsPFObjectById:(PFObject *)object{
    //Check if the object's objectId matches the objectId of any member of the array.
    for (PFObject *arrayObject in array){
        if ([[arrayObject objectId] isEqual:[object objectId]]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)noUsersFound{
    return self.displayFriendsArray.count == 0 || self.displayFriendsArray == nil || isnan(self.displayFriendsArray.count);
}

@end
