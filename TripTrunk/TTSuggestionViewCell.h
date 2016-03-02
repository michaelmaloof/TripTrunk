//
//  TTSuggestionViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 2/25/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TTSuggestionViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *userPhoto;
@property (strong, nonatomic) IBOutlet UILabel *userFullName;
@property (strong, nonatomic) IBOutlet UILabel *username;

@end
