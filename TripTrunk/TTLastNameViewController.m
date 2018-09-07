//
//  TTNameViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTLastNameViewController.h"
#import "TTEmailViewController.h"

@interface TTLastNameViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (strong, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property NSString *lastName;
@property BOOL meetsMinimumRequirements;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalPositionConstraint;
@end

@implementation TTLastNameViewController

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    //FIXME: iPhone4 for iPad hack
    if ([[self deviceName] containsString:@"iPad"]){
        self.verticalPositionConstraint.constant = -145;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastNameTextField.delegate = self;
    self.nextButton.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if (![self.user[@"Last Name"] isEqualToString:@""]){
        self.lastNameTextField.text = [self.user[@"Last Name"] capitalizedString];
        
        if(self.lastNameTextField.text.length > 0){
            self.nextButton.hidden = NO;
            self.meetsMinimumRequirements = YES;
        }else{
            self.nextButton.hidden = YES;
            self.meetsMinimumRequirements = NO;
        }
    }
}

-(void)viewDidAppear:(BOOL)animated{

    [self.lastNameTextField becomeFirstResponder];
}

//UIButtons

- (IBAction)backButtonWasTapped:(id)sender {
    [self previousLoginViewController];
}

- (IBAction)nextButtonWasTapped:(id)sender {
    [self submitName];
}

//Keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitName];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    //name has changed
    self.nextButton.hidden = YES;
    
    NSString *typedText;
    
    if(range.location == textField.text.length)
        typedText = [textField.text stringByAppendingString:string];
    else typedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if(typedText.length > 1){
        self.nextButton.hidden = NO;
        self.meetsMinimumRequirements = YES;
    }else{
        self.nextButton.hidden = YES;
        self.meetsMinimumRequirements = NO;
    }
    
    
    return YES;
}

-(void)submitName{
    if(self.meetsMinimumRequirements){
        self.lastName =  [self.lastNameTextField.text lowercaseString];
        [self performSegueWithIdentifier:@"next" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"next"]){
        TTEmailViewController *vc = segue.destinationViewController;
        [self.user setObject:self.lastName forKey:@"Last Name"];
        vc.user = self.user;
    }
}

@end
