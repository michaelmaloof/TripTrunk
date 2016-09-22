//
//  TTAnalytics.h
//  TripTrunk
//
//  Created by Michael Cannell on 9/20/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface TTAnalytics : NSObject

+(void)initAnalyticsOnStart:(BOOL)env;
+(void)trackScreen:(NSString*)screenName;
+(void)accountCreated;
+(void)photoLiked:(PFUser*)owner;
+(void)photoViewed:(NSString*)photo;
+(void)errorOccurred:(NSString*)errorMessage method:(NSString*)method;
+(void)userMentioned:(NSString*)user;
+(void)commentAdded:(NSString*)user;
+(void)trunkCreated:(NSUInteger)numOfPhotos numOfMembers:(NSUInteger)numOfMembers;
@end
