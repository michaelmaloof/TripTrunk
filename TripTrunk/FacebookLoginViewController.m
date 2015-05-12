//
//  LoginViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "FacebookLoginViewController.h"
#import "HomeMapViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <FacebookSDK/FacebookSDK.h>

@interface FacebookLoginViewController ()


@end

@implementation FacebookLoginViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    
    [PFFacebookUtils initializeFacebook];
    
}

- (IBAction)facebookLoginPressed:(UIButton *)sender {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [indicator setTintColor:[UIColor blackColor]];
    [indicator startAnimating];
    [self.view addSubview:indicator];
    
    // Set permissions required from the facebook user account, you can find more about facebook permissions here https://developers.facebook.com/docs/facebook-login/permissions/v2.0
    
    NSArray *permissionsArray = @[ @"public_profile", @"email", @"user_location"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        
        [indicator stopAnimating];
        [indicator removeFromSuperview];
        
        if (!user) {
            NSString *errorMessage = nil;
            if (!error) {
                //NSLog(@"Uh oh. The user cancelled the Facebook login.");
                errorMessage = @"Uh oh. The user cancelled the Facebook login.";
            } else {
                //NSLog(@"Uh oh. An error occurred: %@", error);
                errorMessage = [error localizedDescription];
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In Error"
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
            [alert show];
        } else {
            if (user.isNew) {
                //NSLog(@"User with facebook signed up and logged in!");
                FBRequest *request = [FBRequest requestForMe];
                
                // Send request to Facebook
                [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    // handle response
                    
                    if(!error){
                        
                        [[PFUser currentUser] setObject:[result objectForKey:@"id"] forKey:@"fbId"];
                        [[PFUser currentUser] setObject:[result objectForKey:@"name"] forKey:@"name"];
                        [[PFUser currentUser] setObject:[result objectForKey:@"name"] forKey:@"username"];
                        [[PFUser currentUser] setObject:[result objectForKey:@"location"][@"name"] forKey:@"location"];
                        [[PFUser currentUser] setObject:[result objectForKey:@"email"] forKey:@"email"];
                        [[PFUser currentUser] saveInBackground];
                    }
                    }];
            } else {
                //NSLog(@"User with facebook logged in!");
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
        }
    }];
}

@end
