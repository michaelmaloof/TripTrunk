//
//  ParseErrorHandlingController.m
//  TripTrunk
//
//  Created by Matt Schoch on 7/2/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "ParseErrorHandlingController.h"
#import <Parse/Parse.h>
#import "TTUtility.h"
#import "TTCache.h"
#import "AppDelegate.h"

@implementation ParseErrorHandlingController

+ (void)handleError:(NSError *)error {
    if (![error.domain isEqualToString:PFParseErrorDomain]) {
        return;
    }
    
    if (error.code == 100){
        [[TTUtility sharedInstance] noInternetConnection];
    }
    
    if (error.code != 120){
        NSLog(@"Error: %@", error);
    }
    
    switch (error.code) {
        case kPFErrorInvalidSessionToken: {
            [self _handleInvalidSessionTokenError];
            break;
        }
    }
}

+ (void)_handleInvalidSessionTokenError {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Invalid Session",@"Invalid Session")
                                 message:NSLocalizedString(@"Session is no longer valid, please log in again.",@"Session is no longer valid, please log in again.")
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okButton = [UIAlertAction
                                actionWithTitle:NSLocalizedString(@"Okay",@"Okay")
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    [(AppDelegate *)[[UIApplication sharedApplication] delegate] logout];
                                }];
    
    [alert addAction:okButton];
    
    UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [vc presentViewController:alert animated:YES completion:nil];
    
    
    
    
    
    
    
    //--------------------------------------
    // Option 1: Show a message asking the user to log out and log back in.
    //--------------------------------------
    // If the user needs to finish what they were doing, they have the opportunity to do so.
    //
//     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid Session",@"Invalid Session")
//                                                         message:NSLocalizedString(@"Session is no longer valid, please log out and log in again.",@"Session is no longer valid, please log out and log in again.")
//                                                        delegate:self
//                                               cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
//                                               otherButtonTitles:nil];
//     [alertView show];
    
    
    //[(AppDelegate *)[[UIApplication sharedApplication] delegate] logout];
    
    //--------------------------------------
    // Option #2: Show login screen so user can re-authenticate.
    //--------------------------------------
    // You may want this if the logout button is inaccessible in the UI.
    //
    // UIViewController *presentingViewController = [[UIApplication sharedApplication].keyWindow.rootViewController;
    // PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
    // [presentingViewController presentViewController:logInViewController animated:YES completion:nil];
}

+(void)errorLikingPhoto:(Photo*)photo{
    [[TTCache sharedCache] decrementLikerCountForPhoto:photo];
}

+(void)errorUnlikingPhoto:(Photo*)photo{
    [[TTCache sharedCache] incrementLikerCountForPhoto:photo];
}

+(void)errorCommentingOnPhoto:(Photo*)photo{
    [[TTCache sharedCache] decrementCommentCountForPhoto:photo];
}

@end
