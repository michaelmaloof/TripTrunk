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
#import "MSFloatingProgressView.h"

#define CLOUDINARY_URL @"cloudinary://334349235853935:YZoImSo-gkdMtZPH3OJdZEOvifo@triptrunk"

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
        
    }
    return self;
}


- (void)uploadPhoto:(Photo *)photo withImageData:(NSData *)imageData;
{
    CLUploader *uploader = [[CLUploader alloc] init:cloudinary delegate:self];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
            HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
            HUD.labelText = @"Uploading Memories";
            HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress

    });
    [uploader upload:imageData
             options:@{@"type":@"upload"}
      withCompletion:^(NSDictionary *successResult, NSString *errorResult, NSInteger code, id context) {
          if (successResult) {
              NSString* publicId = [successResult valueForKey:@"public_id"];
              NSLog(@"Block upload success. Public ID=%@, Full result=%@", publicId, successResult);
              NSString* url = [successResult valueForKey:@"url"];

              photo.imageUrl = url;
              
              [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                  
                  if(error) {
                      NSLog(@"error saving photo to parse: %@", error);
                  }
                  else {
                      NSLog(@"Saved Successfully to parse");
                      // post the notification so that the TrunkViewController can know to reload the data
                      [[NSNotificationCenter defaultCenter] postNotificationName:@"parsePhotosUpdatedNotification" object:nil];
                  }
              }];
              
          } else {
              NSLog(@"Block upload error: %@, %li", errorResult, (long)code);
              
          }
          
      } andProgress:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite, id context) {

          
      }];
    
}

- (void)downloadPhoto:(Photo *)photo;
{
    // Show HUD spinner
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = @"Downloading";
        HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress
    });
    
    AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:photo.imageUrl]]];
    [request setResponseSerializer: [AFImageResponseSerializer serializer]];
    [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject) {
            UIImage *image = (UIImage *)responseObject;
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Hide HUD spinner
                HUD.labelText = @"Complete!";
                [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
                
            });

        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error downloading photo");
    }];
    [request start];
}

- (void)downloadPhotos:(NSArray *)photos;
{
    // Show HUD spinner
    dispatch_async(dispatch_get_main_queue(), ^{
        HUD = [MBProgressHUD showHUDAddedTo:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        HUD.labelText = [NSString stringWithFormat:@"Downloading 1 of %lu", (unsigned long)photos.count];
        HUD.mode = MBProgressHUDModeIndeterminate; // change to Determinate to show progress
    });
    
    __block int completedDownloads = 0;
    for (Photo *photo in photos) {
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
                        HUD.labelText = @"Complete!";
                        [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        HUD.labelText = [NSString stringWithFormat:@"Downloading %i of %lu", completedDownloads + 1, (unsigned long)photos.count];
                    });
                }

            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error downloading photo");
        }];
        [request start];
    }
    
}

- (NSString *)thumbnailImageUrl:(NSString *)urlString;
{
    CLTransformation *transformation = [CLTransformation transformation];
    [transformation setWidthWithInt: 160];
    [transformation setHeightWithInt: 160];
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
    
    // Hide HUD spinner
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
        [HUD hide:YES];
    });
}

-(void)uploaderError:(NSString *)result code:(NSInteger)code context:(id)context {
    NSLog(@"Upload error: %@, %ld", result, (long)code);
    
    // Hide HUD spinner
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:[[[UIApplication sharedApplication] delegate] window] animated:YES];
    });
}

- (void)uploaderProgress:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite context:(id)context {
    float divide = (float)totalBytesWritten/(float)totalBytesExpectedToWrite;
    NSString *string =  [NSString stringWithFormat:@"written:%ld    totalwritten:%ld    expectedToWrite:%ld   divided:%f", (long)bytesWritten, (long)totalBytesWritten, (long)totalBytesExpectedToWrite, divide];
    NSLog(@"%@", string);
    HUD.progress = divide;
}


#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    HUD = nil;
}

- (void)addUploaderProgressView {
    
    progressView = [[MSFloatingProgressView alloc] init];
    
    // Add the progress bar to the Window so it should stay up front
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[[UIApplication sharedApplication] delegate] window] addSubview:progressView];

    });
}

- (void)removeUploaderProgressView {
    //TODO: This doesn't work
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView removeFromSuperview];
    });
    progressView = nil;
}

@end
