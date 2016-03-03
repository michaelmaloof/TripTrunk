//
//  TTHastagMentionColorization.m
//  TripTrunk
//
//  Created by Michael Cannell on 3/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTHashtagMentionColorization.h"
#import <UIKit/UIKit.h>

@implementation TTHashtagMentionColorization

+(NSMutableAttributedString*)colorHashtagAndMentions:(NSUInteger)cursorPosition text:(NSString*)text{
    //Convert caption to Mutable and Attributed
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
    NSError *error = nil;
    //Set the mention and hashtog font color <-- need to use TripTrunk app blue
    UIColor *fontColor = [UIColor blueColor];
    //create the attribute to change mentions and hastags blue
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica Neue" size:14] range:NSMakeRange(0, text.length)];
    
    //Use regular expressions to search through the string and search for the #(letter) pattern
    //This is currently turned off so hastags will remain black
    //    NSRegularExpression *regExHash = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:&error];
    //    NSArray *matches = [regExHash matchesInString:self.caption.text options:0 range:NSMakeRange(0, self.caption.text.length)];
    //
    //    for(NSTextCheckingResult * match in matches){
    //        NSRange wordRange = [match rangeAtIndex:0];
    //        [string addAttribute:NSForegroundColorAttributeName value:fontColor range:wordRange];
    //    }
    
    //Use regular expressions to search through the string and search for the @(letter) pattern
    NSRegularExpression *regExAt = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:&error];
    NSArray *matchesAt = [regExAt matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    //Loop through all the regular expression matches and wrap them in the attributed properties
    for(NSTextCheckingResult * matchAt in matchesAt){
        NSRange wordRangeAt = [matchAt rangeAtIndex:0];
        [string addAttribute:NSForegroundColorAttributeName value:fontColor range:wordRangeAt];
    }
    
//    //Update caption uitextview field
//    self.caption.attributedText = string;
//    //make sure the cursor is in the proper place while typing
//    [self.caption setSelectedRange:NSMakeRange(cursorPosition, 0)];
    
    return string;
}

@end
