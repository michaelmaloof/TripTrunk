//
//  TTHastagMentionColorization.m
//  TripTrunk
//
//  Created by Michael Cannell on 3/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTHashtagMentionColorization.h"
#import <UIKit/UIKit.h>
#import "TTColor.h"
#import "TTFont.h"

@implementation TTHashtagMentionColorization

+(NSMutableAttributedString*)colorHashtagAndMentions:(NSUInteger)cursorPosition text:(NSString*)text{
    //Convert caption to Mutable and Attributed
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
    NSError *error = nil;
    //create the attribute to change mentions and hastags blue
    [string addAttribute:NSFontAttributeName value:[TTFont tripTrunkCommentFont] range:NSMakeRange(0, text.length)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, text.length)];
    
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
        [string addAttribute:NSFontAttributeName value:[TTFont tripTrunkCommentFontBold] range:wordRangeAt];
        [string addAttribute:NSForegroundColorAttributeName value:[TTColor tripTrunkBlueLinkColor] range:wordRangeAt];
    }
    
    return string;
}

@end
