//
//  AddTripViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddTripViewController.h"
#import "AddTripPhotosViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


@interface AddTripViewController () <UIAlertViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate>
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
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation AddTripViewController

- (void)viewDidLoad {
    
    //sometimes segue takes too long to occur or doesnt happen at all. maybe shouldnt check here? 
    
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.tripDatePicker.hidden = YES;
    self.startTripTextField.delegate = self;
    self.endTripTextField.delegate = self;
    self.tripNameTextField.delegate = self;
    self.cityNameTextField.delegate = self;
    self.stateTextField.delegate = self;
    self.countryTextField.delegate = self;
    self.formatter = [[NSDateFormatter alloc]init];
    [self.formatter setDateFormat:@"MM/dd/yyyy"];
    
    //move to opening of app
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    //TEMP
    
    self.tripNameTextField.text = @"Trip to Columbus";
    self.countryTextField.text = @"U.S.";
    self.stateTextField.text = @"Ohio";
    self.cityNameTextField.text = @"Columbus";

    
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
        self.endTripTextField.backgroundColor = [UIColor colorWithRed:228.0/255.0 green:117.0/255.0 blue:100.0/255.0 alpha:1.0];
        self.tripDatePicker.backgroundColor = [UIColor colorWithRed:228.0/255.0 green:117.0/255.0 blue:100.0/255.0 alpha:1.0];
        self.startTripTextField.backgroundColor = [UIColor whiteColor];
        self.tripDatePicker.tag = 1;
        return NO;
    }
    
    else if (textField == self.startTripTextField){
        [self.view endEditing:YES];
        self.tripDatePicker.hidden = NO;
        self.startTripTextField.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:182.0/255.0 blue:34.0/255.0 alpha:1.0];
        self.tripDatePicker.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:182.0/255.0 blue:34.0/255.0 alpha:1.0];
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





- (IBAction)onNextTapped:(id)sender
{
    //dont do this every time they click next. only if they changed location text fields
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    NSString *address = [NSString stringWithFormat:@"%@, %@, %@",self.cityNameTextField.text,self.stateTextField.text,self.countryTextField.text];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error)
    {
        if (error)
        {
            [self notEnoughInfo:@"Please select a valid location and make sure you have internet connection"];
        }
        
        else if (!error)
        {

                if (![self.tripNameTextField.text isEqualToString:@""] && ![self.cityNameTextField.text isEqualToString:@""] && ![self.startTripTextField.text isEqualToString:@""] && ![self.endTripTextField.text isEqualToString:@""])
                {
                    NSTimeInterval startTimeInterval = [self.startDate timeIntervalSince1970];
                    NSTimeInterval endTimeInterval = [self.endDate timeIntervalSince1970];
                    
                    if(startTimeInterval <= endTimeInterval)
                    {

                        [self performSegueWithIdentifier:@"photos" sender:self];
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

                    }
                    else
                    {
                        [self notEnoughInfo:@"Your start date must happen before the end date"];
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
                    }

                }
            
                else
                {
                    [self notEnoughInfo:@"Please fill out all boxes"];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
        
        return;
    }];

}
    

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    AddTripPhotosViewController *addTripPhotosViewController = segue.destinationViewController;
    NSString *tripName = self.tripNameTextField.text;
    NSString *tripCity = self.cityNameTextField.text;
    NSString *start = self.startTripTextField.text;
    NSString *end = self.endTripTextField.text;
    NSString *countryName = self.countryTextField.text;
    NSString *stateName = self.stateTextField.text;
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
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
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
