//
//  TTHomeMapCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 6/15/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTHomeMapCollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *trunkTitle;
@property (strong, nonatomic) IBOutlet UILabel *trunkDates;
@property (strong, nonatomic) IBOutlet UILabel *trunkLocation;
@property (strong, nonatomic) IBOutlet UILabel *trunkMemberInfo;
@property (strong, nonatomic) IBOutlet UIImageView *spotlightTrunkImage;
@property (strong, nonatomic) IBOutlet UIImageView *secondaryTrunkImage;
@property (strong, nonatomic) IBOutlet UIImageView *tertiaryTrunkImage;
@property (strong, nonatomic) IBOutlet UIImageView *quaternaryTrunkImage;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lowerInfoConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *spotlightImageHeightConstraint;

@end
