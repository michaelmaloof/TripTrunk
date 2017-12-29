//
//  TTPhotoViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 9/21/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "TTBaseViewController.h"

@protocol PhotoDelegate
@optional
-(void)photoWasLiked:(BOOL)isFromError;
-(void)photoWasDeleted:(NSNumber*)likes photo:(Photo*)photo;
-(void)photoWasViewed:(Photo*)photo;
//-(void)captionWasAdded:(NSString*)caption;
//-(void)dissmissWasTapped:(NSArray*)mainPhotos;
@end

@interface TTPhotoViewController : TTBaseViewController
@property id<PhotoDelegate> delegate;
@property (strong, nonatomic) Photo *photo;
@property (strong, nonatomic) UIImage *image;
@property int index;
@property (strong, nonatomic) NSArray *photos;
@end
