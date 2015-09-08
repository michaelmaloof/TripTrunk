//
//  CommentTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 8/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "CommentTableViewCell.h"
#import "UIColor+HexColors.h"
#import "TTUtility.h"
#import "TTTAttributedLabel.h"


#define USER_ACTIVITY_URL @"activity://user"

@interface CommentTableViewCell () <TTTAttributedLabelDelegate>

@property (nonatomic, strong, readwrite) PFUser *user;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *contentLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *usernameLabel;
@property (nonatomic, strong, readwrite) NSDictionary *activity;

@end

@implementation CommentTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [self.profilePicImageView setClipsToBounds:YES];
    [self.contentLabel setLineSpacing:5.0];
    [self.contentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.contentLabel setNumberOfLines:0];
    
    
    // Set up Link Attributes (bold and colored)
    UIColor *ttBlueColor = [UIColor colorWithHexString:@"76A4B8"];
    NSDictionary *linkAttributes = @{
                                     (id)kCTForegroundColorAttributeName : (id)ttBlueColor.CGColor,
                                     NSFontAttributeName : [UIFont boldSystemFontOfSize:14]
                                     };
    NSDictionary *activeLinkAttributes = @{
                                           (id)kCTForegroundColorAttributeName : (id)[UIColor darkGrayColor].CGColor,
                                           NSFontAttributeName : [UIFont boldSystemFontOfSize:14]
                                           };
    
    self.usernameLabel.delegate = self;
    self.usernameLabel.linkAttributes = linkAttributes;
    self.usernameLabel.activeLinkAttributes = activeLinkAttributes;
    
    UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageViewTapped:)];
    profileTap.numberOfTapsRequired = 1;
    self.profilePicImageView.userInteractionEnabled = YES;
    [self.profilePicImageView addGestureRecognizer:profileTap];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCommentActivity:(NSDictionary *)activity {
    
    _activity = activity;
    _user = activity[@"fromUser"];

    
    [self updateLabels];
    
}

- (void)updateLabels {
    NSAttributedString *attString = [[TTUtility sharedInstance] attributedStringForCommentActivity:_activity];
    [self.contentLabel setAttributedText:attString];
    
    self.usernameLabel.text = _user.username;
    // Set up a link for the username
    NSRange range = [self.usernameLabel.text rangeOfString:_user.username];
    [self.usernameLabel addLinkToURL:[NSURL URLWithString:USER_ACTIVITY_URL] withRange:range]; // Embedding a custom link in a substring
    
}


- (void)profileImageViewTapped:(UIGestureRecognizer *)gestureRecognizer {
    
    //We use the same delegate method here as for pressing the username, since both go to the same place.
    
    // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
    if (self.delegate && [self.delegate respondsToSelector:@selector(commentCell:didPressUsernameForUser:)]) {
        [self.delegate commentCell:self didPressUsernameForUser:_user];
    }
}

#pragma mark - TTTAttributedLabelDelegate methods
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    
    if ([[url scheme] hasPrefix:@"activity"]) {
        if ([[url host] hasPrefix:@"user"]) {
            /* load user profile screen */
            NSLog(@"Username tapped");
            
            // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
            if (self.delegate && [self.delegate respondsToSelector:@selector(commentCell:didPressUsernameForUser:)]) {
                [self.delegate commentCell:self didPressUsernameForUser:_user];
            }
        }
    } else {
        /* deal with http links here */
    }
}


@end
