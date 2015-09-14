//
//  EditProfileViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/10/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "EditProfileViewController.h"
#import "CitySearchViewController.h"

@interface EditProfileViewController () <CitySearchViewControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *hometownTextField;
@property (strong, nonatomic) IBOutlet UITextView *bioTextView;

@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *currentCity;
@property (weak, nonatomic) IBOutlet UILabel *editBio;

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

    _hometownTextField.delegate = self;
    self.hometownTextField.text = [_user valueForKey:@"hometown"];
    self.bioTextView.text = [_user valueForKey:@"bio"];
    
    // Set Edit button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancelButtonPressed:)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{

//    
//    self.hometownTextField.hidden = YES;
//    self.bioTextView.hidden = YES;
//    self.editBio.hidden = YES;
//    self.currentCity.hidden = YES;
//    self.saveButton.hidden = YES;



}

- (void)viewDidAppear:(BOOL)animated {
    // ADD LAYOUT CONSTRAINT FOR MAKING THE CONTENT VIEW AND SCROLL VIEW THE RIGHT SIZE
    // We put it here because it's causing a crash in viewDidLoad
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1
                                                           constant:0]];
//    
//    self.hometownTextField.hidden =NO;
//    self.bioTextView.hidden = NO;
//    self.saveButton.hidden = NO;
//    self.currentCity.hidden = NO;
//    self.editBio.hidden = NO;
}

- (void)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButtonPressed:(id)sender {
//    [self.saveButton setEnabled:NO];
    
    NSString *hometown = self.hometownTextField.text;
    NSString *bio = self.bioTextView.text;
    
    [_user setValue:hometown forKey:@"hometown"];
    [_user setValue:bio forKey:@"bio"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(shouldSaveUserAndClose:)]) {
        [self.delegate shouldSaveUserAndClose:_user];
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
