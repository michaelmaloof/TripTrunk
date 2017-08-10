//
//  TTTimelinePhotoCellCollectionViewCell.m
//  TripTrunk
//
//  Created by Michael Cannell on 7/28/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTTimelinePhotoCellCollectionViewCell.h"

@implementation TTTimelinePhotoCellCollectionViewCell

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    
    return self;
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.dateView.hidden = YES;
    self.month.hidden = YES;
    self.imageView.image = [UIImage imageNamed:@"tt_square_placeholder"];
}

@end
