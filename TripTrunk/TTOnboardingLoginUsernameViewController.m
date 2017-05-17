//
//  TTOnboardingLoginUsernameViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/17/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTOnboardingLoginUsernameViewController.h"
#import "TTOnboardingLoginPasswordViewController.h"
#import "TTOnboardingTextField.h"
#import "TTOnboardingButton.h"

@interface TTOnboardingLoginUsernameViewController ()
@property (strong, nonatomic) IBOutlet TTOnboardingTextField *usernameTextField;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *noAccountButton;
@property (strong, nonatomic) IBOutlet UILabel *acceptabilityLabel;
@property NSString *username;
@end

@implementation TTOnboardingLoginUsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nextButton.hidden = YES;
    [self.usernameTextField becomeFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if(![self.username isEqualToString:@""])
        self.usernameTextField.text = self.username;
    if(![self.error isEqualToString:@""])
        self.acceptabilityLabel.text = self.error;
    else self.acceptabilityLabel.text = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    self.acceptabilityLabel.text = @"";
    
    //textField delegates are called before update, init for new range
    NSUInteger postRange = (range.location +1) - range.length;
    
    if(postRange > 1){
        self.nextButton.hidden = NO;
        self.noAccountButton.hidden = YES;
    }else{
        self.nextButton.hidden = YES;
        self.noAccountButton.hidden = NO;
    }
    
    
    return YES;
}

#pragma mark - UIButtons
- (IBAction)backWasTapped:(id)sender {
    [self previousLoginViewController];
}

- (IBAction)noAccountWasTapped:(id)sender {
    [self previousLoginViewController];
}

- (IBAction)nextWasTapped:(id)sender {
    [self performSegueWithIdentifier:@"next" sender:self];
}

#pragma mark - Segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TTOnboardingLoginPasswordViewController *vc = segue.destinationViewController;
    vc.username = [self.usernameTextField.text lowercaseString];
    self.username = self.usernameTextField.text;
}
@end
