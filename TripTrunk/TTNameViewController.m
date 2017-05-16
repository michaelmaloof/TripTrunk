//
//  TTNameViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTNameViewController.h"
#import "TTLastNameViewController.h"

@interface TTNameViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property NSString *firstName;
@property BOOL meetsMinimumRequirements;
@end

@implementation TTNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nameTextField.delegate = self;
    self.nextButton.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if (![self.user[@"First Name"] isEqualToString:@""]){
        self.nameTextField.text = [self.user[@"First Name"] capitalizedString];
        
        if(self.nameTextField.text.length > 0){
            self.nextButton.hidden = NO;
            self.meetsMinimumRequirements = YES;
        }else{
            self.nextButton.hidden = YES;
            self.meetsMinimumRequirements = NO;
        }
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [self.nameTextField becomeFirstResponder];
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
    self.meetsMinimumRequirements = NO;
    
    //textField delegates are called before update, init for new range
    NSUInteger postRange = (range.location +1) - range.length;
    
    if(postRange > 0){
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
        self.firstName =  [self.nameTextField.text lowercaseString];
        [self performSegueWithIdentifier:@"next" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"next"]){
        TTLastNameViewController *vc = segue.destinationViewController;
        [self.user setObject:self.firstName forKey:@"First Name"];
        vc.user = self.user;
    }
}

@end
