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
#import "TTUtility.h"
#import "CitySearchViewController.h"
#import "HomeMapViewController.h"

@interface AddTripViewController () <UIAlertViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, CitySearchViewControllerDelegate, UITextViewDelegate>

// Text Fields
@property (weak, nonatomic) IBOutlet UITextField *tripNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *startTripTextField;
@property (weak, nonatomic) IBOutlet UITextField *endTripTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *tripDatePicker;
@property (strong, nonatomic) IBOutlet UITextField *locationTextField;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIButton *helpButton;

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
@property (weak, nonatomic) IBOutlet UILabel *lockLabel;
@property (weak, nonatomic) IBOutlet UIButton *descriptionButton;
@property UITextView *descriptionTextView;
// Date Properties
@property NSDateFormatter *formatter;

@property (strong, nonatomic) UIDatePicker *datePicker;


@property (strong, nonatomic) NSString *city;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSString *country;



@end

@implementation AddTripViewController


- (void)viewDidLoad {
    
//FIXME sometimes segue takes too long to occur or doesnt happen at all. maybe shouldnt check here?
    
    [super viewDidLoad];
    
    self.descriptionTextView = [[UITextView alloc]init];
    self.descriptionTextView.hidden = YES;
    [self.descriptionTextView setFont:[UIFont fontWithName:@"Bradley Hand" size:20]];
    self.descriptionTextView.backgroundColor = [UIColor colorWithRed:250.0/255.0 green:244.0/255.0 blue:229.0/255.0 alpha:1.0];
    self.descriptionTextView.textColor = [UIColor colorWithRed:95.0/255.0 green:148.0/255.0 blue:172.0/255.0 alpha:1.0];
    self.descriptionTextView.frame = CGRectMake(self.view.frame.origin.x + 20, self.view.frame.origin.y + 100, self.view.frame.size.width - 40, self.view.frame.size.height - 200);
    self.descriptionTextView.editable = YES;
    self.descriptionTextView.selectable = YES;
    self.descriptionTextView.scrollEnabled = YES;
    self.descriptionTextView.delegate = self;
    [self.view addSubview:self.descriptionTextView];
    
//currently we don't want users being able to change a trunk tp public or private once the trunk has been created
    self.lockLabel.hidden = YES;
    
//self.clear is just for development. It allows us to quickly clear all the textfields
    self.clear.hidden = YES;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.tripDatePicker.hidden = YES;
    self.startTripTextField.delegate = self;
    self.endTripTextField.delegate = self;
    self.tripNameTextField.delegate = self;
    self.locationTextField.delegate = self;
    self.formatter = [[NSDateFormatter alloc]init];
    [self.formatter setDateFormat:@"MM/dd/yyyy"];
    self.startTripTextField.tintColor = [UIColor clearColor];
    self.endTripTextField.tintColor = [UIColor clearColor];


    
//FIXME This may not be necessary anymore since we no longer need the users location
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
    self.locationManager.delegate = self;
    
//if self.trip is not nil then it means the user is editing a trunk and not creating a new one.
    if (self.trip) {
        _isEditing = YES;
        self.helpButton.hidden = YES;
        self.title  = NSLocalizedString(@"Trunk Details",@"Trunk Details");
        
        self.descriptionTextView.text = self.trip.descriptionStory;
        
        if ([self.descriptionTextView.text isEqualToString:@""]){
            [self.descriptionButton setImage:[UIImage imageNamed:@"editPencil"] forState:UIControlStateNormal];
        } else {
            [self.descriptionButton setImage:[UIImage imageNamed:@"checkCircle"] forState:UIControlStateNormal];
        }
        
//Not sure why but in this view if we don't call this when we change the nav title then the tab bar title changes too.
        [self tabBarTitle];
        
//if they're editing the trunk we fill in the text fields with the correct info
        self.tripNameTextField.text = self.trip.name;
        self.locationTextField.text = [NSString stringWithFormat:@"%@, %@, %@", self.trip.city, self.trip.state, self.trip.country];
        self.startTripTextField.text = self.trip.startDate;
        self.endTripTextField.text = self.trip.endDate;
        
        self.city = self.trip.city;
        self.state = self.trip.state;
        self.country = self.trip.country;
        
        self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Update",@"Update");
        self.navigationItem.rightBarButtonItem.tag = 1;
        self.navigationItem.leftBarButtonItem.tag = 1;
        self.delete.hidden = NO;
        self.public.hidden = YES;
        self.private.hidden = YES;
        
        self.cancelBar.title = NSLocalizedString(@"Cancel",@"Cancel");
        self.cancelBar.enabled = YES;
    }
//if self.trip is  nil then it means the user is creating a new trunk and not simply editing one
    
    else {
        _isEditing = NO;

        // initialize the trip object
        self.title  = NSLocalizedString(@"Add New Trunk", @"Add New Trunk");
        [self tabBarTitle];
        
        self.descriptionTextView.text = @"";

        // Set initial date to the field - should be Today's date.
        self.startTripTextField.text = [self.formatter stringFromDate:[NSDate date]];
        self.endTripTextField.text = [self.formatter stringFromDate:[NSDate date]];

        self.trip = [[Trip alloc] init];
        self.cancelBar.title = @"";
        self.cancelBar.enabled = FALSE;
       

    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Next", @"Next");
    self.navigationItem.rightBarButtonItem.tag = 0;
    self.navigationItem.leftBarButtonItem.tag = 0;
    self.delete.hidden = YES;
    
    }
    
    [self setupDatePicker];

    [self checkPublicPrivate];
    
}

/**
 *  Sets up the date pickers design for selecting the start and end dates of the trunks
 *
 *
 */
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
    UIBarButtonItem *barButtonNext = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"Next")
                                                                      style:UIBarButtonItemStyleDone target:self action:@selector(dismissPickerView:)];
    UILabel *startLabel = [[UILabel alloc] init];
    [startLabel setText:NSLocalizedString(@"Start Date",@"Start Date")];
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
    UIBarButtonItem *barButtonDone = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done")
                                                                      style:UIBarButtonItemStyleDone target:self action:@selector(dismissPickerView:)];
    
    UILabel *endLabel = [[UILabel alloc] init];
    [endLabel setText:NSLocalizedString(@"End Date", @"End Date")];
    [endLabel setFont:[UIFont systemFontOfSize:12.0]];
    [endLabel setTextColor:[UIColor blackColor]];
    [endLabel sizeToFit];
    UIBarButtonItem *endLabelButton = [[UIBarButtonItem alloc] initWithCustomView:endLabel];
    endTripToolbar.items = [[NSArray alloc] initWithObjects:endLabelButton, space, barButtonDone, nil];
    barButtonDone.tintColor=[UIColor blackColor];

    self.endTripTextField.inputView = self.datePicker;
    self.endTripTextField.inputAccessoryView = endTripToolbar;
}

/**
 *  Update the screen based on if the trunk is private or public
 *
 *
 */
-(void)checkPublicPrivate{
    if (self.trip.isPrivate == NO || self.trip == nil)
    {
        [self.private setImage:[UIImage imageNamed:@"unlocked"] forState:UIControlStateNormal];
        [self.private setImage:[UIImage imageNamed:@"lockedGray"] forState:UIControlStateNormal];
        self.backGroundImage.image = [UIImage imageNamed:@"yellowSkyMountain_background"];


        self.public.tag = 1;
        self.private.tag = 0;
    }
    
    else {
        [self.private setImage:[UIImage imageNamed:@"unlockedGray"] forState:UIControlStateNormal];
        [self.private setImage:[UIImage imageNamed:@"locked"] forState:UIControlStateNormal];
        self.backGroundImage.image = [UIImage imageNamed:@"blueSkyMountain_background"];

        self.public.tag = 0;
        self.private.tag = 1;
    }
}

#pragma mark = TextField Delegate Methods

//move the view up and down if the user starts typing to adjust for the keyboard
-(void)textFieldDidBeginEditing:(UITextField *)textField
{

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y -60, self.view.frame.size.width, self.view.frame.size.height);
    
}

-(void)textFieldDidEndEditing:(UITextField *)textField{

    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 60, self.view.frame.size.width, self.view.frame.size.height);
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
//we adjusts the designs of the textfield based on which one the user is typing in
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.endTripTextField) {
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
    else if ([textField isEqual:self.locationTextField]) {
        [textField resignFirstResponder];
        
        CitySearchViewController *searchView = [[CitySearchViewController alloc] init];
        searchView.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:searchView];
        [self presentViewController:navController animated:YES completion:nil];
        return NO;
    }
    
    else {
        self.startTripTextField.backgroundColor = [UIColor whiteColor];
        self.endTripTextField.backgroundColor = [UIColor whiteColor];
        return  YES;
    }
}

#pragma mark - CitySearchViewController Delegate

//if they select location we present a view that allows the user to search for locations
- (void)citySearchDidSelectLocation:(NSString *)location {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    __block BOOL iserror = NO;
    
    [[TTUtility sharedInstance] locationDetailsForLocation:location block:^(NSDictionary *locationDetails, NSError *error) {
        
        if (error){
            self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
            [self tabBarTitle];
            [self notEnoughInfo:NSLocalizedString(@"Something seems to have gone wrong. Please try again later and make sure you're connected to the internet.",@"Something seems to have gone wrong. Please try again later and make sure you're connected to the internet.")];
        }else{
            
            if (locationDetails != nil){
                
                self.city = locationDetails[@"geobytescity"];
                self.state = locationDetails[@"geobytesregion"];
                self.country = locationDetails[@"geobytescountry"];
                
            } else if ([location isEqualToString:@"Barcelona, CT, Spain"]){
                self.city = @"Barcelona";
                self.state =@"Catalonia";
                self.country = @"Spain";
            } else if ([location isEqualToString:@"Sao Paulo, SP, Brazil"]){
                self.city = @"Sao Paulo";
                self.state =@"Sao Paulo";
                self.country = @"Brazil";
            }else {
                iserror = YES;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (iserror == NO){
                    self.locationTextField.text = [NSString stringWithFormat:@"%@, %@, %@", self.city, self.state, self.country];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location Unavailable",@"Location Unavailable")
                                                                    message:NSLocalizedString(@"We apologize. Please try another location.",@"We apologize. Please try another location.")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                                          otherButtonTitles:nil, nil];
                    alert.tag = 69;
                    [alert show];
                }
            });
        }
    }];
    
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



#pragma mark - Date Picker
/**
 *  If the user changed the dates of the trip
 *
 *
 */
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
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if ([self.tripNameTextField.text isEqualToString:@""]){
        [self notEnoughInfo:NSLocalizedString(@"Please name your trunk.",@"Please name your trunk.")];
        self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
        [self tabBarTitle];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else if ([self.locationTextField.text isEqualToString:@""]){
        [self notEnoughInfo:NSLocalizedString(@"Please give your trunk a location.",@"Please give your trunk a location.")];
        self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
        [self tabBarTitle];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        //FIXME dont do this every time they click next. only if they changed location text fields
        self.title = NSLocalizedString(@"Verifying Location...",@"Verifying Location...");
        [self tabBarTitle];
        //take the location the user typed in, make sure its a real location and meets the correct requirements
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        NSString *address = self.locationTextField.text;
        
        [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error)
         {
             if (placemarks == nil && error)
             {
                 NSLog(@"Error geocoding address: %@ withError: %@",address, error);
                 // TODO: Set title image
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                 [self tabBarTitle];
                 [self notEnoughInfo:NSLocalizedString(@"Something seems to have gone wrong. Please try again later.",@"Something seems to have gone wrong. Please try again later.")];
                 self.navigationItem.rightBarButtonItem.enabled = YES;
             } else if (placemarks == nil && !error) {
                 NSLog(@"Error geocoding address: %@ withError: %@",address, error);
                 // TODO: Set title image
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                 [self tabBarTitle];
                 [self notEnoughInfo:NSLocalizedString(@"Something is currently wrong with this location. Please try a different location.",@"Something is currently wrong with this location. Please try a different location.")];
                 self.navigationItem.rightBarButtonItem.enabled = YES;
             } else if (placemarks.count == 0){
                 NSLog(@"Error geocoding address: %@ withError: %@",address, error);
                 // TODO: Set title image
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                 [self tabBarTitle];
                 [self notEnoughInfo:NSLocalizedString(@"Something is currently wrong with this location. Please try a different location.",@"Something is currently wrong with this location. Please try a different location.")];
                 self.navigationItem.rightBarButtonItem.enabled = YES;
             }
             
             else if (!error)
             {
                 //make sure the user filled in all the correct text fields
                 if (![self.tripNameTextField.text isEqualToString:@""] && ![self.locationTextField.text isEqualToString:@""] && ![self.startTripTextField.text isEqualToString:@""] && ![self.endTripTextField.text isEqualToString:@""])
                 {
                     // Trip Input has correct data - save the trip!
                     
                     CLPlacemark *placemark = placemarks.firstObject;
                     
                     self.trip.lat = placemark.location.coordinate.latitude;
                     self.trip.longitude = placemark.location.coordinate.longitude;
                     
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
                     [self notEnoughInfo:NSLocalizedString(@"Please fill out all boxes",@"Please fill out all boxes")];
                     self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                     [self tabBarTitle];
                     self.navigationItem.rightBarButtonItem.enabled = YES;
                     
                 }
             }
             
             self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
             [self tabBarTitle];
             
             return;
         }];
        
    }
    
}

/**
 *  Clears text fields, no longer used
 *
 *
 */
- (IBAction)clearButtonPressed:(id)sender {
    
    [self resetForm];

}

/**
 * Clears textfields
 *
 *
 */
- (void)resetForm {
    // Initialize the view with no data
    self.tripNameTextField.text = @"";
    self.locationTextField.text = @"";
    
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
    alertView.title = NSLocalizedString(@"Are you sure you want to delete this Trunk?",@"Are you sure you want to delete this Trunk?");
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:NSLocalizedString(@"No",@"No")];
    [alertView addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete")];
    alertView.tag = 0;
    [alertView show];
    
    [self tabBarTitle];
    
    
}

- (IBAction)publicTapped:(id)sender {
    if (self.public.tag == 0)
    {
        [self.public setImage:[UIImage imageNamed:@"unlocked"] forState:UIControlStateNormal];
        [self.private setImage:[UIImage imageNamed:@"lockedGray"] forState:UIControlStateNormal];
        self.backGroundImage.image = [UIImage imageNamed:@"yellowSkyMountain_background"];
        self.public.tag = 1;
        self.private.tag = 0;
        self.isPrivate = NO;

    }
    
}


- (IBAction)privateTapped:(id)sender {
    if (self.private.tag == 0)
    {
        [self.public setImage:[UIImage imageNamed:@"unlockedGray"] forState:UIControlStateNormal];
        [self.private setImage:[UIImage imageNamed:@"locked"] forState:UIControlStateNormal];
        self.backGroundImage.image = [UIImage imageNamed:@"blueSkyMountain_background"];
        
        self.public.tag = 0;
        self.private.tag = 1;
        self.isPrivate = YES;

    }

}

- (void)notEnoughInfo:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = message;
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:NSLocalizedString(@"Ok", @"Ok")];
    [alertView show];
    
    [self tabBarTitle];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if (alertView.tag == 0)
    {
        if (buttonIndex == 1)
        {
            [SocialUtility deleteTrip:self.trip];
            NSMutableArray *locationArray = [[NSMutableArray alloc]init];
            for (UIViewController *vc in self.navigationController.viewControllers){
                if ([vc isKindOfClass:[HomeMapViewController class]]){
                    [locationArray addObject:vc];
                }
            }
            
            [self.navigationController popToViewController:[locationArray lastObject] animated:YES];

        }
    }
    

}

#pragma mark - Parse
/**
 *  Save the trip to Parse
 *
 *
 */
-(void)parseTrip {
    
    //FIXME Should only parse if things have been changed
    
    [self setTripName: self.tripNameTextField.text];
    self.trip.startDate = self.startTripTextField.text;
    self.trip.descriptionStory = self.descriptionTextView.text;
    self.trip.endDate = self.endTripTextField.text;
    self.trip.user = [PFUser currentUser].username;
    self.trip.start = [self.formatter dateFromString:self.trip.startDate];
    self.trip.creator = [PFUser currentUser];
    
    // Ensure start date is after end date
    NSTimeInterval startTimeInterval = [[self.formatter dateFromString:self.trip.startDate] timeIntervalSince1970];
    NSTimeInterval endTimeInterval = [[self.formatter dateFromString:self.trip.endDate] timeIntervalSince1970];
    if(startTimeInterval > endTimeInterval)
    {
        [self notEnoughInfo:NSLocalizedString(@"Your start date must happen on or before the end date",@"Your start date must happen on or before the end date")];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        return;
    }
    
//if the most recent photo is nil then we set the date to a long time ago. This way we know the dot on the trunk is blue. I didnt want to leave a nil value in parse.
    if (self.trip.publicTripDetail.mostRecentPhoto == nil){
        NSString *date = @"01/01/1200";
        NSDateFormatter *format = [[NSDateFormatter alloc]init];
        [format setDateFormat:@"yyyy-MM-dd"];
        self.trip.publicTripDetail.mostRecentPhoto = [format dateFromString:date];
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
    
    [[PFUser currentUser] fetch]; // Fetch the currentu

// TRUNKS ARE ALWAYS PUBLIC, SO THIS ISN'T NEEDED ANYMORE. 
//    // If the user is Private then it's not a Publicly Readable Trip. Only people in their FriendsOf role can see it.
//    NSLog(@"Private value: %@", [[PFUser currentUser] objectForKey:@"private"]);
//    if ([[[PFUser currentUser] objectForKey:@"private"] boolValue]) {
//        [tripth setPublicReadAccess:NO];
//        NSLog(@"Set private read permissions - role name: %@", roleName);
//    }
    
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
    else {
        // Only add the friendsOf_ role to the ACL if the trunk is NOT private! A private trunk shouldn't be visible to followers. just trunk members
        // This fixes the shitty bug that was live at launch.
        NSString *roleName = [NSString stringWithFormat:@"friendsOf_%@", [[PFUser currentUser] objectId]];
        [tripACL setReadAccess:YES forRoleWithName:roleName];
    }

    self.trip.ACL = tripACL;
    

    if(!self.trip.publicTripDetail){
        self.trip.publicTripDetail = [[PublicTripDetail alloc]init];
    }

    
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         
         if(error) {
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                 message:NSLocalizedString(@"Please Try Again",@"Please Try Again")
                                                                delegate:self
                                                       cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                       otherButtonTitles:nil, nil];
             alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
             [alertView show];
             
             
         }
         else
         {
             
             if (self.navigationItem.leftBarButtonItem.tag == 0)
             {
                 [self performSegueWithIdentifier:@"addFriends" sender:self];
                 self.navigationItem.rightBarButtonItem.enabled = YES;
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");

             }
             
             else {
                 [self.navigationController popViewControllerAnimated:YES];
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                 self.navigationItem.rightBarButtonItem.enabled = YES;

             }
         }
         // TODO: Set title image
         [self tabBarTitle];
         
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

- (IBAction)questionMarkTapped:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Public vs. Private Trunks",@"Public vs. Private Trunks")
                                                    message:NSLocalizedString(@"\xF0\x9F\x94\x93 = Public Trunk - anyone can view \n \xF0\x9F\x94\x92= Private Trunk - only members can view",@"\xF0\x9F\x94\x93 = Public Trunk - anyone can view \n \xF0\x9F\x94\x92= Private Trunk - only members can view")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (IBAction)descriptionTapped:(id)sender {
    self.descriptionTextView.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.descriptionTextView becomeFirstResponder];
    self.title = NSLocalizedString(@"Tell This Trunk's Story", @"Tell This Trunk's Story");
    [self tabBarTitle];

}

-(void)viewDidAppear:(BOOL)animated{
    
    self.descriptionTextView.text = self.trip.descriptionStory;
    
    if ([self.descriptionTextView.text isEqualToString:@""]){
        [self.descriptionButton setImage:[UIImage imageNamed:@"editPencil"] forState:UIControlStateNormal];
    } else {
        [self.descriptionButton setImage:[UIImage imageNamed:@"checkCircle"] forState:UIControlStateNormal];
    }
    
}

-(void)textViewDidEndEditing:(UITextView *)textView{
    self.descriptionTextView.hidden = YES;
    self.trip.descriptionStory = self.descriptionTextView.text;
    if ([self.descriptionTextView.text isEqualToString:@""]){
        [self.descriptionButton setImage:[UIImage imageNamed:@"editPencil"] forState:UIControlStateNormal];
    } else {
        [self.descriptionButton setImage:[UIImage imageNamed:@"checkCircle"] forState:UIControlStateNormal];
    }
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.title = @"Add New Trunk";
    [self tabBarTitle];
}

@end
