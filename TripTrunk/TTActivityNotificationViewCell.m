//
//  TTActivityNotificationViewCell.m
//  TripTrunk
//
//  Created by Michael Cannell on 1/29/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTActivityNotificationViewCell.h"
#import "TTUtility.h"
#import "TTFont.h"
#import "TTHashtagMentionColorization.h"
#import "SocialUtility.h"

#define USER_ACTIVITY_URL @"activity://user"
#define TOUSER_ACTIVITY_URL @"activity://toUser"
#define TRIP_ACTIVITY_URL @"activity://trip"
#define kPENDING_FOLLOW_ACCEPT_URL @"activity://pendingFollow_accept"
#define kPENDING_FOLLOW_REJECT_URL @"activity://pendingFollow_reject"

@interface TTActivityNotificationViewCell () <TTTAttributedLabelDelegate>
@property (nonatomic, strong, readwrite) PFUser *toUser;
@end


@implementation TTActivityNotificationViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setActivity:(NSDictionary *)activity {
    self.activity = activity;
    self.user = activity[@"fromUser"];
    self.toUser = activity[@"toUser"];
//
//    if (!activity[@"photo"]) {
//        [self.photoImageView setHidden:YES];
//    }
//    else {
//        [self.photoImageView setHidden:NO];
//    }
    [self updateContentLabel];
}

- (void)updateContentLabel {
    NSAttributedString *attString = [[TTUtility sharedInstance] attributedStringForActivity:_activity];
    
    NSMutableAttributedString *mut = [[NSMutableAttributedString alloc] initWithAttributedString:attString];
    
    if ([_activity[@"type"] isEqualToString:@"pending_follow"]) {
        NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
        NSAttributedString *approval = [[NSMutableAttributedString alloc] initWithString:@"\nApprove | Reject"
                                        
                                                                              attributes:@{NSFontAttributeName : [TTFont tripTrunkFont14],
                                                                                           NSParagraphStyleAttributeName: paraStyle,
                                                                                           NSKernAttributeName : [NSNull null]
                                                                                           }];
        [mut appendAttributedString:approval];
    }
    [self.activityStatus setAttributedText:mut];
    // Set up a link for the usernames
    NSRange range = [self.activityStatus.text rangeOfString:_user.username];
    [self.activityStatus addLinkToURL:[NSURL URLWithString:USER_ACTIVITY_URL] withRange:range]; // Embedding a custom link in a substring
    if (self.toUser){
        NSRange toRange = [self.activityStatus.text rangeOfString:self.toUser.username];
        [self.activityStatus addLinkToURL:[NSURL URLWithString:TOUSER_ACTIVITY_URL] withRange:toRange]; // Embedding a custom link in a substring
    }
    if([self.activityStatus.text containsString:@"@"]){
        NSArray *usernamesArray = [TTHashtagMentionColorization extractUsernamesFromComment:self.activityStatus.text];
        for(NSString *name in usernamesArray){
            NSRange userRange = [self.activityStatus.text rangeOfString:name];
            NSString *link = [NSString stringWithFormat:@"activity://%@",name];
            [self.activityStatus addLinkToURL:[NSURL URLWithString:link] withRange:userRange];
        }
    }
    // If it'as an addToTrip or addedPhoto activity, set the Trip Name as a URL
    if ( ( [_activity[@"type"] isEqualToString:@"addToTrip"] || [_activity[@"type"] isEqualToString:@"addedPhoto"])
        && _activity[@"trip"] && [_activity[@"trip"] valueForKey:@"name"])
    {
        // Set up a link for the trip name
        NSRange tripRange = [self.activityStatus.text rangeOfString:[_activity[@"trip"] valueForKey:@"name"]];
        [self.activityStatus addLinkToURL:[NSURL URLWithString:TRIP_ACTIVITY_URL] withRange:tripRange]; // Embedding a custom link in a substring
    }
    else if ([_activity[@"type"] isEqualToString:@"pending_follow"]) {
        // Set up a link for the Approve and Reject actions
        NSRange approveRange = [self.activityStatus.text rangeOfString:@"Approve"];
        [self.activityStatus addLinkToURL:[NSURL URLWithString:kPENDING_FOLLOW_ACCEPT_URL] withRange:approveRange];
        
        NSRange rejectRange = [self.activityStatus.text rangeOfString:@"Reject"];
        [self.activityStatus addLinkToURL:[NSURL URLWithString:kPENDING_FOLLOW_REJECT_URL] withRange:rejectRange];
    }
}

//- (void)photoImageViewTapped:(UIGestureRecognizer *)gestureRecognizer {
//    // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
//    if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressPhoto:)]) {
//        [self.delegate activityCell:self didPressPhoto:[_activity valueForKey:@"photo"]];
//    }
//}

//-(void)roundProfileImageView{
//    [self.profilePicImageView setClipsToBounds:YES];
//    [self.profilePicImageView.layer setCornerRadius:20.0f];
//    [self.profilePicImageView.layer setMasksToBounds:YES];
//    [self.profilePicImageView.layer setBorderWidth:2.0f];
//    self.profilePicImageView.backgroundColor = [TTColor tripTrunkBlue];
//    self.profilePicImageView.layer.borderColor = (__bridge CGColorRef _Nullable)([TTColor tripTrunkWhite]);
//    UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageViewTapped:)];
//    profileTap.numberOfTapsRequired = 1;
//    self.profilePicImageView.userInteractionEnabled = YES;
//    [self.profilePicImageView addGestureRecognizer:profileTap];
//}

- (void)profileImageViewTapped:(UIGestureRecognizer *)gestureRecognizer {
    //We use the same delegate method here as for pressing the username, since both go to the same place.
    // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
    if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressUsernameForUser:)]) {
        [self.delegate activityCell:self didPressUsernameForUser:_user];
    }
}

#pragma mark - TTTAttributedLabelDelegate methods
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[url scheme] hasPrefix:@"activity"]) {
        if ([[url host] hasPrefix:@"user"]) {
            /* load user profile screen */
            // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
            if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressUsernameForUser:)]) {
                [self.delegate activityCell:self didPressUsernameForUser:_user];
            } else if ([[url host] hasPrefix:@"toUser"]) {
                /* load user profile screen */
                
                // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
                if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressUsernameForUser:)]) {
                    [self.delegate activityCell:self didPressUsernameForUser:self.toUser];
                }
            }
        }else if ([[url host] hasPrefix:@"toUser"]) {
            /* load user profile screen */
            
            // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
            if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressUsernameForUser:)]) {
                [self.delegate activityCell:self didPressUsernameForUser:self.toUser];
            }
        }
        else if([[url host] hasPrefix:@"trip"]) {
            /* load user profile screen */
            Trip *trip = (Trip *)_activity[@"trip"];
            // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
            if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressTrip:)]) {
                [self.delegate activityCell:self didPressTrip:trip];
            }
        }
        else if([[url host] hasPrefix:@"pendingFollow_accept"]) {
            /* Approve a Follow Request */
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didAcceptFollowRequest:fromUser:)]) {
                [self.delegate activityCell:self didAcceptFollowRequest:YES fromUser:_user];
            }
        }
        else if([[url host] hasPrefix:@"pendingFollow_reject"]) {
            /* Approve a Follow Request */
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didAcceptFollowRequest:fromUser:)]) {
                [self.delegate activityCell:self didAcceptFollowRequest:NO fromUser:_user];
            }
        }else{
            NSString *urlString = [NSString stringWithFormat:@"%@",url];
            if([urlString containsString:@"@"]){
                /* load user profile screen */
                
                // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
                if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressUsernameForUser:)]) {
                    NSString *username = [NSString stringWithFormat:@"%@",[url host]];
                    [SocialUtility loadUserFromUsername:username block:^(PFUser *user, NSError *error) {
                        [self.delegate activityCell:self didPressUsernameForUser:user];
                    }];
                }
            }
        }
    } else {
        /* deal with http links here */
    }
}

@end
