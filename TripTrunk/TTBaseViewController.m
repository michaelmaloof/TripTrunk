//
//  TTBaseViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 10/10/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import <sys/utsname.h>
#import "TTBaseViewController.h"
#import "AFNetworkReachabilityManager.h"
#import "TTUtility.h"
#import "TTAnalytics.h"

@interface TTBaseViewController ()

@end

@implementation TTBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.followingActivities = [[NSMutableArray alloc] init];
    self.friends = [[NSMutableArray alloc] init];
    self.facebookFriends = [[NSMutableArray alloc] init];
    self.followers = [[NSMutableArray alloc] init];
    self.following = [[NSMutableArray alloc] init];
    self.pending = [[NSMutableArray alloc] init];
    self.promoted = [[NSMutableArray alloc] init];
    
//This is to remove the titles under the tab bar icons
//    [self tabBarTitle];
    [self checkUserInternetConnection];
    
//    if (![PFUser currentUser]) { //if the user isn't logged in take them to the map and force login
//        [self.tabBarController setSelectedIndex:0];
//    }
//This is to remove the word "Back" on the nav bar. We want there just to be an arrow @"<".
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    //set bar item font
    
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [TTColor tripTrunkBlue], NSForegroundColorAttributeName,
                                                                    [TTFont tripTrunkFontBold14], NSFontAttributeName, nil] forState:UIControlStateNormal];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [TTColor tripTrunkBlue], NSForegroundColorAttributeName,
                                                                    [TTFont tripTrunkFontBold14], NSFontAttributeName, nil] forState:UIControlStateNormal];
}

//This is to remove the titles under the tab bar icons
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
//    [self tabBarTitle];
//    self.tabBarController.tabBar.hidden = NO;

    NSString *screenName = [NSString stringWithFormat:@"%@",[self class]];
    [TTAnalytics trackScreen:screenName];
}

-(void)checkUserInternetConnection{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
                [[TTUtility sharedInstance] internetConnectionFound];
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [[TTUtility sharedInstance] internetConnectionFound];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                [[TTUtility sharedInstance] noInternetConnection];
                break;
        }
    }];

}

#pragma mark - UIAlertView
-(void)alertUser:(NSString *)title withMessage:(NSString *)message withYes:(NSString *)yesButton withNo:(NSString *)noButton{

        UIAlertController * alert=[UIAlertController alertControllerWithTitle:title
                                                                      message:message
                                                               preferredStyle:UIAlertControllerStyleAlert];
    if(![yesButton isEqualToString:@""]){
        UIAlertAction* yesB = [UIAlertAction actionWithTitle:yesButton
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action){
                                                              NSLog(@"you pressed the Yes button");
                                                          }];
        [alert addAction:yesB];
    }
    
    if(![noButton isEqualToString:@""]){
        UIAlertAction* noB = [UIAlertAction actionWithTitle:noButton
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action){
                                                             NSLog(@"you pressed cancel button");
                                                         }];
        [alert addAction:noB];
    }
        [self presentViewController:alert animated:YES completion:nil];
}


-(void)tabBarTitle{
//REPAIR: This needs to be fixed for new design
//    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
//    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
//    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
//    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
//    [[self.tabBarController.viewControllers objectAtIndex:4] setTitle:@""];
    
}

- (NSString*)deviceName{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

@end
