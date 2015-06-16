//
//  Utility.m
//  TripTrunk
//
//  Created by Matt Schoch on 6/7/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TTUtility.h"

#define CLOUDINARY_URL @"cloudinary://831333642159488:Dn_JFKToHLc_wXPi1qnkXQJrAtc@mattschoch"

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
    CLUploader* uploader = [[CLUploader alloc] init:cloudinary delegate:self];
    

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

#pragma mark - Cloudinary CLUploaderDelegate

- (void) uploaderSuccess:(NSDictionary*)result context:(id)context {
    NSString* publicId = [result valueForKey:@"public_id"];
    NSLog(@"Upload success. Public ID=%@, Full result=%@", publicId, result);
}

-(void)uploaderError:(NSString *)result code:(NSInteger)code context:(id)context {
    NSLog(@"Upload error: %@, %ld", result, (long)code);
}

- (void) uploaderProgress:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite context:(id)context {
    
    NSLog(@"Upload progress: %ld/%ld (+%ld)", (long)totalBytesWritten, (long)totalBytesExpectedToWrite, (long)bytesWritten);
}




@end
