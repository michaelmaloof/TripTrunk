//
//  TTNameViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTNameViewController.h"
#import "TTEmailViewController.h"

@interface TTNameViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation TTNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nameTextField.delegate = self;
    if (self.isFirstName == NO){
        self.pageTitle.text = @"Last Name";
        self.nameTextField.placeholder = @"Barnard";
    }
}

-(void)viewDidAppear:(BOOL)animated{
    if (![self.firstName isEqualToString:@""] && self.isFirstName == YES){
        self.nameTextField.text = self.firstName;
    } else if (![self.lastName isEqualToString:@""] && self.firstName == NO){
        self.nameTextField.text = self.lastName;
    }
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitName];
    return NO;
}

-(void)submitName{
    NSString *name =  [self.nameTextField.text lowercaseString];
    if([self validateLoginInput:name type:2]){
        if (self.isFirstName == YES){
            self.firstName = name;
            TTNameViewController *lastNameVc = [self.storyboard instantiateViewControllerWithIdentifier:@"NameVC"];
            lastNameVc.username = self.username;
            lastNameVc.password = self.username;
            lastNameVc.firstName = self.firstName;
            lastNameVc.isFirstName = NO;
            lastNameVc.isFBUser = self.isFBUser;
            [self.navigationController pushViewController:lastNameVc animated:NO];
        }else {
            self.lastName = name;
            [self performSegueWithIdentifier:@"next" sender:self];
        }
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"next"]){
        TTEmailViewController *emailVC = segue.destinationViewController;
        emailVC.username = self.username;
        emailVC.password = self.username;
        emailVC.firstName = self.firstName;
        emailVC.lastName = self.lastName;
        emailVC.isFBUser = self.isFBUser;
    }
}

@end
