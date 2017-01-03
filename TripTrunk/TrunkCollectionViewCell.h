//
//  TrunkCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/26/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "Photo.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "TTBaseCollectionViewCell.h"

@interface TrunkCollectionViewCell : TTBaseCollectionViewCell
@property (weak, nonatomic) IBOutlet PFImageView *photo;
@property Photo *tripPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *logo;
@property (strong, nonatomic) IBOutlet UIImageView *videoIcon;

@end
