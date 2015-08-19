//
//  CommentTableViewCell.h
//  TripTrunk
//
//  Created by Matt Schoch on 8/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CommentTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *commentLabel;
@property (nonatomic, strong, readonly) PFUser *user;

- (void)setUser:(PFUser *)user;


@end
