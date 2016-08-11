//
//  TrunkTableViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/26/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "Trip.h"
#import "TTBaseTableViewCell.h"


@interface TrunkTableViewCell : TTBaseTableViewCell
@property Trip *trip;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *seenLogo;

@end
