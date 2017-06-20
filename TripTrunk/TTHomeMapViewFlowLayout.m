//
//  TTHomeMapViewFlowLayout.m
//  TripTrunk
//
//  Created by Michael Cannell on 6/19/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTHomeMapViewFlowLayout.h"


@implementation TTHomeMapViewFlowLayout

- (void)awakeFromNib{
    [super awakeFromNib];
    self.itemSize = CGSizeMake(300.0, 350.0);
    self.minimumLineSpacing = 10.0;
    self.minimumInteritemSpacing = 10.0;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.sectionInset = UIEdgeInsetsMake(0.0, 37.0, 0.0, 37.0);
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGFloat approximatePage = self.collectionView.contentOffset.y / self.pageHeight;
    CGFloat currentPage = (velocity.y < 0.0) ? floor(approximatePage) : ceil(approximatePage);
    
    NSInteger flickedPages = ceil(velocity.y / self.flickVelocity);
    
    if (flickedPages)
        proposedContentOffset.y = (currentPage + flickedPages) * self.pageHeight;
    else proposedContentOffset.y = currentPage * self.pageHeight;
    
    return proposedContentOffset;
}

- (CGFloat)pageHeight {
    return self.itemSize.height + self.minimumLineSpacing;
}

- (CGFloat)flickVelocity {
    return 1.2;
}

@end
