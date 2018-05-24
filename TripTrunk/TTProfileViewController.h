//
//  TTProfileViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 9/20/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TTBaseViewController.h"

@interface TTProfileViewController : TTBaseViewController
@property (strong, nonatomic) PFUser *user;
@property (nonatomic, strong) id delegate;
@end
