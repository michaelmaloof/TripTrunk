//
//  LocationViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTLocationViewController.h"

@interface TTLocationViewController ()
@property (weak, nonatomic) IBOutlet UILabel *pageTitle;
@property (weak, nonatomic) IBOutlet UITextView *info;
@property (weak, nonatomic) IBOutlet UILabel *allowLabel;
@property (weak, nonatomic) IBOutlet UIButton *noThanks;
@property (weak, nonatomic) IBOutlet UIButton *turnOn;

@end

@implementation TTLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

//UIButtons

- (IBAction)noThanksWasTapped:(id)sender {
}

- (IBAction)turnOnWasTapped:(id)sender {
}

@end
