//
//  EditProfileViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/10/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "EditProfileViewController.h"
#import "CitySearchViewController.h"

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
                    [[PFUser currentUser] fetchIfNeeded];
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
                    [[PFUser currentUser] fetchIfNeeded];

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

@end
