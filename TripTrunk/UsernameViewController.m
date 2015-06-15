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
#import "MSTextField.h"

@interface UsernameViewController ()
@property (strong, nonatomic) IBOutlet UITextField *fullnameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField *hometownTextField;

@property (strong, nonatomic) PFUser *user;
@property (nonatomic)BOOL isFBUser;
@end

@implementation UsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"UsernameViewController viewDidLoad");
    
    _fullnameTextField.delegate = self;
    _emailTextField.delegate = self;
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    _hometownTextField.delegate = self;
    
    _user = [PFUser currentUser];
    _isFBUser = NO;

    // If the user has been created - aka logged in through fb.
    if (_user && [_user valueForKey:@"fbid"]) {

        _isFBUser = YES;
        
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
    NSString *fullName = _fullnameTextField.text;
    NSString *email = _emailTextField.text;
    NSString *password = _passwordTextField.text;
    NSString *hometown = _hometownTextField.text;

    
    if ((username || ![username isEqualToString:@""])
        && fullName && email && password && hometown) {
        
        _user = [PFUser user];
        _user.username = username;
        [_user setValue:fullName forKey:@"name"];
        _user.email = email;
        [_user setPassword:password];
        [_user setValue:hometown forKey:@"hometown"];

        NSError *error;
        BOOL didSignUp;
        // fb user exists so save, signup if it's a new user
        if (_isFBUser) {
           didSignUp = [_user save:&error];

        }
        else
        {
           didSignUp = [_user signUp];
        }
        
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

#pragma mark - Keyboard delegate methods

// The following method needed to dismiss the keyboard after input with a click anywhere on the screen outside text boxes

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesBegan:withEvent:");
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
