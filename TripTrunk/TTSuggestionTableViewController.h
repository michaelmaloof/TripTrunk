//
//  TTSuggestionTableViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 2/19/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TTSuggestionTableViewControllerDelegate <NSObject>
- (void)popoverViewControllerShouldDissmissWithNoResults;
- (void)insertUsernameAsMention:(NSString*)username;
@end

@interface TTSuggestionTableViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *suggestionsTable;
@property (strong, nonatomic) NSString *mentionText;
@property (strong, nonatomic) NSMutableArray *friendsArray;
@property (strong, nonatomic) NSArray *displayFriendsArray;
@property (assign) id <TTSuggestionTableViewControllerDelegate> delegate;

-(void)buildFriendsList:(void (^)(BOOL succeeded, NSError *error))completionBlock;
-(void)updateAutocompleteTableView;

@end


