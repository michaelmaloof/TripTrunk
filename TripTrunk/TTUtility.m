//
//  Utility.m
//  TripTrunk
//
//  Created by Matt Schoch on 6/7/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TTUtility.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import "AFNetworking/AFNetworking.h"
#import "TTTTimeIntervalFormatter.h"
#import "MSFloatingProgressView.h"
#import "TTNoInternetView.h"
#import "TTCache.h"
#import "SocialUtility.h"
#import <CoreText/CoreText.h>
#import "TTHashtagMentionColorization.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <GooglePlaces/GooglePlaces.h>
#import "Underscore.h"
#define _ Underscore
#import "TTAnalytics.h"
#import "UploadOperation.h"
#import "AddTripPhotosViewController.h"


#define CLOUDINARY_URL @"cloudinary://334349235853935:YZoImSo-gkdMtZPH3OJdZEOvifo@triptrunk"
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static TTTTimeIntervalFormatter *timeFormatter;


@interface TTUtility () <MBProgressHUDDelegate>{
    MBProgressHUD *HUD;
    MSFloatingProgressView *progressView;
    TTNoInternetView *internetView;
    NSOperationQueue *operationQueue;
}
@property NSString* tripName;
@property int photoCount;
@property int videoCount;
@property int totalPhotos;
@property Trip *trip;
@property NSData *videoFileData;
@end

@implementation TTUtility

CLCloudinary *cloudinary;


+ (TTUtility*)sharedInstance
{
    static TTUtility *_sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[TTUtility alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        // Initialize the base cloudinary object
        cloudinary = [[CLCloudinary alloc] initWithUrl:CLOUDINARY_URL];
        
        // Initialize the Operation Queue
        operationQueue = [NSOperationQueue new];
        [operationQueue setMaxConcurrentOperationCount:2];
        
        if (!timeFormatter) {
            timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
        }
        
    }
    return self;
}

- (void)uploadProfilePic:(NSData *)imageData forUser:(PFUser *)user;
{
    CLUploader *uploader = [[CLUploader alloc] init:cloudinary delegate:self];
    
    // Initialize the progressView if it isn't initialized already
    if (!progressView) {
        progressView = [[MSFloatingProgressView alloc] init];
        [progressView addToWindow];
    }
    // Already initialized, so tell it that we're uploading another photo
    else {
        [progressView incrementTaskCount];
    }
    
    [uploader upload:imageData
             options:@{@"type":@"upload"}
      withCompletion:^(NSDictionary *successResult, NSString *errorResult, NSInteger code, id context) {
          if (successResult) {
              NSString* publicId = [successResult valueForKey:@"public_id"];
              NSLog(@"Block upload success. Public ID=%@, Full result=%@", publicId, successResult);
              NSString* url = [successResult valueForKey:@"url"];
              
              [user setObject:url forKey:@"profilePicUrl"];
              
              [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                  
                  if(error) {
                      [ParseErrorHandlingController handleError:error];
                      [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"uploadProfilePic:"];
                  }
                  else {
                      [[TTUtility sharedInstance] internetConnectionFound];
                  }
              }];
              
          } else {
              NSLog(@"Block upload error: %@, %li", errorResult, (long)code);
          }
          
      } andProgress:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite, id context) {
          
          
      }];
}

- (NSString *)profilePreviewImageUrl:(NSString *)urlString;
{
    // If it's a facebook url, just return that url, no transformation
    if (!urlString || [urlString rangeOfString:@"graph.facebook.com"].length > 0) {
        return urlString;
    }
    
    CLTransformation *transformation = [CLTransformation transformation];
    [transformation setWidthWithInt: 150];
    [transformation setHeightWithInt: 150];
    [transformation setCrop: @"fill"];
    [transformation setQualityWithFloat:10];
    [transformation setFetchFormat:@"jpg"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    
    NSString *transformedUrl = [cloudinary url:[[[url path] lastPathComponent] stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"] options:@{@"transformation": transformation}];
    return transformedUrl;
}

- (NSString *)profileImageUrl:(NSString *)urlString;
{
    // If it's a facebook url, just return that url, no transformation
    if (!urlString || [urlString rangeOfString:@"graph.facebook.com"].length > 0) {
        return urlString;
    }
    
    CLTransformation *transformation = [CLTransformation transformation];
    [transformation setWidthWithInt: 350];
    [transformation setHeightWithInt: 350];
    [transformation setCrop: @"fill"];
    [transformation setQualityWithFloat:60];
    [transformation setFetchFormat:@"jpg"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    
    NSString *transformedUrl = [cloudinary url:[[[url path] lastPathComponent] stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"] options:@{@"transformation": transformation}];
    return transformedUrl;
}

-(void)noInternetConnection{
    // Initialize the progressView if it isn't initialized already
    if (!internetView) {
        internetView = [[TTNoInternetView alloc] init];
        [internetView addToWindow];
    }
}

-(void)internetConnectionFound{
    if (internetView){
        [internetView removeFromWindow];
        internetView = nil;
    }
}

-(void)uploadPhoto:(Photo *)photo photosCount:(int)photosCount toFacebook:(BOOL)publishToFacebook block:(void (^)(Photo *photo))completionBlock;
{
    NSLog(@"uploading photo");
    self.tripName = photo.tripName;
    self.totalPhotos = photosCount;
    self.trip = photo.trip;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];

    
    // Initialize the progressView if it isn't initialized already
    if (!progressView) {
        progressView = [[MSFloatingProgressView alloc] init];
        [progressView addToWindow];
    }
    // Already initialized, so tell it that we're uploading another photo
    else {
        [progressView incrementTaskCount];
    }
    
    /*
    // First, locally save the photo in case it doesn't complete uploading.
    [photo pin];
     
     TODO: Pinning doesn't work.
     First, all PFCachePolicy's in queries need to be removed.
     Then, the actual imageData needs to be pinned, with the Photo object. But, just pinning the Photo object below doesn't include the imageAsset.
    */
    
    // We need to get the actual Image Data for the Photo's imageAsset.
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    [options setVersion:PHImageRequestOptionsVersionCurrent];
    [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
    [options setNetworkAccessAllowed:YES];
    
    [[PHImageManager defaultManager] requestImageDataForAsset:photo.imageAsset options:options
                                                resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                    
                UploadOperation *operation = [UploadOperation asyncBlockOperationWithBlock:^(dispatch_block_t queueCompletionHandler) {

                    [self uploadPhotoToCloudinary:photo withImageData:imageData block:^(BOOL succeeded, NSError *error, Photo *savedPhoto) {
                        if (succeeded) {
                            
                            // Add photo to the local cache
                            [[TTCache sharedCache] setAttributesForPhoto:photo likers:[NSArray array] commenters:[NSArray array] likedByCurrentUser:NO];
                            
                            // post the notification so that the TrunkViewController can know to reload the data
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"parsePhotosUpdatedNotification" object:nil];
                            
                            // Photo saved successfully, so we can unpin it from the local datastore.
                            // TODO: Uncomment this once pinning is actually implemented.
                            //  [photo unpin];
                            
                            // Upload Photo to Facebook also if needed
                            if (publishToFacebook) {
                                // TODO: Actually wait for the Facebook Upload to finish before moving on - have the method return a callback.
                                [self initFacebookUpload:savedPhoto];
                            }
                            
                            // queueCompletionHandler tells the NSOperationQueue that the operation is finished and it can move on.
                            queueCompletionHandler();
                            
                            // Tell the calling-method this whole upload is complete
                            completionBlock(savedPhoto);
                        }
                        else {
                            // Error uploading photo
                            NSLog(@"Error uploading photo (upload photo)...");
                            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"uploadPhoto:"];
                            completionBlock(nil);
                        }
                    }];
                }];
                
                // Add the upload operation to the OperationQueue
                [operationQueue addOperation: operation];
                
            }];
}


-(void)uploadPhotoToCloudinary:(Photo *)photo withImageData:(NSData *)imageData block:(void (^)(BOOL success, NSError *error, Photo *savedPhoto))completionBlock
{
    
    CLUploader *uploader = [[CLUploader alloc] init:cloudinary delegate:self];
    
    // prepare for a background task
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        //TODO: Locally cache photos here
        // This block executes if we're notified that iOS will terminate the app because we're out of background time.
        // Ideally, we cache the photos here, and then when the app starts again we resume uploading.
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    [uploader upload:imageData
             options:@{@"type":@"upload"}
      withCompletion:^(NSDictionary *successResult, NSString *errorResult, NSInteger code, id context) {
          if (successResult) {
              // Photo Uploaded Successfully to Cloudinary
              NSLog(@"Block upload success. Public ID=%@", [successResult valueForKey:@"public_id"]);
              
              photo.imageUrl = [successResult valueForKey:@"url"];
              
              // Save the photo to the Database
              [photo saveEventually:^(BOOL succeeded, NSError *error) {
                  if(error) {
                      [ParseErrorHandlingController handleError:error];
                      completionBlock(nil, error, photo);
                  }
                  else {
                      
                      // We can end our background task now since the photo is uploaded.
                      [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                      bgTask = UIBackgroundTaskInvalid;
                      
                      // Tell the completion handler that it was successful.
                      completionBlock(YES, nil, photo);
                  }
              }];
          }
          else {
              // Error Uploading Photo
              [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",errorResult] method:@"uploadPhotoToCloudinary:"];
              NSLog(@"Block upload error: %@, %li", errorResult, (long)code);
              [[UIApplication sharedApplication] endBackgroundTask:bgTask];
              bgTask = UIBackgroundTaskInvalid;
              completionBlock(nil, [NSError new], photo); // TODO: Add a descriptive error
          }
      } andProgress:nil];
    
}

- (void)downloadPhotoImage:(UIImage *)photo{
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = NSLocalizedString(@"Downloading", @"Downloading");
        HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress
    });
    
    UIImageWriteToSavedPhotosAlbum(photo,nil,nil,nil);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD.labelText = NSLocalizedString(@"Complete!", @"Complete!");
        [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
    });
}

- (void)downloadPhotoVideo:(NSURL *)video{
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = NSLocalizedString(@"Downloading", @"Downloading");
        HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress
    });
    
//    UISaveVideoAtPathToSavedPhotosAlbum(video, nil, nil, nil);
    
    NSData *videoData = [NSData dataWithContentsOfURL:video];
    NSString *videoPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"file.mov"];
    [videoData writeToFile:videoPath atomically:YES];

    UISaveVideoAtPathToSavedPhotosAlbum(videoPath, nil, nil, nil);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD.labelText = NSLocalizedString(@"Complete!", @"Complete!");
        [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
    });
}

- (void)downloadPhoto:(Photo *)photo;
{
    // Show HUD spinner
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = NSLocalizedString(@"Downloading", @"Downloading");
        HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress
    });
    
    // prepare for a background task
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    
    AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:photo.imageUrl]]];
    [request setResponseSerializer: [AFImageResponseSerializer serializer]];
    [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject) {
            UIImage *image = (UIImage *)responseObject;
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            [TTAnalytics downloadPhoto];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Hide HUD spinner
                HUD.labelText = NSLocalizedString(@"Complete!", @"Complete!");
                [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
                
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            });

        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error downloading photo");
        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"downloadPhoto:"];
        
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    [request start];
}

//- (void)downloadPhotos:(NSArray *)photos;
//{
//    // Show HUD spinner
//    dispatch_async(dispatch_get_main_queue(), ^{
//        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
//        NSString *downloadOneOf = NSLocalizedString(@"Downloading 1 of", "Downloading 1 of");
//        HUD.labelText = [NSString stringWithFormat:@"%@ %lu", downloadOneOf,(unsigned long)photos.count];
//        HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress
//    });
//    
//    __block int completedDownloads = 0;
//    for (Photo *photo in photos) {
//        // prepare for a background task
//        __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
//            bgTask = UIBackgroundTaskInvalid;
//        }];
//        
//        AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:photo.imageUrl]]];
//        [request setResponseSerializer: [AFImageResponseSerializer serializer]];
//        [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//            if (responseObject) {
//                // Save image to phone
//                UIImageWriteToSavedPhotosAlbum((UIImage *)responseObject, nil, nil, nil);
//                [TTAnalytics downloadPhoto];
//
//                // Increment counter so we know when to hide the HUD
//                completedDownloads++;
//                if (completedDownloads == photos.count) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        // Hide HUD spinner
//                        HUD.labelText = NSLocalizedString(@"Complete!", @"Complete"!);
//                        [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
//                    });
//                }
//                else {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        NSString *downloading = NSLocalizedString(@"Downloading", "Downloading");
//                        NSString *of = NSLocalizedString(@"of", "of");
//                        HUD.labelText = [NSString stringWithFormat:@"%@ %i %@ %lu", downloading, completedDownloads + 1, of, (unsigned long)photos.count];
//                    });
//                }
//                
//                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
//                bgTask = UIBackgroundTaskInvalid;
//
//            }
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            NSLog(@"Error downloading photo");
//            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"downloadPhotos:"];
//            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
//            bgTask = UIBackgroundTaskInvalid;
//        }];
//        [request start];
//    }
//    
//}

- (void)downloadAllTrunkPhotos:(NSArray *)photos{
    NSLog(@"downloadAllTrunkPhotos");
    // Show HUD spinner
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        NSString *downloadOneOf = NSLocalizedString(@"Downloading 1 of", "Downloading 1 of");
        HUD.labelText = [NSString stringWithFormat:@"%@ %lu", downloadOneOf,(unsigned long)photos.count];
        HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress
    });
    
    __block int completedDownloads = 0;
    for (Photo *photo in photos) {
        // prepare for a background task
        __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        if(photo.video){
            [photo.video fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                NSLog(@"Downloading video: %@",photo.video[@"videoUrl"]);
                NSData *videoData = [NSData dataWithContentsOfURL:[NSURL URLWithString:photo.video[@"videoUrl"]]];
                NSString *videoPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"file.mov"];
                [videoData writeToFile:videoPath atomically:YES];
                
                UISaveVideoAtPathToSavedPhotosAlbum(videoPath, nil, nil, nil);
                
                completedDownloads++;
                if (completedDownloads == photos.count) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // Hide HUD spinner
                        HUD.labelText = NSLocalizedString(@"Complete!", @"Complete"!);
                        [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
                    });
                }else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *downloading = NSLocalizedString(@"Downloading", "Downloading");
                        NSString *of = NSLocalizedString(@"of", "of");
                        HUD.labelText = [NSString stringWithFormat:@"%@ %i %@ %lu", downloading, completedDownloads + 1, of, (unsigned long)photos.count];
                    });
                }
                
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
                
            }];
            
        }else{
    
            AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:photo.imageUrl]]];
            [request setResponseSerializer: [AFImageResponseSerializer serializer]];
            [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                if (responseObject) {
                    NSLog(@"Downloading photo: %@",photo.imageUrl);
                    // Save image to phone
                    UIImageWriteToSavedPhotosAlbum((UIImage *)responseObject, nil, nil, nil);
                    [TTAnalytics downloadPhoto];
                    
                    // Increment counter so we know when to hide the HUD
                    completedDownloads++;
                    if (completedDownloads == photos.count) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // Hide HUD spinner
                            HUD.labelText = NSLocalizedString(@"Complete!", @"Complete"!);
                            [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
                        });
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *downloading = NSLocalizedString(@"Downloading", "Downloading");
                            NSString *of = NSLocalizedString(@"of", "of");
                            HUD.labelText = [NSString stringWithFormat:@"%@ %i %@ %lu", downloading, completedDownloads + 1, of, (unsigned long)photos.count];
                        });
                    }
                    
                    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                    bgTask = UIBackgroundTaskInvalid;
                    
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error downloading photo");
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"downloadPhotos:"];
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }];
            [request start];
        }
    }
    
}

- (void)deletePhoto:(Photo *)photo withblock:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    // If the user isn't the trip nor photo creator, don't let them delete this trip
    if (![[[PFUser currentUser] objectId] isEqualToString:photo.user.objectId] && ![[[PFUser currentUser] objectId] isEqualToString:photo.trip.creator.objectId]) {
        return;
    }

    else{
        [photo deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (!error) {
                 //commented this out because in ios10 this was causing the first photo to be duplicated when a photo was deleted.
                 //[[NSNotificationCenter defaultCenter] postNotificationName:@"parsePhotosUpdatedNotification" object:nil];
                 
                 // Delete any activities that directly references this photo
                 // That SHOULD include all like, and comment activities
                 PFQuery *deleteActivitiesQuery = [PFQuery queryWithClassName:@"Activity"];
                 [deleteActivitiesQuery whereKey:@"photo" equalTo:photo];
                 [deleteActivitiesQuery setLimit:1000];
                 [deleteActivitiesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
                  {
                      if (!error) {
                          // The find succeeded.
                          // Delete the found objects
                          [[TTUtility sharedInstance] internetConnectionFound];
                          
                          for (PFObject *object in objects) {
                              [object deleteEventually];
                          }
                          
                          [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivityObjectsDeleted" object:nil];
                          
                          if(photo.video){
                              //if this is a video, we need to delete the corresponding video object
                              [photo.video deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                  //FIXME: This is temporary and should be moved to Cloud Code
                                  NSArray *urlSegments = [photo.video[@"videoUrl"] componentsSeparatedByString: @"/"];
                                  NSArray *publicId = [[urlSegments lastObject] componentsSeparatedByString:@"."];
                                  CLUploader *uploader = [[CLUploader alloc] init:cloudinary delegate:self];
                                  [uploader destroy:publicId[0] options:@{@"resource_type":@"video"} withCompletion:^(NSDictionary *successResult, NSString *errorResult, NSInteger code, id context) {
                                      completionBlock(YES,nil);
                                  } andProgress:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite, id context) {
                                      //nil
                                  }];
                                  
                              }];
                          }else{
                              completionBlock(YES,nil);
                          }
                          
                      } else {
                          NSLog(@"Error: %@ %@", error, [error userInfo]);
                          completionBlock(NO,error);
                          [ParseErrorHandlingController handleError:error];
                          [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"deletePhoto:"];
                      }
                  }];
                 
             }
             else{
                 completionBlock(NO,error);
             }
             
         }];
    }
    
}

- (NSString *)thumbnailImageUrl:(NSString *)urlString;
{
    CLTransformation *transformation = [CLTransformation transformation];
    [transformation setWidthWithInt: 220];
    [transformation setHeightWithInt: 220];
    [transformation setCrop: @"fill"];
    [transformation setQualityWithFloat:60];
    [transformation setFetchFormat:@"jpg"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    
    NSString *transformedUrl = [cloudinary url:[[[url path] lastPathComponent] stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"] options:@{@"transformation": transformation}];
    return transformedUrl;
}

- (NSString *)mediumQualityImageUrl:(NSString *)urlString;
{
    CLTransformation *transformation = [CLTransformation transformation];

    [transformation setQualityWithFloat:60];
    [transformation setFetchFormat:@"jpg"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    
    NSString *transformedUrl = [cloudinary url:[[[url path] lastPathComponent] stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"] options:@{@"transformation": transformation}];
    return transformedUrl;
}

- (NSString *)lowQualityImageUrl:(NSString *)urlString;
{
    CLTransformation *transformation = [CLTransformation transformation];
    
    [transformation setQualityWithFloat:30];
    [transformation setFetchFormat:@"jpg"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    
    NSString *transformedUrl = [cloudinary url:[[[url path] lastPathComponent] stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"] options:@{@"transformation": transformation}];
    return transformedUrl;
}


- (NSString *)mediumQualityScaledDownImageUrl:(NSString *)urlString;
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    //TODO: change width/height scaling for iPhone 6+ since it's a 3x phone.
    
    CLTransformation *transformation = [CLTransformation transformation];
    [transformation setHeightWithFloat: screenWidth * 2];
    [transformation setHeightWithFloat: screenHeight * 2];
    [transformation setCrop: @"limit"];
    [transformation setQualityWithFloat:60];
    [transformation setFetchFormat:@"jpg"];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    
    NSString *transformedUrl = [cloudinary url:[[[url path] lastPathComponent] stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"] options:@{@"transformation": transformation}];
    return transformedUrl;
}

-(void)uploadVideo:(Photo *)video photosCount:(int)photosCount toFacebook:(BOOL)publishToFacebook block:(void (^)(PFObject *video))completionBlock;
{
    NSLog(@"uploading video");
    self.tripName = video.tripName;
    self.totalPhotos = photosCount;
    self.trip = video.trip;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    
    // Initialize the progressView if it isn't initialized already
    if (!progressView) {
        progressView = [[MSFloatingProgressView alloc] init];
        [progressView addToWindow];
    }
    // Already initialized, so tell it that we're uploading another photo
    else {
        [progressView incrementTaskCount];
    }
    
    /*
     // First, locally save the photo in case it doesn't complete uploading.
     [photo pin];
     
     TODO: Pinning doesn't work.
     First, all PFCachePolicy's in queries need to be removed.
     Then, the actual imageData needs to be pinned, with the Photo object. But, just pinning the Photo object below doesn't include the imageAsset.
     */
    
    // We need to get the actual Image Data for the Photo's imageAsset.
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    [options setVersion:PHVideoRequestOptionsVersionCurrent];
    [options setDeliveryMode:PHVideoRequestOptionsDeliveryModeHighQualityFormat];
    [options setNetworkAccessAllowed:YES];
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:video.imageAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                                    
            UploadOperation *operation = [UploadOperation asyncBlockOperationWithBlock:^(dispatch_block_t queueCompletionHandler) {

                [self uploadVideoToCloudinary:video withAVAsset:asset block:^(BOOL success, NSError *error, Photo *savedVideo) {
                    if (success) {

                        // Add photo to the local cache
                        [[TTCache sharedCache] setAttributesForPhoto:video likers:[NSArray array] commenters:[NSArray array] likedByCurrentUser:NO];

                        // post the notification so that the TrunkViewController can know to reload the data
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"parsePhotosUpdatedNotification" object:nil];

                        // Photo saved successfully, so we can unpin it from the local datastore.
                        // TODO: Uncomment this once pinning is actually implemented.
                        //  [photo unpin];
                        
                        // Upload Photo to Facebook also if needed
                        if (publishToFacebook) {
                            // TODO: Actually wait for the Facebook Upload to finish before moving on - have the method return a callback.
                            savedVideo[@"caption"] = video.caption ? video.caption : @"";
                            savedVideo[@"fileData"] = self.videoFileData;
                            [self initFacebookUpload:savedVideo];
                        }
                        
                        //queueCompletionHandler tells the NSOperationQueue that the operation is finished and it can move on.
                        queueCompletionHandler();
                        
                        // Tell the calling-method this whole upload is complete
                        completionBlock(savedVideo);
                    }
                    else {
                        // Error uploading photo
                        NSLog(@"Error uploading video (upload video)...");
//                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"uploadVideo:"];
                        completionBlock(nil);
                    }
                }];
            }];
        
            // Add the upload operation to the OperationQueue
            [operationQueue addOperation: operation];

        }];
}

-(void)uploadVideoToCloudinary:(Photo *)video withAVAsset:(AVAsset*)asset block:(void (^)(BOOL success, NSError *error, Photo *savedVideo))completionBlock{
    
    CLUploader *uploader = [[CLUploader alloc] init:cloudinary delegate:self];
    
    // prepare for a background task
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    NSString *pathToVideo;
    if(video.editedPath)
        pathToVideo = video.editedPath;
    else pathToVideo = [(AVURLAsset *)asset URL].absoluteString;
    
    pathToVideo = [pathToVideo stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSData *fileData = [NSData dataWithContentsOfFile:pathToVideo];
    self.videoFileData = fileData;
    [uploader upload:fileData
             options:@{@"type":@"upload",@"resource_type":@"video"}
      withCompletion:^(NSDictionary *successResult, NSString *errorResult, NSInteger code, id context) {
          if (successResult) {
              // Video Uploaded Successfully to Cloudinary
              NSLog(@"Block upload success. Public ID=%@", [successResult valueForKey:@"public_id"]);
              
              //remove trimmed video if applicable
              if(video.editedPath){
                  NSFileManager *fileManager = [NSFileManager defaultManager];
                  NSError *error;
                  BOOL success = [fileManager removeItemAtPath:video.editedPath error:&error];
                  if (success)
                      NSLog(@"Temporary file deleted:%@ ",video.editedPath);
                  else NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
              }
              
              PFObject *videoObject = [PFObject objectWithClassName:@"Video"];
              [videoObject setObject:[PFUser currentUser] forKey:@"user"];
              [videoObject setObject:video.trip forKey:@"trip"];
              [videoObject setObject:video.trip.city forKey:@"city"];
              [videoObject setObject:[successResult valueForKey:@"url"] forKey:@"videoUrl"];
              
              PFACL *videoObjectACL = [PFACL ACLWithUser:[PFUser currentUser]];

              if (self.trip.isPrivate == NO) {
                  [videoObjectACL setPublicReadAccess:YES];
              }
              // Private Trip, set the ACL permissions so only the creator has access - and when members are invited then they'll get READ access as well.
              // TODO: only update ACL if private status changed during editing.
              if (self.trip.isPrivate == YES) {
                  [videoObjectACL setPublicReadAccess:NO];
                  [videoObjectACL setReadAccess:YES forUser:self.trip.creator];
                  [videoObjectACL setWriteAccess:YES forUser:self.trip.creator];
              }
              
              videoObject.ACL = videoObjectACL;
              
              [videoObject saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
                  
                  if (error) {
                      NSLog(@"Error saving video (uploadVideoToCloudinary): %@", error);
                      NSLog(@"Block upload error (uploadVideoToCloudinary): %@, %li", errorResult, (long)code);
                      [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                      bgTask = UIBackgroundTaskInvalid;
                      completionBlock(nil, [NSError new], video); // TODO: Add a descriptive error
                      [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"uploadVideoToCloudinary:"];
                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                      message:NSLocalizedString(@"Error uploading photo/video. Please try again.",@"Error uploading photo/video. Please try again.")
                                                                     delegate:self
                                                            cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                            otherButtonTitles:nil, nil];
                      
                      //Show alert view
                      [alert show];
                  }
                  
                  if (completionBlock) {
                      completionBlock(YES, nil, (Photo *)videoObject);
                  }
              }];
          }
          else {
              // Error Uploading Video
              [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",errorResult] method:@"uploadVideoToCloudinary:"];
              NSLog(@"Block upload error (uploadVideoToCloudinary): %@, %li", errorResult, (long)code);
              [[UIApplication sharedApplication] endBackgroundTask:bgTask];
              bgTask = UIBackgroundTaskInvalid;
              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                              message:NSLocalizedString(@"Error uploading video. Please try again.",@"Error uploading video. Please try again.")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                    otherButtonTitles:nil, nil];
              
              //Show alert view
              [alert show];
              completionBlock(nil, [NSError new], video); // TODO: Add a descriptive error
          }
      } andProgress:nil];
    
}

#pragma mark - Cloudinary CLUploaderDelegate

- (void)uploaderSuccess:(NSDictionary*)result context:(id)context {
    NSString* publicId = [result valueForKey:@"public_id"];
    NSLog(@"Upload success. Public ID=%@", publicId);
    
    //don't increment for a video, the thumbnail will be counted instead (as a photo)
    if(!result[@"video"]){
        self.photoCount++;
    }else{
        self.photoCount--;
        self.videoCount++;
    }
    
    // Mark the task as completed in the progressview -- if all uploads are finished, it will remove from the screen
    if ([progressView taskCompleted] && self.photoCount+self.videoCount >= self.totalPhotos) {
        // Uploading is totally complete, so nil the progress view
        progressView = nil;
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        
        //protect against a counting error
        int totalUploaded = self.photoCount+self.videoCount;
        if(totalUploaded > self.totalPhotos)
            totalUploaded = self.totalPhotos;
        
        NSString *videosIncluded = @"";
        NSString *photosIncluded = @"";
        if(self.photoCount > 0)
            photosIncluded = NSLocalizedString(@"photos ",@"photos ");
        
        if(self.videoCount > 0)
            videosIncluded = NSLocalizedString(@"videos ",@"videos ");
        
        if(self.photoCount > 0 && self.videoCount > 0)
            videosIncluded = NSLocalizedString(@"& videos ",@"& videos ");
        
        NSString *alertSuccess = [NSString stringWithFormat:@"Successfully uploaded %1$d/%2$d %3$@%4$@to the '%5$@' trunk",totalUploaded,self.totalPhotos,photosIncluded,videosIncluded,self.tripName];
        
        BOOL messageError = NO;
        if ([alertSuccess rangeOfString:@"(null)"].location != NSNotFound)
            messageError = YES;
        
        if(!messageError){
            localNotification.alertBody = NSLocalizedString(alertSuccess,alertSuccess);
            localNotification.timeZone = [NSTimeZone defaultTimeZone];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            self.tripName = nil;
            self.photoCount = 0;
            self.videoCount = 0;
        }
    }
}

-(void)uploaderError:(NSString *)result code:(NSInteger)code context:(id)context {
    [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",result] method:@"uploaderError:"];
    NSLog(@"Upload error: %@, %ld", result, (long)code);
    
    // Get rid of the progress view
 if ([progressView taskCompleted])
 {
    [progressView removeFromWindow];
     progressView = nil;
     UILocalNotification* localNotification = [[UILocalNotification alloc] init];
     localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
     
     NSString *alertFail = [NSString stringWithFormat:@"There was an error uploading photos & videos to the '%@' trunk",self.tripName];
     
     localNotification.alertBody = NSLocalizedString(alertFail, alertFail);
     localNotification.timeZone = [NSTimeZone defaultTimeZone];
     [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
     self.tripName = nil;
     self.photoCount = 0;
     self.videoCount = 0;
 }
    
}

- (void)uploaderProgress:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite context:(id)context {
    float divide = (float)totalBytesWritten/(float)totalBytesExpectedToWrite;
//    NSString *string =  [NSString stringWithFormat:@"written:%ld    totalwritten:%ld    expectedToWrite:%ld   divided:%f", (long)bytesWritten, (long)totalBytesWritten, (long)totalBytesExpectedToWrite, divide];
//    NSLog(@"%@", string);
    
    [progressView setProgress:divide];
}


#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    HUD = nil;
}



// TEMPRORARY METHODS - DELTE WHEN FINISHED
- (void)addUploaderProgressView {
    
    progressView = [[MSFloatingProgressView alloc] init];
    
    // Add the progress bar to the Window so it should stay up front
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[[UIApplication sharedApplication] delegate] window] addSubview:progressView];

    });
    [progressView setProgress:0.5];
}

#pragma mark - Attributed String

- (NSAttributedString *)attributedStringForActivity:(NSDictionary *)activity {
    
    NSString *type = activity[@"type"];
    
    NSString *content = @"";
    
    BOOL isAllActivity = NO;
    BOOL engagedOnOwnContent = NO;
    
    PFUser *toUser = activity[@"toUser"];
    PFUser *user = activity[@"fromUser"];

    
    if ([type isEqualToString:@"like"]) {
        
        if ([toUser.objectId isEqualToString:[PFUser currentUser].objectId]){
            content = NSLocalizedString(@"liked your photo/video. ",@"liked your photo/video. ");
        } else if ([toUser.objectId isEqualToString:user.objectId]){
            isAllActivity = YES;
            engagedOnOwnContent = YES;
            content = NSLocalizedString(@"liked their own photo/video. ",@"liked their own photo/video. ");
        }
        else {
            isAllActivity = YES;
            content = NSLocalizedString(@"liked a photo/video by ",@"liked a photo/video by ");
        }
    }
    else if ([type isEqualToString:@"comment"]) {
        if ([toUser.objectId isEqualToString:[PFUser currentUser].objectId]){
            NSString *commented = NSLocalizedString(@"commented on your photo/video",@"commented on your photo/video");
            content = [NSString stringWithFormat:@"%@: %@ ", commented,activity[@"content"]];
        } else if ([toUser.objectId isEqualToString:user.objectId]){
            isAllActivity = YES;
            engagedOnOwnContent = YES;
            
            if ([activity[@"isCaption"]boolValue] == NO){
            
                content = NSLocalizedString(@"commented on their own photo/video ",@"commented on their own photo/video ");
            } else {
                content = NSLocalizedString(@"wrote a caption for their photo/video ",@"wrote a caption for their photo/video ");
            }
        } else {
            isAllActivity = YES;
            content = NSLocalizedString(@"commented on a photo/video by",@"commented on a photo/video by");
        }
    }
    else if ([type isEqualToString:@"addToTrip"]) {
        if (activity[@"trip"] && [activity[@"trip"] valueForKey:@"name"]) {
            NSString *added = NSLocalizedString(@"added you to the trunk",@"added you to the trunk");
            content = [NSString stringWithFormat:@"%@ %@ ", added,[activity[@"trip"] valueForKey:@"name"]];
        }
        else {
            content =  NSLocalizedString(@"added you to a trip. ",@"added you to a trip. ");
        }
    }
    else if ([type isEqualToString:@"follow"]) {
        if ([toUser.objectId isEqualToString:[PFUser currentUser].objectId]){
            content = NSLocalizedString(@"followed you. ",@"followed you. ");
        } else {
            isAllActivity = YES;
            content = NSLocalizedString(@"followed ",@"followed ");
        }
    }
    else if ([type isEqualToString:@"addedPhoto"]) {
        NSString *addedPhoto = NSLocalizedString(@"added a photo/video to",@"added a photo/video to");
        content = [NSString stringWithFormat:@"%@ %@ ",addedPhoto, [activity[@"trip"] valueForKey:@"name"]];
    }
    else if ([type isEqualToString:@"pending_follow"]) {
        content =  NSLocalizedString(@"requested to follow you. ",@"requested to follow you. ");
    }
    
    else if ([type isEqualToString:@"mention"]) {
        if ([activity[@"isCaption"]boolValue] == YES) {
            content =  NSLocalizedString(@"mentioned you in a photo/video caption. ",@"mentioned you in a photo/video caption. ");

        }else {
            content =  NSLocalizedString(@"mentioned you in a comment. ",@"mentioned you in a comment. ");
        }
    }
    
    NSString *time = @"";

    if ([activity valueForKey:@"createdAt"]) {
        NSDate *created = [activity valueForKey:@"createdAt"];
        time = [timeFormatter stringForTimeIntervalFromDate:[NSDate date] toDate:created];
    }
    
    NSString *contentString = @"";
    
    if (isAllActivity == NO || engagedOnOwnContent == YES){
        contentString = [NSString stringWithFormat:@"%@ %@", user.username, content];
    }
    else {
        contentString = [NSString stringWithFormat:@"%@ %@ %@ ", user.username, content, toUser.username];
    }

    NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
    

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc]init];
    if (![type isEqualToString:@"comment"]) {
        str = [[NSMutableAttributedString alloc] initWithString:contentString
                                                     attributes:@{NSFontAttributeName : [TTFont tripTrunkFont14],
                                                                  NSParagraphStyleAttributeName: paraStyle,
                                                                  NSKernAttributeName : [NSNull null]
                                                                  }];
        
    } else {
        str = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:contentString];
    }
    
    
    NSAttributedString *timeStr = [[NSAttributedString alloc] initWithString:time
                                                                  attributes:@{NSFontAttributeName : [TTFont tripTrunkFont10],
                                                                               NSParagraphStyleAttributeName: paraStyle,
                                                                               NSKernAttributeName : [NSNull null],
                                                                               (id)kCTForegroundColorAttributeName : (id)[TTColor tripTrunkGray].CGColor
                                                                               }];
    [str appendAttributedString:timeStr];
    
    return str;
}

- (NSAttributedString *)attributedStringForCommentActivity:(NSDictionary *)activity {
    
    NSString *time = @"";
    if ([activity valueForKey:@"createdAt"]) {
        NSDate *created = [activity valueForKey:@"createdAt"];
        time = [timeFormatter stringForTimeIntervalFromDate:[NSDate date] toDate:created];
    }
    
    NSString *contentString = [NSString stringWithFormat:@"%@ ", activity[@"content"]];

    
    NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    
    NSMutableAttributedString *str = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:contentString];
    
    NSAttributedString *timestampStr = [[NSAttributedString alloc] initWithString:time
                                                                  attributes:@{NSFontAttributeName : [TTFont tripTrunkFont10],
                                                                               NSParagraphStyleAttributeName: paraStyle,
                                                                               NSKernAttributeName : [NSNull null],
                                                                               (id)kCTForegroundColorAttributeName : (id)[TTColor tripTrunkGray].CGColor
                                                                               }];
    [str appendAttributedString:timestampStr];
    return str;
}

/*
 * THIS IS A HACK
 * Matt Schoch 9/8/2016
 * This filters out the hardcoded "problem locations" of the result array.
 * There is a performance p
 */
- (NSArray *)arrayWithoutProblemLocations:(NSArray *)locations {
    NSArray *problemLocations = @[
                                 @"Lake Tahoe, CA, United States",
                                 @"Lake Tahoe, NV, United States"
                                 ];
    // Create the predicate, which says the value is NOT IN the problem location array.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", problemLocations];
    
    return [locations filteredArrayUsingPredicate:predicate];
}
- (void)locationsForSearchOLD:(NSString *)str block:(void (^)(NSArray *objects, NSError *error))completionBlock {
    
    NSString *urlString = [NSString stringWithFormat:@"http://gd.geobytes.com/AutoCompleteCity?&q=%@", str];
    NSString *encodedString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    
    AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:encodedString]]];
    [request setResponseSerializer: [AFJSONResponseSerializer serializer]];
    
    [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject) {
            NSArray *responseArray = (NSArray *)responseObject;
            
            /*
             * THIS IS A HACK
             * Matt Schoch 9/8/2016
             * We shouldn't be filtering this result list at all, but we're manually removing stuff (i.e. Lake Tahoe) that doesn't have a valid City/State.
             * When Location API gets switched, remove this arrayWithoutProblemLocations call.
             */
            NSArray *response = [self arrayWithoutProblemLocations:responseArray];
            return completionBlock(response, nil);
        }
        return completionBlock(nil, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error searching for location");
        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"locationsForSearch:"];
        return completionBlock(nil, error);
    }];
    
    [request start];
}

- (void)locationsForSearch:(NSString *)str block:(void (^)(NSArray *objects, NSError *error))completionBlock {

    GMSPlacesClient *placesClient = [GMSPlacesClient sharedClient];

    GMSAutocompleteFilter *filter = [[GMSAutocompleteFilter alloc] init];
    filter.type = kGMSPlacesAutocompleteTypeFilterCity;
    
    // Only search if we actually have something typed in.
    if (str && ![str isEqualToString:@""]) {
        [placesClient autocompleteQuery:str
                                 bounds:nil
                                 filter:filter
                               callback:^(NSArray *results, NSError *error) {
                                   if (error != nil) {
                                       NSLog(@"Autocomplete error %@", [error localizedDescription]);
                                       return completionBlock(nil, error);
                                   }
                                   
                                   // Map the Google Places result into objects containing just the Location String and the PlaceId
                                   NSArray *places = Underscore.arrayMap(results, ^TTPlace *(GMSAutocompletePrediction *place) {
//                                       NSLog(@"Result '%@', with gpID: '%@'", place.attributedFullText.string, place.placeID);
                                       TTPlace *ttPlace = [TTPlace new];
                                       ttPlace.name = place.attributedFullText.string;
                                       ttPlace.gpID = place.placeID;
                                       return ttPlace;
                                   });
                                   return completionBlock(places, nil);
                               }];
    }
    else {
        completionBlock(nil, nil);
    }
    
}

- (void)locationDetailsForLocation:(TTPlace *)location block:(void (^)(TTPlace *ttPlace, NSError *error))completionBlock {
    
    
    [[GMSPlacesClient sharedClient] lookUpPlaceID:location.gpID
                                         callback:^(GMSPlace * _Nullable place, NSError * _Nullable error) {
                                             if (error) {
                                                 NSLog(@"Place Details error %@", [error localizedDescription]);
                                                 return completionBlock(nil, error);
                                             }
                                             
                                             if (place) {
                                                 
                                                 TTPlace *ttPlace = [TTPlace new];
                                                 ttPlace.name = place.name;
                                                 ttPlace.gpID = location.gpID;
                                                 ttPlace.latitude = place.coordinate.latitude;
                                                 ttPlace.longitude = place.coordinate.longitude;
                                                
                                                 
                                                 for (NSObject *component in place.addressComponents) {
                                                     if ([[component valueForKey:@"type"] isEqualToString:@"locality"]) {
                                                         ttPlace.city = [component valueForKey:@"name"];
                                                     }
                                                     else if ([[component valueForKey:@"type"] isEqualToString:@"administrative_area_level_1"]) {
                                                         ttPlace.state = [component valueForKey:@"name"];
                                                     }
                                                     else if ([[component valueForKey:@"type"] isEqualToString:@"country"]) {
                                                         ttPlace.country = [component valueForKey:@"name"];
                                                     }
                                                     else if ([[component valueForKey:@"type"] isEqualToString:@"administrative_area_level_2"]) {
                                                         ttPlace.admin2 = [component valueForKey:@"name"];
                                                     }
                                                 }
                                                 // Just in case there's no Locality, use the adminArea2
                                                 // Not sure if this is actually possible from Google, they may guarantee a locality..
                                                 if (ttPlace.city == nil){
                                                     ttPlace.city = ttPlace.admin2;
                                                 }
                                                 
                                                 return completionBlock(ttPlace, nil);
                                             }
                                             else {
                                                 NSLog(@"No place details for %@", location.gpID);
                                                 return completionBlock(nil, nil);
                                             }
    }];
}

- (void)reportPhoto:(Photo *)photo withReason:(NSString *)reason {
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = NSLocalizedString(@"Submitting...",@"Submitting...");
        HUD.mode = MBProgressHUDModeText; // change to Determinate to show progress
    });
    
    PFObject *report = [PFObject objectWithClassName:@"ReportPhoto"];
    [report setObject:photo forKey:@"photo"];
    [report setValue:reason forKey:@"reason"];
    [report setObject:[PFUser currentUser] forKey:@"user"];
    [report saveInBackground];
    [TTAnalytics reportPhoto];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Hide HUD spinner
        HUD.labelText = NSLocalizedString(@"Submitted!",@"Submitted!");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        });
    });
    
}


#pragma mark - Facebook Photo Upload

- (void)initFacebookUpload:(Photo *)photo {
    
    NSDictionary *photoDetails;
    if(photo[@"videoUrl"]){
        if([photo[@"caption"] isEqualToString:@"Type Photo/video Caption Here"])
            photo[@"caption"] = @"";
        
        photoDetails = @{
                        @"caption" : photo[@"caption"] ? photo[@"caption"] : @"",
                        @"video.mov" : photo[@"fileData"],
                        @"contentType" : @"video/quicktime",
                        @"title" : @" ",
                        @"description" : photo[@"caption"] ? photo[@"caption"] : @""
                        };
    }else{
        if([photo.caption isEqualToString:@"Type Photo/video Caption Here"])
            photo.caption = @"";
        
        photoDetails = @{
                        @"url" : photo.imageUrl,
                        @"caption" : photo.caption ? photo.caption : @""
                        };
    }
    
    
    if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
        [self uploadPhotosToFacebook:photoDetails];
    } else {
        [PFFacebookUtils logInInBackgroundWithPublishPermissions:@[@"publish_actions"] block:^(PFUser * _Nullable user, NSError * _Nullable error) {
            if (!error) {
                if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
                    [self uploadPhotosToFacebook:photoDetails];
                }else{
                    NSLog(@"User did not give permission to post");
                }
            } else {
                // An error occurred. See: https://developers.facebook.com/docs/ios/errors
                NSLog(@"Error : Requesting \"publish_actions\" permission failed with error : %@", error);
                [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"initFacebookUpload:"];
            }
        }];
    }
}

- (void)uploadPhotosToFacebook:(NSDictionary *)photoDetails {
    
    NSString *graphPath;
    if(photoDetails[@"url"])
        graphPath = @"/me/photos";
    else graphPath = @"/me/videos";
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:graphPath parameters:photoDetails HTTPMethod:@"POST"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if(error){
            NSLog(@"Error uploading to facebook: %@",error);
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"uploadPhotosToFacebook:"];
        }else{
            NSLog(@"Facebook upload result: %@",result);
            [TTAnalytics facebookPhotoUpload];
        }
    }];
}


-(void)appWillTerminate:(NSNotification*)note{
    NSLog(@"appWillTerminate");
    
    NSString *message = NSLocalizedString(@"Successfully upoaded %d/%d photos/videos to the '%@' trunk. However, %d photos/videos did not upload.", @"Successfully upoaded %d/%d photos/videos to the '%@' trunk. However, %d photos/videos did not upload.");
    message = [NSString stringWithFormat:message,self.photoCount,self.totalPhotos,self.tripName,self.totalPhotos-self.photoCount];
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    }

    if(self.photoCount != self.totalPhotos){
        
        NSUserDefaults *uploadError = [NSUserDefaults standardUserDefaults];
        [uploadError setObject:message forKey:@"uploadError"];
        [uploadError setObject:self.trip.objectId forKey:@"currentTripId"];
        [uploadError synchronize];
        
        
        NSLog(@"setting up notification.");
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        localNotification.alertBody = message;
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        self.tripName = nil;
        self.trip = nil;
        self.photoCount = 0;
    }
    [NSThread sleepForTimeInterval:2];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

+(BOOL) checkForUpdate{
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString* appID = infoDictionary[@"CFBundleIdentifier"];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/lookup?bundleId=%@", appID]];
    NSData* data = [NSData dataWithContentsOfURL:url];
    NSDictionary* lookup = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    if ([lookup[@"resultCount"] integerValue] == 1){
        NSString* appStoreVersion = lookup[@"results"][0][@"version"];
        NSString* currentVersion = infoDictionary[@"CFBundleShortVersionString"];
        NSString *condAppStoreVersion = [appStoreVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
        NSString *condCurrentVersion = [currentVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
        
        if([condAppStoreVersion intValue] > [condCurrentVersion intValue]){
            //NSLog(@"Version %@ should be upgraded to %@",currentVersion,appStoreVersion);
            return YES;
        }
    }
    return NO;
}


#pragma mark - Video
+(void)updateVideoViewCount:(NSString*)objectId withCount:(int)count{
    //This is an increment in app however it doesn't use master key
//    //Must send the ID when you swipe otherwise it increments the viewCount on the wrong video
//    PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
//    [query whereKey:@"objectId" equalTo:objectId];
//    
//    [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//        int updatedCount = [object[@"viewCount"] intValue]+count;
//        object[@"viewCount"] = [NSNumber numberWithInt:updatedCount];
//        [object saveEventually:^(BOOL succeeded, NSError * _Nullable error) {
//            if(error)
//                NSLog(@"Error updating viewCount for video: %@ :: Photo: %@ :: message: %@",object[@"video"][@"objectId"],object[@"objectId"],error);
//            else NSLog(@"View count updated for this video: %@",object[@"video"][@"objectId"]);
//        }];
//    }];
    
    //Cloud Code version of increment
    NSDictionary *params = @{
                             @"photoId" : objectId,
                             @"count" : [NSNumber numberWithInt:count]
                             };
    [PFCloud callFunctionInBackground:@"IncrementVideoViewCount" withParameters:params block:^(PFObject *response, NSError *error) {
        if (error) {
            [ParseErrorHandlingController handleError:error];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"updateVideoViewCount:"];
            NSLog(@"view count failed for video: %@",objectId);
        }
        else {
            [[TTUtility sharedInstance] internetConnectionFound];
            NSLog(@"view count updated for video: %@",objectId);
        }
        
    }];
}
@end
