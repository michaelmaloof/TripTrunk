//
//  TTUserProfileViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 4/26/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTBaseCollectionViewCell.h"

@interface TTUserProfileViewCell : TTBaseCollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UIImageView *logo;
@property (strong, nonatomic) IBOutlet UIImageView *videoIcon;

@end
