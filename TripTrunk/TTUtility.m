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
#import "TTCache.h"
#import "SocialUtility.h"
#import <CoreText/CoreText.h>


#define CLOUDINARY_URL @"cloudinary://334349235853935:YZoImSo-gkdMtZPH3OJdZEOvifo@triptrunk"

static TTTTimeIntervalFormatter *timeFormatter;

@interface TTUtility () <MBProgressHUDDelegate>{
    MBProgressHUD *HUD;
    MSFloatingProgressView *progressView;
}

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
                      NSLog(@"error saving user to parse: %@", error);
                  }
                  else {
                      NSLog(@"Saved Successfully to parse");
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

- (void)uploadPhoto:(Photo *)photo withImageData:(NSData *)imageData;
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
              NSString* publicId = [successResult valueForKey:@"public_id"];
              NSLog(@"Block upload success. Public ID=%@, Full result=%@", publicId, successResult);
              NSString* url = [successResult valueForKey:@"url"];

              photo.imageUrl = url;
              
              PFACL *photoACL = [PFACL ACLWithUser:[PFUser currentUser]];
              
              // Friends of the user get Read Access
              NSString *roleName = [NSString stringWithFormat:@"friendsOf_%@", [[PFUser currentUser] objectId]];
              [photoACL setReadAccess:YES forRoleWithName:roleName];
              // Also add ReadAccess for the TRUNK MEMBER role so any members of the trunk get read access
              NSString *trunkRole = [NSString stringWithFormat:@"trunkMembersOf_%@", photo.trip.objectId];
              [photoACL setReadAccess:YES forRoleWithName:trunkRole];
              
              // Only the user and trunk creator gets Write Access
              [photoACL setWriteAccess:YES forUser:photo.user];
              [photoACL setWriteAccess:YES forUser:photo.trip.creator];

              
              
              // If it's a private user, then don't give PublicReadAccess for this photo - only Members and Followers can see it.
              NSLog(@"Private value: %@", [[PFUser currentUser] objectForKey:@"private"]);
              if ([[[PFUser currentUser] objectForKey:@"private"] boolValue]) {
                  [photoACL setPublicReadAccess:NO];
                  NSLog(@"Set private photo read permissions - role name: %@", roleName);
              }
              else {
                  [photoACL setPublicReadAccess:YES];
              }
              
              // Set the ACL.
              photo.ACL = photoACL;
              
              [photo saveEventually:^(BOOL succeeded, NSError *error) {
                  
                  if(error) {
                      NSLog(@"error saving photo to parse: %@", error);
                      
                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error saving Photo"
                                                                      message:@"Please try again"
                                                                     delegate:self
                                                            cancelButtonTitle:@"Okay"
                                                            otherButtonTitles:nil, nil];
                      
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alert show];
                    });
                  }
                  else {
                      // Add photo to the cache
                      [[TTCache sharedCache] setAttributesForPhoto:photo likers:[NSArray array] commenters:[NSArray array] likedByCurrentUser:NO];
                      
                      // If the photo had a caption, add the caption as a comment so it'll show up as the first comment, like Instagram does it.
                      if (photo.caption && ![photo.caption isEqualToString:@""]) {
                          [SocialUtility addComment:photo.caption forPhoto:photo isCaption:YES block:^(BOOL succeeded, PFObject *object, NSError *error) {
                        
                            NSLog(@"caption saved as comment");
                          }];
                      }
                      
                      
                      NSLog(@"Saved Successfully to parse");
                      // post the notification so that the TrunkViewController can know to reload the data
                      [[NSNotificationCenter defaultCenter] postNotificationName:@"parsePhotosUpdatedNotification" object:nil];
                      

                      [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                      bgTask = UIBackgroundTaskInvalid;
                  }
              }];
              
          } else {
              NSLog(@"Block upload error: %@, %li", errorResult, (long)code);
              [[UIApplication sharedApplication] endBackgroundTask:bgTask];
              bgTask = UIBackgroundTaskInvalid;
          }
          
      } andProgress:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite, id context) {

          
      }];
    
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
        
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    [request start];
}

- (void)downloadPhotos:(NSArray *)photos;
{
    

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
        
        AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:photo.imageUrl]]];
        [request setResponseSerializer: [AFImageResponseSerializer serializer]];
        [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (responseObject) {
                // Save image to phone
                UIImageWriteToSavedPhotosAlbum((UIImage *)responseObject, nil, nil, nil);
                NSLog(@"saved a photo");

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
            [[UIApplication sharedApplication] endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        [request start];
    }
    
}

- (void)deletePhoto:(Photo *)photo;
{
    // If the user isn't the trip nor photo creator, don't let them delete this trip
    if (![[[PFUser currentUser] objectId] isEqualToString:photo.user.objectId] && ![[[PFUser currentUser] objectId] isEqualToString:photo.trip.creator.objectId]) {
        return;
    }
    
    // Delete any activities that directly references this photo
    // That SHOULD include all like, and comment activities
    PFQuery *deleteActivitiesQuery = [PFQuery queryWithClassName:@"Activity"];
    [deleteActivitiesQuery whereKey:@"photo" equalTo:photo];
    
    [deleteActivitiesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             // The find succeeded.
             // Delete the found objects
             for (PFObject *object in objects) {
                 [object deleteEventually];
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"ActivityObjectsDeleted" object:nil];
             
         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];
    
    [photo deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"parsePhotosUpdatedNotification" object:nil];
    }];
    
  
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
//    NSLog(@"screen size: %f x %f", screenWidth, screenHeight);
    
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

#pragma mark - Cloudinary CLUploaderDelegate

- (void)uploaderSuccess:(NSDictionary*)result context:(id)context {
    NSString* publicId = [result valueForKey:@"public_id"];
    NSLog(@"Upload success. Public ID=%@, Full result=%@", publicId, result);

    // Mark the task as completed in the progressview -- if all uploads are finished, it will remove from the screen
    if ([progressView taskCompleted]) {
        // Uploading is totally complete, so nil the progress view
        progressView = nil;
    }
}

-(void)uploaderError:(NSString *)result code:(NSInteger)code context:(id)context {
    NSLog(@"Upload error: %@, %ld", result, (long)code);
    
    // Get rid of the progress view
 if ([progressView taskCompleted])
 {
    [progressView removeFromWindow];
     progressView = nil;
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
    
    if ([type isEqualToString:@"like"]) {
        content = NSLocalizedString(@"liked your photo.",@"liked your photo.");
    }
    else if ([type isEqualToString:@"comment"]) {
        NSString *commented = NSLocalizedString(@"commented on your photo",@"commented on your photo");
        content = [NSString stringWithFormat:@"%@: %@", commented,activity[@"content"]];
    }
    else if ([type isEqualToString:@"addToTrip"]) {
        if (activity[@"trip"] && [activity[@"trip"] valueForKey:@"name"]) {
            NSString *added = NSLocalizedString(@"added you to the trunk",@"added you to the trunk");
            content = [NSString stringWithFormat:@"%@ %@", added,[activity[@"trip"] valueForKey:@"name"]];
        }
        else {
            content =  NSLocalizedString(@"added you to a trip.",@"added you to a trip.");
        }
    }
    else if ([type isEqualToString:@"follow"]) {
        content = NSLocalizedString(@"followed you.",@"followed you.");
    }
    else if ([type isEqualToString:@"addedPhoto"]) {
        NSString *addedPhoto = NSLocalizedString(@"added a photo to",@"added a photo to");
        content = [NSString stringWithFormat:@"%@ %@",addedPhoto, [activity[@"trip"] valueForKey:@"name"]];
    }
    else if ([type isEqualToString:@"pending_follow"]) {
        content =  NSLocalizedString(@"requested to follow you.",@"requested to follow you.");
    }
    
    PFUser *user = activity[@"fromUser"];
    NSString *time = @"";

    if ([activity valueForKey:@"createdAt"]) {
        NSDate *created = [activity valueForKey:@"createdAt"];
        time = [timeFormatter stringForTimeIntervalFromDate:[NSDate date] toDate:created];
    }
    
    NSString *contentString = [NSString stringWithFormat:@"%@ %@ ", user.username, content];

    NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
    

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:contentString
                                                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14],
                                                                                         NSParagraphStyleAttributeName: paraStyle,
                                                                                         NSKernAttributeName : [NSNull null]
                                                                                         }];
    
    NSAttributedString *timeStr = [[NSAttributedString alloc] initWithString:time
                                                                  attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:11],
                                                                               NSParagraphStyleAttributeName: paraStyle,
                                                                               NSKernAttributeName : [NSNull null],
                                                                               (id)kCTForegroundColorAttributeName : (id)[UIColor grayColor].CGColor
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
    
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:contentString
                                                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14],
                                                                                         NSParagraphStyleAttributeName: paraStyle,
                                                                                         NSKernAttributeName : [NSNull null]
                                                                                         }];
    
    NSAttributedString *timestampStr = [[NSAttributedString alloc] initWithString:time
                                                                  attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:11],
                                                                               NSParagraphStyleAttributeName: paraStyle,
                                                                               NSKernAttributeName : [NSNull null],
                                                                               (id)kCTForegroundColorAttributeName : (id)[UIColor grayColor].CGColor
                                                                               }];
    [str appendAttributedString:timestampStr];
    return str;
}

- (void)locationsForSearch:(NSString *)str block:(void (^)(NSArray *objects, NSError *error))completionBlock {
    
    NSString *urlString = [NSString stringWithFormat:@"http://gd.geobytes.com/AutoCompleteCity?&q=%@", str];
    NSString *encodedString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];

    
    AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:encodedString]]];
    [request setResponseSerializer: [AFJSONResponseSerializer serializer]];

    [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject) {
            NSArray *response = (NSArray *)responseObject;
            return completionBlock(response, nil);
        }
        return completionBlock(nil, nil);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error searching for location");
        return completionBlock(nil, error);
    }];
    
    [request start];
}

- (void)locationDetailsForLocation:(NSString *)str block:(void (^)(NSDictionary *locationDetails, NSError *error))completionBlock {
    
    NSString *urlString = [NSString stringWithFormat:@"http://getcitydetails.geobytes.com/GetCityDetails?fqcn=%@", str];
    
    NSString *encodedString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:encodedString]]];
    
    [request setResponseSerializer: [AFJSONResponseSerializer serializer]];
    
    [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject) {
            NSDictionary *response = (NSDictionary *)responseObject;
            
            return completionBlock(response, nil);
        }
        return completionBlock(nil, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error searching for location");
        return completionBlock(nil, error);
    }];
    
    [request start];
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Hide HUD spinner
        HUD.labelText = NSLocalizedString(@"Submitted!",@"Submitted!");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        });
    });
    
}





@end
