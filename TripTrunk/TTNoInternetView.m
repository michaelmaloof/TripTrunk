//
//  TTNoInternetView.m
//  Pods
//
//  Created by Michael Maloof on 3/5/16.
//
//

#import "TTNoInternetView.h"
#import "TTColor.h"

@interface TTNoInternetView ()
@property (strong, nonatomic)UIProgressView *progressView;
@property (strong, nonatomic)UILabel *titleLabel;

@end

@implementation TTNoInternetView


- (id)init {
    CGRect rect = CGRectMake(0, 64, [[UIScreen mainScreen] bounds].size.width, 30);
    self = [super initWithFrame:rect];
    if (self) {
        [self setBackgroundColor:[TTColor tripTrunkCoral]];
        [self setupUI];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[TTColor tripTrunkCoral]];
        [self setupUI];
    }
    return self;
}


- (id)initWithHeight:(CGFloat)height {
    CGRect rect = CGRectMake(0, 64, [[UIScreen mainScreen] bounds].size.width, height);
    self = [super initWithFrame:rect];
    if (self) {
        [self setBackgroundColor:[TTColor tripTrunkWhite]];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [_titleLabel setFont:[UIFont systemFontOfSize:15]];
    [_titleLabel setTextColor:[TTColor tripTrunkWhite]];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleLabel setText:@"No Internet Connection"];
    [self addSubview:_titleLabel];
}

- (void)cancelButtonPressed {
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


