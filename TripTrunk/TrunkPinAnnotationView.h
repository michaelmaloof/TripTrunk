//
//  TrunkPointAnnotationView.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/25/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface TrunkPinAnnotationView : MKPinAnnotationView
@property NSString *tripName;
@property NSString *user;


@end
