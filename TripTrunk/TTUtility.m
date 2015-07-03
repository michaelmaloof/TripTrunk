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

#define CLOUDINARY_URL @"cloudinary://334349235853935:YZoImSo-gkdMtZPH3OJdZEOvifo@triptrunk"

@interface TTUtility () <MBProgressHUDDelegate>{
    MBProgressHUD *HUD;
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

#pragma mark - Cloudinary CLUploaderDelegate

- (void) uploaderSuccess:(NSDictionary*)result context:(id)context {
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

- (void) uploaderProgress:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite context:(id)context {
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



@end
