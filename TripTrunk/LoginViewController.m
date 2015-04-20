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

@interface LoginViewController ()


@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (IBAction)onLoginTapped:(id)sender {
    PFUser *user = [PFUser user];
    user.username = @"michaelmaloof";
    user.password = @"Harrypotter91";
    user.email = @"michaelmaloof1991@gmail.com";
    
    // other fields can be set if you want to save more information
    user[@"phone"] = @"614-270-1558";
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
            
        } else {
            NSString *errorString = [error userInfo][@"error"];
            // Show the errorString somewhere and let the user try again.
        }
    }];

}

@end
