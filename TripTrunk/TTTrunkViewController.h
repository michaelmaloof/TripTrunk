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

@interface TTTrunkViewController : TTBaseViewController
@property(strong, nonatomic) Excursion *excursion;
@property(strong, nonatomic) Trip *trip;
@end
