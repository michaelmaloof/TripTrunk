//
//  Autocomplete.m
//
//  Created by Radu Lucaciu on 8/17/10.
//  Copyright 2010. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Autocomplete : NSObject
{
	NSMutableArray *candidates;
}

- (Autocomplete *)initWithArray:(NSArray *)initialArray;
- (NSMutableArray *)GetSuggestions:(NSString *)root;
- (void)AddCandidate:(NSString *)candidate;

@end
