//
//  TTOnboardingViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTOnboardingViewController.h"
#import "TTUsernameViewController.h"

@interface TTOnboardingViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *tripTrunkTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *blueElephant;
@property (weak, nonatomic) IBOutlet UIButton *facebook;
@property (weak, nonatomic) IBOutlet UIButton *withoutFacebook;

@end

@implementation TTOnboardingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//UIButtons

- (IBAction)continueWithFacebookWasTapped:(id)sender {
    [self loginWithFacebook];
}

- (IBAction)continueWithoutFacebookWasTapped:(id)sender {
    [self showSetUsernameView];
}

//TODO if facebook, fill in the email and name preset !!!!!!!!!!!
-(void)loginWithFacebook{
    //Added to prevent facebook 304 error. This will clear the current user that wasn't logged out correctly
    FBSDKLoginManager *logMeOut = [[FBSDKLoginManager alloc] init];
    [logMeOut logOut];
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"email", @"public_profile", @"user_friends", @"read_custom_friendlists" ];
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
         if (error) {
             NSString *errorString = [error userInfo][@"error"];
             [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"_loginWithFacebook:"];
             NSLog(@"%@",errorString);
             NSLog(@"%@",error);
             return;
         }
         if (!user) {
             NSLog(@"Uh oh. The user cancelled the Facebook login.");
         } else if (user.isNew) {
             self.isFBUser = YES;
             [self showSetUsernameView];
         } else {
             if ([user objectForKey:@"fbid"] == nil) {
                 FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
                 [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                     if (!error) {
                         // result is a dictionary with the user's Facebook data
                         NSDictionary *userData = (NSDictionary *)result;
                         PFUser *user = [PFUser currentUser];
                         NSString *fbid = [userData objectForKey:@"id"];
                         if (fbid){
                             [user setObject:fbid forKey:@"fbid"];
                             [user saveInBackground];
                         }
                     }else{
                         [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"_loginWithFacebook:"];
                     }
                 }];
             }
             // Make sure the user has a TripTrunk username
             if (![user valueForKey:@"completedRegistration"] || [[user valueForKey:@"completedRegistration"] boolValue] == FALSE) {
                 self.isFBUser = YES;
                 [self showSetUsernameView];
             } else {
                 [self dismissViewControllerAnimated:YES completion:^{
                 }];
             }
         }
     }];
}

- (void)showSetUsernameView {
    [self performSegueWithIdentifier:@"setUsernameSegue" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    TTUsernameViewController *username = segue.destinationViewController;
    username.isFBUser = self.isFBUser;
}

- (IBAction)termsWasTapped:(id)sender {
    EULAViewController *eula = [[EULAViewController alloc] initWithNibName:@"EULAViewController" bundle:[NSBundle mainBundle]];
    eula.alreadyAccepted = YES;
    UINavigationController *homeNavController = [[UINavigationController alloc] initWithRootViewController:eula];
    [self presentViewController:homeNavController animated:YES completion:nil];
}

@end
