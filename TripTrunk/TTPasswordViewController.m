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
@property (weak, nonatomic) IBOutlet UIButton *forgotPassword;

@end

@implementation TTPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.passwordTextField.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated{
    if (![self.password isEqualToString:@""]){
        self.passwordTextField.text = self.password;
    }
    [self.passwordTextField becomeFirstResponder];

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TTNameViewController *nameVC = segue.destinationViewController;
    nameVC.username = self.username;
    nameVC.password = self.password;
    nameVC.isFBUser = self.isFBUser;
    nameVC.isFirstName = YES;
}

//Keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitPassword];
    return NO;
}

-(void)submitPassword {
    NSString *password =  [self.passwordTextField.text lowercaseString];
    if([self validateLoginInput:password type:1] == YES){
        self.password = password;
        [self performSegueWithIdentifier:@"next" sender:self];
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
