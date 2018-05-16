//
//  TTHomeMapViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 6/14/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTBaseViewController.h"


@interface TTHomeMapViewController : TTBaseViewController<UICollectionViewDelegate>

/**
 Trips the user has seen during this session of the app
 */
@property NSMutableArray *viewedTrips;//FIXME SHOULD BE IN A UTILITY CLASS

/**
 photos the user has seen during this session of the app
 */
@property NSMutableArray *viewedPhotos; //FIXME SHOULD BE IN A UTILITY CLASS

@end
