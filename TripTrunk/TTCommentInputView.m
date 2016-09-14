//
//  TTCommentInputView.m
//  TripTrunk
//
//  Created by Matt Schoch on 8/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TTCommentInputView.h"
#import "TTTAttributedLabel.h"
#import "TTSuggestionTableViewController.h"
#import "TTHashtagMentionColorization.h"
#import "CommentListViewController.h"

UIView *topView;

@interface TTCommentInputView () <UITextFieldDelegate, UIPopoverPresentationControllerDelegate,TTSuggestionTableViewControllerDelegate, TTTAttributedLabelDelegate>


@property (weak, nonatomic)NSLayoutConstraint *bottomConstraint;
//############################################# MENTIONS ##################################################
//@property (weak, nonatomic) IBOutlet UITextView *caption;
//@property (weak, nonatomic) IBOutlet TTTAttributedLabel *captionLabel;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTSuggestionTableViewController *autocompletePopover;
//############################################# MENTIONS ##################################################
@end

@implementation TTCommentInputView

- (id)init {
    
    return [self initWithFrame:CGRectZero];
    
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.backgroundColor = [TTColor tripTrunkLightGray];
        
        // Initialize the comment text field and submit button
        _commentField = [[UITextField alloc] initWithFrame:CGRectZero];
        [_commentField setTranslatesAutoresizingMaskIntoConstraints:NO];
        // Style the comment field
        _commentField.backgroundColor = [TTColor tripTrunkWhite];
        _commentField.borderStyle = UITextBorderStyleRoundedRect;
        _commentField.textColor = [TTColor tripTrunkBlack];
        _commentField.font = [TTFont tripTrunkFont14];
        _commentField.placeholder = NSLocalizedString(@"Add a comment...",@"Add a comment...");
        _commentField.autocorrectionType = UITextAutocorrectionTypeYes;
        _commentField.keyboardType = UIKeyboardTypeDefault;
        _commentField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _commentField.delegate = self;
        

        _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_submitButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_submitButton setTitle:NSLocalizedString(@"Send",@"Send") forState:UIControlStateNormal];
        [_submitButton setTitleColor:[TTColor tripTrunkWhite] forState:UIControlStateNormal];
        [_submitButton setBackgroundColor:[TTColor tripTrunkBlue]];
        _submitButton.layer.cornerRadius = 4.0;
        [_submitButton addTarget:self
                          action:@selector(submitButtonPressed)
                forControlEvents:UIControlEventTouchUpInside];
        

        [self addSubview:_commentField];
        [self addSubview:_submitButton];
        [self setupInternalContraints];
        
        
        // Listen for keyboard notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
        
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        topView = window.rootViewController.tabBarController.view;
        
        [self.commentField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
        
    }
    return self;
}

- (void)updateConstraints {
    
    [super updateConstraints];
    
}


-(void)textFieldDidBeginEditing:(UITextField *)textField{
    [self.delegate didBeginTyping];
    [textField setKeyboardType:UIKeyboardTypeDefault];

}

-(void)changeKeyboardType{
    [self.commentField setKeyboardType:UIKeyboardTypeDefault];

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
    
     _bottomConstraint = [NSLayoutConstraint constraintWithItem:self
                                                      attribute:NSLayoutAttributeBottom
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:view
                                                      attribute:NSLayoutAttributeBottom
                                                     multiplier:1.0
                                                       constant:0];
    // Center Vertically
    [view addConstraint:_bottomConstraint];
    
}

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    [self updateBottomLayoutConstraintWithNotification:notification];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
//    [self updateBottomLayoutConstraintWithNotification:notification];
    
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval animationDuration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    _bottomConstraint.constant = 0;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self layoutIfNeeded];
    }];
}

- (void)updateBottomLayoutConstraintWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval animationDuration = [[userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardEndFrame = [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat height = keyboardEndFrame.size.height;
    
    if (height > 0) {
        _bottomConstraint.constant = -height;
    }
    else {
        _bottomConstraint.constant = 0;
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self layoutIfNeeded];
    }];
    
}

- (void)submitButtonPressed {
    // Let the delegate handle the submit button press
    if (self.delegate && [self.delegate respondsToSelector:@selector(commentSubmitButtonPressedWithComment:)]) {
        [self.delegate commentSubmitButtonPressedWithComment:[self separateMentions:self.commentField.text]];
    }
    self.commentField.text = @"";
    // hide the keyboard
    [self endEditing:YES];
    //fixes the keyboard reappearing but looks glitchy, I'm not sure what is making commentField first responder
    [self.commentField resignFirstResponder];

}

//############################################# MENTIONS ##################################################
#pragma mark - UITextFieldDelegate
//As the user types, check for a @mention and display a popup with a list of users to autocomplete
- (void)textViewDidChange:(UITextView *)textView{
    if ([textView.text length] > 1){

        NSString *code = [textView.text substringFromIndex: [textView.text length] - 2];
        if ([code isEqualToString:@" "]){
            [textView setKeyboardType:UIKeyboardTypeDefault];
        }
    }
    
    UITextRange *selectedRange = [self.commentField selectedTextRange];
    //get the word that the user is currently typing
    NSInteger cursorOffset = [self.commentField offsetFromPosition:self.commentField.beginningOfDocument toPosition:selectedRange.start];
    NSString* substring = [self.commentField.text substringToIndex:cursorOffset];
    NSString* lastWord = [[substring componentsSeparatedByString:@" "] lastObject];
    [self.delegate displayAutocompletePopoverFromView:lastWord];
    
    //FIXME: Cursor position is not being used here, refactor!
    self.commentField.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.commentField.text];
    UITextPosition *newPosition = [self.commentField positionFromPosition:selectedRange.end offset:0];
    UITextRange *newRange = [self.commentField textRangeFromPosition:newPosition toPosition:selectedRange.start];
    [self.commentField setSelectedTextRange:newRange];

}

//Adjust the height of the popover to fit the number of usernames in the tableview
-(void)adjustPreferredHeightOfPopover:(NSUInteger)height{
    self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], height);
}

- (NSString*)getUsernameFromLink:(NSString*)link{
    return [link substringFromIndex:1];
}

//-(NSString*)separateMentions:(NSString*)comment{
//    if(![comment containsString:@"@"])
//        return comment;
//
//    NSArray *array = [comment componentsSeparatedByString:@"@"];
//    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
//    return [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
//}

-(NSString*)separateMentions:(NSString*)comment{
    if(![comment containsString:@"@"])
        return comment;
    
    //separate the mentions
    NSArray *array = [comment componentsSeparatedByString:@"@"];
    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
    spacedMentions = [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
    
    //make all mentions lowercase
    array = [spacedMentions componentsSeparatedByString:@" "];
    NSMutableArray *lcArray = [[NSMutableArray alloc] init];
    for(NSString *string in array){
        //check if this is a mention
        if(![string isEqualToString:@""]){
            if([[string substringToIndex:1] isEqualToString:@"@"]){
                [lcArray addObject:[string lowercaseString]];
            }else{
                [lcArray addObject:string];
            }
        }
    }
    return [lcArray componentsJoinedByString:@" "];
}

#pragma mark - UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

-(void)popoverViewControllerShouldDissmissWithNoResults{
    
}

-(void)insertUsernameAsMention:(NSString *)username{
    
}

//############################################# MENTIONS ##################################################


#pragma mark - dealloc

- (void)dealloc {
    // Remove keyboard notification observers when the view is dealloc'd
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




@end
