//
//  TTProfileViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 9/20/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface TTProfileViewController : UIViewController
@property (strong, nonatomic) PFUser *user;
@end
