//
//  TTBaseViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 10/10/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

#import <UIKit/UIKit.h>
#import "ParseErrorHandlingController.h"
#import "TTColor.h"
#import "TTFont.h"

@interface TTBaseViewController : UIViewController
@property (strong, nonatomic) NSMutableArray *followingActivities;
@property (strong, nonatomic) NSMutableArray *friends;
@property (strong, nonatomic) NSMutableArray *facebookFriends;
@property (strong, nonatomic) NSMutableArray *followers;
@property (strong, nonatomic) NSMutableArray *following;
@property (strong, nonatomic) NSMutableArray *pending;
@property (strong, nonatomic) NSMutableArray *promoted;

/**
 *  Make sure we have no tab bar titles
 *
 *
 */
//-(void)tabBarTitle;
-(void)alertUser:(NSString *)title withMessage:(NSString *)message withYes:(NSString *)yesButton withNo:(NSString *)noButton;
- (NSString*)deviceName;
@end
