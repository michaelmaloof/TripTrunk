//
//  TrunkTableViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/26/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Trip.h"

@interface TrunkTableViewCell : UITableViewCell
@property Trip *trip;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *lockImage;
@property (weak, nonatomic) IBOutlet UIImageView *seenLogo;
@property (weak, nonatomic) IBOutlet UILabel *emoji;

@end
