//
//  LoginViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "LoginViewController.h"
#import "HomeMapViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>

@interface LoginViewController ()


@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    
}

- (IBAction)onLoginTapped:(id)sender {
    PFUser *user = [PFUser user];
    user.username = @"mattschoch";
    user.password = @"mattspassword";
    user.email = @"mattschoch@gmail.com";
    
    // other fields can be set if you want to save more information
    user[@"phone"] = @"513-673-3114";
    
//    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (!error) {
//            [self dismissViewControllerAnimated:YES completion:^{
//                
//            }];
//            
//        } else {
//            NSString *errorString = [error userInfo][@"error"];
//            NSLog(@"%@",errorString);
//        }
//    }];
    [self _loginWithFacebook];

}

- (void)_loginWithFacebook {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"email", @"public_profile", @"user_friends"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        
        if (error) {
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"%@",errorString);
            return;

        }
        
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew) {
            NSLog(@"User signed up and logged in through Facebook!");
            user.username = @"mattschoch";
            [user saveInBackground];
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        } else {
            NSLog(@"User logged in through Facebook!");
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
    }];
}

@end
