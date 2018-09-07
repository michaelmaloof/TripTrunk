//
//  TTTrunkLocationViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/16/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTTrunkLocationViewController.h"
#import "TTCitySearchTextField.h"
#import "TTOnboardingButton.h"
#import "TTAddMembersViewController.h"
#import "TTAnalytics.h"
#import "TTCitySearchResultsTableViewController.h"
#import "TTPlace.h"

//CLLocationManager *locationManager;

@interface TTTrunkLocationViewController () <UITextFieldDelegate, TTCitySearchTextFieldDelegate, UIPopoverPresentationControllerDelegate,TTCitySearchResultsDelegate>
@property (strong, nonatomic) IBOutlet TTOnboardingButton *nextButton;
@property (strong, nonatomic) IBOutlet TTCitySearchTextField *trunkLocation;
@property (strong, nonatomic) IBOutlet UISwitch *isPrivate;
@property (strong, nonatomic) TTPlace *place;
@property BOOL authorizationBypass;
@property (strong, nonatomic) TTCitySearchResultsTableViewController *citySearchPopover;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property BOOL meetsMinimumRequirements;
@property (strong, nonatomic) IBOutlet UITextView *trunkTitle;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalPositionConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *privateLabelVPConstraint;
@property (weak, nonatomic) IBOutlet UILabel *privateLabel;
@property (weak, nonatomic) IBOutlet UITextView *privateInfoLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cityVerticalPositionConstraint;

@end

@implementation TTTrunkLocationViewController

#pragma mark - iPad Hack
-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    //FIXME: iPhone4 for iPad hack
    if ([[self deviceName] containsString:@"iPad"]){
        self.verticalPositionConstraint.constant = 0;
        self.cityVerticalPositionConstraint.constant = 16; self.privateLabelVPConstraint.constant = 4;
        self.privateLabel.textColor = [UIColor whiteColor];
        self.privateInfoLabel.textColor = [UIColor whiteColor];
       
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.user = [PFUser currentUser];
    self.trunkLocation.csdelegate = self;
    self.citySearchPopover.srdelegate = self;
    self.nextButton.hidden = YES;
    self.trunkTitle.text = self.trip.name;
//    locationManager = [[CLLocationManager alloc] init];
//    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
//       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways){
//        [self updateUIAlreadyAuthorized];
//    } else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
//              [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
//              [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
//        [self updateUIDeniedAuthorization];
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TTAddMembersViewController *addMembersViewController = segue.destinationViewController;
    NSArray *locale = [self.trunkLocation.text componentsSeparatedByString:@", "]; //FIXME: This is not good. Figure out a better way
    self.trip.city = locale[0];
    self.trip.state = locale[1];
    self.trip.country = locale[2];
    self.trip.lat = self.place.latitude;
    self.trip.longitude = self.place.longitude;
    self.trip.creator = [PFUser currentUser];
    self.trip.user = [PFUser currentUser].username;
    self.trip.isPrivate = self.isPrivate.isSelected;
    self.trip[@"mostRecentPhoto"] = [NSDate date];
    addMembersViewController.trip = self.trip;
    addMembersViewController.delegate = self;
}

- (IBAction)backButtonWasTapped:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonWasTapped:(id)sender {
    if(![self.trunkLocation.text isEqualToString:@""])
        [self performSegueWithIdentifier:@"pushToAddPeopleToTrunk" sender:self];
}

//#pragma mark - CLLocationManagerDelegate
//- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
//    NSLog(@"Failed to get location %@",error);
//    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"locationManager:didFailWithError"];
//    [self performSegueWithIdentifier:@"next" sender:self];
//}
//
//- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
//    if (status == kCLAuthorizationStatusDenied) {
//        // The user denied authorization
//        [self performSegueWithIdentifier:@"next" sender:self];
//    }else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
//        // The user accepted authorization
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//        [locationManager startUpdatingLocation];
//        [self performSegueWithIdentifier:@"next" sender:self];
//    }
//}
//
//#pragma mark - CLLocationManagerAuthorizationStatus
//-(void)updateUIAlreadyAuthorized{
////    self.allowLabel.text = NSLocalizedString(@"You have already authorized TripTrunk to access your location.", @"You have already authorized TripTrunk to access your location.");
////    self.noThanks.hidden = YES;
//    [locationManager startUpdatingLocation];
//    self.authorizationBypass = YES;
//}
//
//-(void)updateUIDeniedAuthorization{
////    self.allowLabel.text = NSLocalizedString(@"You have denied TripTrunk authorization to access your location.", @"You have denied TripTrunk authorization to access your location.");
////    self.noThanks.hidden = YES;
//    self.authorizationBypass = YES;
//}

#pragma mark - TTCitySearchTextFieldDelegate
-(void)displayCitySearchPopoverFromView:(NSArray*)results{
    
    if(self.popover.delegate == nil){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        self.citySearchPopover = [storyboard instantiateViewControllerWithIdentifier:@"TTCitySearchResultsTableViewController"];
        self.citySearchPopover.searchResults = results;
        self.citySearchPopover.modalPresentationStyle = UIModalPresentationPopover;
        
        //force the popover to display like an iPad popover otherwise it will be full screen
        self.popover  = self.citySearchPopover.popoverPresentationController;
        self.popover.delegate = self;
        self.popover.sourceView = self.trunkLocation;
        self.popover.sourceRect = [self.trunkLocation bounds];
        self.popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
        
        self.citySearchPopover.preferredContentSize = CGSizeMake([self.citySearchPopover preferredWidthForPopover], [self.citySearchPopover preferredHeightForPopover]);
        self.citySearchPopover.srdelegate = self;
        [self presentViewController:self.citySearchPopover animated:YES completion:nil];
    }else{
        self.citySearchPopover.searchResults = results;
        self.citySearchPopover.preferredContentSize = CGSizeMake([self.citySearchPopover preferredWidthForPopover], [self.citySearchPopover preferredHeightForPopover]);
        [self.citySearchPopover reloadTable];
    }
}

-(void)dismissCitySearchPopoverFromView{
    self.popover.delegate = nil;
    [self.citySearchPopover dismissViewControllerAnimated:YES completion:nil];
}

-(void)resetCitySearchTextField{
    self.meetsMinimumRequirements = NO;
    self.nextButton.hidden = YES;
}

#pragma mark - UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverController{
    self.popover.delegate = nil;
}

#pragma mark - TTCitySearchResultsDelegate
-(void)didSelectTableRow:(TTPlace*)selectedCity{
    self.place = selectedCity;
    [self.trunkLocation setText:[selectedCity.name stringByReplacingOccurrencesOfString:@", United States" withString:@""]];
    [self.trunkLocation resignFirstResponder];
    self.meetsMinimumRequirements = YES;
    self.nextButton.hidden = NO;
    [self dismissCitySearchPopoverFromView];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField.text isEqualToString:@""]){
        return NO;
    }else{
        [self performSegueWithIdentifier:@"pushToAddPeopleToTrunk" sender:self];
        return YES;
    }
}
@end
