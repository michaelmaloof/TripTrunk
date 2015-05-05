//
//  ProfileViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/5/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "ProfileViewController.h"

@interface ProfileViewController ()

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)followersButtonPressed:(id)sender {
    NSLog(@"Followers Button Pressed");
}
- (IBAction)findFriendsButtonPressed:(id)sender {
    NSLog(@"Find Friends Button Pressed");

}
- (IBAction)followingButtonPressed:(id)sender {
    NSLog(@"Following Button Pressed");

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
