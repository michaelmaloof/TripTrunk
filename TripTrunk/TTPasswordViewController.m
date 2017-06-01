//
//  TTPasswordViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTPasswordViewController.h"
#import "TTNameViewController.h"

@interface TTPasswordViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
//FIXME: Why is this here on an account creation?
@property (weak, nonatomic) IBOutlet UIButton *forgotPassword;
@property (strong, nonatomic) IBOutlet UILabel *acceptabilityLabel;
@property NSString *password;
@property BOOL meetsMinimumRequirements;

@end

@implementation TTPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.passwordTextField.delegate = self;
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.passwordTextField.text = @"";
    self.nextButton.hidden = YES;
    self.meetsMinimumRequirements = NO;
    //Why do we have this here?
    self.forgotPassword.hidden = YES;
}

-(void)viewDidAppear:(BOOL)animated{
    [self.passwordTextField becomeFirstResponder];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"next"]){
        TTNameViewController *nameVC = segue.destinationViewController;
        [self.user setObject:self.password forKey:@"Password"];
        nameVC.user = self.user;
    }
}

//Keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitPassword];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    //password has changed
    self.acceptabilityLabel.text = @"";
    self.nextButton.hidden = YES;
    self.meetsMinimumRequirements = NO;
    
    NSString *typedText;
    
    if(range.location == textField.text.length)
        typedText = [textField.text stringByAppendingString:string];
    else typedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if(typedText.length > 7){
        self.nextButton.hidden = NO;
        //self.forgotPassword.hidden = YES;
        self.meetsMinimumRequirements = YES;
    }else if([typedText containsString:@" "]){
            self.acceptabilityLabel.text = @"Password cannot contain spaces.";
            self.nextButton.hidden = YES;
            self.meetsMinimumRequirements = NO;
    }else{
        self.nextButton.hidden = YES;
        //self.forgotPassword.hidden = NO;
        self.meetsMinimumRequirements = NO;
    }
    
    
    return YES;
}

-(void)submitPassword {
    if(self.meetsMinimumRequirements){
        NSString *password =  [self.passwordTextField.text lowercaseString];
        if([self validateLoginInput:password type:1] == YES){
            self.password = password;
            [self performSegueWithIdentifier:@"next" sender:self];
        }else{
            self.acceptabilityLabel.text = NSLocalizedString(@"Password can't have any spaces.", @"Password can't have any spaces.");
            self.nextButton.hidden = YES;
        }
    }
}

-(BOOL)validatePassword:(NSString*)password {
    return [self validateLoginInput:password type:1];
}

//UIButtons
- (IBAction)backButtonWasTapped:(id)sender {
    [self previousLoginViewController];
}

- (IBAction)forgotPasswordWasTapped:(id)sender {
}

- (IBAction)nextButtonWasTapped:(id)sender {
    [self submitPassword];
}

@end
