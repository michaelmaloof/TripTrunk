//
//  TTTrunkNameViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/16/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTTrunkNameViewController.h"
#import "TTOnboardingButton.h"
#import "TTTrunkDatesViewController.h"

@interface TTTrunkNameViewController () <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UITextField *trunkName;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *nextButton;

@end

@implementation TTTrunkNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *typedText;
    
    if(range.location == textField.text.length)
        typedText = [textField.text stringByAppendingString:string];
    else typedText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if([typedText isEqualToString:@""])
        self.nextButton.hidden = YES;
    else self.nextButton.hidden = NO;
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField.text isEqualToString:@""]){
        return NO;
    }else{
        [self performSegueWithIdentifier:@"pushToTrunkDates" sender:self];
        return YES;
    }
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    TTTrunkDatesViewController *trunkDatesViewController = segue.destinationViewController;
    Trip *trip = [[Trip alloc] init];
    trip.name = self.trunkName.text;
    trunkDatesViewController.trip = trip;
}
 
- (IBAction)backButtonWasTapped:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonWasTapped:(TTOnboardingButton *)sender {
    if(![self.trunkName.text isEqualToString:@""])
        [self performSegueWithIdentifier:@"pushToTrunkDates" sender:self];
}




@end
