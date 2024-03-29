//
//  SocialUtility.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/12/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "SocialUtility.h"
#import "TTCache.h"
#import "MBProgressHUD.h"

@implementation SocialUtility

+ (void)followUserInBackground:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if ([[user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        return;
    }
    // If the user is private then we should be REQUESTING to follow, not following.
    if (user[@"private"]) {
        [self requestToFollowUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (completionBlock) {
                return completionBlock(succeeded, error);
            }
        }];
    }
    else {
        PFObject *followActivity = [PFObject objectWithClassName:@"Activity"];
        [followActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
        [followActivity setObject:user forKey:@"toUser"];
        [followActivity setObject:@"follow" forKey:@"type"];
        
        PFACL *followACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [followACL setPublicReadAccess:YES];
        followActivity.ACL = followACL;
        
        [followActivity saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error saving follow activity%@", error);
            }
            
            // Cache the following status as FOLLOWED
            [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithBool:succeeded] user:user];
            
            if (completionBlock) {
                completionBlock(succeeded, error);
            }
        }];
    }
}

+ (void)requestToFollowUserInBackground:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if ([[user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        return;
    }
    
    PFObject *followActivity = [PFObject objectWithClassName:@"Activity"];
    [followActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
    [followActivity setObject:user forKey:@"toUser"];
    [followActivity setObject:@"pending_follow" forKey:@"type"];
    
    PFACL *followACL = [PFACL ACLWithUser:[PFUser currentUser]];
    // The user you're trying to follow gets read/write to the activity as well so they can approve/deny it.
    [followACL setReadAccess:YES forUser:user];
    [followACL setWriteAccess:YES forUser:user];
    followActivity.ACL = followACL;
    
    [followActivity saveEventually:^(BOOL succeeded, NSError *error) {

        // Cache the following status as PENDING
        [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithInt:2] user:user];
        
        if (completionBlock) {
            completionBlock(succeeded, error);
        }
    }];
}


+ (void)unfollowUser:(PFUser *)user
{
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [query whereKey:@"toUser" equalTo:user];
//    [query whereKey:@"type" equalTo:@"follow"];
    [query whereKey:@"type" containedIn:@[@"follow", @"pending_follow" ]]; // Pending Activities get unfollowed
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *followActivities, NSError *error) {
        // While normally there should only be one follow activity returned, we can't guarantee that.
        
        if (!error) {
            
            // Cache the following status as NOT FOLLOWING
            [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithBool:NO] user:user];
            
            for (PFObject *followActivity in followActivities) {
                [followActivity deleteEventually];
            }
        }
    }];
}

+ (void)acceptFollowRequest:(BOOL)accepted
                     fromUser:(PFUser *)user
                        block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            user.objectId, @"fromUserId",
                            [NSNumber numberWithBool:accepted], @"accepted", nil];
    
    [PFCloud callFunctionInBackground:@"approveFriend" withParameters:params
                                block:^(id  _Nullable success, NSError * _Nullable error) {
                                    NSLog(@"successs: %@", success);
                                    
                                    if (!error) {
                                        completionBlock(YES, error);
                                    }
                                }];
    
}

+ (void)blockUser:(PFUser *)user;
{
    __block MBProgressHUD *HUD;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = NSLocalizedString(@"Blocking...",@"Blocking...");
        HUD.mode = MBProgressHUDModeText; // change to Determinate to show progress
    });
    
    PFObject *block = [PFObject objectWithClassName:@"Block"];
    [block setObject:[PFUser currentUser] forKey:@"fromUser"];
    [block setObject:user forKey:@"blockedUser"];
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [acl setPublicReadAccess:YES];
    [acl setWriteAccess:YES forUser:[PFUser currentUser]];
    [block setACL:acl];
    
    [block saveEventually];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Hide HUD spinner
        HUD.labelText = NSLocalizedString(@"Done!",@"Done!");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        });
    });
}

+ (void)addUser:(PFUser *)user toTrip:(Trip *)trip block:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if ([[user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        return;
    }
    
    PFObject *addToTripActivity = [PFObject objectWithClassName:@"Activity"];
    [addToTripActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
    [addToTripActivity setObject:user forKey:@"toUser"];
    [addToTripActivity setObject:@"addToTrip" forKey:@"type"];
    [addToTripActivity setObject:trip forKey:@"trip"];
    
    PFACL *followACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [followACL setPublicReadAccess:YES];
    [followACL setWriteAccess:YES forUser:user]; // let's the user added to the trip remove themselves
    addToTripActivity.ACL = followACL;
    
    [addToTripActivity saveEventually:^(BOOL succeeded, NSError *error) {
        if (completionBlock) {
            completionBlock(succeeded, error);
        }
    }];
}

+ (PFObject *)createAddToTripObjectForUser:(PFUser *)user onTrip:(Trip *)trip
{
    //COMMENTED OUT because we are adding "self" as a member for easier querying
//    if ([[user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
//        return nil;
//    }
    
    NSString *location = [NSString stringWithFormat:@"%@", trip.city];
    
    PFObject *addToTripActivity = [PFObject objectWithClassName:@"Activity"];
    [addToTripActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
    [addToTripActivity setObject:user forKey:@"toUser"];
    [addToTripActivity setObject:@"addToTrip" forKey:@"type"];
    [addToTripActivity setObject:trip forKey:@"trip"];
    [addToTripActivity setObject:location forKey:@"content"];
    [addToTripActivity setValue:[NSNumber numberWithDouble:trip.lat] forKey:@"latitude"];
    [addToTripActivity setValue:[NSNumber numberWithDouble:trip.longitude] forKey:@"longitude"];
    
    PFACL *followACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [followACL setPublicReadAccess:YES];
    [followACL setWriteAccess:YES forUser:user]; // let's the user added to the trip remove themselves
    addToTripActivity.ACL = followACL;
    
    
    return addToTripActivity;
}

+ (void)deleteTrip:(Trip *)trip;
{
    // If the user isn't the trip creator, don't let them delete this trip
    if (![[[PFUser currentUser] objectId] isEqualToString:[trip.creator objectId]]) {
        return;
    }
    
    // Delete any activities that directly references this trip
    // That SHOULD include all addToTrip, like, and comment activities
    PFQuery *deleteActivitiesQuery = [PFQuery queryWithClassName:@"Activity"];
    [deleteActivitiesQuery whereKey:@"trip" equalTo:trip];

    [deleteActivitiesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             // The find succeeded.
             // Delete the found objects
             for (PFObject *object in objects) {
                 [object deleteEventually];
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivityObjectsDeleted" object:nil];
             
         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];
    
    // Delete all the photos for this trip
    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
    [photoQuery whereKey:@"trip" equalTo:trip];
    [photoQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             // The find succeeded.
             
             // Delete the found Photos
             for (PFObject *object in objects) {
                 [object deleteEventually];
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoObjectsDeleted" object:nil];

         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];

    // Delete the trip itself
    [trip deleteEventually];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TripDeleted" object:nil];


}

+ (void)removeUser:(PFUser *)user fromTrip:(Trip *)trip block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    // If the user isn't currentUser AND the user isn't the trip creator, don't let them remove people.
    // They can remove themselves no matter what, but only the creator can remove others.
    if (![[user objectId] isEqualToString:[[PFUser currentUser] objectId]] && ![[[PFUser currentUser] objectId] isEqualToString:[trip.creator objectId]]) {
        return;
    }
    
    // Also remove the User from the Trip's ACL.
    [trip.ACL setReadAccess:NO forUser:user];
    [trip.ACL setWriteAccess:NO forUser:user];
    [trip saveEventually];

    PFQuery *removeFromTripQuery = [PFQuery queryWithClassName:@"Activity"];
    [removeFromTripQuery whereKey:@"toUser" equalTo:user];
    [removeFromTripQuery whereKey:@"type" equalTo:@"addToTrip"];
    [removeFromTripQuery whereKey:@"trip" equalTo:trip];
    
    [removeFromTripQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             // The find succeeded.
             NSLog(@"Successfully retrieved %lu added-to-trip activities.", (unsigned long)objects.count);
             // Delete the found objects
             for (PFObject *object in objects) {
                 [object deleteInBackground];
             }
             completionBlock(YES, nil);

         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
             completionBlock(NO, error);
         }
     }];
}

+ (void)updateActivityContent:(NSString *)string forTrip:(Trip *)trip;
{
    PFQuery *updateQuery = [PFQuery queryWithClassName:@"Activity"];
    [updateQuery whereKey:@"type" equalTo:@"addToTrip"];
    [updateQuery whereKey:@"trip" equalTo:trip];
    [updateQuery setLimit:1000];
    [updateQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error) {
            NSLog(@"Successfully found Trip activities");
            // Delete the found objects
            NSMutableArray *objectsToUpdate = [[NSMutableArray alloc] init];
            for (PFObject *object in objects) {
                [object setValue:string forKey:@"content"];
                [object setValue:[NSNumber numberWithDouble:trip.lat] forKey:@"latitude"];
                [object setValue:[NSNumber numberWithDouble:trip.longitude] forKey:@"longitude"];

                [objectsToUpdate addObject:object];
            }
            [PFObject saveAllInBackground:objectsToUpdate block:^(BOOL succeeded, NSError * _Nullable error) {
                if (error){
                    
                }
            }];
            
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

+ (void)updatePhotosForTrip:(Trip *)trip;
{
    PFQuery *updateQuery = [PFQuery queryWithClassName:@"Photo"];
    [updateQuery whereKey:@"trip" equalTo:trip];
    [updateQuery setLimit:1000];
    [updateQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             NSLog(@"Successfully found Trip activities");
             // Delete the found objects
             NSMutableArray *objectsToUpdate = [[NSMutableArray alloc] init];
             for (PFObject *object in objects) {
                 [object setValue:trip.name forKey:@"tripName"];
                 [object setValue:trip.city forKey:@"city"];
                 [objectsToUpdate addObject:object];
             }
             [PFObject saveAllInBackground:objectsToUpdate];
             
         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];
}

+ (void)addComment:(NSString *)comment forPhoto:(Photo *)photo isCaption:(BOOL)isCaption block:(void (^)(BOOL, NSError *))completionBlock
{
    if ([comment isEqualToString:@""]) {
        if (completionBlock) {
            return completionBlock(false, nil);
        }
    }
    
    // Increment the cache count.
    [[TTCache sharedCache] incrementCommentCountForPhoto:photo];
    
    
    PFObject *commentActivity = [PFObject objectWithClassName:@"Activity"];
    [commentActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
    [commentActivity setObject:photo.user forKey:@"toUser"];
    [commentActivity setObject:photo forKey:@"photo"];
    [commentActivity setObject:photo.trip forKey:@"trip"];
    [commentActivity setObject:@"comment" forKey:@"type"];
    [commentActivity setObject:comment forKey:@"content"];
    [commentActivity setObject:[NSNumber numberWithBool:isCaption] forKey:@"isCaption"];
    
    // Permissions: commenter and photo owner can edit/delete comments.
    PFACL *commentACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [commentACL setWriteAccess:YES forUser:photo.user];
    [commentACL setPublicReadAccess:YES];
    commentActivity.ACL = commentACL;
    
    [commentActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            if (completionBlock) {
                completionBlock(succeeded, error);
            }
        }
        else {
            // Error, so decrement the cache count again.
            [[TTCache sharedCache] decrementCommentCountForPhoto:photo];
        }
    }];
}

+ (void)getCommentsForPhoto:(Photo *)photo block:(void (^)(NSArray *objects, NSError *error))completionBlock;
{
    // Query all user's that
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"photo" equalTo:photo];
    [query whereKey:@"type" equalTo:@"comment"];
    [query includeKey:@"fromUser"];
    [query orderByAscending:@"createdAt"];
    [query setLimit:1000];
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        completionBlock(objects, error);
    }];
}

+ (void)deleteComment:(PFObject *)commentActivity forPhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    [commentActivity deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        completionBlock(succeeded, error);
    }];
}

+ (void)likePhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    PFQuery *queryExistingLikes = [PFQuery queryWithClassName:@"Activity"];
    [queryExistingLikes whereKey:@"photo" equalTo:photo];
    [queryExistingLikes whereKey:@"type" equalTo:@"like"];
    [queryExistingLikes whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [queryExistingLikes setCachePolicy:kPFCachePolicyNetworkOnly];
    [queryExistingLikes findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        if (!error) {
            for (PFObject *activity in activities) {
                [activity delete];
            }
        }
        
        // proceed to creating new like
        PFObject *likeActivity = [PFObject objectWithClassName:@"Activity"];
        [likeActivity setObject:@"like" forKey:@"type"];
        [likeActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
        [likeActivity setObject:photo.user forKey:@"toUser"];
        [likeActivity setObject:photo forKey:@"photo"];
        [likeActivity setObject:photo.trip forKey:@"trip"];
        
        PFACL *likeACL = [PFACL ACLWithUser:[PFUser currentUser]];
        [likeACL setPublicReadAccess:YES];
        [likeACL setWriteAccess:YES forUser:photo.user];
        likeActivity.ACL = likeACL;
        
        [likeActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (completionBlock) {
                completionBlock(succeeded,error);
            }
        }];
    }];

}

+ (void)unlikePhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    PFQuery *queryExistingLikes = [PFQuery queryWithClassName:@"Activity"];
    [queryExistingLikes whereKey:@"photo" equalTo:photo];
    [queryExistingLikes whereKey:@"type" equalTo:@"like"];
    [queryExistingLikes whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [queryExistingLikes setCachePolicy:kPFCachePolicyNetworkOnly];
    [queryExistingLikes findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        if (!error) {
            for (PFObject *activity in activities) {
                [activity delete];
            }
            
            if (completionBlock) {
                completionBlock(YES,nil);
            }
        }
        else if (completionBlock) {
            completionBlock(NO,error);
        }
    }];
}

+ (PFQuery *)queryForActivitiesOnPhoto:(PFObject *)photo cachePolicy:(PFCachePolicy)cachePolicy;
{
    PFQuery *queryLikes = [PFQuery queryWithClassName:@"Activity"];
    [queryLikes whereKey:@"photo" equalTo:photo];
    [queryLikes whereKey:@"type" equalTo:@"like"];
    
    PFQuery *queryComments = [PFQuery queryWithClassName:@"Activity"];
    [queryComments whereKey:@"photo" equalTo:photo];
    [queryComments whereKey:@"type" equalTo:@"comment"];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryLikes,queryComments,nil]];
    [query setCachePolicy:cachePolicy];
    [query includeKey:@"fromUser"];
    [query includeKey:@"photo"];
    //Order by the time and then order by isCaption so that the caption is always first
    [query orderByAscending:@"createdAt"];
    [query orderByDescending:@"isCaption"];

    return query;
}

+ (void)queryForAllActivities:(NSInteger)count query:(void (^)(NSArray *, NSError *))completionBlock
{
    // Query all user's that
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [query whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:@"fromUser"];
    [query includeKey:@"fromUser"];
    [query includeKey:@"photo"];
    [query includeKey:@"trip"];
    [query includeKey:@"trip.publicTripDetail"];
    [query orderByDescending:@"createdAt"];
    query.limit = 20;
    query.skip = count;
    
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        completionBlock(objects, error);
    }];
}

//+ (void)addToTripActivities:(PFUser *)user forCity:(NSString*)city  {
//    
//    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
//    [query whereKey:@"toUser" equalTo:user];
//    [query whereKey:@"type" equalTo:@"addToTrip"];
//    [query includeKey:@"trip"];
//    
//    if (city && ![city isEqualToString: @""]) {
//        [query whereKey:@"content" equalTo:city];
//    }
//    
//}

+ (void)followingStatusFromUser:(PFUser *)fromUser toUser:(PFUser *)toUser block:(void (^)(NSNumber* followingStatus, NSError *error))completionBlock; {
    // Determine the follow status of the user
    PFQuery *isFollowingQuery = [PFQuery queryWithClassName:@"Activity"];
    [isFollowingQuery whereKey:@"fromUser" equalTo:fromUser];
    [isFollowingQuery whereKey:@"type" equalTo:@"follow"];
    [isFollowingQuery whereKey:@"toUser" equalTo:toUser];

    [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (error) {
            return completionBlock (0, error);
        }
        else if (!error && number > 0) {
            // Cache the user's follow status since we're checking if the current user follows someone else.
            // We don't cache if fromUser isn't the currentUser
            if ([fromUser.objectId isEqualToString:[PFUser currentUser].objectId]) {
                [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithBool:(!error && number > 0)] user:toUser];
            }
            return completionBlock([NSNumber numberWithInt:1], error);
        }
        // Not Following, so check if it's Pending before we return.
        else {
            PFQuery *isPendingQuery = [PFQuery queryWithClassName:@"Activity"];
            [isPendingQuery whereKey:@"fromUser" equalTo:fromUser];
            [isPendingQuery whereKey:@"type" equalTo:@"pending_follow"];
            [isPendingQuery whereKey:@"toUser" equalTo:toUser];
            [isPendingQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
                if (!error && number > 0) {
                    
                    // Cache the follow status.
                    if ([fromUser.objectId isEqualToString:[PFUser currentUser].objectId]) {
                        [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithInt:2] user:toUser];
                    }
                    
                    return completionBlock([NSNumber numberWithInt:2], error);
                }
                
                return completionBlock([NSNumber numberWithInt:0], error);
            }];
        }
    }];
    
}

+ (void)followingUsers:(PFUser *)user block:(void (^)(NSArray *users, NSError *error))completionBlock;{
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKey:@"fromUser" equalTo:user];
    [followingQuery whereKey:@"type" equalTo:@"follow"];
    [followingQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [followingQuery includeKey:@"toUser"];
    [followingQuery setLimit:1000];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
            completionBlock(nil, error);
        }
        else if (!error)
        {
            // Map the activity users into the friends array
            for (PFObject *activity in objects)
            {
                if (![user[@"fbid"]isEqualToString:user[@"username"]]){
                    PFUser *user = activity[@"toUser"];
                    [friends addObject:user];
                }
            }
            // Update the cache
            if (friends.count > 0) {
                [[TTCache sharedCache] setFollowing:friends];
            }
            
            completionBlock(friends, error);
        }
        
    }];
}

+ (void)pendingUsers:(PFUser *)user block:(void (^)(NSArray *users, NSError *error))completionBlock;
{
    NSMutableArray *friends = [[NSMutableArray alloc] init];

    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKey:@"fromUser" equalTo:user];
    [followingQuery whereKey:@"type" equalTo:@"pending_follow"];
    [followingQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [followingQuery includeKey:@"toUser"];
    [followingQuery setLimit:100];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
            completionBlock(nil, error);
        }
        else if (!error)
        {
            // Map the activity users into the friends array
            for (PFObject *activity in objects)
            {
                if (![user[@"fbid"]isEqualToString:user[@"username"]]){
                    PFUser *user = activity[@"toUser"];
                    [friends addObject:user];
                }
            }
            // Update the cache
            if (friends.count > 0) {
                [[TTCache sharedCache] setFollowing:friends];
            }
            
            completionBlock(friends, error);
        }
        
    }];
}

+ (void)followers:(PFUser *)user block:(void (^)(NSArray *users, NSError *error))completionBlock;
{
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"type" equalTo:@"follow"];
    [query whereKeyExists:@"fromUser"];
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    [query includeKey:@"fromUser"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
            completionBlock(nil, error);
        }
        else if (!error)
        {
            // Map the activity users into the friends array
            for (PFObject *activity in objects)
            {
                PFUser *user = activity[@"fromUser"];
                NSLog(@"name: %@", user.username);
                [friends addObject:user];
            }
            // Update the cache
            if (friends.count > 0) {
                [[TTCache sharedCache] setFollowers:friends];
            }
            
            completionBlock(friends, error);
        }
        
    }];
}

+ (void)followerCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;
{
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"fromUser" notEqualTo:user];
    [query whereKey:@"type" equalTo:@"follow"];
    [query whereKeyExists:@"fromUser"];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query setLimit:1000];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        
        completionBlock(number, error);
        
    }];
}

+ (void)followingCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;
{
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"fromUser" equalTo:user];
    [query whereKey:@"toUser" notEqualTo:user];
    [query whereKey:@"type" equalTo:@"follow"];
    [query whereKeyExists:@"toUser"];
    [query setLimit:1000];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        completionBlock(number, error);
        
    }];
}

+ (void)trunkCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;
{
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query setLimit:1000];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        completionBlock(number, error);
    }];
}

@end
