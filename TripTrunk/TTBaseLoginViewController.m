//
//  BaseLoginViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 1/4/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTBaseLoginViewController.h"

@interface TTBaseLoginViewController ()
@property NSString *usernameDescriptor;
@property NSString *passwordDescriptor;
@property NSString *emailDescriptor;
@property NSString *nameDescriptor;
@property NSString *response;
@property NSString *usernameTitle;
@property NSString *passwordTitle;
@property NSString *emailTitle;
@property NSString *nameTitle;

@end

@implementation TTBaseLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createWarningStrings];
    self.navigationController.navigationBar.hidden = YES;
}

-(void)createWarningStrings{
    self.usernameDescriptor = NSLocalizedString (@"Username",@"Username");
    self.usernameTitle = NSLocalizedString (@"Invalid Username",@"Invalid Username");
    self.passwordDescriptor = NSLocalizedString (@"Password",@"Password");
    self.passwordTitle = NSLocalizedString (@"Invalid Password",@"Invalid Password");
    self.nameDescriptor = NSLocalizedString (@"Name",@"Name");
    self.nameTitle = NSLocalizedString (@"Invalid Name",@"Invalid Name");
    self.emailDescriptor = NSLocalizedString (@"Email",@"Email");
    self.emailTitle = NSLocalizedString (@"Invalid Email",@"Invalid Email");
    self.response = NSLocalizedString (@"Okay",@"Okay");
}

-(void)previousLoginViewController{
    [self.navigationController popViewControllerAnimated:YES];
}

-(BOOL)validateLoginInput:(NSString *)input type:(int)inputType{
    if (inputType == 0) { //username
        return [self validateUsernameInput:input];
    } else if (inputType == 1) { //password
        return  [self validatePasswordInput:input];
    } else if (inputType == 2) { //name
        return [self validateNameInput:input];
    } else if (inputType == 3) { //email
        return [self validateEmailInput:input];
    }
    return NO;
}

-(BOOL)validateUsernameInput:(NSString*)input{
    if(![self validateLength:input type:0])
        return NO;
    
    if(![self validateInputHasNoSpaces:input type:0])
        return NO;
    
    if(![self validateInputDoesNotContainIllegalChars:input type:0])
            return NO;
    
    if(![self validateUsernameDoesNotContainSuccessiveChars:input]) //periods and dashes only
        return NO;
    
    if(![self validateUsernameHasMaximumOfTwoChars:input]) //periods and dashes only
        return NO;
    
    if(![self validateUsernameDoesNotBeginWithIllegalChars:input])
        return NO;

    //TODO check if duplicate username on Parse
    
    return YES;
}

-(BOOL)validateEmailInput:(NSString*)input{
    
    if(![self validateLength:input type:3])
        return NO;
    
    if(![self validateEmailAddressIsValidFormat:input])
        return NO;
    
    if(![self validateInputHasNoSpaces:input type:3])
        return NO;
    
    return YES;
}

-(BOOL)validatePasswordInput:(NSString*)password {
    if(![self validateLength:password type:1])
        return NO;
    
    if(![self validateInputHasNoSpaces:password type:1])
        return NO;
    
    //TODO: add more password requirments
    
    return  YES;
}

-(BOOL)validateNameInput:(NSString*)name {
    
    if(![self validateLength:name type:2])
        return NO;
    
    if(![self validateInputDoesNotContainIllegalChars:name type:2])
        return NO;
    
    return YES;
}

//Input Validation

-(BOOL)validateLength:(NSString*)input type:(int)inputType{
    int minimum = 0;
    int maximum = 0;
    NSString *inputDescriptor = [[NSString alloc]init];
    NSString *warningTitle = [[NSString alloc]init];
    NSString *response = self.response;
    if (inputType == 0){ //username
        minimum = 3;
        maximum = 20;
        inputDescriptor = self.usernameDescriptor;
        warningTitle = self.usernameTitle;
    } else if (inputType == 1){ //password
        minimum = 8;
        maximum = 20;
        inputDescriptor = self.passwordDescriptor;
        warningTitle = self.passwordTitle;
    } else if (inputType == 2){ //name
        minimum = 1;
        maximum = 20;
        inputDescriptor = self.nameDescriptor;
        warningTitle = self.nameTitle;
    } else if (inputType == 3){ //email
        minimum = 1;
        maximum = 100;
        inputDescriptor = self.emailDescriptor;
        warningTitle = self.emailTitle;
    }
    
    if (input.length < minimum || input.length > maximum ){
        NSString *warning = [NSString stringWithFormat:@"must be between %d-%d characters", minimum, maximum];
        [self createLoginAlert:warningTitle warning:warning inputType:inputDescriptor response:response];
        return NO;
    }
    return YES;
}

-(BOOL)validateInputHasNoSpaces:(NSString*)input type:(int)inputType{
    NSString *inputDescriptor = [[NSString alloc]init];
    NSString *warningTitle = [[NSString alloc]init];
    NSString *response = self.response;
    if (inputType == 0){ //username
        inputDescriptor = self.usernameDescriptor;
        warningTitle = self.usernameTitle;
    } else if (inputType == 1){ //password
        inputDescriptor = self.passwordDescriptor;
        warningTitle = self.passwordTitle;
    } else if (inputType == 3){ //email
        inputDescriptor = self.emailDescriptor;
        warningTitle = self.emailTitle;
    }
    
    if ([input containsString:@" "]){
        NSString *warning = @"can't have any spaces";
        [self createLoginAlert:warningTitle warning:warning inputType:inputDescriptor response:response];
        return NO;
    }
    return YES;
}

-(BOOL)validateInputDoesNotContainIllegalChars:(NSString*)input type:(int)inputType{
    
    NSString *inputDescriptor = [[NSString alloc]init];
    NSString *warningTitle = [[NSString alloc]init];
    NSString *response = self.response;
    NSString *unders = [input stringByReplacingOccurrencesOfString:@"_" withString:@""];
    NSString *dash = [unders stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *newInput = [dash stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString* newStr = [newInput stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    
    if (inputType == 0){ //username
        inputDescriptor = self.usernameDescriptor;
        warningTitle = self.usernameTitle;
    } else if (inputType == 2){ //name
        inputDescriptor = self.nameDescriptor;
        warningTitle = self.nameTitle;
    }
    if ([newStr length] < [input length])
    {
    NSString *warning = @"can only contain the following characters:\n \n Letters\n Numbers\n _\n .\n -\n";
        [self createLoginAlert:warningTitle warning:warning inputType:inputDescriptor response:response];
        return NO;
    }
    return YES;
}

-(BOOL)validateUsernameDoesNotContainSuccessiveChars:(NSString*)username{
    
    if([username containsString:@".."] || [username containsString:@"--"]){
        [self createLoginAlert:self.usernameTitle warning:@"cannot contain repeated periods or dashes." inputType:@"Username" response:self.response];
        return NO;
    }
    return YES;
}

-(BOOL)validateUsernameHasMaximumOfTwoChars:(NSString*)username{
    NSInteger dashCount = [[username componentsSeparatedByString:@"-"] count]-1;
    NSInteger periodCount = [[username componentsSeparatedByString:@"."] count]-1;
    if(dashCount > 2 || periodCount> 2){
        [self createLoginAlert:self.usernameTitle warning:@"cannot contain more than 2 periods or dashes." inputType:@"Username" response:self.response];
        return NO;
    }
    return YES;
}

-(BOOL)validateUsernameDoesNotBeginWithIllegalChars:(NSString*)username{
    NSString *firstChar = [username substringToIndex:1];
    if([firstChar isEqualToString:@"."] || [firstChar isEqualToString:@"-"]){
        [self createLoginAlert:self.usernameTitle warning:@"cannot begin with periods or dashes." inputType:@"Username" response:self.response];
        return NO;
    }
    return YES;
}

-(BOOL)validateEmailAddressIsValidFormat:(NSString*)emailAddress{
    NSString *expression = @"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$";
    NSError *error = NULL;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:emailAddress options:0 range:NSMakeRange(0, [emailAddress length])];
    
    if(!match || [emailAddress containsString:@".con"]){
        [self createLoginAlert:self.emailTitle warning:@":(" inputType:@"Email"
                      response:self.response];
        return NO;
    }
    return YES;
}


-(void)createLoginAlert:(NSString*)title warning:(NSString*)description inputType:(NSString*)inputType response:(NSString*)response{
    NSString *warning = [NSString stringWithFormat:@"%@ %@",inputType,description];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title,title)
                                                    message:NSLocalizedString(warning, warning)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(response,response)
                                          otherButtonTitles:nil, nil];
    [alert show];
    
}


@end
