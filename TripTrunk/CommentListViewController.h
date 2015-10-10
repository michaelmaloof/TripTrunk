//
//  CommentListViewController.h
//  TripTrunk
//
//  Created by Matt Schoch on 9/3/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "TTBaseViewController.h"


@interface CommentListViewController : TTBaseViewController

- (id)initWithComments:(NSArray *)comments forPhoto:(Photo *)photo;

@end
