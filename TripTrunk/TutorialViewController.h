//
//  TutorialViewController.h
//  TripTrunk
//
//  Created by Bradley Walker on 10/23/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import <Parse/Parse.h>
#import "TTBaseViewController.h"

@protocol TutorialViewDelegate

- (void)userCompletedTutorial;

@end

@interface TutorialViewController : TTBaseViewController

@property id <TutorialViewDelegate> delegate;

@end
