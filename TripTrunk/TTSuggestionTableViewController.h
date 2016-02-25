//
//  TTSuggestionTableViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 2/19/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark - TTSuggestionTableViewControllerDelegate
@protocol TTSuggestionTableViewControllerDelegate <NSObject>

/**
 *  Notifies the delegate that the tableview is empty and it should dismiss the popover from the view
 */
- (void)popoverViewControllerShouldDissmissWithNoResults;

/**
 *  Notifies the delegate to replace the typed text with an NSString
 *
 *  @param username The string to use as the replacement text
 */
- (void)insertUsernameAsMention:(NSString*)username;

/**
 *  Notifies the delegate to resize the height of the popover to match the number of users listed in the tableview
 *  Max size will be a table of 3 cells
 *  If number of cells is greater than 3, the table view will scroll
 *
 *  @param height The integer that the popover height should be set to 
 */
- (void)adjustPreferredHeightOfPopover:(NSUInteger)height;
@end


#pragma mark - TTSuggestionTableViewController
@interface TTSuggestionTableViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate>
/**
 *  Outlet to the UITableView in the storyboard
 */
@property (strong, nonatomic) IBOutlet UITableView *suggestionsTable;

/**
 *  NSString of the currently typed word in the UITextView or UITextField
 */
@property (strong, nonatomic) NSString *mentionText;

/**
 *  An NSArray of PFUsers to hold the list of followers and follingUsers
 */
@property (strong, nonatomic) NSMutableArray *friendsArray;

/**
 *  An NSArray of PFUsers to hold the usernames, firstName, or lastName that match mentionText
 *  This array is used to populate suggestionTable
 */
@property (strong, nonatomic) NSArray *displayFriendsArray;

/**
 *  Property for TTSuggestionTableViewControllerDelegate to talk to its delegates
 */
@property (assign) id <TTSuggestionTableViewControllerDelegate> delegate;

/**
 *  Builds the friends list from Parse following & followers using SocialUtility
 *
 *  @param completionBlock returns boolean of succeed or fail
 *  @param completionBlock returns error message if fail
 */
-(void)buildFriendsList:(void (^)(BOOL succeeded, NSError *error))completionBlock;

/**
 *  Updates the tableview that is displayed in the popover
 *
 */
-(void)updateAutocompleteTableView;

/**
 *  Calculated the width that popover should be displayed
 *  80% of screen width
 *
 */
-(NSUInteger)preferredWidthForPopover;

/**
 *  Calculates the height that the popover should be displayed
 *  Max height it 3 cells
 *  After 3 cells the tableview will scroll
 *
 */
-(NSUInteger)preferredHeightForPopover;

@end


