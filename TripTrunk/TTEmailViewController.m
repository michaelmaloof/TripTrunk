//
//  TTEmailViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTEmailViewController.h"
#import "TTLocationViewController.h"

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
@end

@implementation TTEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emailTextField.delegate = self;
    self.nextButton.hidden = YES;
    self.aI.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if (![self.user[@"Email"] isEqualToString:@""]){
        self.emailTextField.text = self.user[@"Email"];
        
        if([self.emailTextField.text containsString:@"@"] && [self.emailTextField.text containsString:@"."]){
            self.nextButton.hidden = NO;
            self.meetsMinimumRequirements = YES;
        }else{
            self.nextButton.hidden = YES;
            self.meetsMinimumRequirements = NO;
        }
    }
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
    
    //name has changed
    self.nextButton.hidden = YES;
    
    //textField delegates are called before update, init for new range
    //NSUInteger postRange = (range.location +1) - range.length;
    
    if([self.emailTextField.text containsString:@"@"] && [self.emailTextField.text containsString:@"."]){
        self.nextButton.hidden = NO;
        self.meetsMinimumRequirements = YES;
    }else{
        self.nextButton.hidden = YES;
        self.meetsMinimumRequirements = NO;
    }
    
    
    return YES;
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
