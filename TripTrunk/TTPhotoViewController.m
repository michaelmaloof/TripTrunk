//
//  TTPhotoViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 9/21/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTPhotoViewController.h"
#import "TTOnboardingButton.h"

@interface TTPhotoViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *backgroundView;
@property (strong, nonatomic) IBOutlet UIImageView *foregroundView;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *heartButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation TTPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.backgroundView.image = self.photo;
    self.foregroundView.image = self.photo;
    
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 6.0;
    self.scrollView.contentSize = self.foregroundView.frame.size;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.foregroundView;
}

- (IBAction)backActionButton:(id)sender {
    self.backgroundView.hidden = YES; //<---this makes no sense. Why is the background view wider than the entire view itself?
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)heartActionButton:(id)sender {
}
@end
