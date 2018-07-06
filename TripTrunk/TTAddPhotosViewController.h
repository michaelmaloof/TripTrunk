//
//  TTAddPhotosViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 11/27/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTBaseViewController.h"
#import "Trip.h"

@protocol AddPhotosDelegate
-(void)photoUploadCompleted:(NSArray*)photos;
@end

@interface TTAddPhotosViewController : TTBaseViewController
@property (strong,nonatomic) Trip *trip;
@property (strong,nonatomic) NSArray *trunkMembers;
@property id<AddPhotosDelegate> delegate;
@property id adelegate;
@property BOOL newTrip;
@end
