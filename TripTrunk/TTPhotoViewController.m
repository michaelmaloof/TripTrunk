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
    self.backgroundView.tag = 1000;
    self.foregroundView.tag = 1001;
    
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

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender {
}


//MONDAY!!!! FINISH SWIPING THROUGH IMAGES!! <------------------------------------------------------------------------
- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    UIImageView *bI = (UIImageView *)[self.view viewWithTag:1000];
    UIImageView *fI = (UIImageView *)[self.view viewWithTag:1001];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    
    UIImageView *newImageForeground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tt_square_placeholder"]];
    newImageForeground.frame = CGRectMake(width,0,width,height);
    UISwipeGestureRecognizer * swipeleft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeLeftOnImage)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [newImageForeground addGestureRecognizer:swipeleft];
    newImageForeground.userInteractionEnabled = YES;
    
    UIImageView *newImageBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tt_square_placeholder"]];
    newImageBackground.frame = CGRectMake(width,0,width,height);
    newImageBackground.tag = 1000;
    newImageForeground.tag = 1001;
    [self.view insertSubview:newImageForeground atIndex:0];
//    [self.view insertSubview:newImageBackground atIndex:0];

    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        fI.frame = CGRectMake(0-width,0,width,height);
        bI.frame = CGRectMake(0-width,0,width,height);
        newImageForeground.frame = CGRectMake(0,0,width,height);
//        newImageBackground.frame = CGRectMake(0,0,width,height);
    } completion:^(BOOL finished) {
        NSLog(@"DONE");
        [self.foregroundView removeFromSuperview];
        [self.backgroundView removeFromSuperview];
    }];
}

-(void)handleSwipeLeftOnImage{
    NSLog(@"test");
}

@end
