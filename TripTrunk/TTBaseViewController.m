//
//  TTBaseViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 10/10/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "TTBaseViewController.h"

@interface TTBaseViewController ()

@end

@implementation TTBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//This is to remove the titles under the tab bar icons
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:4] setTitle:@""];
    
    
//This is to remove the word "Back" on the nav bar. We want there just to be an arrow @"<".
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
}

//This is to remove the titles under the tab bar icons
-(void)viewWillAppear:(BOOL)animated{
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:4] setTitle:@""];
}


@end
