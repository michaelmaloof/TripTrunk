//
//  AddTripPhotosViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/20/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddTripPhotosViewController.h"
#import <Parse/Parse.h>
#import "Trip.h"

@interface AddTripPhotosViewController ()

@end

@implementation AddTripPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (IBAction)onDoneTapped:(id)sender {
    Trip *trip = [[Trip alloc]init];
    trip.name = self.tripName;
    trip.city = self.tripCity;
    trip.user = [PFUser currentUser].username;
    trip.startDate = self.startDate;
    trip.endDate = self.endDate;
    
    [trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         [self dismissViewControllerAnimated:YES completion:^{
             
         }];
     }];
}



#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}

@end
