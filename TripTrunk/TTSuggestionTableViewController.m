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

#pragma mark - UITableViewDelegate and DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.displayFriendsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [self.suggestionsTable dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    PFUser *userToAdd = self.displayFriendsArray[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"@%@",userToAdd.username];
    
    //stop the tableview from scrolling if the list has 3 or less
    self.suggestionsTable.scrollEnabled = [self preventTableViewFromScrolling];
    
    return cell;
}

//When the user selects a row, send the username to the delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([self.delegate respondsToSelector:@selector(insertUsernameAsMention:)]){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self.delegate insertUsernameAsMention:cell.textLabel.text];
    }
}

#pragma mark - Private Methods
-(void)buildFriendsList:(void (^)(BOOL, NSError *))completionBlock{
    self.friendsArray = [[NSMutableArray alloc] init];
    //Ask SocialUtility to return this user's followers
    [SocialUtility followers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        if(!error){
            //Add ALL users to the array. This list should be the bigger of the two lists so take all of these users
            //and weed out the followingUsers since it will be a smaller list
            [self.friendsArray addObjectsFromArray:users];
            //Ask SocialUtility to return this user's followingUsers
            [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error){
                if(!error){
                    //Loop through all of the followingUsers
                    for(PFUser *user in users){
                        //Check to see if the user is in the array already
                        if(![self array:self.friendsArray containsPFObjectById:user]){
                            //if not, add the user to the array
                            [self.friendsArray addObject:user];
                        }
                    }
                    
                    //If the list isn't empty, reload the tableview
                    if(self.friendsArray.count > 0){
                        [self.suggestionsTable reloadData];
                    }
                    
                    //tell the block to finish with success
                    completionBlock(YES, error);
                    
                }else{
                    //tell the block to finish with failure
                    completionBlock(NO, error);
                }
            }];
        }else{
            //tell the block to finish with failure
            completionBlock(NO, error);
        }
    }];
}

//Update the tableview that is displayed within the popover
-(void)updateAutocompleteTableView{
    self.displayFriendsArray = [[NSArray alloc] init];
    //Create an array of predicates so a user can search by username and first & last name
//    NSMutableArray *partPredicates = [NSMutableArray arrayWithCapacity:3];
//    NSPredicate *usernamePredicate = [NSPredicate predicateWithFormat:@"username beginswith %@", [self.mentionText substringFromIndex:1]];
//    NSPredicate *firstnamePredicate = [NSPredicate predicateWithFormat:@"firstName beginswith %@", [self.mentionText substringFromIndex:1]];
//    NSPredicate *lastnamePredicate = [NSPredicate predicateWithFormat:@"lastName beginswith %@", [self.mentionText substringFromIndex:1]];
//    [partPredicates addObject:usernamePredicate]; [partPredicates addObject:firstnamePredicate]; [partPredicates addObject:lastnamePredicate];
    
    NSMutableArray *partPredicates = [NSMutableArray arrayWithCapacity:2];
    NSPredicate *usernamePredicate = [NSPredicate predicateWithFormat:@"username beginswith %@", [self.mentionText substringFromIndex:1]];
    NSPredicate *firstnamePredicate = [NSPredicate predicateWithFormat:@"lowercaseName contains %@", [self.mentionText substringFromIndex:1]];
    [partPredicates addObject:usernamePredicate]; [partPredicates addObject:firstnamePredicate];

    //Set the predicate to the array of predicates
    NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:partPredicates];
    //Filter the array for only users that match the predicate
    self.displayFriendsArray = [self.friendsArray filteredArrayUsingPredicate:predicate];
    
    //sort the Array alphabetically
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"username" ascending:YES];
    NSArray *sortedArray=[self.displayFriendsArray sortedArrayUsingDescriptors:@[sort]];
    self.displayFriendsArray = [NSArray arrayWithArray:sortedArray];
    
    //tell the delegate that it should adjust the size of the popover based on content
    if([self.delegate respondsToSelector:@selector(adjustPreferredHeightOfPopover:)])
        [self.delegate adjustPreferredHeightOfPopover:[self preferredHeightForPopover]];
    
    //If no users are in the array, tell the delegate to dismiss the Popover
    if([self noUsersFound]){
        if([self.delegate respondsToSelector:@selector(popoverViewControllerShouldDissmissWithNoResults)])
            [self.delegate popoverViewControllerShouldDissmissWithNoResults];
    }else{
        //users are found so reload the table
        [self.suggestionsTable reloadData];
    }
}

//Check if the object's objectId matches the objectId of any member of the array.
- (BOOL) array:(NSArray *)array containsPFObjectById:(PFObject *)object{
    for (PFObject *arrayObject in array){
        if ([[arrayObject objectId] isEqual:[object objectId]]) {
            return YES;
        }
    }
    return NO;
}

//Determine if the table view will be empty
-(BOOL)noUsersFound{
    return self.displayFriendsArray.count == 0 || self.displayFriendsArray == nil || isnan(self.displayFriendsArray.count);
}

//set the width of the popover
-(NSUInteger)preferredWidthForPopover{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    return screenRect.size.width * .80;
}

//Set the height of the popover
-(NSUInteger)preferredHeightForPopover{
    int cellSize = 44;
    return self.displayFriendsArray.count < 3 ? self.displayFriendsArray.count*cellSize : 3;
}

//Determine if the table view should scroll. Only scroll if there are more than 3 users inthe table
-(BOOL)preventTableViewFromScrolling{
    return self.displayFriendsArray.count < 3 ? NO : YES;
}

@end
