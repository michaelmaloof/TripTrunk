//
//  TTCommentInputView.h
//  TripTrunk
//
//  Created by Matt Schoch on 8/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TTCommentInputViewDelegate;

@interface TTCommentInputView : UIView

@property (nonatomic, weak) id<TTCommentInputViewDelegate> delegate;

- (void)setupConstraintsWithView:(UIView *)view;
@end

@protocol TTCommentInputViewDelegate <NSObject>

@required
- (void)commentSubmitButtonPressedWithComment:(NSString *)comment;

@end