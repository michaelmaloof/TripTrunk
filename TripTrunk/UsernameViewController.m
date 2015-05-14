//
//  UsernameViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/7/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "UsernameViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface UsernameViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) PFUser *user;
@end

@implementation UsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"UsernameViewController viewDidLoad");
    
    _user = [PFUser currentUser];
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            NSString *name = userData[@"name"];
            NSString *email = userData[@"email"];
            [_user setObject:facebookID forKey:@"fbid"];
            [_user setObject:name forKey:@"name"];
            [_user setObject:email forKey:@"email"];
            
            NSString *pictureURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID];
            [_user setObject:pictureURL forKey:@"profilePicUrl"];
            
            [_user saveInBackground];

        }
        else {
            NSLog(@"%@",error);
        }
    }];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitButtonPressed:(id)sender {

}

#pragma mark - Navigation

/**
 *  Make sure that we have a username and save it before we let the view unwind back to the home view controller
 */
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    NSString *username = _usernameTextField.text;
    if (username || ![username isEqualToString:@""]) {
        _user.username = username;
        NSError *error;
        [_user save:&error];
        
        if (error) {
            NSLog(@"Error: %@",error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Username Taken, please try another"
                                                           delegate:self
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return NO;
        }
        
        NSLog(@"Username Saved");
        return YES;
    }
    else {
        NSLog(@"No Username Entered");

        return NO;
    }
}


@end
