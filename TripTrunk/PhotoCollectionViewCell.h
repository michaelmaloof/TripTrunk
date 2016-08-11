//
//  PhotoCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/20/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TTBaseCollectionViewCell.h"

@interface PhotoCollectionViewCell : TTBaseCollectionViewCell
@property (weak, nonatomic) IBOutlet TripImageView *tripImageView;
@property (weak, nonatomic) IBOutlet UIImageView *captionImageView;

@end
