//
//  TTTrunkMemberViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 6/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTUserProfileImage.h"

@interface TTTrunkMemberViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet TTUserProfileImage *profilePhoto;



@end
