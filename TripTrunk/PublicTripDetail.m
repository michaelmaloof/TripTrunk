//
//  PublicTripDetail.m
//  TripTrunk
//
//  Created by Michael Maloof on 11/18/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "PublicTripDetail.h"

@implementation PublicTripDetail
@dynamic mostRecentPhoto;
@dynamic photoCount;
@dynamic totalLikes;
@dynamic trip;
@dynamic memberCount;

+(NSString *)parseClassName
{
    return @"PublicTripDetail";
}


+(void)load
{
    [self registerSubclass];
}

@end
