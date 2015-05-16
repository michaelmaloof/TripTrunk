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

            [self showSetUsernameView];

        } else {
            NSLog(@"User logged in through Facebook!");
            
            // Make sure the user has a TripTrunk username
            if (!user.username) {
                [self showSetUsernameView];
            }
            else
            {
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            }
        }
    }];
}

- (void)showSetUsernameView {
    [self performSegueWithIdentifier:@"setUsernameSegue" sender:self];
    
}



@end
