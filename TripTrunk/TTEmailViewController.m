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


@end

@implementation TTEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emailTextField.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated{
    if (![self.email isEqualToString:@""]){
        self.emailTextField.text = self.email;
    }
    [self.emailTextField becomeFirstResponder];

}

//Keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitEmail];
    return NO;
}

-(void)submitEmail{
    NSString *email =  [self.emailTextField.text lowercaseString];
    if([self validateLoginInput:email type:4] == YES){
        self.email = email;
        [self performSegueWithIdentifier:@"next" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TTLocationViewController *locationVC = segue.destinationViewController;
    locationVC.username = self.username;
    locationVC.password = self.password;
    locationVC.email = self.email;
    locationVC.firstName = self.email;
    locationVC.lastName = self.email;
}

//UIButtons
- (IBAction)nextWasTapped:(id)sender {
    [self submitEmail];
}
- (IBAction)backWasTapped:(id)sender {
    [self previousLoginViewController];
}


@end
