//
//  TTPushNotificationHandler.h
//  TripTrunk
//
//  Created by Michael Cannell on 3/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TTPushNotificationHandler : NSObject

+(void)handleMentionPush:(NSDictionary*)payload controller:(UINavigationController*)controller;
+(void)handlePhotoPush:(NSDictionary *)payload controller:(UINavigationController*)controller;
+(void)handleActivityPush:(NSDictionary *)payload controller:(UINavigationController*)controller;
@end
