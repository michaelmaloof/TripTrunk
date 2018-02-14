//
//  TTSettingsViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/8/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTSettingsViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "AppDelegate.h"
#import "TTOnboardingButton.h"

@interface TTSettingsViewController ()

@end

@implementation TTSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UIButtons

- (IBAction)logout:(UIButton *)sender {
    if ([FBSDKAccessToken currentAccessToken]){
        FBSDKLoginManager *logMeOut = [[FBSDKLoginManager alloc] init];
        [logMeOut logOut];
    }
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] logout];
}

- (IBAction)backButtonWasTapped:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
