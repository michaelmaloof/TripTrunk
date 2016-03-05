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
#import "ParseErrorHandlingController.h"
#import "TTUtility.h"

@implementation SocialUtility

+ (PFUser*)loadUserFromUsername:(NSString*)username{

    //Connect to Parse and grab the PFUser from the username
    //FIXME: Some sort of user caching would be a good idea so we don't have to do this everytime
    PFQuery *query = [PFUser query];
    [query whereKey:@"username" equalTo:username];
    PFUser *user = (PFUser *)[query getFirstObject];
    
    return user;
}

+ (void)followUserInBackground:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if ([[user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        return;
    }
    // If the user is private then we should be REQUESTING to follow, not following.
    if ([user[@"private"]boolValue] == YES) {
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
                //FIXME Need to remove the user from follow list
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
            
            [[TTUtility sharedInstance] internetConnectionFound];
            
            // Cache the following status as NOT FOLLOWING
            [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithBool:NO] user:user];
            
            for (PFObject *followActivity in followActivities) {
                [followActivity deleteEventually];
            }
        }else if (error){
            [ParseErrorHandlingController handleError:error];
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
    [followACL setWriteAccess:YES forUser:trip.creator];
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
    [followACL setWriteAccess:YES forUser:trip.creator];
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
             [[TTUtility sharedInstance] internetConnectionFound];
             // The find succeeded.
             // Delete the found objects
             for (PFObject *object in objects) {
                 [object deleteEventually];
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivityObjectsDeleted" object:nil];
             
         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
             [ParseErrorHandlingController handleError:error];
         }
     }];
    
    // Delete all the photos for this trip
    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
    [photoQuery whereKey:@"trip" equalTo:trip];
    [photoQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             // The find succeeded.
             [[TTUtility sharedInstance] internetConnectionFound];
             // Delete the found Photos
             for (PFObject *object in objects) {
                 [object deleteEventually];
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoObjectsDeleted" object:nil];

         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
             [ParseErrorHandlingController handleError:error];
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
             // Delete the found objects
             
             [[TTUtility sharedInstance] internetConnectionFound];
             
             for (PFObject *object in objects) {
                 [object deleteInBackground];
             }
             completionBlock(YES, nil);

         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
             completionBlock(NO, error);
             [ParseErrorHandlingController handleError:error];
         }
     }];
}

+ (void)updateActivityContent:(NSString *)string forTrip:(Trip *)trip;
{
    PFQuery *updateQuery = [PFQuery queryWithClassName:@"Activity"];
    [updateQuery whereKey:@"type" equalTo:@"addToTrip"];
    [updateQuery whereKey:@"trip" equalTo:trip];
    [updateQuery whereKeyExists:@"trip"];
    [updateQuery setLimit:1000];
    [updateQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error) {
            
            [[TTUtility sharedInstance] internetConnectionFound];
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
                    [ParseErrorHandlingController handleError:error];
                }
            }];
            
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            [ParseErrorHandlingController handleError:error];
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
             [[TTUtility sharedInstance] internetConnectionFound];
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
             [ParseErrorHandlingController handleError:error];
         }
     }];
}

+ (void)addComment:(NSString *)comment forPhoto:(Photo *)photo isCaption:(BOOL)isCaption block:(void (^)(BOOL, PFObject *, NSError *))completionBlock
{
    if ([comment isEqualToString:@""]) {
        if (completionBlock) {
            return completionBlock(false, nil, nil);
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
    
    [photo.trip fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        [commentACL setWriteAccess:YES forUser:photo.trip.creator];
        [commentACL setPublicReadAccess:YES];
        commentActivity.ACL = commentACL;
        
        [commentActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                if (completionBlock) {
                    completionBlock(succeeded, object, error);
                }
                                [[TTUtility sharedInstance] internetConnectionFound];
            }
            else {
                // Error, so decrement the cache count again.
                [ParseErrorHandlingController handleError:error];
                [[TTCache sharedCache] decrementCommentCountForPhoto:photo];
            }
        }];
    }];
}

+ (void)addMention:(PFObject *)commentObject isCaption:(BOOL)isCaption withUser:(PFUser*)user forPhoto:(Photo *)photo block:(void (^)(BOOL, NSError *))completionBlock
{
    if (commentObject == nil) {
        if (completionBlock)
            return completionBlock(false, nil);
    }
    
    PFObject *mentionActivity = [PFObject objectWithClassName:@"Activity"];
    [mentionActivity setObject:[PFUser currentUser] forKey:@"fromUser"];
    [mentionActivity setObject:user forKey:@"toUser"];
    [mentionActivity setObject:photo forKey:@"photo"];
    [mentionActivity setObject:photo.trip forKey:@"trip"];
    [mentionActivity setObject:@"mention" forKey:@"type"];
    [mentionActivity setObject:commentObject forKey:@"comment"];
    [mentionActivity setObject:[NSNumber numberWithBool:isCaption] forKey:@"isCaption"];
    
    // Permissions: commenter and photo owner can edit/delete comments.
    PFACL *mentionACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [mentionACL setWriteAccess:YES forUser:photo.user];
    
    [photo.trip fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        [mentionACL setWriteAccess:YES forUser:photo.trip.creator];
        [mentionACL setPublicReadAccess:YES];
        mentionActivity.ACL = mentionACL;
        
        [mentionActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [[TTUtility sharedInstance] internetConnectionFound];
                if (completionBlock) {
                    completionBlock(succeeded, error);
                }
            } else if (!error){
                [ParseErrorHandlingController handleError:error];
            }
        }];
    }];
}

+ (void)deleteMention:(PFObject *)commentObject withUser:(PFUser*)user block:(void (^)(BOOL, NSError *))completionBlock{
    if (commentObject == nil) {
        if (completionBlock)
            return completionBlock(false, nil);
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"comment" equalTo:commentObject];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *object, NSError *error){
        if (!error && object.count != 0){
             [object[0] deleteEventually];
            [[TTUtility sharedInstance] internetConnectionFound];
            return completionBlock(true, error);
        }else{
            NSLog(@"Error: %@", error);
            [ParseErrorHandlingController handleError:error];
            return completionBlock(false, error);
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
        
        if (error){
            [ParseErrorHandlingController handleError:error];
        } else {
            [[TTUtility sharedInstance] internetConnectionFound];
        }
        
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
            [[TTUtility sharedInstance] internetConnectionFound];
            for (PFObject *activity in activities) {
                [activity delete];
            }
        } else if (error){
            [ParseErrorHandlingController handleError:error];
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
        
        [photo.trip fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            
            if (error){
                [ParseErrorHandlingController handleError:error];
            } else {
                [[TTUtility sharedInstance] internetConnectionFound];
            }
         
            [likeACL setWriteAccess:YES forUser:photo.user];
            [likeACL setWriteAccess:YES forUser:photo.trip.creator];
            
            likeActivity.ACL = likeACL;
            
            [likeActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                if (error){
                    [ParseErrorHandlingController handleError:error];
                } else {
                    [[TTUtility sharedInstance] internetConnectionFound];
                }
                
                if (completionBlock) {
                    completionBlock(succeeded,error);
                }
                
            }];
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
            [[TTUtility sharedInstance] internetConnectionFound];
            for (PFObject *activity in activities) {
                [activity delete];
            }
            
            if (completionBlock) {
                completionBlock(YES,nil);
            }
        }
        else if (completionBlock) {
            completionBlock(NO,error);
        } else if (error){
            [ParseErrorHandlingController handleError:error];
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

+ (void)queryForAllActivities:(NSInteger)count trips:(NSMutableArray*)trips activities:(NSMutableArray*)activities isRefresh:(BOOL)isRefresh query:(void (^)(NSArray *, NSError *))completionBlock
{
    // Query all user's that
    PFQuery *Pfollow = [PFQuery queryWithClassName:@"Activity"];
    [Pfollow whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [Pfollow whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [Pfollow whereKeyExists:@"fromUser"];
    [Pfollow whereKey:@"type" equalTo:@"pending_follow"];
    
    PFQuery *follow = [PFQuery queryWithClassName:@"Activity"];
    [follow whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [follow whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [follow whereKeyExists:@"fromUser"];
    [follow whereKey:@"type" equalTo:@"follow"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [query whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:@"fromUser"];
    [query whereKeyExists:@"trip"];
    
    PFQuery *photos = [PFQuery queryWithClassName:@"Activity"];
    [photos whereKey:@"trip" containedIn:trips];
    [photos whereKey:@"type" equalTo:@"addedPhoto"];
    [query whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:@"trip"];
  
    PFQuery *subqueries = [PFQuery orQueryWithSubqueries:@[Pfollow, follow ,query, photos]];
    subqueries.limit = 20;
    [subqueries orderByDescending:@"createdAt"];
    [subqueries includeKey:@"fromUser"];
    [subqueries includeKey:@"toUser"];

    [subqueries includeKey:@"photo"];
    [subqueries includeKey:@"trip"];
    [subqueries includeKey:@"trip.publicTripDetail"];
    [subqueries whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];

    for (PFObject *ojber in activities){
        int count = 0;
        for (PFObject *objer2 in activities){
            if ([objer2.objectId isEqualToString:ojber.objectId]){
                count +=1;
                if (count ==2){
                }
            }
        }
    }
    
    if (activities > 0 && isRefresh == NO){
        
        PFObject *object = activities.lastObject;
        NSMutableArray *objIds = [[NSMutableArray alloc]init];
        for (PFObject *obj in activities){
            [objIds addObject:obj.objectId];
        }
        
        [subqueries whereKey:@"createdAt" lessThanOrEqualTo:object.createdAt];
        [subqueries whereKey:@"objectId" notContainedIn:objIds];
        
    } else if (isRefresh ==YES && activities.count >0){
        
        PFObject *object = activities.lastObject;
        NSMutableArray *objIds = [[NSMutableArray alloc]init];
        for (PFObject *obj in activities){
            [objIds addObject:obj.objectId];
        }
        
        [subqueries whereKey:@"createdAt" greaterThan:object.createdAt];
        [subqueries whereKey:@"objectId" notContainedIn:objIds];
    }
    
    
    [subqueries setCachePolicy:kPFCachePolicyNetworkOnly]; //is this the right one?

    
    [subqueries findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        completionBlock(objects, error);
        if (error){
            [ParseErrorHandlingController handleError:error];
        } else {
            [[TTUtility sharedInstance] internetConnectionFound];
        }
    }];
}

+ (void)queryForFollowingActivities:(NSInteger)count friends:(NSMutableArray*)friends activities:(NSMutableArray*)activities isRefresh:(BOOL)isRefresh query:(void (^)(NSArray *, NSError *))completionBlock
{
    PFQuery *likes = [PFQuery queryWithClassName:@"Activity"];
    [likes whereKey:@"fromUser" containedIn:friends];
    [likes whereKey:@"toUser" notEqualTo:[PFUser currentUser]];
    [likes whereKey:@"type" equalTo:@"like"];
    [likes whereKeyExists:@"trip"];

    PFQuery *following = [PFQuery queryWithClassName:@"Activity"];
    [following whereKey:@"fromUser" containedIn:friends];
    [following whereKey:@"type" equalTo:@"follow"];
    [following whereKey:@"toUser" notEqualTo:[PFUser currentUser]];
    
    PFQuery *subqueries = [PFQuery orQueryWithSubqueries:@[likes, following]];
    subqueries.limit = 20;
    [subqueries orderByDescending:@"createdAt"];
    [subqueries includeKey:@"fromUser"];
    [subqueries includeKey:@"toUser"];
    [subqueries includeKey:@"photo"];
    [subqueries includeKey:@"trip"];
    [subqueries includeKey:@"trip.publicTripDetail"];
    [subqueries whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    
    for (PFObject *ojber in activities){
        int count = 0;
        for (PFObject *objer2 in activities){
            if ([objer2.objectId isEqualToString:ojber.objectId]){
                count +=1;
                if (count ==2){
                    NSLog(@"clone %@", ojber.objectId);
                }
            }
        }
    }
    
    if (activities > 0 && isRefresh == NO){
        
        PFObject *object = activities.lastObject;
        NSMutableArray *objIds = [[NSMutableArray alloc]init];
        for (PFObject *obj in activities){
            [objIds addObject:obj.objectId];
        }
        
        [subqueries whereKey:@"createdAt" lessThanOrEqualTo:object.createdAt];
        [subqueries whereKey:@"objectId" notContainedIn:objIds];
        
    } else if (isRefresh ==YES && activities.count >0){
        
        PFObject *object = activities.lastObject;
        NSMutableArray *objIds = [[NSMutableArray alloc]init];
        for (PFObject *obj in activities){
            [objIds addObject:obj.objectId];
        }
        
        [subqueries whereKey:@"createdAt" greaterThan:object.createdAt];
        [subqueries whereKey:@"objectId" notContainedIn:objIds];
    }
    
    
    [subqueries setCachePolicy:kPFCachePolicyNetworkOnly]; //is this the right one?
    
    
    [subqueries findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        completionBlock(objects, error);
        if (error){
            [ParseErrorHandlingController handleError:error];
        } else {
            [[TTUtility sharedInstance] internetConnectionFound];
        }
    }];
}



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
            [ParseErrorHandlingController handleError:error];
            NSLog(@"Error: %@",error);
            completionBlock(nil, error);
        }
        else if (!error)
        {
            [[TTUtility sharedInstance] internetConnectionFound];
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
            [ParseErrorHandlingController handleError:error];
            NSLog(@"Error: %@",error);
            completionBlock(nil, error);
        }
        else if (!error)
        {
            [[TTUtility sharedInstance] internetConnectionFound];
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
            [ParseErrorHandlingController handleError:error];
            NSLog(@"Error: %@",error);
            completionBlock(nil, error);
        }
        else if (!error)
        {
            [[TTUtility sharedInstance] internetConnectionFound];
            // Map the activity users into the friends array
            for (PFObject *activity in objects)
            {
                PFUser *user = activity[@"fromUser"];
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
    [query includeKey:@"trip"];
    [query whereKeyExists:@"trip"];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query setLimit:1000];
//    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
//        completionBlock(number, error);
//    }];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        
        if (error){
            [ParseErrorHandlingController handleError:error];
        }else {
//            [[TTUtility sharedInstance] internetConnectionFound];
        }
        int count = 0;
        for (PFObject *obj in objects){
            if (obj[@"trip"]) {
                count += 1;
            }
        completionBlock(count, error);
        }
    }];
}

+ (void)trunkMembers:(Trip*)trip block:(void (^)(NSArray *users, NSError *error))completionBlock{
    NSMutableArray *members = [[NSMutableArray alloc] init];
    
    PFQuery *memberQuery = [PFQuery queryWithClassName:@"Activity"];
    [memberQuery whereKey:@"trip" equalTo:trip];
    [memberQuery whereKey:@"type" equalTo:@"addToTrip"];
    [memberQuery whereKey:@"toUser" notEqualTo:trip.creator];
    [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [memberQuery includeKey:@"toUser"];
    
    
    
    [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            NSLog(@"Error: %@",error);
            completionBlock(nil, error);
            [ParseErrorHandlingController handleError:error];
        }else{
            [[TTUtility sharedInstance] internetConnectionFound];
            // These are Activity objects, so loop through and just pull out the "toUser" User objects.
            for (PFObject *activity in objects) {
                PFUser *user = activity[@"toUser"];
                if (![user[@"fbid"]isEqualToString:user[@"username"]]){
                    [members addObject: user];
                }
            }
            
            completionBlock(members, error);
        }
        
    }];
}

@end
