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
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *facebook;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self roundButtons];
    [self setPlaceholderText];
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    [_usernameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [_passwordTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self handleLoginDisplay];
}

-(void)setPlaceholderText{
    
    NSAttributedString *username = [[NSAttributedString alloc] initWithString:@"username" attributes:@{ NSForegroundColorAttributeName : [TTColor tripTrunkRed]}];
    self.usernameTextField.attributedPlaceholder = username;
    
    NSAttributedString *password = [[NSAttributedString alloc] initWithString:@"password" attributes:@{ NSForegroundColorAttributeName : [TTColor tripTrunkRed]}];
    self.passwordTextField.attributedPlaceholder = password;

}

-(void)roundButtons{
    [self.loginButton.layer setCornerRadius:20.0f];
    [self.loginButton.layer setMasksToBounds:YES];
    [self.facebook.layer setCornerRadius:20.0f];
    [self.facebook.layer setMasksToBounds:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [self handleLoginDisplay];
}

-(void)textFieldDidChange :(UITextField *)theTextField{
    [self handleLoginDisplay];
    
    if ([theTextField.text length] > 1){
        
        NSString *code = [theTextField.text substringFromIndex: [theTextField.text length] - 2];
        if ([code isEqualToString:@" "]){
            [theTextField setKeyboardType:UIKeyboardTypeDefault];
        }
        
    }
}

- (IBAction)loginWithUsernameButtonPressed:(id)sender {
    NSError *error;
    NSString *username = [_usernameTextField.text lowercaseString];

    [PFUser logInWithUsername:username
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
            [self showSetUsernameView];
            
        } else
        {
            if ([user objectForKey:@"fbid"] == nil)
            {
                FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
                [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                    if (!error)
                    {
                        // result is a dictionary with the user's Facebook data
                        NSDictionary *userData = (NSDictionary *)result;
                        PFUser *user = [PFUser currentUser];
                        NSString *fbid = [userData objectForKey:@"id"];
                        if (fbid){
                            [user setObject:fbid forKey:@"fbid"];
                            [user saveInBackground];
                        }
                    }
                    }];
                    
                 }
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
    [self handleLoginDisplay];
    [super touchesBegan:touches withEvent:event];
}

// Go to the next textfield or close the keyboard when the return button is pressed

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    [self handleLoginDisplay];
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField isKindOfClass:[MSTextField class]])
        dispatch_async(dispatch_get_main_queue(),
                       ^ { [[(MSTextField *)textField nextField] becomeFirstResponder]; });
    
    return YES;
    
}

-(void)handleLoginDisplay{
    if ([self.usernameTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""]){
        self.loginButton.enabled = NO;
        self.loginButton.alpha = .3;
    } else {
        self.loginButton.enabled = YES;
        self.loginButton.alpha = 1;
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    [self handleLoginDisplay];
}

- (IBAction)signUpWithFacebookWasTapped:(id)sender {
    [self _loginWithFacebook];

}





@end
