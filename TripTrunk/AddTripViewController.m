//
//  AddTripViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddTripViewController.h"
#import "AddTripPhotosViewController.h"


@interface AddTripViewController ()
@property (weak, nonatomic) IBOutlet UITextField *tripNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *cityNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *startTripTextField;
@property (weak, nonatomic) IBOutlet UITextField *endTripTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *tripDatePicker;

@end

@implementation AddTripViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)onCancelTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *tripName = self.tripNameTextField.text;
    NSString *tripCity = self.cityNameTextField.text;
    NSString *start = self.startTripTextField.text;
    NSString *end = self.endTripTextField.text;
    
    AddTripPhotosViewController *addTripPhotosViewController= segue.destinationViewController;
    addTripPhotosViewController.tripName = tripName;
    addTripPhotosViewController.tripCity = tripCity;
    addTripPhotosViewController.startDate = start;
    addTripPhotosViewController.endDate = end;
    
}
@end
