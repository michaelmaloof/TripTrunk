//
//  TTTrunkDatesViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/27/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTTrunkDatesViewController.h"
#import "TTOnboardingButton.h"
#import "TTTrunkLocationViewController.h"
#import "TTTextField.h"

@interface TTTrunkDatesViewController ()
@property (strong, nonatomic) IBOutlet UITextView *trunkTitle;
@property (strong, nonatomic) IBOutlet TTTextField *startDate;
@property (strong, nonatomic) IBOutlet TTTextField *endDate;
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *nextButton;
@end

@implementation TTTrunkDatesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.trunkTitle.text = self.trip.name;
    self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    [self.datePicker addTarget:self action:@selector(onDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.startDate.inputView = self.datePicker;
    self.endDate.inputView = self.datePicker;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextField
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([self.startDate.text isEqualToString:@""] && [self.endDate.text isEqualToString:@""]){
        return NO;
    }else{
        [self performSegueWithIdentifier:@"pushToTrunkLocation" sender:self];
        return YES;
    }
}

#pragma mark - UIButtons
- (IBAction)nextButtonWasTapped:(TTOnboardingButton *)sender {
    [self performSegueWithIdentifier:@"pushToTrunkLocation" sender:self];
}

- (IBAction)backButtonWasTapped:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TTTrunkLocationViewController *trunkLocationViewController = segue.destinationViewController;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterMediumStyle];
    NSDate *startDate = [[NSDate alloc] init];
    startDate = [df dateFromString:self.startDate.text];
    NSDate *endDate = [[NSDate alloc] init];
    endDate = [df dateFromString:self.endDate.text];
    [df setDateFormat:@"MM/dd/yyyy"];
    self.trip.startDate = [df stringFromDate:startDate];
    self.trip.endDate = [df stringFromDate:endDate];
    trunkLocationViewController.trip = self.trip;
}

#pragma mark - UIDatePicker
- (void)onDatePickerValueChanged:(UIDatePicker *)datePicker{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterMediumStyle];
    if([self.startDate isFirstResponder])
        self.startDate.text = [df stringFromDate:datePicker.date];
    else self.endDate.text = [df stringFromDate:datePicker.date];
    
    if([self.startDate.text isEqualToString:@""] || [self.endDate.text isEqualToString:@""])
        self.nextButton.hidden = YES;
    else self.nextButton.hidden = NO;
}


@end
