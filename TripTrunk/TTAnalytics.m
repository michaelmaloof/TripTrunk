//
//  TTAnalytics.m
//  TripTrunk
//
//  Created by Michael Cannell on 9/20/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#define trackingID @"UA-72708236-2"

#import "TTAnalytics.h"
#import "GoogleAnalytics/GAI.h"
#import "GoogleAnalytics/GAIDictionaryBuilder.h"
#import "GoogleAnalytics/GAIEcommerceProduct.h"
#import "GoogleAnalytics/GAIEcommerceProductAction.h"
#import "GoogleAnalytics/GAIEcommercePromotion.h"
#import "GoogleAnalytics/GAIFields.h"
#import "GoogleAnalytics/GAILogger.h"
#import "GoogleAnalytics/GAITrackedViewController.h"
#import "GoogleAnalytics/GAITracker.h"
#import <Parse/Parse.h>

@implementation TTAnalytics

+(void)initAnalyticsOnStart{
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:trackingID];
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString *user = [PFUser currentUser].username;
    [tracker set:kGAIUserId value:user];
    [tracker set:kGAIAppVersion value:version];
}

+(void)trackScreen:(NSString*)screenName{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}



@end
