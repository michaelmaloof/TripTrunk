//
//  Photo.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>
#import <Photos/Photos.h>
#import "Trip.h"

@interface Photo : PFObject <PFSubclassing>
@property (nonatomic) NSDate *createdAt;
@property NSInteger likes;
@property Trip *trip;
@property PFUser *user;
@property NSString *tripName;
@property NSString *caption;
@property NSString *fbID;
@property BOOL favorite;
@property NSMutableArray *usersWhoHaveLiked;
@property NSString *city;
@property NSString *userName;
@property NSString *imageUrl;
@property PFObject *video;
@property NSString *editedPath;

/**
 *  Transient image property. This doesn't get saved to Parse, it's used so that we can keep the Image itself with the object after downloading from the URL
 */
@property UIImage *image;
@property PHAsset *imageAsset;


@end
