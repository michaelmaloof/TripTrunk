//
//  DLFPhotoCell.m
//  PhotosPicker
//
//  Created by  on 11/26/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "DLFPhotoCell.h"

@interface DLFPhotoCell ()

@property (nonatomic, weak) UIView *highlightedView;
@property (nonatomic, strong) UIImageView *imageHolder;
@property int size;
@end

@implementation DLFPhotoCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [UIImageView new];
        self.imageHolder = [UIImageView new];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.imageView setClipsToBounds:YES];
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    if (_thumbnailImage != thumbnailImage) {
        _thumbnailImage = thumbnailImage;
        self.imageView.image = thumbnailImage;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (!self.highlightedView) {
        UIView *view = [[UIView alloc] initWithFrame:self.imageView.frame];
        [view setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8]];
        [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
//        [view.layer setBorderColor:[UIColor redColor].CGColor];
//        [view.layer setBorderWidth:5];
        UIImage *image = [UIImage imageNamed:@"checkmark"];
        self.size = image.size.width*0.75;
        self.imageHolder = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.size, self.size)];
        self.imageHolder.image = image;
        [view addSubview:self.imageHolder];
        view.hidden = YES;
        [self.contentView addSubview:view];
        self.highlightedView = view;
    }
    [self.highlightedView setHidden:!highlighted];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.imageView setFrame:self.contentView.bounds];
    [self.highlightedView setFrame:self.imageView.frame];
    [self.imageHolder setFrame:CGRectMake(self.imageView.frame.size.width-self.size-5, self.imageView.frame.size.height-self.size-5, self.size, self.size)];
}

@end
