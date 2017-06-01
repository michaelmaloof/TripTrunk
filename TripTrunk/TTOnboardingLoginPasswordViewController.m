//
//  TTOnboardingLoginPasswordViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/17/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTOnboardingLoginPasswordViewController.h"
#import "TTOnboardingTextField.h"
#import "TTOnboardingButton.h"

@interface TTOnboardingLoginPasswordViewController ()
@property (strong, nonatomic) IBOutlet TTOnboardingTextField *passwordTextField;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *loginButton;
@property (strong, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@end

@implementation TTOnboardingLoginPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginButton.hidden = YES;
    [self.passwordTextField becomeFirstResponder];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    NSString *typedText;
    
    if(range.location == textField.text.length)
        typedText = [textField.text stringByAppendingString:string];
    else typedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if(typedText.length > 7){
        self.loginButton.hidden = NO;
        self.forgotPasswordButton.hidden = YES;
    }else{
        self.loginButton.hidden = YES;
        self.forgotPasswordButton.hidden = NO;
    }
    
    
    return YES;
}

#pragma mark - UIButton
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backWasTapped:(id)sender {
    [self previousLoginViewController];
}


- (IBAction)loginWasTapped:(id)sender {
    
    [PFUser logInWithUsernameInBackground:self.username password:[self.passwordTextField.text lowercaseString] block:^(PFUser * _Nullable user, NSError * _Nullable error) {
        
        if (error) {
            NSLog(@"Error: %@",error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                            message:NSLocalizedString(@"Your username and/or password is incorrect. Please try again.",@"Your username and/or password is incorrect. Please try again.")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
        
    }];
}


@end
