//
//  Photo.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "Photo.h"

@implementation Photo
@dynamic createdAt;
@dynamic likes;
@dynamic imageFile;
@dynamic user;
@dynamic name;
@dynamic caption;
@dynamic fbID;
@dynamic favorite;
@dynamic usersWhoHaveLiked;


+(NSString *)parseClassName
{
    return @"Photo";
}


+(void)load
{
    [self registerSubclass];
}

@end
