//
//  TTReportBugViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/2/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTReportBugViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *bugTextView;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@end
