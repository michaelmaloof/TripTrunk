//
//  Excursion.m
//  TripTrunk
//
//  Created by Michael Cannell on 8/11/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "Excursion.h"

@implementation Excursion

@dynamic creator;
@dynamic trip;
@dynamic trunk;
@dynamic homeAtCreation;

+(NSString *)parseClassName
{
    return @"Excursion";
}


+(void)load
{
    [self registerSubclass];
}

@end

