//
//  TTHashtagMentionColorization.h
//  TripTrunk
//
//  Created by Michael Cannell on 3/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTHashtagMentionColorization : NSObject

+(NSMutableAttributedString*)colorHashtagAndMentions:(NSUInteger)cursorPosition text:(NSString*)text;
+(NSArray*)extractUsernamesFromComment:(NSString*)text;

@end
