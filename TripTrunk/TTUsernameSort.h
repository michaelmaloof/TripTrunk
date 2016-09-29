//
//  TTUsernameSort.h
//  TripTrunk
//
//  Created by Michael Cannell on 9/29/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTUsernameSort : NSObject
-(NSMutableArray*)sortResultsByUsername:(NSArray*)results searchTerm:(NSString*)searchTerm;
@end
