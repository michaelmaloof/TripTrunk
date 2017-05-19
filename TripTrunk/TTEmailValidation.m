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
    if(checkString.length>0){
        NSString *illegalEndingCharacters = @"~`!@#$%^&*()_+-=}|[]:;'<>?,./'";
        NSString *lastCharacter = [checkString substringFromIndex: [checkString length] - 1];
        
        if([illegalEndingCharacters containsString:lastCharacter])
            return NO;
    }
    
    NSString *emailRegex = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";\
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:checkString];
}

@end
