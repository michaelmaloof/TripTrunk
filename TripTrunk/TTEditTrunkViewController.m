//
//  TTEditTrunkViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 7/11/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTEditTrunkViewController.h"
#import "TTTextField.h"
#import "TTOnboardingButton.h"
#import "MBProgressHUD.h"

@interface TTEditTrunkViewController ()
@property (strong, nonatomic) IBOutlet TTTextField *trunkName;
@property (strong, nonatomic) IBOutlet TTTextField *startDate;
@property (strong, nonatomic) IBOutlet TTTextField *endDate;
@property (strong, nonatomic) IBOutlet UISwitch *isPrivate;
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (strong,nonatomic) MBProgressHUD *HUD;
@end

@implementation TTEditTrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification) name:UIKeyboardWillShowNotification object:nil];
    
    self.HUD = [[MBProgressHUD alloc] init];
    
    self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    [self.datePicker addTarget:self action:@selector(onDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.startDate.inputView = self.datePicker;
    self.endDate.inputView = self.datePicker;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy"];
    NSDate *sd = [df dateFromString:self.trip.startDate];
    NSDate *ed = [df dateFromString:self.trip.endDate];
    [df setDateFormat:@"MMM dd, yyyy"];
    
    self.trunkName.text = self.trip.name;
    self.isPrivate.enabled = self.trip.isPrivate;
    self.startDate.text = [df stringFromDate:sd];
    self.endDate.text = [df stringFromDate:ed];
    
    self.isPrivate.enabled = YES;
    self.isPrivate.userInteractionEnabled = YES;
}

#pragma mark - UITextField
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([self.startDate.text isEqualToString:@""] && [self.endDate.text isEqualToString:@""]){
        return NO;
    }else{
        [self saveChangesToTrunk];
        return YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIDatePicker
- (void)onDatePickerValueChanged:(UIDatePicker *)datePicker{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterMediumStyle];
    if([self.startDate isFirstResponder])
        self.startDate.text = [df stringFromDate:datePicker.date];
    else self.endDate.text = [df stringFromDate:datePicker.date];
    
    [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:4.0];

}


- (IBAction)cancelButtonWasTapped:(TTOnboardingButton *)sender {
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


- (IBAction)saveButtonWasTapped:(TTOnboardingButton *)sender {
    [self saveChangesToTrunk];
}

-(void)saveChangesToTrunk{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        self.HUD.labelText = NSLocalizedString(@"Saving...",@"Saving...");
        self.HUD.mode = MBProgressHUDModeText; // change to Determinate to show progress
    });
    
    self.trip.isPrivate = self.isPrivate;
    self.trip.name = self.trunkName.text;
    self.trip.startDate = self.startDate.text;
    self.trip.endDate = self.endDate.text;
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        [self dismissViewControllerAnimated:YES completion:^{
            // Hide HUD spinner
            self.HUD.labelText = NSLocalizedString(@"Changes Saved!",@"Changes Saved!");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(trunkDetailsEdited:)]) {
                    [self.delegate trunkDetailsEdited:self.trip];
                }
                [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
            });
        }];
    }];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:3.0];
    return YES;
}

-(void)dismissKeyboard{
    [self.trunkName resignFirstResponder];
    [self.startDate resignFirstResponder];
    [self.endDate resignFirstResponder];
}

-(void)keyboardWillShowNotification{
    [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:3.0];
}

@end
