//
//  TTEditTrunkViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 7/11/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTBaseViewController.h"
#import "Trip.h"

@protocol EditTrunkDelegate;

@interface TTEditTrunkViewController : TTBaseViewController
@property (nonatomic, strong) Trip* trip;
@property (strong,nonatomic) id<EditTrunkDelegate>delegate;
@end

@protocol EditTrunkDelegate <NSObject>
-(void)trunkDetailsEdited:(Trip*)trip;
@end
