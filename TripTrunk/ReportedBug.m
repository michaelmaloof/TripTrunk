//
//  ReportedBug.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "ReportedBug.h"

@implementation ReportedBug
@dynamic email;
@dynamic bug;
@dynamic version;
@dynamic user;
@dynamic isKnownAbout;
@dynamic isFixed;

+(NSString *)parseClassName
{
    return @"ReportedBug";
}


+(void)load
{
    [self registerSubclass];
}

@end