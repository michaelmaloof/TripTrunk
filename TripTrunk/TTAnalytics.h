//
//  TTAnalytics.h
//  TripTrunk
//
//  Created by Michael Cannell on 9/20/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTAnalytics : NSObject

+(void)trackScreen:(NSString*)screenName;
+(void)initAnalyticsOnStart;
@end
