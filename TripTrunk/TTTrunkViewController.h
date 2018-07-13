//
//  TTTrunkViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 9/5/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTBaseViewController.h"
#import "Excursion.h"
#import "Trip.h"
#import "Photo.h"

@protocol TrunkDelegate;

@interface TTTrunkViewController : TTBaseViewController
@property(strong, nonatomic) Excursion *excursion;
@property(strong, nonatomic) Trip *trip;
@property (strong,nonatomic) id<TrunkDelegate>delegate;
@end

@protocol TrunkDelegate <NSObject>
- (void)trunkDetailsEdited:(Trip *)trip;
@end
