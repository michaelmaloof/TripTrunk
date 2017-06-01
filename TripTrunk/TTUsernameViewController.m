//
//  TTUsernameViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTUsernameViewController.h"
#import "TTPasswordViewController.h"
#import "MBProgressHUD.h"

@interface TTUsernameViewController () <UITextFieldDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UIImageView *trunkImage;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *account;
@property (strong, nonatomic) IBOutlet UIImageView *availabilityIcon;
@property (strong, nonatomic) IBOutlet UILabel *availabilityLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *aI;
@property BOOL lookupInterrupted;
@property BOOL lookupFinished;
@end

@implementation TTUsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.usernameTextField.delegate = self;
    self.nextButton.hidden = YES;
    self.aI.hidden = YES;
    [self.aI startAnimating];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.lookupFinished = NO;
    self.availabilityLabel.text = @"";
    self.availabilityIcon.image = nil;
    self.nextButton.hidden = YES;
    int minimumUsernameLength = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MinimumUsernameLength"] intValue];
    if(self.usernameTextField.text.length >= minimumUsernameLength)
        [self performSelector:@selector(checkUsernameAvailability) withObject:nil afterDelay:1.5f];

}

-(void)viewDidAppear:(BOOL)animated{
//    if (![self.username isEqualToString:@""]){
//        self.usernameTextField.text = self.username;
//    }
    [self.usernameTextField becomeFirstResponder];
}

//UIButtons
- (IBAction)backButtonWasTapped:(id)sender {
    [self previousLoginViewController];
}
- (IBAction)nextButtonWasTapped:(id)sender {
    [self submitUsername];
}
- (IBAction)accountWasTapped:(id)sender {
    [self performSegueWithIdentifier:@"login" sender:self];
}

//Keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self submitUsername];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    //username has changed, cancel the selector if called
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkUsernameAvailability) object:nil];
    self.availabilityLabel.text = @"";
    self.aI.hidden = YES;
    self.availabilityIcon.image = nil;
    self.account.hidden = NO;
    self.nextButton.hidden = YES;
    self.lookupInterrupted = YES;
    self.lookupFinished = NO;
    
    int minimumUsernameLength = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MinimumUsernameLength"] intValue];
    NSString *typedText;
    
    if(range.location == textField.text.length)
        typedText = [textField.text stringByAppendingString:string];
    else typedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if(typedText.length > 0 && typedText.length < minimumUsernameLength){
        self.availabilityLabel.text = @"Please select a longer username...";
        self.aI.hidden = YES;
        self.availabilityIcon.image = nil;
    }else if([typedText containsString:@" "]){
        self.availabilityLabel.text = @"Username cannot contain spaces.";
        self.aI.hidden = YES;
        self.availabilityIcon.image = nil;
    }else{
        self.availabilityLabel.text = @"";
        if(typedText.length >= minimumUsernameLength){
            [self performSelector:@selector(checkUsernameAvailability) withObject:nil afterDelay:1.5f];
        }
    }
    
    
    return YES;
}

-(void)checkUsernameAvailability{
    self.availabilityLabel.text = @"Checking username availability...";
    self.aI.hidden = NO;
    self.availabilityIcon.image = nil;
    self.lookupInterrupted = NO;
    
    //Cloud code to check availability
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            self.usernameTextField.text, @"username", nil];
    
    [PFCloud callFunctionInBackground:@"ValidateUsername" withParameters:params
                                block:^(id  _Nullable success, NSError * _Nullable error) {
                                    if (!error)
                                        [self usernameDetermination:YES];
                                    else [self usernameDetermination:NO];
                                    
    }];
}

-(void)usernameDetermination:(BOOL)available{
    
    if(!self.lookupInterrupted){
        if(available){
            self.availabilityLabel.text = @"Username available!";
            self.aI.hidden = YES;
            self.account.hidden = YES;
            self.nextButton.hidden = NO;
            self.availabilityIcon.image = [UIImage imageNamed:@"tt_Green_Check"];
            self.lookupFinished = YES;
        }else{
            self.availabilityLabel.text = @"Sorry, please select a different username.";
            self.aI.hidden = YES;
            self.availabilityIcon.image = [UIImage imageNamed:@"tt_Red_X"];
            self.lookupFinished = NO;
        }
    }
}

-(void)submitUsername{
    if(self.lookupFinished){
        NSString *username =  [self.usernameTextField.text lowercaseString];
        self.username = username;
        [self performSegueWithIdentifier:@"next" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"next"]){
        TTPasswordViewController *vc = segue.destinationViewController;
        NSMutableDictionary *user = [[NSMutableDictionary alloc] init];
        [user setObject:self.username forKey:@"Username"];
        [user setObject:self.isFBUser ? @"1":@"0" forKey:@"Facebook User"];
        
        vc.user = user;
    }
}

//-(void)dealloc{
//    @try{
//        [[NSNotificationCenter defaultCenter] removeObserver:self];
//    }@catch(id anException){
//        //do nothing, obviously it wasn't attached because an exception was thrown
//    }
//}

@end
