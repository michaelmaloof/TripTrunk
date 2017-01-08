//
//  TTOnboardingViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTOnboardingViewController.h"

@interface TTOnboardingViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *icon;
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
}

- (IBAction)continueWithoutFacebookWasTapped:(id)sender {
}

@end
