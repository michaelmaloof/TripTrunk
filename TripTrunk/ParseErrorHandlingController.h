//
//  ParseErrorHandlingController.h
//  TripTrunk
//
//  Created by Matt Schoch on 7/2/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"

@interface ParseErrorHandlingController : NSObject
+ (void)handleError:(NSError *)error;
+(void)errorLikingPhoto:(Photo*)photo;
+(void)errorUnlikingPhoto:(Photo*)photo;
@end
