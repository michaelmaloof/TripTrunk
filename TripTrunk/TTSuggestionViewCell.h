//
//  TTSuggestionViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 2/25/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTBaseTableViewCell.h"

@interface TTSuggestionViewCell : TTBaseTableViewCell
@property (strong, nonatomic) IBOutlet TTUserProfileImage *userPhoto;
@property (strong, nonatomic) IBOutlet UILabel *userFullName;
@property (strong, nonatomic) IBOutlet UILabel *username;

@end
