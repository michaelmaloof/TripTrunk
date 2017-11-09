//
//  TTPhotoViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 9/21/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTPhotoViewController : UIViewController
@property (strong, nonatomic) UIImage *photo;
@property int index;
@property (strong, nonatomic) NSArray *photos;
@end
