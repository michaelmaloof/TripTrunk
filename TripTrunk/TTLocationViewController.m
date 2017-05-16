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

@end

@implementation TTLocationViewController{
    CLLocationManager *locationManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    locationManager = [[CLLocationManager alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//UIButtons

- (IBAction)noThanksWasTapped:(id)sender {
    [self performSegueWithIdentifier:@"next" sender:self];
}

- (IBAction)turnOnWasTapped:(id)sender {
    //TODO Track Location:
    locationManager.delegate = self;
    [locationManager requestWhenInUseAuthorization];
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

- (IBAction)backWasTapped:(id)sender {
    [self previousLoginViewController];
}



@end
