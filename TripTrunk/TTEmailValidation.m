//
//  TTEmailValidation.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/19/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTEmailValidation.h"

@implementation TTEmailValidation


+(BOOL)emailIsValid:(NSString *)checkString{
    
    // added this because RegEx wasn't catching it
    if([checkString containsString:@" "])
        return NO;
    
    if([checkString containsString:@".@"])
        return NO;
    
    if([checkString containsString:@"@."])
        return NO;
    
    if([checkString containsString:@".."])
        return NO;
    
    if([checkString containsString:@"@"]){
        NSArray *emailSplit = [checkString componentsSeparatedByString:@"@"];
        NSString *local = emailSplit[0];
        NSString *domain = emailSplit[1];
        if(local.length > 64)
            return NO;
        
        if(domain.length > 255)
            return NO;
    }
    
    if(checkString.length>0){
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@" options:NSRegularExpressionCaseInsensitive error:nil];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:checkString options:0 range:NSMakeRange(0, [checkString length])];
        if(numberOfMatches > 1)
            return NO;
    
        NSString *illegalEndingCharacters = @"~`!@#$%^&*()_+-=}|[]:;'<>?,./'";
        NSString *lastCharacter = [checkString substringFromIndex: [checkString length] - 1];
        
        if([illegalEndingCharacters containsString:lastCharacter])
            return NO;
    }
    //hack done
    
    NSString *emailRegex = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";\
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:checkString];
}

@end
