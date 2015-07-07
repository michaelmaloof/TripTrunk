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
#import "LoginViewController.h"


@interface TTUtility : NSObject <CLUploaderDelegate>

/**
 *  Singleton instances of the shared API
 *
 *  @return shared API instance
 */
+ (TTUtility *)sharedInstance;

/**
 *  Uploads a Photo to Cloudinary, sets the url on the Photo object, and then saves the Photo object to Parse
 *
 *  @param photo     TripTrunk parse Photo object
 *  @param imageData NSData of a JPEG image (works with PNG as well, but that takes up more space, so we recommend JPEG)
 */
- (void)uploadPhoto:(Photo *)photo withImageData:(NSData *)imageData;

/**
 *  Takes a Photo's imageUrl and alters it to be a Cloudinary url with thumbnail transformations
 *
 *  @param urlString imageUrl of a Photo on Cloudinary
 *
 *  @return String of a transformed imageUrl
 */
- (NSString *)thumbnailImageUrl:(NSString *)urlString;

/**
 *  Takes a Photo's imageUrl and alters it to be a Cloudinary url with a quality of 60
 *
 *  @param urlString imageUrl of a Photo on Cloudinary
 *
 *  @return String of a transformed imageUrl
 */
- (NSString *)mediumQualityImageUrl:(NSString *)urlString;


//@property LoginViewController *login;

@end


