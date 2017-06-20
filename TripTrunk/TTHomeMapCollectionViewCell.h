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
@property (strong, nonatomic) IBOutlet UIButton *spotlightTrunkImage;
@property (strong, nonatomic) IBOutlet UIButton *secondaryTrunkImage;
@property (strong, nonatomic) IBOutlet UIButton *tertiaryTrunkImage;
@property (strong, nonatomic) IBOutlet UIButton *quaternaryTrunkImage;

@end
