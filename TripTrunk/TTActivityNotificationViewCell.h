//
//  TTActivityNotificationViewCell.h
//  TripTrunk
//
//  Created by Michael Cannell on 1/29/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "Trip.h"
#import "Photo.h"
#import "TTTAttributedLabel.h"

@protocol ActivityTableViewCellDelegate;

@interface TTActivityNotificationViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *profilePic;
@property (strong, nonatomic) IBOutlet UILabel *firstLastName;
@property (strong, nonatomic) IBOutlet TTTAttributedLabel *activityStatus;
@property (nonatomic, strong) PFUser *user;
@property (nonatomic, strong, readonly) NSDictionary *activity;
@property (nonatomic, strong) id<ActivityTableViewCellDelegate> delegate;

- (void)setActivity:(NSDictionary *)activity;

@end

@protocol ActivityTableViewCellDelegate <NSObject>

//- (void)activityCell:(TTActivityNotificationViewCell *)cellView didPressPhoto:(Photo *)photo;
- (void)activityCell:(TTActivityNotificationViewCell *)cellView didPressUsernameForUser:(PFUser *)user;
- (void)activityCell:(TTActivityNotificationViewCell *)cellView didPressTrip:(Trip *)trip;
- (void)activityCell:(TTActivityNotificationViewCell *)cellView didAcceptFollowRequest:(BOOL)didAccept fromUser:(PFUser *)user;


@end
