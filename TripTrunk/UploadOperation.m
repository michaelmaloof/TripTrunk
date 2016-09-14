//
//  UploadOperation.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/14/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "UploadOperation.h"

@interface UploadOperation () {
    BOOL _finished;
    BOOL _executing;
}

@property (nonatomic, copy) AsyncBlock block;

@end

@implementation UploadOperation

+ (instancetype)asyncBlockOperationWithBlock:(AsyncBlock)block {
    return [[UploadOperation alloc] initWithAsyncBlock:block];
}

- (instancetype)initWithAsyncBlock:(AsyncBlock)block {
    if (self = [super init]) {
        self.block = block;
    }
    return self;
}

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    self.block(^{
        [self willChangeValueForKey:@"isExecuting"];
        _executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    });
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isExecuting {
    return _executing;
}

- (BOOL)isAsynchronous {
    return YES;
}

@end
