//
//  AddTripFriendsViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/29/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "Trip.h"
#import "TTBaseTableViewController.h"

@protocol MemberDelegate
-(void)memberWasAdded:(id)sender;
-(void)memberWasAddedTemporary:(PFUser*)profile;
-(void)memberFailedToLoad:(id)sender;



@end

@interface AddTripFriendsViewController : TTBaseTableViewController

/**
 *  Initializer that sets the currently-being-created Trip so we know what trip to add the friends to
 *
 *  @param trip Trip custom parse object
 *  @param members Array of members currently in the trip
 *
 *  @return self
 */
- (id)initWithTrip:(Trip *)trip andExistingMembers:(NSArray *)members;

@property id<MemberDelegate> delegate;


@property (strong, nonatomic) Trip *trip;

@property (nonatomic)BOOL isTripCreation;

@end




