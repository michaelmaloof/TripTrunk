//
//  MSFloatingProgressView.m
//  TripTrunk
//
//  Created by Matt Schoch on 7/9/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "MSFloatingProgressView.h"

@implementation MSFloatingProgressView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)init {
    CGRect rect = CGRectMake(0, 64, [[UIScreen mainScreen] bounds].size.width, 40);
    self = [super initWithFrame:rect];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setupUI];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setupUI];
    }
    return self;
}


- (id)initWithHeight:(CGFloat)height {
    CGRect rect = CGRectMake(0, 64, [[UIScreen mainScreen] bounds].size.width, height);
    self = [super initWithFrame:rect];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    //Add cancel/close button
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 40, 0, 40, 40)];
    [closeButton setTitle:@"X" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];

    [self addSubview:closeButton];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 100, 20)];
    [titleLabel setText:@"Uploading..."];
    [titleLabel setTextColor:[UIColor blackColor]];
    [self addSubview:titleLabel];
    
    //TODO: Implement the actual progress bar
}

- (void)setProgress:(CGFloat)progress {
    //TODO: implement methods for updating the progress view
    
}



@end
