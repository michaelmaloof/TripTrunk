//
//  TrunkViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/26/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Trip.h"
#import "TTBaseViewController.h"

@protocol MemberCountDelegate
@optional;
-(void)memberCountUpdated:(int)count forTrip:(Trip*)trip;
@end

@interface TrunkViewController : TTBaseViewController
@property Trip *trip;
@property NSObject<MemberCountDelegate>* delegate;
@end
