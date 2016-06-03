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

@protocol AddMemberDelegate
-(void)memberWasAdded:(id)sender;
-(void)memberWasAddedTemporary:(PFUser*)profile;
-(void)memberFailedToLoad:(PFUser*)sender;
@end

@interface TTEditTripFriendsViewController : TTBaseViewController
- (id)initWithTrip:(Trip *)trip andExistingMembers:(NSArray *)members;

@property id<AddMemberDelegate> delegate;
@property (strong, nonatomic) Trip *trip;
@property (nonatomic)BOOL isTripCreation;
@property (strong, nonatomic) NSMutableArray *existingMembers;
@end
