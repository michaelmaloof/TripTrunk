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
#import "TTSuggestionViewCell.h"
#import "TTUtility.h"

@interface TTSuggestionTableViewController()
@property unsigned long popoverHeight;
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
    TTSuggestionViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    PFUser *userToAdd = self.displayFriendsArray[indexPath.row];
//    cell.userFullName.text = [NSString stringWithFormat:@"%@ %@",userToAdd[@"name"],userToAdd[@"lastName"]];
    cell.userFullName.text = userToAdd[@"name"];
    cell.username.text = [NSString stringWithFormat:@"@%@ ",userToAdd.username];
    [self setProfilePic:userToAdd[@"profilePicUrl"] indexPath:indexPath];
    
    //stop the tableview from scrolling if the list has 3 or less
    self.suggestionsTable.scrollEnabled = [self preventTableViewFromScrolling];
    
    return cell;
}

//When the user selects a row, send the username to the delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([self.delegate respondsToSelector:@selector(insertUsernameAsMention:)]){
        PFUser *user = self.displayFriendsArray[indexPath.row];
        [self.delegate insertUsernameAsMention:[NSString stringWithFormat:@"@%@",user.username]];
    }else{
        NSLog(@"Delegate error: insertUsernameAsMention:");
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
    //[cd] in the predicate tells it to ignore case and diacritic
    NSMutableArray *partPredicates = [NSMutableArray arrayWithCapacity:3];
    NSPredicate *usernamePredicate = [NSPredicate predicateWithFormat:@"username beginswith[cd] %@", [self.mentionText substringFromIndex:1]];
    NSPredicate *firstnamePredicate = [NSPredicate predicateWithFormat:@"firstName beginswith[cd] %@", [self.mentionText substringFromIndex:1]];
    NSPredicate *lastnamePredicate = [NSPredicate predicateWithFormat:@"lastName beginswith[cd] %@", [self.mentionText substringFromIndex:1]];
    [partPredicates addObject:usernamePredicate]; [partPredicates addObject:firstnamePredicate]; [partPredicates addObject:lastnamePredicate];

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
        self.displayFriendsArray = nil;
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
    if(self.displayFriendsArray.count == 0)
        return self.popoverHeight;
    
    self.popoverHeight = self.displayFriendsArray.count < 3 ? self.displayFriendsArray.count*cellSize : 3;
    return self.popoverHeight;
}

//Determine if the table view should scroll. Only scroll if there are more than 3 users inthe table
-(BOOL)preventTableViewFromScrolling{
    return self.displayFriendsArray.count < 3 ? NO : YES;
}

-(NSString*)separateMentions:(NSString*)comment{
    if(![comment containsString:@"@"])
        return comment;
    
    NSArray *array = [comment componentsSeparatedByString:@"@"];
    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
    return [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
}

-(void)saveMentionToDatabase:(PFObject*)object comment:(NSString*)comment previousComment:(NSString*)previousComment photo:(Photo *)photo{
    //save mention to database
    NSArray *mentionList = [[NSArray alloc] initWithArray:[self commentMentionsWithUsernames:[self separateMentions:comment] previousComment:previousComment]];
    
    if (mentionList) {
        for(PFUser *user in mentionList){
            [SocialUtility addMention:object isCaption:YES withUser:user forPhoto:photo block:^(BOOL succeeded, NSError *error){
                if(succeeded)
                    NSLog(@"Mention added to db for %@",user.username);
                else NSLog(@"Error: %@", error);
            }];
        }
    }
    
}

-(NSArray*)commentMentionsWithUsernames:(NSString*)comment previousComment:(NSString*)previousComment{
    
    //quick check to see if the string contains an @ before we do regex
    if([comment containsString:@"@"]){
        NSMutableArray *array = [[NSMutableArray alloc] init];
        
        //create an array of every word in the comment
        NSArray *allWords = [comment componentsSeparatedByString:@" "];
        
        //Loop through all of the words
        for(NSString *word in allWords){
            //check if the word starts with a @
            if(![word isEqualToString:@""]){
                if([[word substringToIndex:1] isEqualToString:@"@"]){
                    //check to see if the user was already in the caption to prevent adding them to the db multiple times
                    if(![previousComment containsString:word]){
                        //load user from username
                        PFUser *mentionedUser = [SocialUtility loadUserFromUsername:[word substringFromIndex:1]];
                        //If the user is found, add it the array to return
                        if(mentionedUser)
                            [array addObject:mentionedUser];
                    }
                }
            }
        }
        
        //return an array with all of the mention usernames in the comment
        if(array.count > 0){
            NSArray *weededArray = [[NSSet setWithArray:array] allObjects];
            return weededArray;
        }
        
    }
    
    //there are no mentions, just return nil
    return nil;
}

-(void)removeMentionFromDatabase:(PFObject*)object comment:(NSString*)comment previousComment:(NSString*)previousComment{
    //remove mention from database
    NSArray *mentionList = [[NSArray alloc] initWithArray:[self removeMentionsWithUsernames:[self separateMentions:comment] previousComment:previousComment]];
    if (mentionList) {
        for(PFUser *user in mentionList){
            [SocialUtility deleteMention:object withUser:user block:^(BOOL succeeded, NSError *error){
                if(succeeded)
                    NSLog(@"Mention removed to db for %@",user.username);
                else NSLog(@"Error: %@", error);
            }];
        }
    }
    
}

-(NSArray*)removeMentionsWithUsernames:(NSString*)comment previousComment:(NSString*)previousComment{
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    //create an array of every word in the previous comment
    NSArray *allWords = [previousComment componentsSeparatedByString:@" "];
    
    //Loop through all of the words
    for(NSString *word in allWords){
        //check if the word starts with a @
        if(![word isEqualToString:@""]){
            if([[word substringToIndex:1] isEqualToString:@"@"]){
                //check to see if the user was in the previous comment and not in the current comment
                if(![comment containsString:word]){
                    //load user from username
                    PFUser *mentionedUser = [SocialUtility loadUserFromUsername:[word substringFromIndex:1]];
                    //If the user is found, add it the array to return
                    if(mentionedUser)
                        [array addObject:mentionedUser];
                }
            }
        }
    }
    
    //return an array with all of the mention usernames in the comment
    if(array.count > 0){
        NSArray *weededArray = [[NSSet setWithArray:array] allObjects];
        return weededArray;
    }
    
    //there are no mentions, just return nil
    return nil;
}

#pragma mark - REFACTOR THIS INTO IT"S OWN CLASS
- (void)setProfilePic:(NSString *)urlString indexPath:(NSIndexPath*)indexPath{
    NSURL *pictureURL = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:urlString]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:pictureURL];
    
    // Run network request asynchronously
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         if (connectionError == nil && data != nil) {
             
             // Set image on the UI thread
             dispatch_async(dispatch_get_main_queue(), ^{
                 TTSuggestionViewCell *cell = [self.suggestionsTable cellForRowAtIndexPath:indexPath];
                 cell.userPhoto.image = [[UIImage alloc] initWithData:data];
             });
             
         }
     }];
}

@end
