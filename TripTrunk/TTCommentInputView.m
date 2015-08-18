//
//  TTCommentInputView.m
//  TripTrunk
//
//  Created by Matt Schoch on 8/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TTCommentInputView.h"
#import "UIColor+HexColors.h"

@interface TTCommentInputView ()

@property (strong, nonatomic)UITextField *commentField;
@property (strong, nonatomic)UIButton *submitButton;

@end

@implementation TTCommentInputView

- (id)init {
    
    return [self initWithFrame:CGRectZero];
    
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.backgroundColor = [UIColor colorWithHexString:@"cccccc"];
        
        // Initialize the comment text field and submit button
        _commentField = [[UITextField alloc] initWithFrame:CGRectZero];
        [_commentField setTranslatesAutoresizingMaskIntoConstraints:NO];
        // Style the comment field
        _commentField.backgroundColor = [UIColor whiteColor];
        _commentField.borderStyle = UITextBorderStyleRoundedRect;
        _commentField.textColor = [UIColor blackColor];
        _commentField.font = [UIFont systemFontOfSize:14.0];
        _commentField.placeholder = @"Add a comment...";
        _commentField.autocorrectionType = UITextAutocorrectionTypeYes;
        _commentField.keyboardType = UIKeyboardTypeDefault;
        _commentField.clearButtonMode = UITextFieldViewModeWhileEditing;
//        _commentField.delegate = self;
        

        _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_submitButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_submitButton setTitle:@"Send" forState:UIControlStateNormal];
        [_submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_submitButton setBackgroundColor:[UIColor colorWithHexString:@"00b300"]];
        _submitButton.layer.cornerRadius = 4.0;
        

        [self addSubview:_commentField];
        [self addSubview:_submitButton];
        [self setupInternalContraints];
    }
    return self;
}

- (void)updateConstraints {
    
    [super updateConstraints];
    
}

- (void)setupInternalContraints {
    
    // CommentField Constraints
    
    // Width constraint, 75% of parent view width
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_commentField
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:0.75
                                                      constant:0.0]];
    
    // Height constraint, 12 less than parent
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_commentField
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1
                                                      constant:-12]];
    
    // Align almost-left
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_commentField
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1.0
                                                      constant:12.0]];
    
    // Center Vertically
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_commentField
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0.0]];
    
    // SubmitButton Constraints
    
    // Width constraint 1 - close to right
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_submitButton
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:-12.0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_submitButton
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_commentField
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:12]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_submitButton
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                        toItem:_commentField
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:0]];
    
    
    
    // Height constraint, 12 less than parent
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_submitButton
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                    multiplier:1
                                                      constant:-12]];
    
    // Center Vertically
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_submitButton
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0.0]];

}

- (void)setupConstraintsWithView:(UIView *)view {
    
    
    // Width constraint, half of parent view width
    [view addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1
                                                           constant:0]];
    
    // Height constraint, half of parent view height
    [view addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:44]];
    
    // Center horizontally
    [view addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];
    
    // vertical algin bottom
    [view addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0
                                                           constant:0.0]];
    
}

@end
