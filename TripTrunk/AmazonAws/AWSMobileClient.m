//
//  AWSMobileHubClient.m
//
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-objc v0.7
//
#import "AWSMobileClient.h"
#import <AWSMobileHubHelper/AWSMobileHubHelper.h>

@interface AWSMobileClient ()

@property (nonatomic) BOOL initialized;

@end

@implementation AWSMobileClient

- (instancetype)init {
    //AWSLogDebug(@"init");
    self = [super init];
    _initialized = NO;
    //[AWSLogger defaultLogger].logLevel = AWSLogLevelInfo;
    return self;
}

- (void)dealloc {
    // Should never get called
    //AWSLogError(@"Dealloc called on singleton AWSMobileClient.");
}

#pragma mark Singleton Methods

+ (instancetype)sharedInstance {
    static AWSMobileClient* client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[self alloc] init];
    });
    
    return client;
}

#pragma mark AppDelegate Methods

- (BOOL)didFinishLaunching:(UIApplication *)application
              withOptions:(NSDictionary *)launchOptions {
    //AWSLogDebug(@"didFinishLaunching:withOptions:");

    BOOL didFinishLaunching = [[AWSIdentityManager defaultIdentityManager] interceptApplication:application
                                                                  didFinishLaunchingWithOptions:launchOptions];

    didFinishLaunching &= [[AWSPushManager defaultPushManager] interceptApplication:application
                                                      didFinishLaunchingWithOptions:launchOptions];

    if (!_initialized) {
        [[AWSIdentityManager defaultIdentityManager] resumeSessionWithCompletionHandler:^(id result, NSError *error) {
            NSLog(@"result = %@, error = %@", result, error);
        }];
        _initialized = YES;
    }

    return didFinishLaunching;
}

- (BOOL)withApplication:(UIApplication *)application
               withURL:(NSURL *)url
 withSourceApplication:(NSString *)sourceApplication
        withAnnotation:(id)annotation {
    //AWSLogDebug(@"withApplication:withURL:...");

    [[AWSIdentityManager defaultIdentityManager] interceptApplication:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation];
    
    if (!_initialized) {
        _initialized = YES;
    }

    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    //AWSLogDebug(@"applicationDidBecomeActive");
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[AWSPushManager defaultPushManager] interceptApplication:application
             didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [[AWSPushManager defaultPushManager] interceptApplication:application
             didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[AWSPushManager defaultPushManager] interceptApplication:application
                                 didReceiveRemoteNotification:userInfo];
}

#pragma mark - AWS Methods

@end
