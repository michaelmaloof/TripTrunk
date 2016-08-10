//
//  TTTrunkMemberViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 6/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTBaseCollectionViewCell.h"

@interface TTTrunkMemberViewCell : TTBaseCollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet TTUserProfileImage *profilePhoto;



@end
