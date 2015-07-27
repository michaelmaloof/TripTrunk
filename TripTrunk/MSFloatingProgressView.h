//
//  MSFloatingProgressView.h
//  TripTrunk
//
//  Created by Matt Schoch on 7/9/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MSFloatingProgressView : UIView

- (id)initWithHeight:(CGFloat)height;

- (int)remainingTasks;

- (void)incrementTaskCount;

- (void)setProgress:(float)progress;

- (void)addToWindow;

- (void)removeFromWindow;

- (BOOL)taskCompleted;

@end