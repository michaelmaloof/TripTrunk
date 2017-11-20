//
//  TTBaseViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 10/10/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#define kScreenWidth [[UIScreen mainScreen] applicationFrame].size.width
#define kScreenHeight [[UIScreen mainScreen] applicationFrame].size.height

#import <UIKit/UIKit.h>
#import "ParseErrorHandlingController.h"
#import "TTColor.h"
#import "TTFont.h"

@interface TTBaseViewController : UIViewController

/**
 *  Make sure we have no tab bar titles
 *
 *
 */
-(void)tabBarTitle;


@end
