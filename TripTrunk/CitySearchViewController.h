//
//  CitySearchViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 9/8/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTBaseTableViewController.h"


@protocol CitySearchViewControllerDelegate;

@interface CitySearchViewController : TTBaseTableViewController

@property (nonatomic, strong) id<CitySearchViewControllerDelegate> delegate;


@end

@protocol CitySearchViewControllerDelegate <NSObject>

- (void)citySearchDidSelectLocation:(NSString *)location;

@end