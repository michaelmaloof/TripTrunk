//
//  TTTimeLineCollectionViewCell.h
//  TripTrunk
//
//  Created by Michael Maloof on 2/15/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTTimeLineCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *userprofile;
@property (weak, nonatomic) IBOutlet UIImageView *newsfeedPhoto;
@property (weak, nonatomic) IBOutlet UIButton *username;
@property (weak, nonatomic) IBOutlet UIButton *tripName;
@property (weak, nonatomic) IBOutlet UILabel *timeStamp;
@property (weak, nonatomic) IBOutlet UIButton *location;



@end
