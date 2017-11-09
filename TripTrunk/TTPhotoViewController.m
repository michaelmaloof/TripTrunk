//
//  TTPhotoViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 9/21/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTPhotoViewController.h"
#import "TTOnboardingButton.h"
#import "UIImageView+AFNetworking.h"

@interface TTPhotoViewController () <UIGestureRecognizerDelegate>
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
    
    [self preloadPreviousImage];
    [self preloadNextImage];
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

    if((int)self.index == 0)
        self.index = (int)self.photos.count-1;
    else self.index--;
    
    UIImageView *bI = (UIImageView *)[self.view viewWithTag:1000];
    UIImageView *fI = (UIImageView *)[self.view viewWithTag:1001];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    UIImageView *newImageForeground = [[UIImageView alloc] initWithFrame:CGRectMake(0-width,0,width,height)];
    [newImageForeground setImageWithURL:[NSURL URLWithString:self.photos[self.index]]];
    newImageForeground.contentMode = UIViewContentModeScaleAspectFit;
    
    UISwipeGestureRecognizer *swipeleft=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [newImageForeground addGestureRecognizer:swipeleft];
    UISwipeGestureRecognizer *swiperight=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [newImageForeground addGestureRecognizer:swiperight];
    
    newImageForeground.userInteractionEnabled = YES;
    
    UIImageView *newImageBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0-width,0,width,height)];
    [newImageBackground setImageWithURL:[NSURL URLWithString:self.photos[self.index]]];
    newImageBackground.contentMode = UIViewContentModeScaleAspectFill;
    newImageBackground.alpha = 0.45;
    newImageBackground.tag = 1000;
    newImageForeground.tag = 1001;
    [self.view insertSubview:newImageForeground atIndex:2];
    [self.view insertSubview:newImageBackground atIndex:0];
    
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        fI.frame = CGRectMake(width,0,width,height);
        bI.frame = CGRectMake(width,0,width,height);
        newImageForeground.frame = CGRectMake(0,0,width,height);
        newImageBackground.frame = CGRectMake(0,0,width,height);
    } completion:^(BOOL finished) {
        [fI removeFromSuperview];
        [bI removeFromSuperview];
    }];
    
    [self preloadPreviousImage];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    
    if((int)self.index == (int)self.photos.count-1)
        self.index = 0;
    else self.index++;
    
    UIImageView *bI = (UIImageView *)[self.view viewWithTag:1000];
    UIImageView *fI = (UIImageView *)[self.view viewWithTag:1001];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    UIImageView *newImageForeground = [[UIImageView alloc] initWithFrame:CGRectMake(width,0,width,height)];
    [newImageForeground setImageWithURL:[NSURL URLWithString:self.photos[self.index]]];
    newImageForeground.contentMode = UIViewContentModeScaleAspectFit;
    
    UISwipeGestureRecognizer *swipeleft=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    swipeleft.direction=UISwipeGestureRecognizerDirectionLeft;
    [newImageForeground addGestureRecognizer:swipeleft];
    UISwipeGestureRecognizer *swiperight=[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    swiperight.direction=UISwipeGestureRecognizerDirectionRight;
    [newImageForeground addGestureRecognizer:swiperight];
    
    newImageForeground.userInteractionEnabled = YES;
    
    UIImageView *newImageBackground = [[UIImageView alloc] initWithFrame:CGRectMake(width,0,width,height)];
    [newImageBackground setImageWithURL:[NSURL URLWithString:self.photos[self.index]]];
    newImageBackground.contentMode = UIViewContentModeScaleAspectFill;
    newImageBackground.alpha = 0.45;
    newImageBackground.tag = 1000;
    newImageForeground.tag = 1001;
    [self.view insertSubview:newImageForeground atIndex:2];
    [self.view insertSubview:newImageBackground atIndex:0];

    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        fI.frame = CGRectMake(0-width,0,width,height);
        bI.frame = CGRectMake(0-width,0,width,height);
        newImageForeground.frame = CGRectMake(0,0,width,height);
        newImageBackground.frame = CGRectMake(0,0,width,height);
    } completion:^(BOOL finished) {
        [fI removeFromSuperview];
        [bI removeFromSuperview];
    }];
    
    [self preloadNextImage];
}

-(void)preloadPreviousImage{
    int nextIndex;
    if((int)self.index == 0)
        nextIndex = (int)self.photos.count-1;
    else nextIndex = self.index-1;
    
    UIImageView *preloadImage = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    [preloadImage setImageWithURL:[NSURL URLWithString:self.photos[nextIndex]]];
}

-(void)preloadNextImage{
    int nextIndex;
    if((int)self.index == (int)self.photos.count-1)
        nextIndex = 0;
    else nextIndex = self.index+1;
    
    UIImageView *preloadImage = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    [preloadImage setImageWithURL:[NSURL URLWithString:self.photos[nextIndex]]];
}

-(void)handleSwipeLeftOnImage:(UIGestureRecognizer*)recognizer {
    NSLog(@"test");
}
@end
