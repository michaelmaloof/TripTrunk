//
//  ActivityTableViewCell.h
//  TripTrunk
//
//  Created by Matt Schoch on 9/2/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "Photo.h"
#import "TTTAttributedLabel.h"
#import "Trip.h"

@protocol ActivityTableViewCellDelegate;

@interface ActivityTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profilePicImageView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (nonatomic, strong, readonly) PFUser *user;
@property (nonatomic, strong, readonly) NSDictionary *activity;
@property (nonatomic, strong) id<ActivityTableViewCellDelegate> delegate;

- (void)setActivity:(NSDictionary *)activity;

@end

@protocol ActivityTableViewCellDelegate <NSObject>

- (void)activityCell:(ActivityTableViewCell *)cellView didPressPhoto:(Photo *)photo;
- (void)activityCell:(ActivityTableViewCell *)cellView didPressUsernameForUser:(PFUser *)user;
- (void)activityCell:(ActivityTableViewCell *)cellView didPressTrip:(Trip *)trip;
- (void)activityCell:(ActivityTableViewCell *)cellView didAcceptFollowRequest:(BOOL)didAccept fromUser:(PFUser *)user;


@end
