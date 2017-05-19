//
//  LocationViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTLocationViewController.h"
#import "TTHomeViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface TTLocationViewController () <CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UILabel *allowLabel;
@property (weak, nonatomic) IBOutlet UIButton *noThanks;
@property (weak, nonatomic) IBOutlet UIButton *turnOn;
@property BOOL authorizationBypass;
@end

@implementation TTLocationViewController{
    CLLocationManager *locationManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    locationManager = [[CLLocationManager alloc] init];
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
       [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways){
        [self updateUIAlreadyAuthorized];
    } else if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
              [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
              [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        [self updateUIDeniedAuthorization];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidLayoutSubviews{
    if(self.authorizationBypass)
        [self.turnOn setTitle:NSLocalizedString(@"CONTINUE", @"CONTINUE") forState:UIControlStateNormal];
}

//UIButtons

- (IBAction)noThanksWasTapped:(id)sender {
    [self performSegueWithIdentifier:@"next" sender:self];
}

- (IBAction)turnOnWasTapped:(id)sender {
    if(self.authorizationBypass){
        [self performSegueWithIdentifier:@"next" sender:self];
    }else{
        locationManager.delegate = self;
        [locationManager requestWhenInUseAuthorization];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TTHomeViewController *vc = segue.destinationViewController;
    vc.aNewUser = self.user;
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"Failed to get location %@",error);
    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"locationManager:didFailWithError"];
    [self performSegueWithIdentifier:@"next" sender:self];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusDenied) {
        // The user denied authorization
        [self performSegueWithIdentifier:@"next" sender:self];
    }else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // The user accepted authorization
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];
        [self performSegueWithIdentifier:@"next" sender:self];
    }
}

#pragma mark - CLLocationManagerAuthorizationStatus
-(void)updateUIAlreadyAuthorized{
    self.allowLabel.text = NSLocalizedString(@"You have already authorized TripTrunk to access your location.", @"You have already authorized TripTrunk to access your location.");
    self.noThanks.hidden = YES;
    [locationManager startUpdatingLocation];
    self.authorizationBypass = YES;
}

-(void)updateUIDeniedAuthorization{
    self.allowLabel.text = NSLocalizedString(@"You have denied TripTrunk authorization to access your location.", @"You have denied TripTrunk authorization to access your location.");
    self.noThanks.hidden = YES;
    self.authorizationBypass = YES;
}

#pragma mark - UIButtons
- (IBAction)backWasTapped:(id)sender {
    [self previousLoginViewController];
}



@end
