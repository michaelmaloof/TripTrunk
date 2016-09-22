//
//  TTPlace.m
//  TripTrunk
//
//  Created by Matt Schoch on 9/20/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTPlace.h"



@implementation TTPlace
@dynamic name;
@dynamic city;
@dynamic state;
@dynamic country;
@dynamic gpID;
@dynamic admin2;
@dynamic latitude;
@dynamic longitude;


//+ (NSDictionary *)dictionary
//{
//    return @{@"name": self.name};
//}

+ (NSString *)parseClassName
{
    return @"TTPlace";
}


+ (void)load
{
    [self registerSubclass];
}


@end
