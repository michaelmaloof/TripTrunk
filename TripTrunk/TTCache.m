//
//  TTCache.m
//  TripTrunk
//
//  Created by Matt Schoch on 8/6/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//
//  Heavily copied from Parse Anypic
//

#import "TTCache.h"

NSString *const kTTUserDefaultsCacheFacebookFriendsKey      = @"com.triptrunk.TripTrunk.userDefaults.cache.friends";
NSString *const kTTUserDefaultsCachePromotedUsersKey        = @"com.triptrunk.TripTrunk.userDefaults.cache.promotedUsers";
NSString *const kTTFollowingKey                             = @"followingUsers";
NSString *const kTTFollowersKey                             = @"usersWhoFollow";
NSString *const kTTUserTripsKey                             = @"userTripsKey";

NSString *const kTTPhotoAttributesIsLikedByCurrentUserKey = @"isLikedByCurrentUser";
NSString *const kTTPhotoAttributesLikeCountKey            = @"likeCount";
NSString *const kTTPhotoAttributesLikersKey               = @"likers";
NSString *const kTTPhotoAttributesCommentCountKey         = @"commentCount";
NSString *const kTTPhotoAttributesCommentersKey           = @"commenters";

NSString *const kTTUserAttributesPhotoCountKey                 = @"photoCount";
NSString *const kTTUserAttributesIsFollowedByCurrentUserKey    = @"isFollowedByCurrentUser";

NSString *const kTTTripAttributesMembers                    = @"tripMembers";



@interface TTCache ()

@property (nonatomic, strong) NSCache *cache;
- (void)setAttributes:(NSDictionary *)attributes forPhoto:(Photo *)photo;

@end

@implementation TTCache

#pragma mark - Initialization

+ (id)sharedCache {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark - TTCache

- (void)clear {
    [self.cache removeAllObjects];
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];

}

- (void)setAttributesForPhoto:(Photo *)photo likers:(NSArray *)likers commenters:(NSArray *)commenters likedByCurrentUser:(BOOL)likedByCurrentUser {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:likedByCurrentUser],kTTPhotoAttributesIsLikedByCurrentUserKey,
                                @([likers count]),kTTPhotoAttributesLikeCountKey,
                                likers,kTTPhotoAttributesLikersKey,
                                @([commenters count]),kTTPhotoAttributesCommentCountKey,
                                commenters,kTTPhotoAttributesCommentersKey,
                                nil];
    [self setAttributes:attributes forPhoto:photo];
}

- (NSDictionary *)attributesForPhoto:(Photo *)photo {
    NSString *key = [self keyForPhoto:photo];
    return [self.cache objectForKey:key];
}

- (NSNumber *)commentCountForPhoto:(Photo *)photo {
    NSDictionary *attributes = [self attributesForPhoto:photo];
    if (attributes) {
        return [attributes objectForKey:kTTPhotoAttributesCommentCountKey];
    }
    
    return [NSNumber numberWithInt:0];
}

- (NSArray *)commentersForPhoto:(Photo *)photo {
    NSDictionary *attributes = [self attributesForPhoto:photo];
    if (attributes) {
        return [attributes objectForKey:kTTPhotoAttributesCommentersKey];
    }
    
    return [NSArray array];
}
- (void)incrementCommentCountForPhoto:(Photo *)photo {
    NSNumber *commentCount = [NSNumber numberWithInt:[[self commentCountForPhoto:photo] intValue] + 1];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForPhoto:photo]];
    [attributes setObject:commentCount forKey:kTTPhotoAttributesCommentCountKey];
    [self setAttributes:attributes forPhoto:photo];
}

- (void)decrementCommentCountForPhoto:(Photo *)photo {
    NSNumber *commentCount = [NSNumber numberWithInt:[[self commentCountForPhoto:photo] intValue] - 1];
    if ([commentCount intValue] < 0) {
        return;
    }
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForPhoto:photo]];
    [attributes setObject:commentCount forKey:kTTPhotoAttributesCommentCountKey];
    [self setAttributes:attributes forPhoto:photo];
}

- (void)setAttributesForUser:(PFUser *)user photoCount:(NSNumber *)count followedByCurrentUser:(BOOL)following {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                count,kTTUserAttributesPhotoCountKey,
                                [NSNumber numberWithBool:following],kTTUserAttributesIsFollowedByCurrentUserKey,
                                nil];
    [self setAttributes:attributes forUser:user];
}

- (NSDictionary *)attributesForUser:(PFUser *)user {
    NSString *key = [self keyForUser:user];
    return [self.cache objectForKey:key];
}

- (NSNumber *)photoCountForUser:(PFUser *)user {
    NSDictionary *attributes = [self attributesForUser:user];
    if (attributes) {
        NSNumber *photoCount = [attributes objectForKey:kTTUserAttributesPhotoCountKey];
        if (photoCount) {
            return photoCount;
        }
    }
    
    return [NSNumber numberWithInt:0];
}

- (void)setPhotoCount:(NSNumber *)count user:(PFUser *)user {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
    [attributes setObject:count forKey:kTTUserAttributesPhotoCountKey];
    [self setAttributes:attributes forUser:user];
}


#pragma mark - Photo Likes

- (NSNumber *)likeCountForPhoto:(Photo *)photo {
    NSDictionary *attributes = [self attributesForPhoto:photo];
    if (attributes) {
        return [attributes objectForKey:kTTPhotoAttributesLikeCountKey];
    }
    
    return [NSNumber numberWithInt:0];
}

- (NSArray *)likersForPhoto:(Photo *)photo {
    NSDictionary *attributes = [self attributesForPhoto:photo];
    if (attributes) {
        return [attributes objectForKey:kTTPhotoAttributesLikersKey];
    }
    
    return [NSArray array];
}

- (void)setPhotoIsLikedByCurrentUser:(Photo *)photo liked:(BOOL)liked {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForPhoto:photo]];
    [attributes setObject:[NSNumber numberWithBool:liked] forKey:kTTPhotoAttributesIsLikedByCurrentUserKey];
    [self setAttributes:attributes forPhoto:photo];
}

- (BOOL)isPhotoLikedByCurrentUser:(Photo *)photo {
    NSDictionary *attributes = [self attributesForPhoto:photo];
    if (attributes) {
        return [[attributes objectForKey:kTTPhotoAttributesIsLikedByCurrentUserKey] boolValue];
    }
    
    return NO;
}

- (void)incrementLikerCountForPhoto:(Photo *)photo {
    NSNumber *likerCount = [NSNumber numberWithInt:[[self likeCountForPhoto:photo] intValue] + 1];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForPhoto:photo]];
    [attributes setObject:likerCount forKey:kTTPhotoAttributesLikeCountKey];
    [self setAttributes:attributes forPhoto:photo];
}

- (void)decrementLikerCountForPhoto:(Photo *)photo {
    NSNumber *likerCount = [NSNumber numberWithInt:[[self likeCountForPhoto:photo] intValue] - 1];
    if ([likerCount intValue] < 0) {
        return;
    }
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForPhoto:photo]];
    [attributes setObject:likerCount forKey:kTTPhotoAttributesLikeCountKey];
    [self setAttributes:attributes forPhoto:photo];
}


#pragma mark - Follower/following

- (void)setFollowStatus:(NSNumber *)following user:(PFUser *)user {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForUser:user]];
    [attributes setObject:following forKey:kTTUserAttributesIsFollowedByCurrentUserKey];
    [self setAttributes:attributes forUser:user];
}

- (NSNumber *)followStatusForUser:(PFUser *)user {
    NSDictionary *attributes = [self attributesForUser:user];
    if (attributes) {
        NSNumber *followStatus = [attributes objectForKey:kTTUserAttributesIsFollowedByCurrentUserKey];
        if (followStatus) {
            return followStatus;
        }
    }
    
    return 0;
}

- (void)setPromotedUsers:(NSArray *)users {

    
    // This should work fine, but it crashes because PFObject doesn't implement NSCoding.
    // Once that is fixed (we'll need to extend PFObject probably) then this will work fine - just delete the return above.
    NSString *key = kTTUserDefaultsCachePromotedUsersKey;

    [self.cache setObject:users forKey:key];
//
    return;
    
    //TODO: Implement NSCoding so this will work
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:users];

    [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)promotedUsers {
    

    NSString *key = kTTUserDefaultsCachePromotedUsersKey;
    if ([self.cache objectForKey:key]) {
        return [self.cache objectForKey:key];
    }
    
    return [NSArray array];
    
    // TODO: implement NSCoding on the user object array so this can work
    
    // All this "works", but will crash because PFObject doesn't implement nscoding. If that is fixed then this will work fine, just delete the return above.
    
    if ([self.cache objectForKey:key]) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:[self.cache objectForKey:key]];
    }
    
    NSArray *users = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
    
    if (users) {
        [self.cache setObject:users forKey:key];
    }
    
    return users;
}

- (void)setFacebookFriends:(NSArray *)friends {
    NSString *key = kTTUserDefaultsCacheFacebookFriendsKey;
    [self.cache setObject:friends forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:friends forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)facebookFriends {
    NSString *key = kTTUserDefaultsCacheFacebookFriendsKey;
    if ([self.cache objectForKey:key]) {
        return [self.cache objectForKey:key];
    }
    
    NSArray *friends = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if (friends) {
        [self.cache setObject:friends forKey:key];
    }
    
    return friends;
}

- (void)setFollowing:(NSArray *)following;
{
    NSString *key = kTTFollowingKey;
    [self.cache setObject:following forKey:key];
}

- (NSArray *)following;
{
    NSString *key = kTTFollowingKey;
    if ([self.cache objectForKey:key]) {
        return [self.cache objectForKey:key];
    }
    
    NSArray *friends = [NSArray array];
    
    return friends;
}

- (void)setFollowers:(NSArray *)followers;
{
    NSString *key = kTTFollowersKey;
    [self.cache setObject:followers forKey:key];
}

- (NSArray *)followers;
{
    NSString *key = kTTFollowersKey;
    if ([self.cache objectForKey:key]) {
        return [self.cache objectForKey:key];
    }
    
    NSArray *friends = [NSArray array];
    
    return friends;
}

#pragma mark - Trips

- (NSDictionary *)attributesForTrip:(Trip *)trip {
    NSString *key = [self keyForTrip:trip];
    return [self.cache objectForKey:key];
}

- (void)setTrips:(NSArray *)trips {
    NSString *key = kTTUserTripsKey;
    [self.cache setObject:trips forKey:key];
}

- (NSArray *)trips {
    NSString *key = kTTUserTripsKey;
    if ([self.cache objectForKey:key]) {
        return [self.cache objectForKey:key];
    }
    
    NSArray *trips = [NSArray array];
    
    return trips;
}

- (void)setMembers:(NSArray *)members forTrip:(Trip *)trip;
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:[self attributesForTrip:trip]];
    [attributes setObject:members forKey:kTTTripAttributesMembers];
    [self setAttributes:attributes forTrip:trip];
}

- (NSArray *)membersForTrip:(Trip *)trip;
{
    NSDictionary *attributes = [self attributesForTrip:trip];
    if (attributes) {
        return [attributes objectForKey:kTTTripAttributesMembers];
    }
    
    return [NSArray array];
}

#pragma mark - ()

- (void)setAttributes:(NSDictionary *)attributes forPhoto:(Photo *)photo {
    NSString *key = [self keyForPhoto:photo];
    [self.cache setObject:attributes forKey:key];
}

- (void)setAttributes:(NSDictionary *)attributes forUser:(PFUser *)user {
    NSString *key = [self keyForUser:user];
    [self.cache setObject:attributes forKey:key];
}

- (void)setAttributes:(NSDictionary *)attributes forTrip:(Trip *)trip {
    NSString *key = [self keyForTrip:trip];
    [self.cache setObject:attributes forKey:key];
}

- (NSString *)keyForPhoto:(Photo *)photo {
    return [NSString stringWithFormat:@"photo_%@", [photo objectId]];
}

- (NSString *)keyForUser:(PFUser *)user {
    return [NSString stringWithFormat:@"user_%@", [user objectId]];
}

- (NSString *)keyForTrip:(Trip *)trip {
    return [NSString stringWithFormat:@"trip_%@", [trip objectId]];
}

@end
