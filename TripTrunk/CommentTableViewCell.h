//
//  CommentTableViewCell.h
//  TripTrunk
//
//  Created by Matt Schoch on 8/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@protocol CommentTableViewCellDelegate;

@interface CommentTableViewCell : UITableViewCell

@property (nonatomic, strong) id<CommentTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *profilePicImageView;

@property (nonatomic, strong, readonly) PFUser *user;
@property (nonatomic, strong, readonly) NSDictionary *activity;
- (void)setUser:(PFUser *)user;

- (void)setCommentActivity:(NSDictionary *)activity;

@end

@protocol CommentTableViewCellDelegate <NSObject>

- (void)commentCell:(CommentTableViewCell *)cellView didPressUsernameForUser:(PFUser *)user;

@end
