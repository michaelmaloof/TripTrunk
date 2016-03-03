//
//  EditCaptionViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 10/29/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "EditCaptionViewController.h"

@interface EditCaptionViewController ()
@property (weak, nonatomic) IBOutlet UILabel *hideLabel;

@end

@implementation EditCaptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hideLabel.hidden = YES;
    self.imageView.image = self.image;
    self.captionBox.text = self.caption;
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
- (IBAction)backButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButtonTapped:(id)sender {
    [self.delegate captionButtonTapped:0 caption:self.captionBox.text];
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)removeButtonTapped:(id)sender {
    self.captionBox.text = @"";

}

- (IBAction)deleteButtonTapped:(id)sender {
    [self.delegate captionButtonTapped:1 caption:self.captionBox.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//[(AppDelegate *)[[UIApplication sharedApplication] delegate] logout];

@end
