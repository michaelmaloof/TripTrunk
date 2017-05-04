//
//  TTUsernameViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTUsernameViewController.h"
#import "TTPasswordViewController.h"
#import "MBProgressHUD.h"

@interface TTUsernameViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *account;

@end

@implementation TTUsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.usernameTextField.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated{
    if (![self.username isEqualToString:@""]){
        self.usernameTextField.text = self.username;
    }
    
    [self.usernameTextField becomeFirstResponder];
}

//UIButtons
- (IBAction)backButtonWasTapped:(id)sender {
    [self previousLoginViewController];
}
- (IBAction)nextButtonWasTapped:(id)sender {
    [self submitUsername];
}
- (IBAction)accountWasTapped:(id)sender {
}

//Keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitUsername];
    return NO;
}

-(void)submitUsername{
    NSString *username =  [_usernameTextField.text lowercaseString];
    if([self validateLoginInput:username type:0] == YES){
        self.username = username;
        [self performSegueWithIdentifier:@"next" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TTPasswordViewController *passwordVC = segue.destinationViewController;
    passwordVC.username = self.username;
    passwordVC.isFBUser = self.isFBUser;

    
}

@end
