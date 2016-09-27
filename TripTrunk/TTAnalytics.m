//
//  TTAnalytics.m
//  TripTrunk
//
//  Created by Michael Cannell on 9/20/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#define devTrackingID @"UA-72708236-2"
#define prodTrackingID @"UA-72708236-3"

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

id<GAITracker> tracker;

@implementation TTAnalytics

+(void)initAnalyticsOnStart:(BOOL)env{
    
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
    gai.dispatchInterval = 20;
    
    if(env)
       tracker = [[GAI sharedInstance] trackerWithTrackingId:prodTrackingID];
    else tracker = [[GAI sharedInstance] trackerWithTrackingId:devTrackingID];
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
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

+(void)errorOccurred:(NSString*)errorMessage method:(NSString*)method{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Error"
                                                          action:method
                                                           label:errorMessage
                                                           value:nil] build]];
}

+(void)accountCreated{
    tracker = [[GAI sharedInstance] defaultTracker];
    NSString *user = [PFUser currentUser].username;
    [tracker set:kGAIUserId value:user];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Users"
                                                          action:@"Account Creation"
                                                           label:user
                                                           value:nil] build]];
}

+(void)photoLiked:(PFUser*)owner{
    tracker = [[GAI sharedInstance] defaultTracker];
    NSString *user = owner.username;
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Photo Liked"
                                                           label:user
                                                           value:nil] build]];
}

+(void)photoUnliked:(PFUser*)owner{
    tracker = [[GAI sharedInstance] defaultTracker];
    NSString *user = owner.username;
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Photo Unliked"
                                                           label:user
                                                           value:nil] build]];
}

+(void)photoViewed:(NSString*)photo{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Photo Viewed"
                                                           label:photo
                                                           value:nil] build]];
}

+(void)userMentioned:(NSString*)user{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"User Mention"
                                                           label:user
                                                           value:nil] build]];
}

+(void)deleteUserMention{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"User Mention"
                                                           label:nil
                                                           value:nil] build]];
}

+(void)commentAdded:(NSString*)user{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Comment"
                                                           label:user
                                                           value:nil] build]];
}

+(void)trunkCreated:(NSUInteger)numOfPhotos numOfMembers:(NSUInteger)numOfMembers{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Trunk Created"
                                                           label:nil
                                                           value:nil] build]];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Trunk"
                                                          action:@"photo count"
                                                           label:[NSString stringWithFormat:@"%li",(unsigned long)numOfPhotos]
                                                           value:nil] build]];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Trunk"
                                                          action:@"member count"
                                                           label:[NSString stringWithFormat:@"%li",(unsigned long)numOfMembers]
                                                           value:nil] build]];
}

+(void)facebookPhotoUpload{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Facebook Photo Upload"
                                                           label:nil
                                                           value:nil] build]];
}

+(void)downloadPhoto{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Photo Downloaded"
                                                           label:nil
                                                           value:nil] build]];
}

+(void)reportPhoto{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Photo Reported"
                                                           label:nil
                                                           value:nil] build]];
}

+(void)deleteTrunk{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Trunk Deleted"
                                                           label:nil
                                                           value:nil] build]];
}

+(void)deleteUser{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"User Deleted From Trunk"
                                                           label:nil
                                                           value:nil] build]];
}

+(void)deleteComment{
    tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Activity"
                                                          action:@"Comment Deleted"
                                                           label:nil
                                                           value:nil] build]];
}


@end
