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

@interface UsernameViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) PFUser *user;
@end

@implementation UsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"UsernameViewController viewDidLoad");
    
    _user = [PFUser currentUser];

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
        [_user saveInBackground];
        NSLog(@"Username Saved");
        return YES;
    }
    else {
        NSLog(@"No Username Entered");

        return NO;
    }
}


@end
