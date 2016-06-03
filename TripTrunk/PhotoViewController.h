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
@optional
-(void)photoWasLiked:(BOOL)isFromError;
-(void)photoWasDisliked:(BOOL)isFromError;
-(void)photoWasDeleted:(NSNumber*)likes photo:(Photo*)photo;
-(void)photoWasViewed:(Photo*)photo;
-(void)captionWasAdded:(NSString*)caption;
@end

@interface PhotoViewController : TTBaseViewController
@property Photo *photo; //mattschoch 6/10 - added so that we can pass in the image directly instead of downloading it again
@property (strong, nonatomic) NSArray *trunkMembers;
@property Trip *trip;
@property NSArray *photos;
@property NSArray *trunkAlbum;
@property int arrayInt;
@property id<PhotoDelegate> delegate;
@property BOOL fromNotification;
@property BOOL fromTimeline;
@property BOOL fromProfile;
@property BOOL fromAddPhotosViewController;

-(void)captionButtonTapped:(int)button caption:(NSString*)text;

@end
