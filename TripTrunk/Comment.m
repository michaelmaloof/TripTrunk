//
//  Comment.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/30/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "Comment.h"

@implementation Comment
@dynamic user;
@dynamic comment;
@dynamic datePosted;
@dynamic photo;
@dynamic trip;
@dynamic city;

+(NSString *)parseClassName
{
    return @"Comment";
}


+(void)load
{
    [self registerSubclass];
}

@end
