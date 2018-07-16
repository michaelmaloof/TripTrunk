//
//  TTAddMembersViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 12/27/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Trip.h"
#import "TTBaseViewController.h"

@interface TTAddMembersViewController : TTBaseViewController
@property (strong,nonatomic) Trip *trip;
@property (strong,nonatomic) id delegate;
@property (strong, nonatomic) NSArray *existingMembersOfTrunk;
@end
