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

@interface TTTrunkDatesViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextView *trunkTitle;
@property (weak, nonatomic) IBOutlet TTTextField *startDate;
@property (weak, nonatomic) IBOutlet TTTextField *endDate;
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet TTOnboardingButton *nextButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalPositionConstrinat;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateVerticalPositionConstrinat;
@end

@implementation TTTrunkDatesViewController

#pragma mark - iPad Hack
-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    //FIXME: iPhone4 for iPad hack
    if ([[self deviceName] containsString:@"iPad"]){
        self.verticalPositionConstrinat.constant = 0;
        self.startLabel.textColor = [UIColor whiteColor];
        self.endLabel.textColor = [UIColor whiteColor];
        self.dateVerticalPositionConstrinat.constant =  25;
    }
}

-(void)dismissDatePicker{
    [self.startDate resignFirstResponder];
    [self.endDate resignFirstResponder];
}

#pragma mark - views
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
    self.trip.endDate = [df stringFromDate:endDate];
    self.trip.startDate = [df stringFromDate:startDate];
    self.trip.start = [df dateFromString:self.trip.startDate];
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
    
    //FIXME: iPhone 4 for iPad Hack
    [self performSelector:@selector(dismissDatePicker) withObject:nil afterDelay:2.0];
}


@end
