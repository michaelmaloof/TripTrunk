//
//  SocialUtility.h
//  TripTrunk
//
//  Created by Matt Schoch on 5/12/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface SocialUtility : NSObject


+ (void)followUserInBackground:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock;
+ (void)unfollowUser:(PFUser *)user;

@end
