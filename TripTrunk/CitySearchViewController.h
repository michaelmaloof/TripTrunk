//
//  CitySearchViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 9/8/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTBaseTableViewController.h"
#import "TTPlace.h"


@protocol CitySearchViewControllerDelegate;

@interface CitySearchViewController : TTBaseTableViewController

@property (nonatomic, strong) id<CitySearchViewControllerDelegate> delegate;


@end

@protocol CitySearchViewControllerDelegate <NSObject>

/**
 * returns an TTPlace with 2 keys:
 * name - NSString for the city, state, country of the location
 * placeId - NSString of the Google PlaceID for this location, used to get the Lat/Long, etc.
 */
- (void)citySearchDidSelectLocation:(TTPlace *)location;

@end
