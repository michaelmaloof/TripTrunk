//
//  TTEmailViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTEmailViewController.h"
#import "TTLocationViewController.h"
#import "TTEmailValidation.h"

@interface TTEmailViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *aI;
@property (strong, nonatomic) IBOutlet UILabel *availabilityLabel;
@property (strong, nonatomic) IBOutlet UIImageView *availabilityIcon;
@property NSString *email;
@property BOOL meetsMinimumRequirements;
@property BOOL lookupInterrupted;
@property BOOL lookupFinished;
@end

@implementation TTEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emailTextField.delegate = self;
    self.nextButton.hidden = YES;
    self.aI.hidden = YES;
    [self.aI startAnimating];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if (![self.user[@"Email"] isEqualToString:@""])
        self.emailTextField.text = self.user[@"Email"];
    
    self.lookupFinished = NO;
    self.availabilityLabel.text = @"";
    self.availabilityIcon.image = nil;
    self.nextButton.hidden = YES;
    self.meetsMinimumRequirements = NO;
    int minimumUsernameLength = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MinimumUsernameLength"] intValue];
    if(self.emailTextField.text.length >= minimumUsernameLength)
        [self performSelector:@selector(checkEmailAvailability) withObject:nil afterDelay:1.5f];
}

-(void)viewDidAppear:(BOOL)animated{
    [self.emailTextField becomeFirstResponder];
}

//Keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitEmail];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    //Email has changed
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkEmailAvailability) object:nil];
    self.availabilityLabel.text = @"";
    self.aI.hidden = YES;
    self.availabilityIcon.image = nil;
    self.nextButton.hidden = YES;
    self.lookupInterrupted = YES;
    self.lookupFinished = NO;
    
    //int minimumUsernameLength = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MinimumUsernameLength"] intValue];

//    NSString *e = textField.text; NSString *email;
//    if([string isEqualToString:@""])
//        email = [e substringToIndex:e.length - 1];
//    else email = [e stringByAppendingString:string];
    
    NSString *typedText;
    
    if(range.location == textField.text.length)
        typedText = [textField.text stringByAppendingString:string];
    else typedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if([TTEmailValidation emailIsValid:typedText]){
        self.availabilityLabel.text = @"";
        [self performSelector:@selector(checkEmailAvailability) withObject:nil afterDelay:1.5f];
    }else{
        self.availabilityLabel.text = @"Please enter a valid email address...";
        self.aI.hidden = YES;
        self.availabilityIcon.image = nil;
    }

    return YES;
}

-(void)checkEmailAvailability{
    self.availabilityLabel.text = @"Checking email availability...";
    self.aI.hidden = NO;
    self.availabilityIcon.image = nil;
    self.lookupInterrupted = NO;
    
    //Cloud code to check availability
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.emailTextField.text, @"emailaddress", nil];
    
    [PFCloud callFunctionInBackground:@"ValidateEmailAddress" withParameters:params
                                block:^(id  _Nullable success, NSError * _Nullable error) {
                                    if (!error)
                                        [self emailDetermination:YES];
                                    else [self emailDetermination:NO];
                                    
                                }];
}

-(void)emailDetermination:(BOOL)available{
    
    if(!self.lookupInterrupted){
        if(available){
            self.availabilityLabel.text = @"Email address available!";
            self.aI.hidden = YES;
            self.nextButton.hidden = NO;
            self.availabilityIcon.image = [UIImage imageNamed:@"tt_Green_Check"];
            self.lookupFinished = YES;
            self.meetsMinimumRequirements = YES;
        }else{
            self.availabilityLabel.text = @"Sorry, that email address is already in use.";
            self.aI.hidden = YES;
            self.availabilityIcon.image = [UIImage imageNamed:@"tt_Red_X"];
            self.lookupFinished = NO;
            self.meetsMinimumRequirements = NO;
        }
    }
}

-(void)submitEmail{
    if(self.meetsMinimumRequirements){
        NSString *email =  [self.emailTextField.text lowercaseString];
        if([self validateLoginInput:email type:3]){
            self.email = email;
            [self performSegueWithIdentifier:@"next" sender:self];
        }
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TTLocationViewController *vc = segue.destinationViewController;

    [self.user setObject:self.email forKey:@"Email"];
    vc.user = self.user;
}

//UIButtons
- (IBAction)nextWasTapped:(id)sender {
    [self submitEmail];
}
- (IBAction)backWasTapped:(id)sender {
    [self previousLoginViewController];
}


@end
