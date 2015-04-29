//
//  TrunkCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/26/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface TrunkCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet PFImageView *photo;
@property Photo *tripPhoto;

@end
