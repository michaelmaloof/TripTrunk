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


@implementation TTAnalytics

+(void)initAnalyticsOnStart{
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:trackingID];
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString *user = [PFUser currentUser].username;
    [tracker set:kGAIUserId value:user];
    [tracker set:kGAIAppVersion value:version];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Users"
                                                          action:@"Startup"
                                                           label:user
                                                           value:nil] build]];
}

+(void)trackScreen:(NSString*)screenName{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

+(void)errorOccurred:(NSString*)errorMessage method:(NSString*)method{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Error"
                                                          action:method
                                                           label:errorMessage
                                                           value:nil] build]];
}

+(void)accountCreated{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    NSString *user = [PFUser currentUser].username;
    [tracker set:kGAIUserId value:user];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Users"
                                                          action:@"Account Creation"
                                                           label:user
                                                           value:nil] build]];
}

+(void)photoLiked:(PFUser*)owner{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    NSString *user = owner.username;
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Like"
                                                           label:user
                                                           value:nil] build]];
}

+(void)photoViewed{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Photo Viewed"
                                                           label:nil
                                                           value:nil] build]];
}



@end
