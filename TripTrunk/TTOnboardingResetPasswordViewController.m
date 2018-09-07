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
@property NSString *email;
@property BOOL lookupInterrupted;
@property BOOL lookupFinished;
@property BOOL meetsMinimumRequirements;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalPositionConstraint;
@end

@implementation TTOnboardingResetPasswordViewController

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    //FIXME: iPhone4 for iPad hack
    if ([[self deviceName] containsString:@"iPad"]){
        self.verticalPositionConstraint.constant = -145;
        self.acceptabilityLabel.textColor = [UIColor whiteColor];
    }
}

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
    
    //Email has changed
    self.acceptabilityLabel.text = @"";
    self.resetButton.hidden = YES;
    self.lookupInterrupted = YES;
    self.lookupFinished = NO;
    
    NSString *typedText;
    
    if(range.location == textField.text.length)
        typedText = [textField.text stringByAppendingString:string];
    else typedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if([TTEmailValidation emailIsValid:typedText]){
        self.acceptabilityLabel.text = @"";
        self.resetButton.hidden = NO;
    }else{
        self.acceptabilityLabel.text = @"Please enter a valid email address...";
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
                        
                        UIAlertController * alert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Request Sent",@"Request Sent")
                                                                                      message:NSLocalizedString(@"If you don't see the email in 24 hours please try to reset the password again",@"If you don't see the email in 24 hours please try to reset the password again")
                                                                               preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* noButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay",@"Okay")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action){
                                                                             NSLog(@"you pressed Okay button");
                                                                             [self.navigationController popViewControllerAnimated:YES];
                                                                         }];
                        [alert addAction:noButton];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                        
                        
                    }else{
                        
                        UIAlertController * alert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                                      message:error.localizedDescription
                                                                               preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* noButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay",@"Okay")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action){
                                                                             NSLog(@"you pressed cancel button");
                                                                             
                                                                         }];
                        [alert addAction:noButton];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                    
                }];
//            }
        }
    }
}

@end
