//
//  PhotoCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/20/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TripImageView.h"

@interface PhotoCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet TripImageView *tripImage;
@property (weak, nonatomic) IBOutlet UIImageView *captionImage;

@end
