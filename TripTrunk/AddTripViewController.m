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
@property (weak, nonatomic) IBOutlet UIImageView *backGroundImage;

@end

@implementation AddTripViewController

- (void)viewDidLoad {
    
//FIXME sometimes segue takes too long to occur or doesnt happen at all. maybe shouldnt check here?
    
    [super viewDidLoad];
    self.title = @"Trip Details";
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
    
//FIXME Do I even need this?
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
    self.locationManager.delegate = self;
    
    if (self.trip) {
        self.tripNameTextField.text = self.trip.name;
        self.countryTextField.text = self.trip.country;
        self.stateTextField.text= self.trip.state;
        self.cityNameTextField.text = self.trip.city;
        self.startTripTextField.text = self.trip.startDate;
        self.endTripTextField.text = self.trip.endDate;
        
        self.navigationItem.rightBarButtonItem.title = @"Update";
        self.navigationItem.rightBarButtonItem.tag = 1;
        self.navigationItem.leftBarButtonItem.tag = 1;
    }
    
    else {
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    self.navigationItem.rightBarButtonItem.title = @"Next";
    self.navigationItem.rightBarButtonItem.tag = 0;
    self.navigationItem.leftBarButtonItem.tag = 0;
    
    }

    
}

- (IBAction)onCancelTapped:(id)sender {
    if (self.navigationItem.leftBarButtonItem.tag == 0)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
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
//FIXME dont do this every time they click next. only if they changed location text fields
    
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
                        if (self.navigationItem.rightBarButtonItem.tag == 0 )
                        {
                        [self performSegueWithIdentifier:@"photos" sender:self];
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        }
                        
                        else
                        {
                            [self parseTrip];
                        }

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
    
    NSString *tripName = self.tripNameTextField.text;
    NSString *tripCity = self.cityNameTextField.text;
    NSString *start = self.startTripTextField.text;
    NSString *end = self.endTripTextField.text;
    NSString *countryName = self.countryTextField.text;
    NSString *stateName = self.stateTextField.text;
    
    AddTripPhotosViewController *addTripPhotosViewController = segue.destinationViewController;
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

-(void)parseTrip {
    
//FIXME Should only parse if things have been changed
    
    self.trip.name = self.tripNameTextField.text;
    self.trip.country = self.countryTextField.text;
    self.trip.state = self.stateTextField.text;
    self.trip.city = self.cityNameTextField.text;
    self.trip.startDate = self.startTripTextField.text;
    self.trip.endDate = self.endTripTextField.text;
    
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         [self dismissViewControllerAnimated:YES completion:^{
             
             if(error) {
                 //FIXME Check to see if actually works
                 UIAlertView *alertView = [[UIAlertView alloc] init];
                 alertView.delegate = self;
                 alertView.title = @"No internet connection.";
                 alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                 [alertView addButtonWithTitle:@"OK"];
                 [alertView show];
             }
             if (!error)
             {
                 [self.navigationController popViewControllerAnimated:YES];
             }
             
         }];
     }];
}







@end
