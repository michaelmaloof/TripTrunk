//
//  AddTripViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddTripViewController.h"
#import "AddTripPhotosViewController.h"


@interface AddTripViewController () <UIAlertViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *tripNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *cityNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *startTripTextField;
@property (weak, nonatomic) IBOutlet UITextField *endTripTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *tripDatePicker;
@property (weak, nonatomic) IBOutlet UITextField *countryTextField;
@property (weak, nonatomic) IBOutlet UITextField *stateTextField;
@property NSDateFormatter *formatter;
@property NSDate *startDate;
@property NSDate *endDate;

@end

@implementation AddTripViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tripDatePicker.hidden = YES;
    self.startTripTextField.delegate = self;
    self.endTripTextField.delegate = self;
    self.tripNameTextField.delegate = self;
    self.cityNameTextField.delegate = self;
    self.stateTextField.delegate = self;
    self.countryTextField.delegate = self;
    self.formatter = [[NSDateFormatter alloc]init];
    [self.formatter setDateFormat:@"MM/dd/yyyy"];
    
}

- (IBAction)onCancelTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    self.tripDatePicker.hidden = YES;
    self.startTripTextField.backgroundColor = [UIColor whiteColor];
    self.endTripTextField.backgroundColor = [UIColor whiteColor];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.endTripTextField) {
        [self.view endEditing:YES];
        self.tripDatePicker.hidden = NO;
        self.endTripTextField.backgroundColor = [UIColor redColor];
        self.tripDatePicker.backgroundColor = [UIColor redColor];
        self.startTripTextField.backgroundColor = [UIColor whiteColor];
        self.tripDatePicker.tag = 1;
        return NO;
    }
    
    else if (textField == self.startTripTextField){
        [self.view endEditing:YES];
        self.tripDatePicker.hidden = NO;
        self.startTripTextField.backgroundColor = [UIColor blueColor];
        self.tripDatePicker.backgroundColor = [UIColor blueColor];
        self.endTripTextField.backgroundColor = [UIColor whiteColor];
        self.tripDatePicker.tag = 0;
        return NO;
    }
    
    else {
        self.tripDatePicker.hidden = YES;
        self.startTripTextField.backgroundColor = [UIColor whiteColor];
        self.endTripTextField.backgroundColor = [UIColor whiteColor];
        return  YES;
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"photos"])
    {
        if (![self.tripNameTextField.text isEqualToString:@""] && ![self.cityNameTextField.text isEqualToString:@""] && ![self.startTripTextField.text isEqualToString:@""] && ![self.endTripTextField.text isEqualToString:@""])
        {
            NSTimeInterval startTimeInterval = [self.startDate timeIntervalSince1970];
            NSTimeInterval endTimeInterval = [self.endDate timeIntervalSince1970];
            
            if(startTimeInterval <= endTimeInterval){
                return YES;
            }
            
            else if (startTimeInterval > endTimeInterval)
                [self notEnoughInfo:@"Your start date must happen before the end date"];
                return NO;
        }
    }
    
    [self notEnoughInfo:@"Please fill out all boxes"];
    return NO;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    NSString *tripName = self.tripNameTextField.text;
    NSString *tripCity = self.cityNameTextField.text;
    NSString *start = self.startTripTextField.text;
    NSString *end = self.endTripTextField.text;
    NSString *countryName = self.countryTextField.text;
    NSString *stateName = self.stateTextField.text;
    
    AddTripPhotosViewController *addTripPhotosViewController= segue.destinationViewController;
    addTripPhotosViewController.tripName = tripName;
    addTripPhotosViewController.tripCity = tripCity;
    addTripPhotosViewController.tripCountry = countryName;
    addTripPhotosViewController.tripState = stateName;
    addTripPhotosViewController.startDate = start;
    addTripPhotosViewController.endDate = end;
    
}

- (void)notEnoughInfo:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = message;
    [alertView addButtonWithTitle:@"Ok"];
    [alertView show];
}

- (IBAction)datePickerTapped:(id)sender {
    
    if (self.tripDatePicker.tag == 0){
        self.startTripTextField.text = [self.formatter stringFromDate:self.tripDatePicker.date];
        self.startDate = self.tripDatePicker.date;

    }
    
    else if (self.tripDatePicker.tag == 1){
        self.endTripTextField.text = [self.formatter stringFromDate:self.tripDatePicker.date];
        self.endDate = self.tripDatePicker.date;
    }
    
}
@end
