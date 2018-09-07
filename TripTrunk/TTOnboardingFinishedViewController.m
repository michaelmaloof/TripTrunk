//
//  TTOnboardingViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/8/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTOnboardingFinishedViewController.h"

@interface TTOnboardingFinishedViewController ()
@property (weak, nonatomic) IBOutlet UITextView *info;

@end

@implementation TTOnboardingFinishedViewController

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    //FIXME: iPhone4 for iPad hack
    if ([[self deviceName] containsString:@"iPad"]){
        self.info.hidden = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)letsGoWasTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
