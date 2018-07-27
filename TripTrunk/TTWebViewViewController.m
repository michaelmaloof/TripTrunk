//
//  TTWebViewViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 7/26/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTWebViewViewController.h"
#import <WebKit/WebKit.h>
#import "TTOnboardingButton.h"

@interface TTWebViewViewController () <WKNavigationDelegate>
@property (strong, nonatomic) WKWebView *webView;
@end

@implementation TTWebViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tabBarController.tabBar setHidden:YES];
    NSURL *url = [NSURL URLWithString:self.url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame];
    [self.webView loadRequest:request];
//    [self.view addSubview:self.webView];
    [self.view insertSubview:self.webView atIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (IBAction)backButtonAction:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
