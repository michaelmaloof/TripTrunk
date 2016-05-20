//
//  CommentTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 8/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "CommentTableViewCell.h"
#import "TTUtility.h"
#import "TTTAttributedLabel.h"
#import "SocialUtility.h"
#import "TTColor.h"
#import "TTHashtagMentionColorization.h"

#define USER_ACTIVITY_URL @"activity://user"

@interface CommentTableViewCell () <TTTAttributedLabelDelegate>

@property (nonatomic, strong, readwrite) PFUser *user;

@property (nonatomic, strong, readwrite) NSDictionary *activity;

@end

@implementation CommentTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [self.profilePicImageView setClipsToBounds:YES];
//    [self.contentLabel setLineSpacing:5.0];
    [self.contentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.contentLabel setNumberOfLines:0];
        
    
    // Set up Link Attributes (bold and colored)
    UIColor *ttBlueColor = [TTColor tripTrunkBlueLinkColor];
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
    self.contentLabel.delegate = self;
    self.contentLabel.linkAttributes = linkAttributes;
    self.contentLabel.activeLinkAttributes = activeLinkAttributes;
    
    
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
    
    if([self.contentLabel.text containsString:@"@"]){
        NSArray *usernamesArray = [TTHashtagMentionColorization extractUsernamesFromComment:self.contentLabel.text];
        for(NSString *name in usernamesArray){
            NSRange userRange = [self.contentLabel.text rangeOfString:name];
            NSString *link = [NSString stringWithFormat:@"activity://%@",name];
            [self.contentLabel addLinkToURL:[NSURL URLWithString:link] withRange:userRange];
        }
    }
    
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
            
            // If our delegate is set, pass along the TTTAttributeLabel Delegate method to the Cells delegate method.
            if (self.delegate && [self.delegate respondsToSelector:@selector(commentCell:didPressUsernameForUser:)]) {
                [self.delegate commentCell:self didPressUsernameForUser:_user];
            }
        }else{
            NSString *urlString = [NSString stringWithFormat:@"%@",url];
            if([urlString containsString:@"@"]){
                NSString *username = [NSString stringWithFormat:@"%@",[url host]];
                [SocialUtility loadUserFromUsername:username block:^(PFUser *user, NSError *error) {
                    [self.delegate commentCell:self didPressUsernameForUser:user];
                }];
            }
        }
    } else {
        /* deal with http links here */
    }
    
}


@end
