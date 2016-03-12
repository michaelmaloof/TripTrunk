//
//  TTCommentInputView.m
//  TripTrunk
//
//  Created by Matt Schoch on 8/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TTCommentInputView.h"
#import "UIColor+HexColors.h"
#import "KILabel.h"
#import "TTSuggestionTableViewController.h"
#import "TTHashtagMentionColorization.h"
#import "CommentListViewController.h"

UIView *topView;

@interface TTCommentInputView () <UITextFieldDelegate, UIPopoverPresentationControllerDelegate,TTSuggestionTableViewControllerDelegate>

@property (strong, nonatomic)UITextField *commentField;
@property (strong, nonatomic)UIButton *submitButton;
@property (weak, nonatomic)NSLayoutConstraint *bottomConstraint;
//############################################# MENTIONS ##################################################
//@property (weak, nonatomic) IBOutlet UITextView *caption;
//@property (weak, nonatomic) IBOutlet KILabel *captionLabel;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTSuggestionTableViewController *autocompletePopover;
@property (strong, nonatomic) NSString *previousComment;
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
        self.backgroundColor = [UIColor colorWithHexString:@"cccccc"];
        
        // Initialize the comment text field and submit button
        _commentField = [[UITextField alloc] initWithFrame:CGRectZero];
        [_commentField setTranslatesAutoresizingMaskIntoConstraints:NO];
        // Style the comment field
        _commentField.backgroundColor = [UIColor whiteColor];
        _commentField.borderStyle = UITextBorderStyleRoundedRect;
        _commentField.textColor = [UIColor blackColor];
        _commentField.font = [UIFont systemFontOfSize:14.0];
        _commentField.placeholder = NSLocalizedString(@"Add a comment...",@"Add a comment...");
        _commentField.autocorrectionType = UITextAutocorrectionTypeYes;
        _commentField.keyboardType = UIKeyboardTypeDefault;
        _commentField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _commentField.delegate = self;
        

        _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_submitButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_submitButton setTitle:NSLocalizedString(@"Send",@"Send") forState:UIControlStateNormal];
        [_submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_submitButton setBackgroundColor:[UIColor colorWithHexString:@"00b300"]];
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
        [self.delegate commentSubmitButtonPressedWithComment:self.commentField.text];
    }
    self.commentField.text = @"";
    // hide the keyboard
    [self endEditing:YES];

}

////FIXME: This needs to be refactored into a single method
//- (void)colorHashtagAndMentions{
//    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.commentField.text];
//    NSError *error = [[NSError alloc] init];
//    UIColor *fontColor = [UIColor blueColor];
//    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica" size:14] range:NSMakeRange(0, self.commentField.text.length)];
//    
////    //This is used to highlight and link #hashtags
////    NSRegularExpression *regExHash = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:&error];
////    NSArray *matches = [regExHash matchesInString:self.commentField.text options:0 range:NSMakeRange(0, self.commentField.text.length)];
////    
////    for(NSTextCheckingResult * match in matches){
////        NSRange wordRange = [match rangeAtIndex:0];
////        [string addAttribute:NSForegroundColorAttributeName value:fontColor range:wordRange];
////    }
//    
//    NSRegularExpression *regExAt = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:&error];
//    NSArray *matchesAt = [regExAt matchesInString:self.commentField.text options:0 range:NSMakeRange(0, self.commentField.text.length)];
//    
//    for(NSTextCheckingResult * matchAt in matchesAt){
//        NSRange wordRangeAt = [matchAt rangeAtIndex:0];
//        [string addAttribute:NSForegroundColorAttributeName value:fontColor range:wordRangeAt];
//    }
//    
//    self.commentField.attributedText = string;
//}

//############################################# MENTIONS ##################################################
-(void)updateMentionsInDatabase:(PFObject*)object{
    [self.autocompletePopover saveMentionToDatabase:object comment:self.commentField.text previousComment:self.previousComment photo:self.photo members:self.trunkMembers];
//    [self.autocompletePopover removeMentionFromDatabase:object comment:self.photo.caption previousComment:self.previousComment];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    UITextRange *cursorPosition = [textField selectedTextRange];
    //FIXME: Cursor position is not being used here, refactor!
    self.commentField.attributedText = [TTHashtagMentionColorization colorHashtagAndMentions:0 text:self.commentField.text];
    UITextPosition *newPosition = [textField positionFromPosition:cursorPosition.end offset:0];
    UITextRange *newRange = [textField textRangeFromPosition:newPosition toPosition:cursorPosition.start];
    [self.commentField setSelectedTextRange:newRange];
    return YES;
}


//As the user types, check for a @mention and display a popup with a list of users to autocomplete
- (void)textViewDidChange:(UITextView *)textView{
    //get the word that the user is currently typing
    UITextRange* selectedRange = [self.commentField selectedTextRange];
    NSInteger cursorOffset = [self.commentField offsetFromPosition:self.commentField.beginningOfDocument toPosition:selectedRange.start];
    NSString* substring = [self.commentField.text substringToIndex:cursorOffset];
    NSString* lastWord = [[substring componentsSeparatedByString:@" "] lastObject];
    
    //Display the Popover if there is a @ plus a letter typed and only if it is not already showing
    if([self displayAutocompletePopover:lastWord]){
        if(!self.autocompletePopover.delegate){
            //Instantiate the view controller and set its size
            [self.delegate displayAutocompletePopover:lastWord];
        }
    }
    
    //Update the table view in the popover but only if it is currently displayed
    if([self updateAutocompletePopover:lastWord]){
        self.autocompletePopover.mentionText = lastWord;
        [self.autocompletePopover updateAutocompleteTableView];
    }
    
    //Remove the popover if a space is typed
    if([self dismissAutocompletePopover:lastWord]){
//        [self dismissViewControllerAnimated:YES completion:nil]; <-----------------
        self.popover.delegate = nil;
        self.autocompletePopover = nil;
    }
}

//Only true if user has typed an @ and a letter and if the popover is not showing
-(BOOL)displayAutocompletePopover:(NSString*)lastWord{
    return [lastWord containsString:@"@"] && ![lastWord isEqualToString:@"@"] && !self.popover.delegate;
}

//Only true if the popover is showing and the user typed a space
-(BOOL)dismissAutocompletePopover:(NSString*)lastWord{
    return self.popover.delegate && ([lastWord hasSuffix:@" "] || [lastWord isEqualToString:@""]);
}

//Only true if the popover is showing and there are friends to show in the table view and the @mention isn't broken
-(BOOL)updateAutocompletePopover:(NSString*)lastWord{
    return self.popover.delegate && self.autocompletePopover.displayFriendsArray.count > 0 && ![lastWord isEqualToString:@""];
}

//Dismiss the popover and reset the delegates
-(void)removeAutocompletePopoverFromSuperview{
//    [self dismissViewControllerAnimated:YES completion:nil]; <-----------------
    self.popover.delegate = nil;
    self.autocompletePopover = nil;
}

#pragma mark - TTSuggestionTableViewControllerDelegate
//The popover is telling this view controller to dismiss it
- (void)popoverViewControllerShouldDissmissWithNoResults{
    [self removeAutocompletePopoverFromSuperview];
}

//replace the currently typed word with the the username
-(void)insertUsernameAsMention:(NSString*)username{
    //Get the currently typed word
    UITextRange* selectedRange = [self.commentField selectedTextRange];
    NSInteger cursorOffset = [self.commentField offsetFromPosition:self.commentField.beginningOfDocument toPosition:selectedRange.start];
    NSString* substring = [self.commentField.text substringToIndex:cursorOffset];
    NSString* lastWord = [[substring componentsSeparatedByString:@" "] lastObject];
    //get a mutable copy of the current caption
    NSMutableString *caption = [NSMutableString stringWithString:self.commentField.text];
    //create the replacement range of the typed mention
    NSRange mentionRange = NSMakeRange(cursorOffset-[lastWord length], [lastWord length]);
    //replace that typed @mention with the user name of the user they want to mention
    NSString *mentionString = [caption stringByReplacingCharactersInRange:mentionRange withString:[NSString stringWithFormat:@"%@ ",username]];
    
    //display the new caption
    self.commentField.text = mentionString;
    //dismiss the popover
    [self removeAutocompletePopoverFromSuperview];
    //reset the font colors and make sure the cursor is right after the mention. +1 to add a space
    //FIXME: See above
    self.commentField.attributedText = [TTHashtagMentionColorization colorHashtagAndMentions:0 text:self.commentField.text];

    //FIXME: Cursor position is not being used here, refactor!
    self.commentField.attributedText = [TTHashtagMentionColorization colorHashtagAndMentions:0 text:self.commentField.text];
    UITextPosition *newPosition = [self.commentField positionFromPosition:selectedRange.start offset:0];
    UITextRange *newRange = [self.commentField textRangeFromPosition:newPosition toPosition:selectedRange.start];
    [self.commentField setSelectedTextRange:newRange];
    self.autocompletePopover.delegate = nil;
}

//Adjust the height of the popover to fit the number of usernames in the tableview
-(void)adjustPreferredHeightOfPopover:(NSUInteger)height{
    self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], height);
}

- (NSString*)getUsernameFromLink:(NSString*)link{
    return [link substringFromIndex:1];
}

-(NSString*)separateMentions:(NSString*)comment{
    if(![comment containsString:@"@"])
        return comment;
    
    NSArray *array = [comment componentsSeparatedByString:@"@"];
    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
    return [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
}

#pragma mark - UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

//############################################# MENTIONS ##################################################


#pragma mark - dealloc

- (void)dealloc {
    // Remove keyboard notification observers when the view is dealloc'd
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
