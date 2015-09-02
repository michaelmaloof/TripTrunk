//
//  ActivityTableViewCell.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/2/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "ActivityTableViewCell.h"

@interface ActivityTableViewCell () <TTTAttributedLabelDelegate>

@property (nonatomic, strong, readwrite) PFUser *user;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *contentLabel;
@property (nonatomic, strong, readwrite) NSDictionary *activity;
@end

@implementation ActivityTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.profilePicImageView setClipsToBounds:YES];
    [self.photoImageView setClipsToBounds:YES];

    [self.contentLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.contentLabel setNumberOfLines:0];
    self.contentLabel.delegate = self;
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];


}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setActivity:(NSDictionary *)activity {

    _activity = activity;
    _user = activity[@"fromUser"];
    
    NSString *type = activity[@"type"];
    
    NSString *content = @"";

    
    if ([type isEqualToString:@"like"]) {
        content = @"liked your photo.";
    }
    else if ([type isEqualToString:@"comment"]) {
        content = [NSString stringWithFormat:@"commented on your photo: %@", activity[@"content"]];
    }
    else if ([type isEqualToString:@"addToTrip"]) {
        content = @"added you to a trip.";
    }
    else if ([type isEqualToString:@"follow"]) {
        content = @"followed you.";
    }
    
    [self updateLabelWithString:content];
}

- (void)updateLabelWithString:(NSString *)content {
//    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:_user.username];
//    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:fullString
//                                                                    attributes:@{
//                                                                                 (id)kCTForegroundColorAttributeName : (id)[UIColor redColor].CGColor,
//                                                                                 NSFontAttributeName : [UIFont boldSystemFontOfSize:16],
//                                                                                 NSKernAttributeName : [NSNull null],
//                                                                                 (id)kTTTBackgroundFillColorAttributeName : (id)[UIColor greenColor].CGColor
//                                                                                 }];
    
    NSString *fullString = [NSString stringWithFormat:@"%@ %@", _user.username, content];
    self.contentLabel.text = fullString;
    
    NSRange range = [self.contentLabel.text rangeOfString:_user.username];
    [self.contentLabel addLinkToURL:[NSURL URLWithString:@"activity://user"] withRange:range]; // Embedding a custom link in a substring

}

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
    } else {
        /* deal with http links here */
    }
}

@end
