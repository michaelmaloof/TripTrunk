//
//  TTNewsFeedViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 2/12/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTBaseViewController.h"

@protocol NewsDelegate
-(void)backWasTapped:(id)sender;



@end

@interface TTNewsFeedViewController : TTBaseViewController
@property id<NewsDelegate> delegate;


@end
