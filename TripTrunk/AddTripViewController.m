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
#import "AddTripFriendsViewController.h"

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
@property (weak, nonatomic) IBOutlet UIButton *delete;
@property NSString *country;
@property NSString *city;
@property NSString *state;
@property (weak, nonatomic) IBOutlet UIButton *public;
@property (weak, nonatomic) IBOutlet UIButton *private;
@property BOOL isPrivate;

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
        self.delete.hidden = NO;
    }
    
    else {
        // initialize the trip object
        self.trip = [[Trip alloc] init];
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    self.navigationItem.rightBarButtonItem.title = @"Next";
    self.navigationItem.rightBarButtonItem.tag = 0;
    self.navigationItem.leftBarButtonItem.tag = 0;
    self.delete.hidden = YES;
    
    }

    [self checkPublicPrivate];

}

-(void)checkPublicPrivate{
    if (self.trip.isPrivate == NO || self.trip == nil)
    {
        self.public.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
        self.private.backgroundColor = [UIColor whiteColor];
        self.public.tag = 1;
        self.private.tag = 0;
    }
    
    else {
        self.public.backgroundColor = [UIColor whiteColor];
        self.private.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
        self.public.tag = 0;
        self.private.tag = 1;
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
        self.endTripTextField.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:182.0/255.0 blue:34.0/255.0 alpha:1.0];
        self.tripDatePicker.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:182.0/255.0 blue:34.0/255.0 alpha:1.0];
        self.startTripTextField.backgroundColor = [UIColor whiteColor];
        self.tripDatePicker.tag = 1;
        return NO;
    }
    
    else if (textField == self.startTripTextField){
        [self.view endEditing:YES];
        self.tripDatePicker.hidden = NO;
        self.startTripTextField.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
        self.tripDatePicker.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
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
                        // Trip Input has correct data - save the trip!
                    
                        CLPlacemark *placemark= placemarks.firstObject;
                        self.country = placemark.country;
                        self.city = placemark.locality;
                        self.state = placemark.administrativeArea;
                        NSLog(@"Got input for trip");
                        [self parseTrip];
                            
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
    
  AddTripFriendsViewController *vc = segue.destinationViewController;
    vc.trip = self.trip;
    vc.isTripCreation = YES;
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
    self.trip.country = self.country;
    self.trip.state = self.state;
    self.trip.city = self.city;
    self.trip.startDate = self.startTripTextField.text;
    self.trip.endDate = self.endTripTextField.text;
    self.trip.isPrivate = self.isPrivate;
    self.trip.user = [PFUser currentUser].username;

    NSLog(@"Saving Trip: %@", self.trip);
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         
             if(error) {
                 //FIXME Check to see if actually works
                 UIAlertView *alertView = [[UIAlertView alloc] init];
                 alertView.delegate = self;
                 alertView.title = @"No internet connection.";
                 alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                 [alertView addButtonWithTitle:@"OK"];
                 [alertView show];
             }
             else
             {
                 NSLog(@"Trip Saved, performing segue to add friends");
                 
             //   AddTripFriendsViewController *vc = [[AddTripFriendsViewController alloc]init];
              //   vc.trip = self.trip;
               //  vc.isTripCreation = YES;
               //  [self.navigationController pushViewController:vc animated:YES];

                 [self performSegueWithIdentifier:@"addFriends" sender:self];
                 // Save Successful - push to Add Friends screen

             }
             
         }];
}

- (IBAction)onDeleteWasTapped:(id)sender {
    
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = @"Are you sure you want to delete this Trunk?";
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"No"];
    [alertView addButtonWithTitle:@"Delete"];
    alertView.tag = 0;
    [alertView show];
    
    
}

- (IBAction)publicTapped:(id)sender {
    if (self.public.tag == 0)
    {
        self.public.tag = 1;
        self.private.tag = 0;
        self.public.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
        self.private.backgroundColor = [UIColor whiteColor];
        self.isPrivate = NO;
    }
    
}


- (IBAction)privateTapped:(id)sender {
    if (self.private.tag == 0)
    {
        self.public.tag = 0;
        self.private.tag = 1;
        self.public.backgroundColor = [UIColor whiteColor];
        self.private.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
        self.isPrivate = YES;

    }

}



-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (alertView.tag == 0)
    {
        if (buttonIndex == 1)
        {
            [self.trip deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }];
        }
    }
    

}

@end
