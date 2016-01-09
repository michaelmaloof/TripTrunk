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
#import "MSTextField.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>


@interface LoginViewController ()

@property (strong, nonatomic) IBOutlet MSTextField *usernameTextField;
@property (strong, nonatomic) IBOutlet MSTextField *passwordTextField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    
    
}
- (IBAction)loginWithUsernameButtonPressed:(id)sender {
    NSError *error;
    
    [PFUser logInWithUsername:_usernameTextField.text
                     password:_passwordTextField.text
                        error:&error];
    if (error) {
        NSLog(@"Error: %@",error);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Try again",@"Try again")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{   
    }];
    
}


- (IBAction)onLoginTapped:(id)sender {

    [self _loginWithFacebook];

}

- (IBAction)signupWithEmailPressed:(id)sender {
    [self performSegueWithIdentifier:@"setUsernameSegue" sender:self];
}

- (void)_loginWithFacebook
{
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"email", @"public_profile", @"user_friends"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error)
    {
        
        if (error)
        {
            NSString *errorString = [error userInfo][@"error"];
            NSLog(@"%@",errorString);
            return;
        }
        
        if (!user)
        {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew)
        {
            NSLog(@"User signed up and logged in through Facebook!");
            [self showSetUsernameView];
            
        } else
        {
            NSLog(@"User logged in through Facebook!");
            
                // Make sure the user has a TripTrunk username
                 if (![user valueForKey:@"completedRegistration"] || [[user valueForKey:@"completedRegistration"] boolValue] == FALSE) {
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

#pragma mark - Keyboard delegate methods

// The following method needed to dismiss the keyboard after input with a click anywhere on the screen outside text boxes

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

// Go to the next textfield or close the keyboard when the return button is pressed

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField isKindOfClass:[MSTextField class]])
        dispatch_async(dispatch_get_main_queue(),
                       ^ { [[(MSTextField *)textField nextField] becomeFirstResponder]; });
    
    return YES;
    
}





@end
