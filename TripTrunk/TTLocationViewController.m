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
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
   [self performSegueWithIdentifier:@"next" sender:self];

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TTHomeViewController *homeVC = segue.destinationViewController;
    homeVC.username = self.username;
    homeVC.password = self.password;
    homeVC.email = self.email;
    homeVC.firstName = self.email;
    homeVC.lastName = self.email;
    homeVC.isFBUser = self.isFBUser;
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Failed to get location %@",error);
}



@end
