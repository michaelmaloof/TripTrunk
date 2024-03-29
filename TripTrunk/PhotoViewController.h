//
//  PhotoViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/29/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "Trip.h"
#import "TTBaseViewController.h"

@protocol PhotoDelegate
-(void)photoWasLiked:(id)sender;
-(void)photoWasDisliked:(id)sender;
-(void)photoWasDeleted:(NSNumber*)likes;



@end

@interface PhotoViewController : TTBaseViewController
@property Photo *photo; //mattschoch 6/10 - added so that we can pass in the image directly instead of downloading it again

@property Trip *trip;

@property NSArray *photos;
@property NSArray *trunkAlbum;
@property NSInteger arrayInt;
@property id<PhotoDelegate> delegate;

-(void)captionButtonTapped:(int)button caption:(NSString*)text;


@end
