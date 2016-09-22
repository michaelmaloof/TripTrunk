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

+(void)initAnalyticsOnStart;
+(void)trackScreen:(NSString*)screenName;
+(void)accountCreated;
+(void)photoLiked:(PFUser*)owner;
+(void)photoViewed;
+(void)errorOccurred:(NSString*)errorMessage method:(NSString*)method;
@end
