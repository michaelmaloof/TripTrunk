//
//  TTErrorHandler.h
//  TripTrunk
//
//  Created by Michael Cannell on 3/24/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"

@interface TTErrorHandler : NSObject

+(void)errorLikingPhoto:(Photo*)photo;
+(void)errorUnlikingPhoto:(Photo*)photo;

@end
