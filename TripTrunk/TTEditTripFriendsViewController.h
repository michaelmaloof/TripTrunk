//
//  TTEditTripFriendsViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 6/2/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "Trip.h"
#import "TTBaseViewController.h"

@protocol EditMemberDelegate
-(void)memberWasAdded:(id)sender;
-(void)memberWasAddedTemporary:(PFUser*)profile;
-(void)memberFailedToLoad:(PFUser*)sender;
@optional
-(void)membersAdded:(NSArray*)users;
-(void)membersAddFailed:(NSArray*)users;
@end

@interface TTEditTripFriendsViewController : TTBaseViewController
- (id)initWithTrip:(Trip *)trip andExistingMembers:(NSArray *)members;

@property id<EditMemberDelegate> delegate;
@property (strong, nonatomic) Trip *trip;
@property (nonatomic)BOOL isTripCreation;
@property (strong, nonatomic) NSMutableArray *existingMembers;
@end
