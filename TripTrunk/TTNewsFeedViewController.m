//
//  TTNewsFeedViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 2/12/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTNewsFeedViewController.h"

@interface TTNewsFeedViewController ()

@end

@implementation TTNewsFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitleImage];
    [self createLeftButtons];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTitleImage {
    UIImage *logo = [UIImage imageNamed:@"tripTrunkTitle"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
    logoView.frame = CGRectMake(logoView.frame.origin.x, logoView.frame.origin.y,logoView.frame.size.width,self.navigationController.navigationBar.frame.size.height*.6);
    [logoView setContentMode:UIViewContentModeScaleAspectFit];
    self.navigationItem.titleView = logoView;
    [self.navigationItem.titleView setContentMode:UIViewContentModeScaleAspectFit];
}

-(void)createLeftButtons{
    
    self.navigationItem.leftBarButtonItem = nil;
    UIImage *image = [UIImage imageNamed:@"moree"];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width/1.8, image.size.height/1.8);
    
    UIButton *bttn = [[UIButton alloc] initWithFrame:buttonFrame];
    [bttn addTarget:self action:@selector(switchToMap) forControlEvents:UIControlEventTouchUpInside];
    [bttn setImage:image forState:UIControlStateNormal];
    
    UIBarButtonItem *buttonOne= [[UIBarButtonItem alloc] initWithCustomView:bttn];
    
    self.navigationItem.leftBarButtonItem = buttonOne;
}

-(void)switchToMap{
    [self.navigationController popToRootViewControllerAnimated:NO];
}


@end
