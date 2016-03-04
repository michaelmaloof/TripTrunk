//
//  TTUserProfileImage.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/25/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTUserProfileImage.h"

@implementation TTUserProfileImage

-(id)initWithCoder:(NSCoder *)aDecoder{
    if(self == [super initWithCoder:aDecoder]){
        self.layer.cornerRadius = 19;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 0;
    }
    
    return self;
}
@end
