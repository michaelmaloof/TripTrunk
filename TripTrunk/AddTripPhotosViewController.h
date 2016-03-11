//
//  AddTripPhotosViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/20/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Trip.h"
#import "TTBaseViewController.h"


@interface AddTripPhotosViewController : TTBaseViewController
@property Trip *trip;
@property NSString *tripName;
@property NSString *tripCity;
@property NSString *tripCountry;
@property NSString *tripState;
@property NSString *startDate;
@property NSString *endDate;
@property BOOL isPrivate;
@property (nonatomic)BOOL isTripCreation;
@property (strong, nonatomic) NSArray *trunkMembers;
@end

