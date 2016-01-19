//
//  EditProfileViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/10/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "EditProfileViewController.h"
#import "CitySearchViewController.h"
#import "EULAViewController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>



@interface EditProfileViewController () <CitySearchViewControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *hometownTextField;
@property (strong, nonatomic) IBOutlet UITextView *bioTextView;
@property (strong, nonatomic) IBOutlet UITextField *nameTextView;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *currentCity;
@property (weak, nonatomic) IBOutlet UILabel *editBio;
@property (weak, nonatomic) IBOutlet UISwitch *privateAccountSwitch;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;

@end

@implementation EditProfileViewController

- (id)initWithUser:(PFUser *)user;
{
    self = [super initWithNibName:@"EditProfileViewController" bundle:nil]; // nil is ok if the nib is included in the main bundle
    if (self && user) {
        _user = user;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Edit Profile";
    [self.scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] == YES)
    {
        self.facebookButton.hidden = YES;
    } else {
        self.facebookButton.hidden = NO;

    }
    
    
    _hometownTextField.delegate = self;
    self.hometownTextField.text = [_user valueForKey:@"hometown"];
    self.bioTextView.text = [_user valueForKey:@"bio"];
    self.nameTextView.text = _user[@"name"];
    if (_user[@"private"] && [_user[@"private"] boolValue] == YES) {
        self.privateAccountSwitch.on = YES;
    }
    
    // Set Edit button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancelButtonPressed:)];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (void)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)privateSwitchChanged:(id)sender {
    
    if (self.privateAccountSwitch.isOn) {
        // ACCOUNT WAS TURNED TO PRIVATE
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are You Sure?"
                                                        message:@"A private account hides your pictures from anyone who doesn't follow you. Users must request to follow you"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Continue", nil];
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are You Sure?"
                                                        message:@"All of your pictures will become visible to anyone on the app, not just your followers"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Continue", nil];
        [alert show];
    }
    
}

- (IBAction)saveButtonPressed:(id)sender {
//    [self.saveButton setEnabled:NO];
    
    NSString *hometown = self.hometownTextField.text;
    NSString *bio = self.bioTextView.text;
    NSString *name = self.nameTextView.text;

    [_user setValue:hometown forKey:@"hometown"];
    [_user setValue:bio forKey:@"bio"];
    [_user setValue:name forKey:@"name"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(shouldSaveUserAndClose:)]) {
        [self.delegate shouldSaveUserAndClose:_user];
    }
    
}
- (IBAction)termsOfServiceButtonPressed:(id)sender {
    EULAViewController *eula = [[EULAViewController alloc] initWithNibName:@"EULAViewController" bundle:[NSBundle mainBundle]];
    eula.alreadyAccepted = YES;
    UINavigationController *homeNavController = [[UINavigationController alloc] initWithRootViewController:eula];
    
    [self presentViewController:homeNavController animated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // Reset the switch they just changed
        self.privateAccountSwitch.on = !self.privateAccountSwitch.on;
    }
    else if (buttonIndex == 1) {
        NSLog(@"Continue Button Pressedd");
        if (self.privateAccountSwitch.isOn) {
            // Become Private
            NSLog(@"Become Private");
            [PFCloud callFunctionInBackground:@"becomePrivate" withParameters:nil block:^(id  _Nullable object, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Error becoming private: %@", error);
                }
                else {
                    NSLog(@"Successfully privatized");
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[PFUser currentUser] fetch];
                        NSLog(@"Private value: %@", [[PFUser currentUser] objectForKey:@"private"]);
                        [self.delegate privacyChanged:[PFUser currentUser]];
                    });

                }
            }];
        }
        else {
            // Become Public
            NSLog(@"Become Public");
            [PFCloud callFunctionInBackground:@"becomePublic" withParameters:nil block:^(id  _Nullable object, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Error becoming public: %@", error);
                }
                else {
                    NSLog(@"Successfully publicized");
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[PFUser currentUser] fetch];
                        NSLog(@"Private value: %@", [[PFUser currentUser] objectForKey:@"private"]);
                        [self.delegate privacyChanged:[PFUser currentUser]];
                    });
                }
            }];
            
        }
    }
}


#pragma mark - Keyboard delegate methods

// The following method needed to dismiss the keyboard after input with a click anywhere on the screen outside text boxes

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

// close the keyboard when the return button is pressed

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    
    return YES;
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if ([textField isEqual:self.hometownTextField]) {
        [textField resignFirstResponder];
        
        CitySearchViewController *searchView = [[CitySearchViewController alloc] init];
        searchView.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:searchView];
        [self presentViewController:navController animated:YES completion:nil];
        return NO;
    }
    
    return  YES;
}


#pragma mark - CitySearchViewController Delegate

- (void)citySearchDidSelectLocation:(NSString *)location {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    
    // If it's a US city/state, we don't need to display the country, we'll assume United States.
    
    [self.hometownTextField setText:[location stringByReplacingOccurrencesOfString:@", United States" withString:@""]];
}

- (IBAction)addFacebook:(id)sender
{
    //List of permissions we want from the user's facebook to link tp the parse user. We don't need the email since we won't be changing their current email to their facebook email.
    NSArray *permissionsArray = @[@"public_profile", @"user_friends"];
    
    //Make sure the user isnt already linked with facebook
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] == NO)
    {
        [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withReadPermissions:permissionsArray block:^(BOOL succeeded, NSError * _Nullable error)
         {
             
             if (error)
             {
                 //ERROR HANDLE: User Was Unable to link with facebook please try again or contact austin
                 UIAlertView *alertView = [[UIAlertView alloc] init];
                 alertView.delegate = self;
                 alertView.title = NSLocalizedString(@"Something went wrong",@"Something went wrong");
                 alertView.message = NSLocalizedString(@"Please try again or contact austinbarnard@triptrunkapp.com.",@"Please try again or contact austinbarnard@triptrunkapp.com.");
                 alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                 [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                 [alertView show];
                 
             } else //succesfully connected the parse user to their facebook account
             {
                 //we need to logout the user and log them back in for the fbid in parse to update. Its annoying and we should see if we can fix it.
                 [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error)
                  {
                      if (error)
                      {
                        //ERROR HANDLE: tell the user we linked the acccount succefully but you need to log back in with the login with facebook option for the link to go into effect
                          [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                              UIAlertView *alertView = [[UIAlertView alloc] init];
                              alertView.delegate = self;
                              alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                              alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                              [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                              [alertView show];
                              
                              [self.tabBarController setSelectedIndex:0];
                          }];
                          
                      } else {
                          [self loginWithFacebook];
                      }
                      
                  }];
             }
         }];
    }
}

-(void)loginWithFacebook{
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"email", @"public_profile", @"user_friends"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error)
     {
         
         if (error)
         {
        //ERROR HANDLE: tell the user we linked the acccount but we need them to relogin, then take them to the login screen
             NSString *errorString = [error userInfo][@"error"];
             NSLog(@"%@",errorString);
             
             [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                 UIAlertView *alertView = [[UIAlertView alloc] init];
                 alertView.delegate = self;
                 alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                 alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                 [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                 [alertView show];
                 
                 [self.tabBarController setSelectedIndex:0];
             }];

             
             return;
             
         }
         
         if (!user)
         {
             [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                 UIAlertView *alertView = [[UIAlertView alloc] init];
                 alertView.delegate = self;
                 alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                 alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                 [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                 [alertView show];
                 
                 [self.tabBarController setSelectedIndex:0];
             }];

         } else
         {
             
             if ([user objectForKey:@"fbid"] == nil)
             {
                 FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
                 [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                     if (!error)
                     {
                         // result is a dictionary with the user's Facebook data
                         NSDictionary *userData = (NSDictionary *)result;
                         PFUser *user = [PFUser currentUser];
                         NSString *fbid = [userData objectForKey:@"id"];
                         if (fbid)
                         {
                             [user setObject:fbid forKey:@"fbid"];
                             [user saveInBackground];
                         }
                     } else {
                        //ERROR HANDLE: tell the user we linked the acccount but we need them to relogin, then take them to the login screen
                         
                         [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                             UIAlertView *alertView = [[UIAlertView alloc] init];
                             alertView.delegate = self;
                             alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                             alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                             [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                             [alertView show];
                             
                             [self.tabBarController setSelectedIndex:0];
                         }];

                     }
                 }];
                 
             }
         }
     }];
    
}


@end
