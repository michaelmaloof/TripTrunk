//
//  UploadOperation.h
//  TripTrunk
//
//  Created by Matt Schoch on 9/14/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AsyncBlock)(dispatch_block_t completionHandler);

@interface UploadOperation : NSOperation


@property (nonatomic, readonly, copy) AsyncBlock block;

+ (instancetype)asyncBlockOperationWithBlock:(AsyncBlock)block;

- (instancetype)initWithAsyncBlock:(AsyncBlock)block;

@end
