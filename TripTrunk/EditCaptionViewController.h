//
//  EditCaptionViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 10/29/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "TTBaseViewController.h"

@protocol EditDelegate
-(void)captionButtonTapped:(int)button caption:(NSString*)text;

@end

@interface EditCaptionViewController : TTBaseViewController
@property NSString *caption;
@property (weak, nonatomic) IBOutlet UITextView *captionBox;
@property UIImage *image;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property id<EditDelegate> delegate;

@end
