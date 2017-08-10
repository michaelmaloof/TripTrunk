//
//  TTTimelinePhotoCellCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 7/28/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTRoundedView.h"

@interface TTTimelinePhotoCellCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *month;
@property (strong, nonatomic) IBOutlet TTRoundedView *dateView;

@end
