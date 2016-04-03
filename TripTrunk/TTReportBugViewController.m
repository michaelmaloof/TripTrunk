//
//  TTReportBugViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/2/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTReportBugViewController.h"
#import "ReportedBug.h"
#import "ParseErrorHandlingController.h"
#import "TTUtility.h"

@interface TTReportBugViewController () <UIAlertViewDelegate>

@end

@implementation TTReportBugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitWasTapped:(id)sender {
    
    if ([self.bugTextView.text isEqualToString:@""]){
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Tell Us The Bug You Found",@"Please Tell Us The Bug You Found")
                                                        message:NSLocalizedString(@"We need a description of the bug and the steps you did in the app to find it.",@"We need a description of the bug and the steps you did in the app to find it.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
        
    } else if ([self.emailTextField.text isEqualToString:@""]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Provide an Email",@"Please Provide an Email")
                                                        message:NSLocalizedString(@"We will need to contact you with questions on the bug",@"We will need to contact you with questions on the bug")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];

    } else {
        [self reportBug];
    }
    
}

-(void)reportBug{
    ReportedBug *bug = [[ReportedBug alloc]init];
    bug.email = self.emailTextField.text;
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
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


@end
