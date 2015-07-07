//
//  TrunkMembersViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/31/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "Trip.h"

@interface TrunkMembersViewController : UITableViewController
/**
 *  Initializer that sets the currently-being-created Trip so we know what trip to add the friends to
 *
 *  @param trip Trip custom parse object
 *
 *  @return self
 */
- (id)initWithTrip:(Trip *)trip;
@property BOOL isMember;
@end
