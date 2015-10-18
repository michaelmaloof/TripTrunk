//
//  ImagePickerCellCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 10/17/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImagePickerCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ImageView;
@property BOOL isSelected;

@end
