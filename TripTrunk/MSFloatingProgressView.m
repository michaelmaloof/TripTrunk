//
//  MSFloatingProgressView.m
//  TripTrunk
//
//  Created by Matt Schoch on 7/9/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "MSFloatingProgressView.h"
#import "TTColor.h"
#import "TTFont.h"

@interface MSFloatingProgressView ()
@property (strong, nonatomic)UIProgressView *progressView;
@property (strong, nonatomic)UILabel *titleLabel;
@property (nonatomic)int taskCount;
@property (nonatomic)int completedTaskCount;

@end

@implementation MSFloatingProgressView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)init {
    CGRect rect = CGRectMake(0, 64, [[UIScreen mainScreen] bounds].size.width, 30);
    self = [super initWithFrame:rect];
    if (self) {
        _taskCount = 1;
        _completedTaskCount = 0;
        [self setBackgroundColor:[TTColor tripTrunkBlue]];
        [self setupUI];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _taskCount = 1;
        _completedTaskCount = 0;
        [self setBackgroundColor:[TTColor tripTrunkBlue]];
        [self setupUI];
    }
    return self;
}


- (id)initWithHeight:(CGFloat)height {
    CGRect rect = CGRectMake(0, 64, [[UIScreen mainScreen] bounds].size.width, height);
    self = [super initWithFrame:rect];
    if (self) {
        _taskCount = 1;
        _completedTaskCount = 0;
        [self setBackgroundColor:[TTColor tripTrunkWhite]];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
//    //Add cancel/close button
//    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 40, 0, 40, 40)];
//    [closeButton setTitle:@"X" forState:UIControlStateNormal];
//    [closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    [closeButton addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//
//    [self addSubview:closeButton];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, 20)];
    [_titleLabel setFont:[TTFont tripTrunkFont8]];
    [_titleLabel setTextColor:[TTColor tripTrunkBlack]];
    [self addSubview:_titleLabel];
    [self updateLabel:_completedTaskCount + 1 of:_taskCount];
    
    //TODO: Implement the actual progress bar UI
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 10, self.frame.size.width, 2)];
    [_progressView setProgressTintColor:[TTColor tripTrunkWhite]];
    [self addSubview:_progressView];
}

- (void)updateLabel:(int)current of:(int)total {
    self.titleLabel.textColor = [TTColor tripTrunkWhite];
    [_titleLabel setText:[NSString stringWithFormat:@"Uploading %i of %i", current, total]];
}

- (void)cancelButtonPressed {
}

- (void)incrementTaskCount {
    _taskCount++;
    [self updateLabel:_completedTaskCount + 1 of:_taskCount];
}

- (int)remainingTasks {
    return _taskCount - _completedTaskCount;
}

- (void)setProgress:(float)progress {
    // Progress can't go down, so only set progress if either the current progress is already complete (meaning a previous task is done) or the progress is an increase
    if (_progressView.progress >= 1 || _progressView.progress < progress) {
        [_progressView setProgress:progress];
    }
}

- (BOOL)taskCompleted {
    _completedTaskCount++;
    [self setProgress:0];
        
    if (_completedTaskCount == _taskCount) {
        [self removeFromWindow];
        return true;
    }
    else {
        [self updateLabel:_completedTaskCount + 1 of:_taskCount];
    }
    return false;

}

- (void)addToWindow {
    // Add the progress bar to the Window so it should stay up front
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[[UIApplication sharedApplication] delegate] window] addSubview:self];
    });
}

- (void)removeFromWindow {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeFromSuperview];
    });
}


@end
