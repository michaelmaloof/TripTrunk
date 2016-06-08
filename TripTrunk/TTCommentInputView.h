//
//  TTCommentInputView.h
//  TripTrunk
//
//  Created by Matt Schoch on 8/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
@protocol TTCommentInputViewDelegate;

@interface TTCommentInputView : UIView

@property (nonatomic, weak) id<TTCommentInputViewDelegate> delegate;
//@property (strong, nonatomic)NSString *previousComment;
@property (strong, nonatomic)UITextField *commentField;
@property (strong, nonatomic) NSArray *trunkMembers;
@property (strong, nonatomic) Photo *photo;
@property (strong, nonatomic)UIButton *submitButton;

-(void)changeKeyboardType;


- (void)setupConstraintsWithView:(UIView *)view;
@end

@protocol TTCommentInputViewDelegate <NSObject>

-(void)didBeginTyping;
-(void)didEndTyping;

@optional
-(void)displayAutocompletePopoverFromView:(NSString*)text;
-(void)dismissAutocompletePopoverFromView;


@required
- (void)commentSubmitButtonPressedWithComment:(NSString *)comment;

@end