//
//  BaseLoginViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 1/4/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "TTBaseViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "MSTextField.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "EULAViewController.h"
#import "TTAnalytics.h"
#import "TTUtility.h"

@interface TTBaseLoginViewController : TTBaseViewController
@property (nonatomic)BOOL isFBUser;

-(void)previousLoginViewController;
-(BOOL)validateLoginInput:(NSString*)input type:(int)inputType;


@end
