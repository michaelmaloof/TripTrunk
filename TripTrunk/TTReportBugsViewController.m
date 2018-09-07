//
//  TTReportBugsViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 7/27/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTReportBugsViewController.h"
#import "ReportedBug.h"
#import "TTUtility.h"
#import "TTOnboardingButton.h"

@interface TTReportBugsViewController ()
@property (weak, nonatomic) IBOutlet UITextView *bugTextView;
@property (weak,nonatomic) NSString *email;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bugReportHeightConstraint;
@end

@implementation TTReportBugsViewController

#pragma mark - iPad Hack
-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    //FIXME: iPhone4 for iPad hack
    if ([[self deviceName] containsString:@"iPad"]){
        self.bugReportHeightConstraint.constant = 150;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.tabBar.hidden = YES;
    PFUser *user = [PFUser currentUser];
    self.email = user[@"email"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)submitWasTapped:(TTOnboardingButton*)sender {
    
    if ([self.bugTextView.text isEqualToString:@""]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Tell Us The Bug You Found",@"Please Tell Us The Bug You Found")
                                                        message:NSLocalizedString(@"We need a description of the bug and the steps you did in the app to find it.",@"We need a description of the bug and the steps you did in the app to find it.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        
    } else {
        [self reportBug];
    }
    
}

-(void)textFieldDidChange :(UITextField *)theTextField{
    if ([theTextField.text length] > 1){
        
        NSString *code = [theTextField.text substringFromIndex: [theTextField.text length] - 2];
        if ([code isEqualToString:@" "]){
            [theTextField setKeyboardType:UIKeyboardTypeDefault];
        }
    }
}

-(void)reportBug{
    ReportedBug *bug = [[ReportedBug alloc]init];
    bug.email = self.email;
    bug.bug = self.bugTextView.text;
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    bug.version = [NSString stringWithFormat:@"Version: %@ (%@)", appVersionString, appBuildString];
    bug.user = [PFUser currentUser];
    bug.isKnownAbout = NO;
    bug.isFixed = NO;
    
    [bug saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error){
            [ParseErrorHandlingController handleError:error];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"An Error Occured, Please Try Again.",@"An Error Occured, Please Try Again.")
                                                            message:NSLocalizedString(@"",@"")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                                  otherButtonTitles:nil, nil];
            [alert show];
            
        } else {
            [[TTUtility sharedInstance] internetConnectionFound];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Your Bug Has Been Sent",@"our Bug Has Been Sent")
                                                            message:NSLocalizedString(@"We will fix this as soon as possible. If you think this is a serious issue and would like to contact us directly, please email our CEO at austinbarnard@triptrunkapp.com",@"We will fix this as soon as possible. If you think this is a serious issue and would like to contact us directly, please email our CEO at austinbarnard@triptrunkapp.com")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                                  otherButtonTitles:nil, nil];
            alert.tag = 5;
            [alert show];
        }
    }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 5){
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)textViewDidChange:(UITextView *)textView{
    if ([textView.text length] > 1){
        
        NSString *code = [textView.text substringFromIndex: [textView.text length] - 2];
        if ([code isEqualToString:@" "]){
            [textView setKeyboardType:UIKeyboardTypeDefault];
        }
    }
}

- (IBAction)backButtonAction:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)tapGestureAction:(UITapGestureRecognizer *)sender {
    [self.bugTextView resignFirstResponder];
}

@end
