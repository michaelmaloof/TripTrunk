//
//  TTHomeViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTHomeViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "MBProgressHUD.h"
#import "CitySearchViewController.h"

@interface TTHomeViewController () <CitySearchViewControllerDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (weak, nonatomic) IBOutlet UITextField *homeTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *finishButton;
@property (strong, nonatomic) PFUser *user;

@end

@implementation TTHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _user = [PFUser currentUser];
    self.homeTextField.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//UIButtons
- (IBAction)backButtonWasTapped:(id)sender {
    [self previousLoginViewController];
}
- (IBAction)finishButtonWasTapped:(id)sender {
    //approve hometown FIRST
    [self createAccount];
}

-(void)handleFacebookUser{
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // result is a dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            dispatch_async(dispatch_get_main_queue(), ^{
            });
            
            NSString *facebookID = userData[@"id"];
            
            if (facebookID == nil){
                facebookID = @"";
            }

            [_user setObject:facebookID forKey:@"fbid"];
            NSString *pictureURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID];
            [_user setObject:pictureURL forKey:@"profilePicUrl"];
            [_user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                [self submitTripTrunkAccount];
            }];
            
        }
        else {
            NSLog(@"%@",error);
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"handleFacebookUser:"];
        }
    }];
}

-(void)createAccount{
    if (self.isFBUser == YES){
        [self handleFacebookUser];
    }else {
        [self submitTripTrunkAccount];
    }
}

-(void)submitTripTrunkAccount{
    // Init the user ONLY if it doesn't exist. If we're logging in with FB, _user is already populated
    if (!self.user) {
        self.user = [PFUser user];
    }
    else {
        self.user = [PFUser currentUser];
    }
    
//    self.user.username = self.username;
//    [self.user setValue:self.firstName forKey:@"firstName"];
//    [self.user setValue:self.lastName forKey:@"lastName"];
//    NSString *fullName = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
//    [self.user setValue:fullName forKey:@"name"];
//    self.user.email = self.email;
//    [self.user setPassword:self.password];
//    [self.user setValue:self.hometown forKey:@"hometown"];
    
    self.user.username = self.aNewUser[@"Username"];
    [self.user setValue:self.aNewUser[@"First Name"] forKey:@"firstName"];
    [self.user setValue:self.aNewUser[@"Last Name"] forKey:@"lastName"];
    NSString *fullName = [NSString stringWithFormat:@"%@ %@", self.aNewUser[@"First Name"], self.aNewUser[@"Last Name"]];
    [self.user setValue:fullName forKey:@"name"];
    self.user.email = self.aNewUser[@"Email"];
    self.user.password = self.aNewUser[@"Password"];
    [self.user setValue:self.homeTextField.text forKey:@"hometown"];
    
    
    
    // Set that the user has completed registration
    [self.user setValue:[NSNumber numberWithBool:YES] forKey:@"completedRegistration"];
    
    NSError *error;
    // fb user exists so save, signup if it's a new user
    if (self.isFBUser) {
        [self.user save:&error];
        // After setting the username/password, the Session Token gets erased because it was authenticated with FB.
        // So, we now have to Log In again otherwise an error with throw.
        [PFUser logInWithUsernameInBackground:self.user.username password:self.user.password];
    }
    else
    {
        [self.user signUp:&error];
    }
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    [self performSegueWithIdentifier:@"next" sender:self];
}


#pragma mark - CitySearchViewController Delegate

- (void)citySearchDidSelectLocation:(TTPlace *)location {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
    // If it's a US city/state, we don't need to display the country, we'll assume United States.
    
    [self.homeTextField setText:[location.name stringByReplacingOccurrencesOfString:@", United States" withString:@""]];
}

#pragma mark - Keyboard delegate methods

// The following method needed to dismiss the keyboard after input with a click anywhere on the screen outside text boxes

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

// Go to the next textfield or close the keyboard when the return button is pressed

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    BOOL didResign = [textField resignFirstResponder];
    if (!didResign) return NO;
    
    if ([textField isKindOfClass:[MSTextField class]])
        dispatch_async(dispatch_get_main_queue(),
                       ^ { [[(MSTextField *)textField nextField] becomeFirstResponder]; });
    
    return YES;
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ([textField isEqual:self.homeTextField]) {
        [textField resignFirstResponder];
        
        CitySearchViewController *searchView = [[CitySearchViewController alloc] init];
        searchView.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:searchView];
        [self presentViewController:navController animated:YES completion:nil];
        return NO;
    }
    
    return  YES;
}


@end
