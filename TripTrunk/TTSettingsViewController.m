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
#import "TTWebViewViewController.h"

@interface TTSettingsViewController ()
@property (strong, nonatomic) IBOutlet UILabel *versionLabel;
@property NSString *url;
@end

@implementation TTSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.tabBar.hidden = YES;
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    self.versionLabel.text = [NSString stringWithFormat:@"%@(%@)",appVersion,buildNumber];
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

- (IBAction)termsButtonAction:(TTOnboardingButton *)sender {
    self.url = @"http://triptrunkapp.com/user-agreement";
    [self performSegueWithIdentifier:@"pushToWebView" sender:self];
}

- (IBAction)reportButtonActions:(TTOnboardingButton *)sender {
    
}

- (IBAction)privacyPolicyButtonAction:(TTOnboardingButton *)sender {
    self.url = @"http://triptrunkapp.com/privacy-policy";
    [self performSegueWithIdentifier:@"pushToWebView" sender:self];
}

#pragma mark - Seugue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"pushToWebView"]){
        TTWebViewViewController *webVC = segue.destinationViewController;
        webVC.url = self.url;
    }
}
@end
