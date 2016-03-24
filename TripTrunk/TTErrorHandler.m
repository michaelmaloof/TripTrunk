//
//  TTErrorHandler.m
//  TripTrunk
//
//  Created by Michael Cannell on 3/24/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTErrorHandler.h"
#import "TTCache.h"

@implementation TTErrorHandler

+(void)errorLikingPhoto:(Photo*)photo{
    [[TTCache sharedCache] decrementLikerCountForPhoto:photo];
}

+(void)errorUnlikingPhoto:(Photo*)photo{
    [[TTCache sharedCache] incrementLikerCountForPhoto:photo];
}


@end
