//
//  ActivityTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/2/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "ActivityTableViewCell.h"
#import "UIColor+HexColors.h"
#import "TTUtility.h"

#define USER_ACTIVITY_URL @"activity://user"
#define TRIP_ACTIVITY_URL @"activity://trip"


@interface ActivityTableViewCell () <TTTAttributedLabelDelegate>

@property (nonatomic, strong, readwrite) PFUser *user;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *contentLabel;
@property (nonatomic, strong, readwrite) NSDictionary *activity;
@end

@implementation ActivityTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];

    [self.profilePicImageView setClipsToBounds:YES];
    [self.photoImageView setClipsToBounds:YES];
    [self.contentLabel setLineSpacing:5.0];
    
    self.contentLabel.delegate = self;

    [self.contentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.contentLabel setNumberOfLines:0];

    
    // Set up Link Attributes (bold and colored)
    UIColor *ttBlueColor = [UIColor colorWithRed:(95.0/255.0) green:(148.0/255.0) blue:(172.0/255.0) alpha:1];
    NSDictionary *linkAttributes = @{
                                     (id)kCTForegroundColorAttributeName : (id)ttBlueColor.CGColor,
                                     NSFontAttributeName : [UIFont boldSystemFontOfSize:14]
                                     };
    NSDictionary *activeLinkAttributes = @{
                                           (id)kCTForegroundColorAttributeName : (id)[UIColor darkGrayColor].CGColor,
                                           NSFontAttributeName : [UIFont boldSystemFontOfSize:14]
                                           };
    
    self.contentLabel.linkAttributes = linkAttributes;
    self.contentLabel.activeLinkAttributes = activeLinkAttributes;
    
    UITapGestureRecognizer *photoTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoImageViewTapped:)];
    photoTap.numberOfTapsRequired = 1;
    self.photoImageView.userInteractionEnabled = YES;
    [self.photoImageView addGestureRecognizer:photoTap];
    
    UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageViewTapped:)];
    profileTap.numberOfTapsRequired = 1;
    self.profilePicImageView.userInteractionEnabled = YES;
    [self.profilePicImageView addGestureRecognizer:profileTap];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setActivity:(NSDictionary *)activity {

    _activity = activity;
    _user = activity[@"fromUser"];
    
    if (!activity[@"photo"]) {
        [self.photoImageView setHidden:YES];
    }
    else {
        [self.photoImageView setHidden:NO];
    }
    
    
    [self updateContentLabel];

}

- (void)updateContentLabel {
    NSAttributedString *attString = [[TTUtility sharedInstance] attributedStringForActivity:_activity];
    [self.contentLabel setAttributedText:attString];
    
    // Set up a link for the username
    NSRange range = [self.contentLabel.text rangeOfString:_user.username];
    [self.contentLabel addLinkToURL:[NSURL URLWithString:USER_ACTIVITY_URL] withRange:range]; // Embedding a custom link in a substring
    
    // If it'as an addToTrip activity, set the Trip Name as a URL
    if ([_activity[@"type"] isEqualToString:@"addToTrip"] && _activity[@"trip"] && [_activity[@"trip"] valueForKey:@"name"]) {
        // Set up a link for the username
        NSRange tripRange = [self.contentLabel.text rangeOfString:[_activity[@"trip"] valueForKey:@"name"]];
        [self.contentLabel addLinkToURL:[NSURL URLWithString:TRIP_ACTIVITY_URL] withRange:tripRange]; // Embedding a custom link in a substring
    }

}

- (void)photoImageViewTapped:(UIGestureRecognizer *)gestureRecognizer {
    // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
    if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressPhoto:)]) {
        [self.delegate activityCell:self didPressPhoto:[_activity valueForKey:@"photo"]];
    }
}

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
            NSLog(@"Username tapped");
            
            // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
            if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressUsernameForUser:)]) {
                [self.delegate activityCell:self didPressUsernameForUser:_user];
            }
        }
        else if([[url host] hasPrefix:@"trip"]) {
            /* load user profile screen */
            NSLog(@"Trip tapped");
            Trip *trip = (Trip *)_activity[@"trip"];
            // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
            if (self.delegate && [self.delegate respondsToSelector:@selector(activityCell:didPressTrip:)]) {
                [self.delegate activityCell:self didPressTrip:trip];
            }
        }
    } else {
        /* deal with http links here */
    }
}

@end
