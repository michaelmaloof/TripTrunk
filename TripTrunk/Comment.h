//
//  Comment.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/30/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>

@interface Comment : PFObject <PFSubclassing>
@property NSString *comment;
@property NSString *user;
@property NSDate *datePosted;
@property NSString *photo;
@property NSString *trip;
@property NSString *city;

@end
