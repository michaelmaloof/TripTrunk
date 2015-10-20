//
//  TTForgotPasswordViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 10/19/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "TTForgotPasswordViewController.h"
#import <Parse/Parse.h>

@interface TTForgotPasswordViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@end

@implementation TTForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)resetPassword:(id)sender {
    if (![self.emailTextField.text containsString:@"@"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Enter Valid Email",@"Please Enter Valid Email")
                                                        message:NSLocalizedString(@"",@"")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
    } else {
        [PFUser requestPasswordResetForEmailInBackground:self.emailTextField.text];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Request Sent",@"Request Sent")
                                                        message:NSLocalizedString(@"If you don't see the email in 24 hours please try to reset the password again",@"If you don't see the email in 24 hours please try to reset the password again")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        alert.tag = 1;
        [alert show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (IBAction)remembered:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
