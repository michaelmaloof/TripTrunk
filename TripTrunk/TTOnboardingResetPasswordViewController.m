//
//  TTOnboardingResetPasswordViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/17/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTOnboardingResetPasswordViewController.h"
#import "TTOnboardingTextField.h"
#import "TTOnboardingButton.h"
#import "TTEmailValidation.h"

@interface TTOnboardingResetPasswordViewController ()
@property (strong, nonatomic) IBOutlet TTOnboardingTextField *emailTextField;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *resetButton;
@property (strong, nonatomic) IBOutlet UILabel *acceptabilityLabel;
@property BOOL meetsMinimumRequirements;
@end

@implementation TTOnboardingResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.resetButton.hidden = YES;
    [self.emailTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if([self.emailTextField.text containsString:@"@"] && [self.emailTextField.text containsString:@"."]){
        self.resetButton.hidden = NO;
        self.meetsMinimumRequirements = YES;
    }else{
        self.resetButton.hidden = YES;
        self.meetsMinimumRequirements = NO;
    }
    
    NSString *e = textField.text; NSString *email;
    if([string isEqualToString:@""])
        email = [e substringToIndex:e.length - 1];
    else email = [e stringByAppendingString:string];
    
    if([TTEmailValidation emailIsValid:email]){
        self.resetButton.hidden = NO;
        self.meetsMinimumRequirements = YES;
    }else{
        self.resetButton.hidden = YES;
        self.meetsMinimumRequirements = NO;
    }
    
    
    return YES;
}

#pragma mark - UIButton
- (IBAction)backWasTapped:(id)sender {
    [self previousLoginViewController];
}

- (IBAction)resetWasTapped:(id)sender {
    if(self.meetsMinimumRequirements){
        NSString *email =  [self.emailTextField.text lowercaseString];
        if([self validateLoginInput:email type:3]){
//            //reset password
//            if (![self.emailTextField.text containsString:@"@"]){
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Enter Valid Email",@"Please Enter Valid Email")
//                                                                message:NSLocalizedString(@"",@"")
//                                                               delegate:self
//                                                      cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
//                                                      otherButtonTitles:nil, nil];
//                [alert show];
//            } else {
                [PFUser requestPasswordResetForEmailInBackground:self.emailTextField.text block:^(BOOL succeeded, NSError * _Nullable error) {
                    if(!error){
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Request Sent",@"Request Sent")
                                                                        message:NSLocalizedString(@"If you don't see the email in 24 hours please try to reset the password again",@"If you don't see the email in 24 hours please try to reset the password again")
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                                              otherButtonTitles:nil, nil];
                        alert.tag = 1;
                        [alert show];
                    }else{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                        message:error.localizedDescription
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                                              otherButtonTitles:nil, nil];
                        alert.tag = 1;
                        [alert show];
                    }
                    
                }];
//            }
        }
    }
}

@end
