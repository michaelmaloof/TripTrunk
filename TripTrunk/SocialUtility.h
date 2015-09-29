//
//  SocialUtility.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/12/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Trip.h"
#import "Photo.h"

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
 *  CurrentUser requests to follow the given user
 *
 *  @param user            User to follow
 *  @param completionBlock callback with success or error of the REQUEST-not followed yet
 */
+ (void)requestToFollowUserInBackground:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock;

/**
 *  The Parse CurrentUser will unfollow the given User
 *
 *  @param user the user to unfollow
 */
+ (void)unfollowUser:(PFUser *)user;

/**
 *  The currentUser will block the given user
 *
 *  @param user User to block
 */
+ (void)blockUser:(PFUser *)user;

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
 *  Delete the trip and all related objects
 *  Everything is set to deleteEventually so it may take some time to actually delete
 *  Notifications are sent for each completed deletion with the names:
 *  "PhotoObjectsDeleted", "ActivityObjectsDeleted", and "TripDeleted"
 *  The controller calling deleteTrip should observe these notifications and reload the UI components accordingly
 *
 *  @param trip            Trip to delete
 */
+ (void)deleteTrip:(Trip *)trip;

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

/**
 *  Updates the Content field of all addToTrip Activity objects on Parse for the given Trip
 *
 *  @param string new content string
 *  @param trip   Trip needing update
 */
+ (void)updateActivityContent:(NSString *)string forTrip:(Trip *)trip;

/**
 *  Update the Photo objects on Parse for the given trip
 *  Useful when the Trip has been updated and we need to make sure the Photo objects reference the same trip info
 *
 *  @param trip Trip needing the update
 */
+ (void)updatePhotosForTrip:(Trip *)trip;

/**
 *  Adds a comment on the given photo
 *
 *  @param comment         Comment string
 *  @param photo           Photo object on which the comment is being written
 *  @param completionBlock completion handler callback
 */
+ (void)addComment:(NSString *)comment forPhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;

/**
 *  Retrieves the all of the Comment Activity objects for the given Photo
 *
 *  @param photo           Photo that we want the comments for
 *  @param completionBlock completion block with Activity object array and nullable error
 */
+ (void)getCommentsForPhoto:(Photo *)photo block:(void (^)(NSArray *objects, NSError *error))completionBlock;

/**
 *  Deletes a Comment Activity object on the given photo
 *
 *  @param commentActivity Activity for the comment that needs to be deleted
 *  @param photo           Photo containing the Activity
 *  @param completionBlock completion block with Success or Error
 */
+ (void)deleteComment:(PFObject *)commentActivity forPhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;


/**
 *  Adds a Like Activity from the current user on the given photo
 *
 *  @param photo           Photo that the user likes
 *  @param completionBlock completion block with success or error
 */
+ (void)likePhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;

/**
 *  Unlikes the given photo if the user already liked it
 *
 *  @param photo           Photo the user no longer likes
 *  @param completionBlock completion block with success or error
 */
+ (void)unlikePhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;

/**
 *  Creates a PFQuery for all activities on the given photo
 *
 *  @param photo       Photo to get activities for
 *  @param cachePolicy should we query the cache or just get from the internet?
 *
 *  @return PFQuery ready to execute
 */
+ (PFQuery *)queryForActivitiesOnPhoto:(PFObject *)photo cachePolicy:(PFCachePolicy)cachePolicy;

/**
 *  Gets all Activities for the current user
 *
 *  @param completionBlock Array of Activity objects or error
 */
+ (void)queryForAllActivities:(void (^)(NSArray *activities, NSError *error))completionBlock;

/**
 *  Gets the following status of one user to another
 *
 *  @param fromUser        User doing the following
 *  @param toUser          User to check if the other user follows
 *  @param completionBlock BOOL for following status or Error
 */
+ (void)followingStatusFromUser:(PFUser *)fromUser toUser:(PFUser *)toUser block:(void (^)(BOOL isFollowing, NSError *error))completionBlock;

/**
 *  Gets the list of users that the given user follows
 *
 *  @param user            User of which we want their following list
 *  @param completionBlock completion block with users array or error
 */
+ (void)followingUsers:(PFUser *)user block:(void (^)(NSArray *users, NSError *error))completionBlock;

/**
 *  Gets the list of users that follow a given user
 *
 *  @param user            User to find the followers of
 *  @param completionBlock completion block with users array or error
 */
+ (void)followers:(PFUser *)user block:(void (^)(NSArray *users, NSError *error))completionBlock;

/**
 *  Gets the count of followers a given user has
 *
 *  @param user            User of whom to get their follower count
 *  @param completionBlock block with count or error
 */
+ (void)followerCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;

/**
 *  Gets the count of users a given user is following
 *
 *  @param user            User of whom to get their following count
 *  @param completionBlock block with count or error
 */
+ (void)followingCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;

/**
 *  Gets the count of trunks a user is part of
 *
 *  @param user            User of whom to find their trunk count
 *  @param completionBlock block with count or error
 */
+ (void)trunkCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;


@end
