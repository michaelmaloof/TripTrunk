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
#import "MSTextField.h"
#import "SocialUtility.h"

@interface AddTripViewController () <UIAlertViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate>

// Text Fields
@property (weak, nonatomic) IBOutlet UITextField *tripNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *cityNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *startTripTextField;
@property (weak, nonatomic) IBOutlet UITextField *endTripTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *tripDatePicker;
@property (weak, nonatomic) IBOutlet UITextField *countryTextField;
@property (weak, nonatomic) IBOutlet UITextField *stateTextField;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UIImageView *backGroundImage;
@property (weak, nonatomic) IBOutlet UIButton *delete;
@property (weak, nonatomic) IBOutlet UIButton *public;
@property (weak, nonatomic) IBOutlet UIButton *private;
@property BOOL isPrivate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBar;
@property BOOL needsCityUpdate; // if the trunk already exists and we changed the city of the trip
@property BOOL needsNameUpdate; // if the trunk already exists and we changed the name of the trip
@property BOOL isEditing; // if the trunk already exists and we're editing it
@property (weak, nonatomic) IBOutlet UIButton *clear;

// Date Properties
@property NSDateFormatter *formatter;

@property (strong, nonatomic) UIDatePicker *datePicker;

@end

@implementation AddTripViewController

- (void)viewDidLoad {
    
//FIXME sometimes segue takes too long to occur or doesnt happen at all. maybe shouldnt check here?
    
    [super viewDidLoad];
    self.clear.hidden = YES;
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];

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
        _isEditing = YES;
        self.title = @"Trunk Details";
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
        self.public.hidden = YES;
        self.private.hidden = YES;
        
        self.cancelBar.title = @"Cancel";
        self.cancelBar.enabled = YES;
    }
    
    else {
        _isEditing = NO;

        // initialize the trip object
        self.title = @"New Trunk";

        // Set initial date to the field - should be Today's date.
        self.startTripTextField.text = [self.formatter stringFromDate:[NSDate date]];
        self.endTripTextField.text = [self.formatter stringFromDate:[NSDate date]];

        self.trip = [[Trip alloc] init];
        self.cancelBar.title = @"";
        self.cancelBar.enabled = FALSE;
       

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
    
    [self setupDatePicker];

    [self checkPublicPrivate];

}

-(void)viewWillAppear:(BOOL)animated {
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y -75, self.view.frame.size.width, self.view.frame.size.height);
    
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 75, self.view.frame.size.width, self.view.frame.size.height);
    
}

- (void)setupDatePicker {
    self.datePicker = [[UIDatePicker alloc] init];
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    
    [self.datePicker addTarget:self
                        action:@selector(dateChanged:)
              forControlEvents:UIControlEventValueChanged];
    
    // Generic Flexible Space
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Start Date Toolbar
    UIToolbar *startTripToolbar= [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.datePicker.frame.size.width, 40)];
    UIBarButtonItem *barButtonNext = [[UIBarButtonItem alloc] initWithTitle:@"Next"
                                                                      style:UIBarButtonItemStyleDone target:self action:@selector(dismissPickerView:)];
    UILabel *startLabel = [[UILabel alloc] init];
    [startLabel setText:@"Start Date"];
    [startLabel setFont:[UIFont systemFontOfSize:12.0]];
    [startLabel setTextColor:[UIColor blackColor]];
    [startLabel sizeToFit];
    UIBarButtonItem *labelbutton = [[UIBarButtonItem alloc] initWithCustomView:startLabel];
    startTripToolbar.items = [[NSArray alloc] initWithObjects:labelbutton, space, barButtonNext,nil];
    barButtonNext.tintColor=[UIColor blackColor];
    
    self.startTripTextField.inputView = self.datePicker; // set the textfield to use the picker instead of a keyboard
    self.startTripTextField.inputAccessoryView = startTripToolbar;

    // End Date Toolbar
    UIToolbar *endTripToolbar= [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.datePicker.frame.size.width, 40)];
    UIBarButtonItem *barButtonDone = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                      style:UIBarButtonItemStyleDone target:self action:@selector(dismissPickerView:)];
    
    UILabel *endLabel = [[UILabel alloc] init];
    [endLabel setText:@"End Date"];
    [endLabel setFont:[UIFont systemFontOfSize:12.0]];
    [endLabel setTextColor:[UIColor blackColor]];
    [endLabel sizeToFit];
    UIBarButtonItem *endLabelButton = [[UIBarButtonItem alloc] initWithCustomView:endLabel];
    endTripToolbar.items = [[NSArray alloc] initWithObjects:endLabelButton, space, barButtonDone, nil];
    barButtonDone.tintColor=[UIColor blackColor];

    self.endTripTextField.inputView = self.datePicker;
    self.endTripTextField.inputAccessoryView = endTripToolbar;
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

#pragma mark - Keyboard delegate methods

// The following method needed to dismiss the keyboard after input with a click anywhere on the screen outside text boxes

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touchesBegan:withEvent:");
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
    self.startTripTextField.backgroundColor = [UIColor whiteColor];
    self.endTripTextField.backgroundColor = [UIColor whiteColor];
}

// Go to the next textfield or close the keyboard when the return button is pressed

- (BOOL)textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField isKindOfClass:[MSTextField class]])
        dispatch_async(dispatch_get_main_queue(),
                       ^ { [[(MSTextField *)textField nextField] becomeFirstResponder]; });
    
    return YES;
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.endTripTextField) {
//        [self.view endEditing:YES];
        self.datePicker.tag = 1;
        self.endTripTextField.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:182.0/255.0 blue:34.0/255.0 alpha:1.0];
        self.datePicker.backgroundColor = [UIColor colorWithRed:242.0/255.0 green:182.0/255.0 blue:34.0/255.0 alpha:1.0];
        self.startTripTextField.backgroundColor = [UIColor whiteColor];
        return YES;
    }
    
    else if (textField == self.startTripTextField){
//        [self.view endEditing:YES];
        self.datePicker.tag = 0;
        self.startTripTextField.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
        self.datePicker.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:191.0/255.0 blue:217.0/255.0 alpha:1.0];
        self.endTripTextField.backgroundColor = [UIColor whiteColor];
        return YES;
    }
     
    else {
        self.startTripTextField.backgroundColor = [UIColor whiteColor];
        self.endTripTextField.backgroundColor = [UIColor whiteColor];
        return  YES;
    }
}

#pragma mark - Date Picker

- (void)dateChanged:(id)sender {
    
    if (self.datePicker.tag == 0) {
        self.startTripTextField.text = [self.formatter stringFromDate:self.datePicker.date];
        self.trip.startDate = [self.formatter stringFromDate:self.datePicker.date];
    }
    else if (self.datePicker.tag == 1) {
        self.endTripTextField.text = [self.formatter stringFromDate:self.datePicker.date];
        self.trip.endDate = [self.formatter stringFromDate:self.datePicker.date];
    }
}

-(void)dismissPickerView:(id)sender
{
    if (self.datePicker.tag == 0) {
        [self.endTripTextField becomeFirstResponder];
    }
    else {
        [self.view endEditing:YES];
        self.startTripTextField.backgroundColor = [UIColor whiteColor];
        self.endTripTextField.backgroundColor = [UIColor whiteColor];
    }
}

#pragma mark - Button Actions

- (IBAction)onCancelTapped:(id)sender {
    if (self.navigationItem.leftBarButtonItem.tag == 0)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)onNextTapped:(id)sender
{
//FIXME dont do this every time they click next. only if they changed location text fields
    self.title = @"Verifying Location...";
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    NSString *address = [NSString stringWithFormat:@"%@, %@, %@",self.cityNameTextField.text,self.stateTextField.text,self.countryTextField.text];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error)
    {
        if (error)
        {
            // TODO: Set title image
            self.title = @"TripTrunk";
            [self notEnoughInfo:@"Please select a valid location and make sure you have internet connection"];
        }
        
        else if (!error)
        {

                if (![self.tripNameTextField.text isEqualToString:@""] && ![self.cityNameTextField.text isEqualToString:@""] && ![self.startTripTextField.text isEqualToString:@""] && ![self.endTripTextField.text isEqualToString:@""])
                {
                    // Trip Input has correct data - save the trip!
                    
                    CLPlacemark *placemark = placemarks.firstObject;
                    self.trip.country = placemark.country;
                    
                    if (placemark.locality == nil){
                        [self setTripCityName:placemark.administrativeArea];
                        self.trip.state = placemark.administrativeArea;
                    } else{
                        [self setTripCityName:placemark.locality];
                        self.trip.state = placemark.administrativeArea;
                    }
                    [self parseTrip];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

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

- (IBAction)clearButtonPressed:(id)sender {
    
    [self resetForm];

}

- (void)resetForm {
    // Initialize the view with no data
    self.tripNameTextField.text = @"";
    self.countryTextField.text = @"";
    self.stateTextField.text= @"";
    self.cityNameTextField.text = @"";
    
    // Set initial date to the field - should be Today's date.
    self.startTripTextField.text = [self.formatter stringFromDate:[NSDate date]];
    self.endTripTextField.text = [self.formatter stringFromDate:[NSDate date]];
    
    if (!_isEditing) {
        self.trip = [[Trip alloc] init];
    }
}

// Sets the cityname for self.trip, and if it changed then sets the global flag to tell use we changed the cityname
// This is mainly so we know if we need to update the Activity models with a new city or not.
- (BOOL)setTripCityName:(NSString *)cityName
{
    if (![self.trip.city isEqualToString:cityName]) {
        self.trip.city = cityName;
        _needsCityUpdate = YES;
    }
    else{
        return NO;
    }
    return YES;
}

- (BOOL)setTripName:(NSString *)name
{
    if (![self.trip.name isEqualToString:name]) {
        self.trip.name = name;
        _needsNameUpdate = YES;
    }
    else{
        return NO;
    }
    return YES;
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

- (void)notEnoughInfo:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = message;
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"Ok"];
    [alertView show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if (alertView.tag == 0)
    {
        if (buttonIndex == 1)
        {
            [SocialUtility deleteTrip:self.trip];
            
            [self.navigationController popToRootViewControllerAnimated:YES];

        }
    }
    

}

#pragma mark - Parse

-(void)parseTrip {
    
    //FIXME Should only parse if things have been changed
    
    [self setTripName: self.tripNameTextField.text];
    self.trip.startDate = self.startTripTextField.text;
    self.trip.endDate = self.endTripTextField.text;
    self.trip.user = [PFUser currentUser].username;
    self.trip.start = [self.formatter dateFromString:self.trip.startDate];
    self.trip.creator = [PFUser currentUser];
    
    // Ensure start date is after end date
    NSTimeInterval startTimeInterval = [[self.formatter dateFromString:self.trip.startDate] timeIntervalSince1970];
    NSTimeInterval endTimeInterval = [[self.formatter dateFromString:self.trip.endDate] timeIntervalSince1970];
    if(startTimeInterval > endTimeInterval)
    {
        [self notEnoughInfo:@"Your start date must happen on or before the end date"];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
    
    if (self.trip.mostRecentPhoto == nil){
        NSString *date = @"01/01/1200";
        NSDateFormatter *format = [[NSDateFormatter alloc]init];
        [format setDateFormat:@"yyyy-MM-dd"];
        self.trip.mostRecentPhoto = [format dateFromString:date];
    }
    
    // If we're editing an existing trip AND we changed the city, we need to update any Activities for this trip to include the new city name.
    if (_isEditing && _needsCityUpdate) {
        [SocialUtility updateActivityContent:self.trip.city forTrip:self.trip];
    }
    
    // If we're editing an existing trip AND we changed the name, we need to update any Photos for this trip to include the new name.
    if (_isEditing && (_needsNameUpdate || _needsCityUpdate)) {
        [SocialUtility updatePhotosForTrip:self.trip];
    }
    
    PFACL *tripACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [tripACL setPublicReadAccess:YES];
    
    self.trip.isPrivate = self.isPrivate;
    
    // Private Trip, set the ACL permissions so only the creator has access - and when members are invited then they'll get READ access as well.
    // TODO: only update ACL if private status changed during editing.
    if (self.isPrivate) {
        [tripACL setPublicReadAccess:NO];
        [tripACL setReadAccess:YES forUser:self.trip.creator];
        [tripACL setWriteAccess:YES forUser:self.trip.creator];
        
        // If this is editing a trip, we need to all existing members to the Read ACL.
        if (_isEditing) {
            // TODO: Add all Trunk Members to READ ACL.
        }
    }

    self.trip.ACL = tripACL;
    
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         
         if(error) {
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                 message:@"Please Try Again"
                                                                delegate:self
                                                       cancelButtonTitle:@"Okay"
                                                       otherButtonTitles:nil, nil];
             alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
             [alertView show];
             
         }
         else
         {
             
             if (self.navigationItem.leftBarButtonItem.tag == 0)
             {
                 [self performSegueWithIdentifier:@"addFriends" sender:self];
             }
             
             else {
                 [self.navigationController popViewControllerAnimated:YES];
             }
         }
         // TODO: Set title image
         self.title = @"TripTrunk";
         
     }];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    AddTripFriendsViewController *vc = segue.destinationViewController;
    vc.trip = self.trip;
    vc.isTripCreation = YES;
    
    // Set up an observer that will be used to reset the form after trip completion
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetForm)
                                                 name:@"resetTripFromNotification"
                                               object:nil];

}

#pragma mark - Dealloc

- (void)dealloc {
    
    // Remove any observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
