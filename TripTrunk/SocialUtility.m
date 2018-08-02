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
#import "TTAnalytics.h"
#define CLOUDINARY_URL @"cloudinary://334349235853935:YZoImSo-gkdMtZPH3OJdZEOvifo@triptrunk"

@implementation SocialUtility

+ (PFUser*)loadUserFromUsername:(NSString*)username{

    //Connect to Parse and grab the PFUser from the username
    //FIXME: Some sort of user caching would be a good idea so we don't have to do this everytime
    PFQuery *query = [PFUser query];
    [query whereKey:@"username" equalTo:[username lowercaseString]];
    PFUser *user = (PFUser *)[query getFirstObject];
    
    return user;
}

+ (void)loadUserFromUsername:(NSString*)username block:(void (^)(PFUser* user, NSError *error))completionBlock{
    
    //Connect to Parse and grab the PFUser from the username
    PFQuery *query = [PFUser query];
    [query whereKey:@"username" equalTo:[username lowercaseString]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        completionBlock((PFUser*)object, error);
    }];
    
}

+ (void)followUserInBackground:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if ([[user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        return;
    }
    
    if ([self checkIfUserIsTemporarilyFollowed:user] == YES){
        return;
    }
    
    
    [self temporarilyMarkUserAsIsFollowing:user];
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
        [followACL setWriteAccess:true forUser:user];
        followActivity.ACL = followACL;
        
//        [followActivity saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
            [followActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            
            [self removeUserFromTemporaryFollowing:user];
            
            if (error) {
                NSLog(@"Error saving follow activity%@", error);
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"followUserInBackground:"];
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
    
//  [followActivity saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
    [followActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        if(error)
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"requestToFollowUserInBackground:"];

        // Cache the following status as PENDING
        [[TTCache sharedCache] setFollowStatus:[NSNumber numberWithInt:2] user:user];
        
        if (completionBlock) {
            completionBlock(succeeded, error);
        }
    }];
}

//FIXME: This should have a completion block
+ (void)unfollowUser:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock{
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
            [[TTCache sharedCache] removeFollowedUser:user];
            for (PFObject *followActivity in followActivities) {
                [followActivity deleteEventually];
            }
            
            if (completionBlock) {
                completionBlock(YES, error);
            }
        }else if (error){
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"unfollowUser:"];
            completionBlock(NO, error);
        }
    }];
}

+ (void)acceptFollowRequest:(BOOL)accepted
                     fromUser:(PFUser *)user
                        block:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            user.objectId, @"fromUserId",
                            [NSNumber numberWithBool:accepted], @"accepted", nil];
    
    [PFCloud callFunctionInBackground:@"approveFriend" withParameters:params
                                block:^(id  _Nullable success, NSError * _Nullable error) {
                                    if (!error) {
                                        completionBlock(YES, error);
                                    }else{
                                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"acceptFollowRequest:"];
                                    }
                                }];
    
}

+ (void)blockUser:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    __block MBProgressHUD *HUD;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = NSLocalizedString(@"Blocking...",@"Blocking...");
        HUD.mode = MBProgressHUDModeText; // change to Determinate to show progress
    });
    
    PFObject *block = [PFObject objectWithClassName:@"BlockedUsers"];
    [block setObject:[PFUser currentUser] forKey:@"fromUser"];
    [block setObject:user forKey:@"blockedUser"];
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [acl setPublicReadAccess:YES];
    [acl setWriteAccess:YES forUser:[PFUser currentUser]];
    [block setACL:acl];
    
    [block saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(error)
            HUD.labelText = NSLocalizedString(@"Error!",@"Error!");
        else HUD.labelText = NSLocalizedString(@"Done!",@"Done!");
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Hide HUD spinner
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
                if(error)
                    completionBlock(NO,error);
                else completionBlock(YES,nil);
            });
        });
    }];
    
    
    
}

+ (void)unblockUser:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    __block MBProgressHUD *HUD;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = NSLocalizedString(@"Unblocking...",@"Unblocking...");
        HUD.mode = MBProgressHUDModeText; // change to Determinate to show progress
    });
    
    PFQuery *query = [PFQuery queryWithClassName:@"BlockedUsers"];
    [query whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [query whereKey:@"blockedUser" equalTo:user];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (object) {
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if(succeeded)
                    completionBlock(YES,nil);
                else completionBlock(NO, error);
            }];
        } else {
            NSLog(@"Unable to delete: %@", error);
            completionBlock(NO,error);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Hide HUD spinner
            HUD.labelText = NSLocalizedString(@"Done!",@"Done!");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
            });
        });
    }];
}

+ (void)checkForUserBlockStatus:(PFUser *)user block:(void (^)(BOOL blocked, NSError *error))completionBlock{
    
    PFQuery *query = [PFQuery queryWithClassName:@"BlockedUsers"];
    [query whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [query whereKey:@"blockedUser" equalTo:user];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error)
            completionBlock(YES,error);
        
        if (objects.count == 1)
            completionBlock(YES,nil);
        else completionBlock(NO,nil);
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
    [followACL setWriteAccess:YES forUser:trip.creator];
    addToTripActivity.ACL = followACL;
    
//    [addToTripActivity saveEventually:^(BOOL succeeded, NSError *error) {
        [addToTripActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if(error)
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"addUser:"];
        
        if (completionBlock) {
//            PublicTripDetail *ptdId = trip.publicTripDetail;
//                PFQuery *query3 = [PFQuery queryWithClassName:@"PublicTripDetail"];
//                [query3 getObjectInBackgroundWithId:ptdId.objectId block:^(PFObject *pfObject, NSError *error) {
//                    int count = 0;
//                    if(pfObject[@"memberCount"])
//                        count = [pfObject[@"memberCount"] intValue];
//                    
//                    count++;
//                    [pfObject setObject:[NSNumber numberWithInt:count] forKey:@"memberCount"];
//                    [pfObject saveInBackground];
//                }];
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
    [deleteActivitiesQuery setLimit:1000];

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
             [TTAnalytics deleteTrunk];
             
         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
             [ParseErrorHandlingController handleError:error];
             [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"deleteTrip:"];
         }
     }];
    
    // Delete all the photos for this trip
    PFQuery *photoQuery = [PFQuery queryWithClassName:@"Photo"];
    [photoQuery whereKey:@"trip" equalTo:trip];
    [photoQuery setLimit:1000];
    [photoQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             // The find succeeded.
             [[TTUtility sharedInstance] internetConnectionFound];
             // Delete the found Photos
             for (PFObject *object in objects) {
                 [object deleteEventually];
                 //FIXME: This is termporary. Move to CC
                 if(object[@"video"]){
                     CLCloudinary *cloudinary = [[CLCloudinary alloc] init];
                     // Initialize the base cloudinary object
                     cloudinary = [[CLCloudinary alloc] initWithUrl:CLOUDINARY_URL];
                     Photo *photo = [[Photo alloc] init];
                     photo = (Photo*)object;
                     [photo.video fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                        [photo.video deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            NSLog(@"Video object deleted from Parse");
                             NSArray *urlSegments = [photo.video[@"videoUrl"] componentsSeparatedByString: @"/"];
                             NSArray *publicId = [[urlSegments lastObject] componentsSeparatedByString:@"."];
                             CLUploader *uploader = [[CLUploader alloc] init:cloudinary delegate:nil];
                             [uploader destroy:publicId[0] options:@{@"resource_type":@"video"} withCompletion:^(NSDictionary *successResult, NSString *errorResult, NSInteger code, id context) {
                                 NSLog(@"Video deleted from Cloudinary");
                             } andProgress:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite, id context) {
                                 //nil
                             }];
                         }];
                         
                     }];
                 }
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoObjectsDeleted" object:nil];

         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
             [ParseErrorHandlingController handleError:error];
             [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"deleteTrip:"];
         }
     }];
    
    
    NSDictionary *params = @{
       @"tripId" : trip.objectId
    };
    [PFCloud callFunctionInBackground:@"removePublicTripDetailsForTrip" withParameters:params block:^(NSString *response, NSError *error) {
         if (!error) {
             NSLog(@"Delete publicTripDetails: success");
         }else{
             NSLog(@"Delete publicTripDetails error: %@",error);
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
    [removeFromTripQuery setLimit:1000];
    [removeFromTripQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             // The find succeeded.
             // Delete the found objects
             
             ///-----------------------------
             //THIS DECREMENTS THE MEMBER COUNT BY 1
             PublicTripDetail *ptdId = trip.publicTripDetail;
             PFQuery *query3 = [PFQuery queryWithClassName:@"PublicTripDetail"];
             [query3 getObjectInBackgroundWithId:ptdId.objectId block:^(PFObject *pfObject, NSError *error) {
                 int count = 0;
                 if(pfObject[@"memberCount"])
                     count = [pfObject[@"memberCount"] intValue];
                 
                 count--;
                 [pfObject setObject:[NSNumber numberWithInt:count] forKey:@"memberCount"];
                 [pfObject saveInBackground];
             }];
             ///-----------------------------^
             
             [[TTUtility sharedInstance] internetConnectionFound];
             
             for (PFObject *object in objects) {
                 [object deleteInBackground];
             }
             // If the Trip is private, tell CloudCode to also remove any photos they added.
             if (trip.isPrivate) {
                 [PFCloud callFunctionInBackground:@"RemovePhotosForUser" withParameters:@{@"tripId": trip.objectId, @"user": user }];
             }
             [TTAnalytics deleteUser];
             completionBlock(YES, nil);

         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
             completionBlock(NO, error);
             [ParseErrorHandlingController handleError:error];
             [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"removeUser:"];
         }
     }];
}

+ (void)updateActivityContent:(NSString *)string forTrip:(Trip *)trip;
{
    PFQuery *updateQuery = [PFQuery queryWithClassName:@"Activity"];
    [updateQuery whereKeyExists:@"trip"];
    [updateQuery whereKey:@"type" equalTo:@"addToTrip"];
    [updateQuery whereKey:@"trip" equalTo:trip];
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
                    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"updateActivityContent:"];
                }
            }];
            
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"updateActivityContent:"];
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
             [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"updatePhotosForTrip:"];
         }
     }];
}

+ (void)addComment:(NSString *)comment forPhoto:(Photo *)photo isCaption:(BOOL)isCaption block:(void (^)(BOOL, PFObject *, PFObject *, NSError *))completionBlock
{
    if ([comment isEqualToString:@""]) {
        if (completionBlock) {
            return completionBlock(false, nil, nil, nil);
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
        
        [commentACL setPublicReadAccess:YES];
        [commentACL setWriteAccess:YES forUser:photo.trip.creator];
        [commentACL setWriteAccess:YES forUser:[PFUser currentUser]];
        [commentACL setWriteAccess:YES forUser:photo.user];
        commentActivity.ACL = commentACL;
        
//        [commentActivity saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
            [commentActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error){
                [ParseErrorHandlingController handleError:error];
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"addComment:"];
            }else{
                [[TTUtility sharedInstance] internetConnectionFound];
            }
            
            if (completionBlock){
                //has to be done this way because saveEventually will continue to try over and over. We don't want to decrement the likerCount until it FAILS completely
                if(error){
                    [ParseErrorHandlingController errorCommentingOnPhoto:photo];
                    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"addComment:"];
                }else{
                    [TTAnalytics commentAdded:photo.userName];
                }
                completionBlock(succeeded, object, commentActivity, error);
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
    [mentionACL setWriteAccess:YES forUser:photo.trip.creator];
    
    [photo.trip fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        [mentionACL setWriteAccess:YES forUser:photo.trip.creator];
        [mentionACL setPublicReadAccess:YES];
        mentionActivity.ACL = mentionACL;
        [photo.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            if(![photo.user.objectId isEqual:user.objectId]){
                [mentionActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        [[TTUtility sharedInstance] internetConnectionFound];
                        if (completionBlock) {
                            NSLog(@"Comment added");
                            completionBlock(succeeded, error);
                        }
                    } else if (!error){
                        [ParseErrorHandlingController handleError:error];
                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"addMention:"];
                        NSLog(@"Comment NOT added");
                    }
                }];
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
    [query whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"comment" equalTo:commentObject];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *object, NSError *error){
        if (!error && object.count != 0){
             [object[0] deleteEventually];
            [[TTUtility sharedInstance] internetConnectionFound];
            [TTAnalytics deleteUserMention];
            return completionBlock(true, error);
        }else{
            NSLog(@"Error: %@", error);
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"deleteMention:"];
            return completionBlock(false, error);
        }
     }];
}

+ (void)getCommentsForPhoto:(Photo *)photo block:(void (^)(NSArray *objects, NSError *error))completionBlock;
{
    // Query all user's that
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKeyExists:@"fromUser"];
    [query whereKeyExists:@"toUser"];
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
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"getCommentsForPhoto:"];
        } else {
            [[TTUtility sharedInstance] internetConnectionFound];
        }
        
    }];
}

+ (void)deleteComment:(PFObject *)commentActivity forPhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    [commentActivity deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error)
            [commentActivity deleteEventually];
        
        if(succeeded){
            [[TTCache sharedCache] decrementCommentCountForPhoto:photo];
            //delete photo caption if it actually is a caption
            if([commentActivity[@"isCaption"] boolValue]){
                PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
                [query whereKey:@"objectId" equalTo:photo.objectId];
                
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                    if (error){
                        [ParseErrorHandlingController handleError:error];
                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"deleteComment:"];
                    } else {
                        [[TTUtility sharedInstance] internetConnectionFound];
                        [object setObject:@"" forKey:@"caption"];
//                        [object saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
                            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            [TTAnalytics deleteComment];
                            completionBlock(succeeded, error);
                        }];
                        
                    }
                }];
            }
        }
        
//        completionBlock(succeeded, error);
    }];
}

+ (void)likePhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    [photo.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [TTAnalytics photoLiked:photo.user];
        NSDictionary *params = @{
                                 @"photoId" : photo.objectId
                                 };
        [PFCloud callFunctionInBackground:@"Activity.Like" withParameters:params block:^(PFObject *response, NSError *error) {
            if (error) {
                [ParseErrorHandlingController handleError:error];
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"likePhoto:"];
                completionBlock(false, error);
            }
            else {
                [[TTUtility sharedInstance] internetConnectionFound];
                
                completionBlock(true, nil);
            }
            
        }];
    }];

}

+ (void)unlikePhoto:(Photo *)photo block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
{
    [photo.user fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [TTAnalytics photoUnliked:photo.user];
        PFQuery *queryExistingLikes = [PFQuery queryWithClassName:@"Activity"];
        [queryExistingLikes whereKey:@"photo" equalTo:photo];
        [queryExistingLikes whereKey:@"type" equalTo:@"like"];
        [queryExistingLikes whereKey:@"fromUser" equalTo:[PFUser currentUser]];
        [queryExistingLikes setCachePolicy:kPFCachePolicyNetworkOnly];
        [queryExistingLikes setLimit:1000];
        [queryExistingLikes findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
            if (!error) {
                [[TTUtility sharedInstance] internetConnectionFound];
                for (PFObject *activity in activities) {
                    [activity deleteEventually];
                }
                
                if (completionBlock) {
                    completionBlock(YES,nil);
                }
            }
            
            else if (error){
                [ParseErrorHandlingController handleError:error];
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"unlikePhoto:"];
                [ParseErrorHandlingController errorUnlikingPhoto:photo];
                
                if (completionBlock) {
                    completionBlock(NO,error);
                }
            }
        }];
    }];
}

+ (PFQuery *)queryForActivitiesOnPhoto:(PFObject *)photo cachePolicy:(PFCachePolicy)cachePolicy;
{
    PFQuery *queryLikes = [PFQuery queryWithClassName:@"Activity"];
    [queryLikes whereKeyExists:@"fromUser"];
    [queryLikes whereKeyExists:@"toUser"];
    [queryLikes whereKey:@"photo" equalTo:photo];
    [queryLikes whereKey:@"type" equalTo:@"like"];
    
    PFQuery *queryComments = [PFQuery queryWithClassName:@"Activity"];
    [queryComments whereKeyExists:@"fromUser"];
    [queryComments whereKeyExists:@"toUser"];
    [queryComments whereKey:@"photo" equalTo:photo];
    [queryComments whereKey:@"type" equalTo:@"comment"];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:queryLikes,queryComments,nil]];
    [query setCachePolicy:cachePolicy];
    [query includeKey:@"fromUser"];
    [query includeKey:@"photo"];
    [query setLimit:1000];
    //Order by the time and then order by isCaption so that the caption is always first
    [query orderByAscending:@"createdAt"];
    [query orderByDescending:@"isCaption"];
    

    return query;
}

+ (void)queryForAllActivities:(NSInteger)count trips:(NSMutableArray*)trips activities:(NSMutableArray*)activities isRefresh:(BOOL)isRefresh query:(void (^)(NSArray *, NSError *))completionBlock
{
    // Query all user's that
    PFQuery *Pfollow = [PFQuery queryWithClassName:@"Activity"];
    [Pfollow whereKeyExists:@"fromUser"];
    [Pfollow whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [Pfollow whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [Pfollow whereKey:@"type" equalTo:@"pending_follow"];
    
    PFQuery *follow = [PFQuery queryWithClassName:@"Activity"];
    [follow whereKeyExists:@"fromUser"];
    [follow whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [follow whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [follow whereKey:@"type" equalTo:@"follow"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKeyExists:@"fromUser"];
    [query whereKeyExists:@"trip"];
    [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [query whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    
    PFQuery *photos = [PFQuery queryWithClassName:@"Activity"];
    [photos whereKeyExists:@"trip"];
    [photos whereKey:@"trip" containedIn:trips];
    [photos whereKey:@"type" equalTo:@"addedPhoto"];
    [photos whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
  
    PFQuery *subqueries = [PFQuery orQueryWithSubqueries:@[Pfollow, follow ,query, photos]];
    subqueries.limit = 20;
    [subqueries orderByDescending:@"createdAt"];
    [subqueries whereKeyExists:@"fromUser"];
    [subqueries whereKeyExists:@"toUser"];
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
        
        if (object){
            [subqueries whereKey:@"createdAt" lessThanOrEqualTo:object.createdAt];
        }
        if (objIds){
            [subqueries whereKey:@"objectId" notContainedIn:objIds];
        }
        
    } else if (isRefresh ==YES && activities.count >0){
        
        PFObject *object = activities.firstObject;
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
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"queryForAllActivities:"];
        } else {
            [[TTUtility sharedInstance] internetConnectionFound];
        }
    }];
}

+ (void)queryForFollowingActivities:(NSInteger)count friends:(NSMutableArray*)friends activities:(NSMutableArray*)activities isRefresh:(BOOL)isRefresh query:(void (^)(NSArray *, NSError *))completionBlock
{
    
    
    PFQuery *likes = [PFQuery queryWithClassName:@"Activity"];
    [likes whereKeyExists:@"trip"];
    [likes whereKeyExists:@"fromUser"];
    [likes whereKeyExists:@"toUser"];
    [likes whereKey:@"fromUser" containedIn:friends];
    [likes whereKey:@"toUser" notEqualTo:[PFUser currentUser]];
    [likes whereKey:@"type" equalTo:@"like"];
    [likes whereKey:@"fromUser" containedIn:friends];

    PFQuery *following = [PFQuery queryWithClassName:@"Activity"];
    [following whereKey:@"fromUser" containedIn:friends];
    [following whereKey:@"type" equalTo:@"follow"];
    [following whereKey:@"toUser" notEqualTo:[PFUser currentUser]];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKeyExists:@"toUser"];
    [query whereKeyExists:@"trip"];
    [likes whereKey:@"toUser" containedIn:friends];
    [query whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [query whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:@"fromUser"];
    [query whereKey:@"type" equalTo:@"comment"];
    
    PFQuery *photos = [PFQuery queryWithClassName:@"Activity"];
    [photos whereKeyExists:@"trip"];
    [photos whereKeyExists:@"fromUser"];
    [photos whereKeyExists:@"toUser"];
    [photos whereKey:@"type" equalTo:@"addedPhoto"];
    [photos whereKey:@"fromUser" containedIn:friends];
    [photos whereKey:@"fromUser" notEqualTo:[PFUser currentUser]];
    
    PFQuery *subqueries = [PFQuery orQueryWithSubqueries:@[likes, following, photos,query]];
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
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"queryForFollowingActivities:"];
        } else {
            [[TTUtility sharedInstance] internetConnectionFound];
        }
    }];
}

+ (void)queryForProfilePicUrlFromFBID:(id)fbid  block:(void (^)(NSString* result, NSError *error))completionBlock {
    PFQuery *user = [PFQuery queryWithClassName:@"User"];
    [user whereKey:@"fbid" equalTo:fbid];
    
    [user findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if(error){
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"queryForProfilePicUrlFromFBID:"];
            return completionBlock (nil, error);
        }else{
            PFUser *foundUser = objects[0];
            return completionBlock(foundUser[@"fbid"], error);
        }
    }];
}

+ (void)queryForUserFromFBID:(id)fbid  block:(void (^)(PFUser* user, NSError *error))completionBlock {
    PFQuery *user = [PFUser query];
    [user whereKey:@"fbid" equalTo:fbid];
    [user getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if(error){
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"queryForUserFromFBID:"];
            return completionBlock (nil, error);
        }else{
            return completionBlock((PFUser*)object, error);
        }
    }];
}



+ (void)followingStatusFromUser:(PFUser *)fromUser toUser:(PFUser *)toUser block:(void (^)(NSNumber* followingStatus, NSError *error))completionBlock; {
    // Determine the follow status of the user
    PFQuery *isFollowingQuery = [PFQuery queryWithClassName:@"Activity"];
    [isFollowingQuery whereKeyExists:@"fromUser"];
    [isFollowingQuery whereKeyExists:@"toUser"];
    [isFollowingQuery whereKey:@"fromUser" equalTo:fromUser];
    [isFollowingQuery whereKey:@"type" equalTo:@"follow"];
    [isFollowingQuery whereKey:@"toUser" equalTo:toUser];

    [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (error) {
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"followingStatusFromUser:"];
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
            [isPendingQuery whereKeyExists:@"fromUser"];
            [isPendingQuery whereKeyExists:@"toUser"];
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
    [followingQuery whereKeyExists:@"fromUser"];
    [followingQuery whereKeyExists:@"toUser"];
    [followingQuery whereKey:@"fromUser" equalTo:user];
    [followingQuery whereKey:@"type" equalTo:@"follow"];
    [followingQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [followingQuery includeKey:@"toUser"];
    [followingQuery setLimit:1000];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"followingUsers:"];
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
                //FIXME at some point we should cache and display everyone
                if ([user.objectId isEqualToString:[PFUser currentUser].objectId]){
                    [[TTCache sharedCache] setFollowing:friends];
                }
            }
            
            completionBlock(friends, error);
        }
        
    }];
}

+ (void)pendingUsers:(PFUser *)user block:(void (^)(NSArray *users, NSError *error))completionBlock;
{
    NSMutableArray *friends = [[NSMutableArray alloc] init];

    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKeyExists:@"fromUser"];
    [followingQuery whereKeyExists:@"toUser"];
    [followingQuery whereKey:@"fromUser" equalTo:user];
    [followingQuery whereKey:@"type" equalTo:@"pending_follow"];
    [followingQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [followingQuery includeKey:@"toUser"];
    [followingQuery setLimit:100]; //fixme Why isnt this 1000?
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"pendingUsers:"];
            if (error.code != 120){
                NSLog(@"Error: %@",error);
            }
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
    [query whereKeyExists:@"fromUser"];
    [query whereKeyExists:@"toUser"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"type" equalTo:@"follow"];
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    [query includeKey:@"fromUser"];
    [query setLimit:1000];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"followers:"];
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
                if (user){
                    [friends addObject:user];
                }
            }
            // Update the cache
            if (friends.count > 0) {
                //FIXME at some point we should cache and display everyone
                if ([user.objectId isEqualToString:[PFUser currentUser].objectId]){
                    [[TTCache sharedCache] setFollowers:friends];
                }
            }
            
            completionBlock(friends, error);
        }
        
    }];
}

+ (void)followerCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;
{
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKeyExists:@"toUser"];
    [query whereKeyExists:@"fromUser"];
    [query whereKey:@"toUser" equalTo:user];
    [query whereKey:@"fromUser" notEqualTo:user];
    [query whereKey:@"type" equalTo:@"follow"];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query setLimit:1000];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if(error)
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"followerCount:"];
        completionBlock(number, error);
        
    }];
}

+ (void)followingCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;
{
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKeyExists:@"toUser"];
    [query whereKeyExists:@"fromUser"];
    [query whereKey:@"fromUser" equalTo:user];
    [query whereKey:@"toUser" notEqualTo:user];
    [query whereKey:@"type" equalTo:@"follow"];
    [query setLimit:1000];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if(error)
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"followingCount:"];
        completionBlock(number, error);
        
    }];
}

+ (void)trunkCount:(PFUser *)user block:(void (^)(int count, NSError *error))completionBlock;
{
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKeyExists:@"toUser"];
    [query whereKeyExists:@"fromUser"];
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
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"trunkCount:"];
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
    [memberQuery whereKeyExists:@"fromUser"];
    [memberQuery whereKeyExists:@"toUser"];
    [memberQuery whereKey:@"trip" equalTo:trip];
    [memberQuery whereKey:@"type" equalTo:@"addToTrip"];
    [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [memberQuery includeKey:@"toUser"];
    [memberQuery setLimit:1000];
    
    
    [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            NSLog(@"Error: %@",error);
            completionBlock(nil, error);
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"trunkMembers:"];
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

+ (void)memberStatusOfTrunk:(Trip*)trip user:(PFUser*)user block:(void (^)(BOOL followingStatus, NSError *error))completionBlock{
    
    PFQuery *memberQuery = [PFQuery queryWithClassName:@"Activity"];
    [memberQuery whereKeyExists:@"fromUser"];
    [memberQuery whereKeyExists:@"toUser"];
    [memberQuery whereKey:@"trip" equalTo:trip];
    [memberQuery whereKey:@"type" equalTo:@"addToTrip"];
    [memberQuery whereKey:@"toUser" equalTo:user];
    [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [memberQuery setLimit:1000];
    
    [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error){
            NSLog(@"Error: %@",error);
            completionBlock(false, error);
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"memberStatusOfTrunk:"];
        }else{
            [[TTUtility sharedInstance] internetConnectionFound];
            if(objects.count >0)
                completionBlock(true, error);
        }
        
    }];
}

+(void)temporarilyMarkUserAsIsFollowing:(PFUser*)user{
    NSString *valueToSave = user.objectId;
    [[NSUserDefaults standardUserDefaults] setObject:valueToSave forKey:user.objectId];
}

+(void)removeUserFromTemporaryFollowing:(PFUser*)user{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:user.objectId];
}

+(BOOL)checkIfUserIsTemporarilyFollowed:(PFUser*)user{
    NSString *savedValue = [[NSUserDefaults standardUserDefaults]
                            stringForKey:user.objectId];
    
    if (savedValue == user.objectId){
        return YES;
    } else {
        return NO;
    }
}

+(void)loadUserImages:(PFUser*)user withLimit:(int)limit block:(void (^)(NSArray *objects, NSError *error))completionBlock{
    PFQuery *findPhotosUser = [PFQuery queryWithClassName:@"Photo"];
    [findPhotosUser whereKey:@"user" equalTo:user];
    [findPhotosUser orderByDescending:@"createdAt"];
    [findPhotosUser includeKey:@"trip.creator"];
    [findPhotosUser includeKey:@"trip"];
    [findPhotosUser includeKey:@"user"];
    [findPhotosUser setLimit:limit];
    [findPhotosUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            [[TTUtility sharedInstance] internetConnectionFound];
            completionBlock(objects,nil);
        } else {
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"loadUserImages:withLimit:"];
            completionBlock(nil,error);
        }
    }];
}


+ (void)queryForTrunksWithFollowers:(NSArray*)followers withoutPreviousTrunks:(NSArray*)previousTrunks withLimit:(int)limit block:(void (^)(NSArray* activities, NSError *error))completionBlock{
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"type" equalTo:@"addToTrip"];
    [query whereKey:@"toUser" containedIn:followers];
    [query whereKey:@"trip" notContainedIn:previousTrunks];
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"trip"];
    [query setLimit:limit];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            [[TTUtility sharedInstance] internetConnectionFound];
            completionBlock(objects,nil);
        } else {
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"queryForTrunksWithFollowers:withLimit:"];
            completionBlock(nil,error);
        }
    }];
    
}

@end
