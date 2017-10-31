//
//  TTPassthroughCollectionView.m
//  TripTrunk
//
//  Created by Michael Cannell on 10/27/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTPassthroughCollectionView.h"

@implementation TTPassthroughCollectionView

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
}

@end
