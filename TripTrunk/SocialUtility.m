//
//  SocialUtility.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/12/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "SocialUtility.h"

@implementation SocialUtility

#pragma mark User Following

+ (void)followUserInBackground:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if ([[user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        return;
    }
    
    PFObject *followActivity = [PFObject objectWithClassName:@"Activity"];
    [followActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
    [followActivity setObject:user forKey:@"toUser"];
    [followActivity setObject:@"follow" forKey:@"type"];
    
    PFACL *followACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [followACL setPublicReadAccess:YES];
    followActivity.ACL = followACL;
    
    [followActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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
    [query whereKey:@"type" equalTo:@"follow"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *followActivities, NSError *error) {
        // While normally there should only be one follow activity returned, we can't guarantee that.
        
        if (!error) {
            for (PFObject *followActivity in followActivities) {
                [followActivity deleteEventually];
            }
        }
    }];
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
    
    [addToTripActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
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
    
    PFACL *followACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [followACL setPublicReadAccess:YES];
    [followACL setWriteAccess:YES forUser:user]; // let's the user added to the trip remove themselves
    addToTripActivity.ACL = followACL;
    
    
    return addToTripActivity;
}

+ (void)removeUser:(PFUser *)user fromTrip:(Trip *)trip block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    // If the user isn't currentUser AND the user isn't the trip creator, don't let them remove people.
    // They can remove themselves no matter what, but only the creator can remove others.
    if (![[user objectId] isEqualToString:[[PFUser currentUser] objectId]] && ![[user objectId] isEqualToString:[trip.creator objectId]]) {
        return;
    }
    
    PFObject *removeFromTripActivity = [PFObject objectWithClassName:@"Activity"];
    [removeFromTripActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
    [removeFromTripActivity setObject:user forKey:@"toUser"];
    [removeFromTripActivity setObject:@"addToTrip" forKey:@"type"];
    [removeFromTripActivity setObject:trip forKey:@"trip"];
    
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
    [updateQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error) {
            NSLog(@"Successfully found Trip activities");
            // Delete the found objects
            NSMutableArray *objectsToUpdate = [[NSMutableArray alloc] init];
            for (PFObject *object in objects) {
                [object setValue:string forKey:@"content"];
                [objectsToUpdate addObject:object];
            }
            [PFObject saveAllInBackground:objectsToUpdate];
            
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

+ (void)updatePhotosForTrip:(Trip *)trip;
{
    PFQuery *updateQuery = [PFQuery queryWithClassName:@"Photo"];
    [updateQuery whereKey:@"trip" equalTo:trip];
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

+ (void)addComment:(NSString *)comment forPhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    PFObject *commentActivity = [PFObject objectWithClassName:@"Activity"];
    [commentActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
    [commentActivity setObject:photo.user forKey:@"toUser"];
    [commentActivity setObject:photo forKey:@"photo"];
    [commentActivity setObject:@"comment" forKey:@"type"];
    [commentActivity setObject:comment forKey:@"content"];
    
    // Permissions: commenter and photo owner can edit/delete comments.
    PFACL *commentACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [commentACL setWriteAccess:YES forUser:photo.user];
    [commentACL setPublicReadAccess:YES];
    commentActivity.ACL = commentACL;
    
    [commentActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            completionBlock(succeeded, error);
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
    
    return query;
}


@end
