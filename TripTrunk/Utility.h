//
//  Utility.h
//  TripTrunk
//
//  Created by Matt Schoch on 6/7/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Trip.h"
#import "Photo.h"

#import "Cloudinary.h"
#import <Parse/Parse.h>


@interface Utility : NSObject <CLUploaderDelegate>

/**
 *  Singleton instances of the shared API
 *
 *  @return shared API instance
 */
+ (Utility *)sharedInstance;

- (void)uploadPhoto:(Photo *)photo withImageData:(NSData *)imageData;

@end
