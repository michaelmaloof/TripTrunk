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
 *  Uploads a photo to Cloudinary and sets the url as the profilepic on the User object.
 *
 *  @param imageData NSData of a raw image
 *  @param user  User whose profile pic it is
 */
- (void)uploadProfilePic:(NSData *)imageData forUser:(PFUser *)user;

/**
 *  Takes a user's profilePicUrl and alters it to be a Cloudinary url with 200x200 dimensions
 *
 *  @param urlString imageUrl of a User ProfilePic on Cloudinary
 *
 *  @return String of a transformed imageUrl
 */
- (NSString *)profileImageUrl:(NSString *)urlString;

/**
 *  Uploads a Photo to Cloudinary, sets the url on the Photo object, and then saves the Photo object to Parse
 *
 *  @param photo     TripTrunk parse Photo object
 *  @param imageData NSData of a JPEG image (works with PNG as well, but that takes up more space, so we recommend JPEG)
 */
- (void)uploadPhoto:(Photo *)photo withImageData:(NSData *)imageData;

/**
 *  Save the given photo to Camera Roll
 *
 *  @param photo   Photo Object containing the imageUrl of the remote image to save
 */
- (void)downloadPhoto:(Photo *)photo;

/**
 *  Save a list of photos to Camera Roll
 *
 *  @param photos Array of Photo objects to save, each containing the imageUrl of a remote image to save
 */
- (void)downloadPhotos:(NSArray *)photos;

/**
 *  Deletes the photo and all Activities that reference the photo
 *  Everything deletes in the background so it may take some time to actually delete
 *  Notifications are sent for each completed deletion with the names:
 *  "parsePhotosUpdatedNotification" and "ActivityObjectsDeleted"
 *  The controller calling deleteTrip should observe these notifications and reload the UI components accordingly
 *
 *  @param photo Photo object
 */
- (void)deletePhoto:(Photo *)photo;

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

/**
 *  Takes a Photo's imageUrl and alters it to be a Cloudinary url with a quality of 60 and downsized to the phone's screen size
 *
 *  @param urlString imageUrl of a Photo on Cloudinary
 *
 *  @return String of a transformed imageUrl
 */
- (NSString *)mediumQualityScaledDownImageUrl:(NSString *)urlString;


- (void)addUploaderProgressView;


- (NSAttributedString *)attributedStringForActivity:(NSDictionary *)activity;

- (NSAttributedString *)attributedStringForCommentActivity:(NSDictionary *)activity;

@end


