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
#import "TTCitySearchTextField.h"
#import "TTCitySearchResultsTableViewController.h"
#import "TTPlace.h"

@interface TTHomeViewController () <UITextFieldDelegate, TTCitySearchTextFieldDelegate, UIPopoverPresentationControllerDelegate,TTCitySearchResultsDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (weak, nonatomic) IBOutlet TTCitySearchTextField *homeTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *finishButton;
@property (strong, nonatomic) PFGeoPoint *hometownGeoPoint;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) TTCitySearchResultsTableViewController *citySearchPopover;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property BOOL meetsMinimumRequirements;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalPositionConstraint;
@end

@implementation TTHomeViewController

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    //FIXME: iPhone4 for iPad hack
    if ([[self deviceName] containsString:@"iPad"]){
        self.verticalPositionConstraint.constant = -145;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _user = [PFUser currentUser];
    self.homeTextField.csdelegate = self;
    self.citySearchPopover.srdelegate = self;
    self.finishButton.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.meetsMinimumRequirements = NO;
    self.finishButton.hidden = YES;
}

-(void)viewDidAppear:(BOOL)animated{
    [self.homeTextField becomeFirstResponder];
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
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/v2.12/me/" parameters:@{@"fields": @"id"}];
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
    
    __block BOOL usernameIsAvailable;
    __block BOOL emailIsAvailable;
    [self usernameStillAvailableFromInitialCheckWithCompletionBlock:^(BOOL available) {
        if(available)
            usernameIsAvailable = YES;
        else usernameIsAvailable = NO;
        
        
        [self emailStillAvailableFromInitialCheckWithCompletionBlock:^(BOOL available) {
            if(available)
                emailIsAvailable = YES;
            else emailIsAvailable = NO;
            
            
            
            if(usernameIsAvailable && emailIsAvailable){
                if (self.isFBUser == YES)
                    [self handleFacebookUser];
                else [self submitTripTrunkAccount];
            }else{
                
                NSString *username = @""; NSString *email = @"";
                NSString *and = @""; NSString *is = @" is";
                
                if(!usernameIsAvailable)
                    username = NSLocalizedString(@" username",@" username");
                
                if(!emailIsAvailable)
                    email = NSLocalizedString(@" email address",@" email address");
                
                if(!usernameIsAvailable && !emailIsAvailable){
                    and = NSLocalizedString(@" and",@" and");
                    is = NSLocalizedString(@" are",@" are");
                }
                
                NSString *message = [NSString stringWithFormat:@"We're sorry but the%@%@%@ you used%@ no longer available. Please select a new%@%@%@.",username,and,email,is,username,and,email];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account Creation Error",@"Account Creation Error")
                                                                message:NSLocalizedString(message, message)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Ok",@"Ok")
                                                      otherButtonTitles:nil, nil];
                [alert show];
            }
            
        }];
        
    }];
}

-(void)usernameStillAvailableFromInitialCheckWithCompletionBlock:(void(^)(BOOL))completionBlock{
    //Cloud code to check availability
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.aNewUser[@"Username"], @"username", nil];
    
    [PFCloud callFunctionInBackground:@"ValidateUsername" withParameters:params
                                block:^(id  _Nullable success, NSError * _Nullable error) {
                                    if (error)
                                        completionBlock(NO);
                                    else completionBlock(YES);
    }];
}

-(void)emailStillAvailableFromInitialCheckWithCompletionBlock:(void(^)(BOOL))completionBlock{
    //Cloud code to check availability
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.aNewUser[@"Email"], @"emailaddress", nil];
    
    [PFCloud callFunctionInBackground:@"ValidateEmailAddress" withParameters:params
                                block:^(id  _Nullable success, NSError * _Nullable error) {
                                    if (error)
                                        completionBlock(NO);
                                    else completionBlock(YES);
    }];
}

-(void)submitTripTrunkAccount{
    if(![self.homeTextField.text isEqualToString:@""]){
        // Init the user ONLY if it doesn't exist. If we're logging in with FB, _user is already populated
        if (!self.user)
            self.user = [PFUser user];
        else self.user = [PFUser currentUser];
        
        self.user.username = self.aNewUser[@"Username"];
        [self.user setValue:self.aNewUser[@"First Name"] forKey:@"firstName"];
        [self.user setValue:self.aNewUser[@"Last Name"] forKey:@"lastName"];
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", self.aNewUser[@"First Name"], self.aNewUser[@"Last Name"]];
        [self.user setValue:fullName forKey:@"name"];
        self.user.email = self.aNewUser[@"Email"];
        self.user.password = self.aNewUser[@"Password"];
        [self.user setValue:self.hometownGeoPoint forKey:@"hometownGeoPoint"];
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
        }else{
            [self.user signUp:&error];
        }
        
        
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [self performSegueWithIdentifier:@"next" sender:self];
    }
}


//#pragma mark - CitySearchViewController Delegate
//
//- (void)citySearchDidSelectLocation:(TTPlace *)location {
//    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
//    
//    // If it's a US city/state, we don't need to display the country, we'll assume United States.
//    
//    [self.homeTextField setText:[location.name stringByReplacingOccurrencesOfString:@", United States" withString:@""]];
//    self.finishButton.hidden = NO;
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
        self.popover.sourceView = self.homeTextField;
        self.popover.sourceRect = [self.homeTextField bounds];
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
    self.finishButton.hidden = YES;
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
    [self.homeTextField setText:[selectedCity.name stringByReplacingOccurrencesOfString:@", United States" withString:@""]];
    self.hometownGeoPoint = [[PFGeoPoint alloc] init];
    self.hometownGeoPoint = [PFGeoPoint geoPointWithLatitude:selectedCity.latitude longitude:selectedCity.longitude];
    [self.homeTextField resignFirstResponder];
    self.meetsMinimumRequirements = YES;
    self.finishButton.hidden = NO;
    [self dismissCitySearchPopoverFromView];
}

@end
