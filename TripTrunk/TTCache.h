//
//  TTCache.h
//  TripTrunk
//
//  Created by Matt Schoch on 8/6/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Photo.h"
#import "Trip.h"


@interface TTCache : NSObject

/**
 *  Singleton cache instance
 *
 *  @return returns the singleton cache
 */
+ (id)sharedCache;

/**
 *  Clears the cache & user defaults
 */
- (void)clear;


- (NSDictionary *)attributesForPhoto:(Photo *)photo;
- (NSArray *)commentersForPhoto:(Photo *)photo;

- (void)incrementCommentCountForPhoto:(Photo *)photo;
- (void)decrementCommentCountForPhoto:(Photo *)photo;

- (NSDictionary *)attributesForUser:(PFUser *)user;
- (NSNumber *)photoCountForUser:(PFUser *)user;
- (void)setPhotoCount:(NSNumber *)count user:(PFUser *)user;

#pragma mark - fully implemented
- (void)setAttributesForPhoto:(Photo *)photo likers:(NSArray *)likers commenters:(NSArray *)commenters likedByCurrentUser:(BOOL)likedByCurrentUser;
- (NSNumber *)likeCountForPhoto:(Photo *)photo;
- (NSArray *)likersForPhoto:(Photo *)photo;
- (void)setPhotoIsLikedByCurrentUser:(Photo *)photo liked:(BOOL)liked;
- (BOOL)isPhotoLikedByCurrentUser:(Photo *)photo;
- (void)incrementLikerCountForPhoto:(Photo *)photo;
- (void)decrementLikerCountForPhoto:(Photo *)photo;

- (NSNumber *)commentCountForPhoto:(Photo *)photo;


/**
 *  Set the cache for the current user's following status of another user
 *
 *  @param following YES or NO if the current user is following the given user
 *  @param user      user that might be followed
 */
- (void)setFollowStatus:(BOOL)following user:(PFUser *)user;

/**
 *  Get the cached follow status of the current user to another user
 *
 *  @param user user to check follow status
 *
 *  @return BOOL for isFollowing
 */
- (BOOL)followStatusForUser:(PFUser *)user;

/**
 *  Set the cache & user defaults for the promoted user list
 *
 *  @param users Array of PFUser objects
 */
- (void)setPromotedUsers:(NSArray *)users;

/**
 *  Get the cached promoted user list
 *
 *  @return Array of PFUser objects
 */
- (NSArray *)promotedUsers;

/**
 *  Set the cache & user defaults for the user's facebook friend list
 *
 *  @param friends Array of fbid strings
 */
- (void)setFacebookFriends:(NSArray *)friends;

/**
 *  Get the cached facebook friend list
 *
 *  @return Array of fbid strings
 */
- (NSArray *)facebookFriends;

/**
 *  Set the cache for the user's following list
 *
 *  @param following Array of PFUser objects
 */
- (void)setFollowing:(NSArray *)following;

/**
 *  Get the cached following list
 *
 *  @return Array of PFUser objects
 */
- (NSArray *)following;

/**
 *  Set the cache for the user's followers list
 *
 *  @param followers Array of PFUser objects
 */
- (void)setFollowers:(NSArray *)followers;

/**
 *  Get the cached followers list
 *
 *  @return Array of PFUser objects
 */
- (NSArray *)followers;

/**
 *  Set the cache for the current user's trips
 *
 *  @param trips Array of Trip objects
 */
- (void)setTrips:(NSArray *)trips;

/**
 *  Get the cached trip list for the current user
 *
 *  @return Array of Trip objects
 */
- (NSArray *)trips;

/**
 *  Set the cache of trip members on a trip
 *
 *  @param members Array of PFUser objects who are part of the trip
 *  @param trip    Trip object
 */
- (void)setMembers:(NSArray *)members forTrip:(Trip *)trip;

/**
 *  Get the cached members for the trip
 *
 *  @param trip trip
 *
 *  @return Array of PFUser objects
 */
- (NSArray *)membersForTrip:(Trip *)trip;

@end
