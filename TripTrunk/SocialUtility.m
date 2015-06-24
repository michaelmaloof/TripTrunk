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


@end
