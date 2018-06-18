//
//  TTMainTabBarController.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/2/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTMainTabBarController.h"
#import "TTHomeMapViewController.h"
#import "TTProfileViewController.h"
#import "TTActivityNotificationsViewController.h"
#import "TTOnboardingViewController.h"
#import "TTBaseViewController.h"

@interface TTMainTabBarController ()

@end

@implementation TTMainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initMapAndTrunks];
    [self setupNotificationCenter];
}
    
-(void)setupNotificationCenter{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetMapForLogout)
                                                 name:@"resetMapForLogout"
                                               object:nil];
}

-(void)sendUserToLogin{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    TTOnboardingViewController *loginViewController = (TTOnboardingViewController *)[storyboard instantiateViewControllerWithIdentifier:@"TTOnboardingViewController"];
    [self.tabBarController presentViewController:loginViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)initMapAndTrunks{
    UIStoryboard *homeStoryboard = [UIStoryboard storyboardWithName:@"Home" bundle:nil];
    UIStoryboard *profileStoryboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
    UIStoryboard *activityStoryboard = [UIStoryboard storyboardWithName:@"Search" bundle:nil];
    
    TTHomeMapViewController *tab1 = (TTHomeMapViewController *)[homeStoryboard instantiateViewControllerWithIdentifier:@"TTHomeMapNavController"];
    TTProfileViewController *tab2 = (TTProfileViewController *)[profileStoryboard instantiateViewControllerWithIdentifier:@"TTProfileNavController"];
    TTActivityNotificationsViewController * tab3 = (TTActivityNotificationsViewController *)[activityStoryboard instantiateViewControllerWithIdentifier:@"TTSearchNavController"];
    
    NSArray *tabBarControllers = @[tab1,tab2,tab3];
    
    [self setViewControllers:tabBarControllers animated:NO];
    
    tab1.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Travel Feed", @"Travel Feed") image:[UIImage imageNamed:@"tt_travelfeed_tab"] selectedImage:[UIImage imageNamed:@"tt_travelfeed_tab"]];
    tab2.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"My Journey", @"My Journey") image:[UIImage imageNamed:@"tt_myjourney_tab"] selectedImage:[UIImage imageNamed:@"tt_myjourney_tab"]];
    tab3.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Search", @"Search") image:[UIImage imageNamed:@"tt_search_tab"] selectedImage:[UIImage imageNamed:@"tt_search_tab"]];
    
    self.tabBar.alpha = 0.4;
    self.tabBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    
    [self.view setNeedsLayout];
    [self.view setNeedsDisplay];
}

-(void)resetMapForLogout{
    [[NSNotificationCenter defaultCenter] removeObserver:@"resetMapForLogout"];
    [self setSelectedIndex:0];
    UINavigationController *firstNavController = (UINavigationController *)[self selectedViewController];
    [firstNavController popToRootViewControllerAnimated:YES];
}

@end
