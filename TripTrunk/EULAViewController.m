//
//  EULAViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 10/6/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "EULAViewController.h"

@interface EULAViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation EULAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *urlString = @"http://www.triptrunkapp.com/user-agreement/";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:urlRequest];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Agree"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(agreeToEULA)];
    [self.navigationController.navigationBar setTintColor:[TTColor tripTrunkBlue]];
    self.title = @"Terms of Service";
    
    
    if (!self.alreadyAccepted) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Terms of Service" message:@"You must accept the TripTrunk End User License Agreement to continue." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)agreeToEULA {
    if (!self.alreadyAccepted) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are You Sure?" message:@"By continuing, you acknowledge that you read and agree to the Terms of Service." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Agree", nil];
        [alert show];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"agreedToEULA"];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"agreedToEULA"];
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }

}



@end
