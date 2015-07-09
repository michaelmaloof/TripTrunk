//
//  SocialUtility.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/12/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Trip.h"

#import <Parse/Parse.h>

@interface SocialUtility : NSObject

/**
 *  CurrentUser will follow the given user, asychronous operation
 *
 *  @param user            User to follow
 *  @param completionBlock callback with success or error
 */
+ (void)followUserInBackground:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock;

/**
 *  The Parse CurrentUser will unfollow the given User
 *
 *  @param user the user to unfollow
 */
+ (void)unfollowUser:(PFUser *)user;

/**
 *  Adds a single user to a Trip, and also stores which user added them to that trip.
 *  In the future, this can support any user in a trip adding any other user to it, not just trip creators adding friends to the trip
 *
 *  @param user            PFUser object
 *  @param trip            Trip parse object
 *  @param completionBlock success or error
 */
+ (void)addUser:(PFUser *)user toTrip:(Trip *)trip block:(void (^)(BOOL succeeded, NSError *error))completionBlock;

/**
 *  Creates a PFObject for the Activity class that has the relation of a user in a trip.
 *  Works exactly like addUser:toTrip, except it doesn't actually save to Parse
 *  This method is so many users can be added to a trip and then saved in a batch operation
 *
 *  @param user PFUser object
 *  @param trip Trip parse object
 *
 *  @return PFObject, which is an Activity class
 */
+ (PFObject *)createAddToTripObjectForUser:(PFUser *)user onTrip:(Trip *)trip;

/**
 *  Removes the Parse Activity that added the given user to the given trip
 *  Enforces that a user can only remove themself unless they are the creator
 *  Does not enforce preventing creators from leaving their own trip--that must be done elsewhere
 *
 *  @param user            Trip Member that should be removed
 *  @param trip            Trip of which the user is a member
 *  @param completionBlock Callback with Success or Error
 */
+ (void)removeUser:(PFUser *)user fromTrip:(Trip *)trip block:(void (^)(BOOL succeeded, NSError *error))completionBlock;


@end
