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
#import "MBProgressHUD.h"
#import "CitySearchViewController.h"

@interface UsernameViewController () <CitySearchViewControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *fullnameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *usernameTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UITextField *hometownTextField;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;

@property (strong, nonatomic) PFUser *user;
@property (nonatomic)BOOL isFBUser;
@end

@implementation UsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setPlaceholderText];
    [self roundCreateButton];
    _firstNameTextField.delegate = self;
    _fullnameTextField.delegate = self;
    _emailTextField.delegate = self;
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    _hometownTextField.delegate = self;
    _user = [PFUser currentUser];
    _isFBUser = NO;

    // If the user has been created - aka logged in through fb.
    if (_user) {
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.title = NSLocalizedString(@"You're About to Make a New TripTrunk Account Using This Facebook Account",@"You're About to Make a New TripTrunk Account Using This Facebook Account");
        alert.message = NSLocalizedString(@"If you'd like to instead link your Facebook to an already existing TripTrunk account, please go to settings within your TripTrunk account", @"If you'd like to link your Facebook to an already existing TripTrunk account, please go to settings within your TripTrunk account");
        alert.delegate = self;
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel",@"Cancel!")];
        [alert addButtonWithTitle:NSLocalizedString(@"Great, Begin Creating Account!",@"Great, Begin Create Account!")];
        [alert show];

          }
}

-(void)setPlaceholderText{
    
    NSAttributedString *firstName = [[NSAttributedString alloc] initWithString:@"first name" attributes:@{ NSForegroundColorAttributeName : [TTColor tripTrunkRed]}];
    self.firstNameTextField.attributedPlaceholder = firstName;
    
    NSAttributedString *fullName = [[NSAttributedString alloc] initWithString:@"last name" attributes:@{ NSForegroundColorAttributeName : [TTColor tripTrunkRed]}];
    self.fullnameTextField.attributedPlaceholder = fullName;
    
    NSAttributedString *email = [[NSAttributedString alloc] initWithString:@"email" attributes:@{ NSForegroundColorAttributeName : [TTColor tripTrunkRed]}];
    self.emailTextField.attributedPlaceholder = email;
    
    NSAttributedString *username = [[NSAttributedString alloc] initWithString:@"username" attributes:@{ NSForegroundColorAttributeName : [TTColor tripTrunkRed]}];
    self.usernameTextField.attributedPlaceholder = username;
    
    NSAttributedString *password = [[NSAttributedString alloc] initWithString:@"password" attributes:@{ NSForegroundColorAttributeName : [TTColor tripTrunkRed]}];
    self.passwordTextField.attributedPlaceholder = password;
    
    NSAttributedString *hometown = [[NSAttributedString alloc] initWithString:@"current city" attributes:@{ NSForegroundColorAttributeName : [TTColor tripTrunkRed]}];
    self.hometownTextField.attributedPlaceholder = hometown;
    
}

-(void)roundCreateButton{
    [self.createAccountButton.layer setCornerRadius:20.0f];
    [self.createAccountButton.layer setMasksToBounds:YES];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){
        [self handleFacebookUser];
    } else if (alertView.tag != 11) {
            if (_user) {
                [self.user deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (error){
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                }];
                 }];
            }
    }
}

-(void)textFieldDidChange :(UITextField *)theTextField{
    if ([theTextField.text length] > 1){

    NSString *code = [theTextField.text substringFromIndex: [theTextField.text length] - 2];
    if ([code isEqualToString:@" "]){
        [theTextField setKeyboardType:UIKeyboardTypeDefault];
    }
    }
}



-(void)handleFacebookUser{
    _isFBUser = YES;
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateFieldsWithFBInfo:userData];
            });
            
            NSString *facebookID = userData[@"id"];
            //                NSString *name = userData[@"name"];
            NSString *email = userData[@"email"];
            
            if (email == nil){
                email = @"";
            }
            
            if (facebookID == nil){
                facebookID = @"";
            }
            
            //                if (name == nil){
            //                    name = @"";
            //                }
            
            
            [_user setObject:facebookID forKey:@"fbid"];
            //                [_user setObject:name forKey:@"name"];
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


- (void)updateFieldsWithFBInfo:(NSDictionary *)userData {
    [self.emailTextField setText:userData[@"email"]];
//    [self.fullnameTextField setText:userData[@"name"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitButtonPressed:(id)sender {

}

- (IBAction)cancelButtonPressed:(id)sender {
    if (_user) {
        [self.user deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error){
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }];
    } else {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - CitySearchViewController Delegate

- (void)citySearchDidSelectLocation:(TTPlace *)location {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
    // If it's a US city/state, we don't need to display the country, we'll assume United States.
    
    [self.hometownTextField setText:[location.name stringByReplacingOccurrencesOfString:@", United States" withString:@""]];
}

#pragma mark - Navigation

/**
 *  Make sure that we have a username and save it before we let the view unwind back to the home view controller
 */
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    
    if ([identifier isEqualToString:@"cancelUnwind"]) {
        return NO;
    }
    else if ([identifier isEqualToString:@"submitUnwind"])
    {
    
        NSString *username =  [_usernameTextField.text lowercaseString];
        NSString *firstName = _firstNameTextField.text;
        NSString *lastName = _fullnameTextField.text;
        NSString *email = _emailTextField.text;
        NSString *password = _passwordTextField.text;
        NSString *hometown = _hometownTextField.text;
        
        if(![self validateUsername:username])
            return NO;
        
        // Show a progress hud
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        // Init the user ONLY if it doesn't exist. If we're logging in with FB, _user is already populated
        if (!_user) {
            _user = [PFUser user];
        }
        else {
            _user = [PFUser currentUser];
        }
        
        _user.username = username;
        [_user setValue:firstName forKey:@"firstName"];
        [_user setValue:lastName forKey:@"lastName"];
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        [_user setValue:fullName forKey:@"name"];
        _user.email = email;
        [_user setPassword:password];
        [_user setValue:hometown forKey:@"hometown"];
        
        // Set that the user has completed registration
        [_user setValue:[NSNumber numberWithBool:YES] forKey:@"completedRegistration"];
        
        NSError *error;
        // fb user exists so save, signup if it's a new user
        if (_isFBUser) {
            [_user save:&error];
            // After setting the username/password, the Session Token gets erased because it was authenticated with FB.
            // So, we now have to Log In again otherwise an error with throw.
            [PFUser logInWithUsernameInBackground:_user.username password:_user.password];
        }
        else
        {
           [_user signUp:&error];
        }
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if (error.code == 202)
        {
            //Log error
            [ParseErrorHandlingController handleError:error];

            //Create 'username in use' alert view
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                            message:NSLocalizedString(@"Username Taken, please try another",@"Username Taken, please try another")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                  otherButtonTitles:nil, nil];
            alert.tag = 11;

            //Clear user property
//            self.user = nil;

            //Show alert view
            [alert show];
            return NO;
        }
        else if (error.code == 203)
        {
            //Log error
            [ParseErrorHandlingController handleError:error];

            //Create 'email address in use' alert view
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                            message:NSLocalizedString(@"This email address is linked to an existing account, please try another",@"This email address is linked to an existing account, please try another")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                  otherButtonTitles:nil, nil];
            //Clear user property
//            self.user = nil;

            //Show alert view
            [alert show];
            return NO;
        }else if (error.code == 125){
            //Log error
            [ParseErrorHandlingController handleError:error];
            
            //Create 'email address invalid' alert view
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                            message:NSLocalizedString(@"Invalid Email Address",@"Invalid Email Address")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                  otherButtonTitles:nil, nil];
            
            //Show alert view
            [alert show];
            return NO;
        }

        return YES;

    }
    else {
        return NO;
    }
}

-(BOOL)validateUsername:(NSString*)username{
    
    if(![self validateAllFieldsHaveValues:username])
        return NO;
    
    if(![self validateUsernameLength:username])
        return NO;
    
    if(![self validateUsernameHasNoSpaces:username])
        return NO;
    
    if (![username containsString:@"."] && ![username containsString:@"_"] && ![username containsString:@"-"]){
        
        if(![self validateUsernameDoesNotContainIllegalChars:username])
            return NO;
        
    } else {
        NSString *unders = [username stringByReplacingOccurrencesOfString:@"_" withString:@""];
        NSString *dash = [unders stringByReplacingOccurrencesOfString:@"-" withString:@""];
        NSString *newUsername = [dash stringByReplacingOccurrencesOfString:@"." withString:@""];
        
        if(![self validateUsernameDoesNotContainIllegalChars:newUsername])
            return NO;
    }
    
    if(![self validateUsernameDoesNotContainSuccessiveChars:username]) //periods and dashes only
        return NO;
    
    if(![self validateUsernameHasMaximumOfTwoChars:username]) //periods and dashes only
        return NO;
    
    if(![self validateUsernameDoesNotBeginWithIllegalChars:username])
        return NO;
    
    if(![self validateEmailAddressIsValidFormat:self.emailTextField.text])
        return NO;
    
    return YES;
}

-(BOOL)validateAllFieldsHaveValues:(NSString*)username{
    
    if (username.length == 0 ||
        self.emailTextField.text.length == 0 || self.passwordTextField.text.length == 0 ||
        self.hometownTextField.text.length == 0 || self.firstNameTextField.text.length == 0 ||
        self.fullnameTextField.text.length == 0) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Please fill out all fields",@"Please fill out all fields")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        
        return NO;
    }
    
    return YES;
}

-(BOOL)validateUsernameLength:(NSString*)username{
    if (username.length < 3 || username.length > 20 ){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Username must be between 2-20 characters",@"Username must be between 2-20 characters")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        
        return NO;
    }
    
    return YES;
}

-(BOOL)validateUsernameHasNoSpaces:(NSString*)username{
    
    if ([username containsString:@" "]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Username can't have any spaces.",@"Username can't have any spaces.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        
        return NO;
        
    }
    
    return YES;
}

-(BOOL)validateUsernameDoesNotContainIllegalChars:(NSString*)username{
    
    NSString* newStr = [username stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    
    if ([newStr length] < [username length])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Username can only contain the following characters:\n \n Letters\n Numbers\n _\n .\n -\n", @"Username can only contain the following characters:\n \n Letters\n Numbers\n _\n .\n -\n")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        
        return NO;
        
    }
    
    return YES;
}

-(BOOL)validateUsernameDoesNotContainSuccessiveChars:(NSString*)username{
    
    if([username containsString:@".."] || [username containsString:@"--"]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Username cannot contain repeated periods or dashes.", @"Username cannot contain repeated periods or dashes.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        
        return NO;
        
    }
    
    return YES;
}

-(BOOL)validateUsernameHasMaximumOfTwoChars:(NSString*)username{
    
    NSInteger dashCount = [[username componentsSeparatedByString:@"-"] count]-1;
    NSInteger periodCount = [[username componentsSeparatedByString:@"."] count]-1;
    
    if(dashCount > 2 || periodCount> 2){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Username cannot contain more than 2 periods or dashes.", @"Username cannot contain more than 2 periods or dashes.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        return NO;
    }
    
    return YES;
}

-(BOOL)validateUsernameDoesNotBeginWithIllegalChars:(NSString*)username{
    
    NSString *firstChar = [username substringToIndex:1];
    if([firstChar isEqualToString:@"."] || [firstChar isEqualToString:@"-"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Username cannot begin with periods or dashes.", @"Username cannot begin with periods or dashes.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        return NO;
    }
    
    return YES;
}

//FIXME this doesnt actually validate if its a real email
-(BOOL)validateEmailAddressIsValidFormat:(NSString*)emailAddress{
    NSString *expression = @"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$";
    NSError *error = NULL;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:emailAddress options:0 range:NSMakeRange(0, [emailAddress length])];
    
    if(!match || [emailAddress containsString:@".con"]){
        //Create 'email address invalid' alert view
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                        message:NSLocalizedString(@"Invalid Email Address",@"Invalid Email Address")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        
        //Show alert view
        [alert show];
        return NO;
    }
    return YES;
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

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ([textField isEqual:self.hometownTextField]) {
        [textField resignFirstResponder];
        
        CitySearchViewController *searchView = [[CitySearchViewController alloc] init];
        searchView.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:searchView];
        [self presentViewController:navController animated:YES completion:nil];
        return NO;
    }
    
    return  YES;
}


@end
