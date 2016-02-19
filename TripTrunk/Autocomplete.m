//
//  Autocomplete.m
//
//  Created by Radu Lucaciu on 8/17/10.
//  Copyright 2010. All rights reserved.
//

#import "Autocomplete.h"


@implementation Autocomplete

- (Autocomplete *)initWithArray:(NSArray *)initialArray
{
	self = [super init];
	if (self)
	{
		candidates = [[NSMutableArray alloc] initWithArray:initialArray];
		[candidates sortUsingSelector:@selector(compare:)];
	}
	
	return self;
}

- (NSMutableArray *)GetSuggestions:(NSString *)root
{
	if ([root length] == 0)
	{
		return candidates;
	}
	
	NSPredicate *startPredicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] %@", root];
	return [NSMutableArray arrayWithArray:[candidates filteredArrayUsingPredicate:startPredicate]];
}

- (void)AddCandidate:(NSString *)candidate
{
	//Is the candidate already in the list?
	for (int i = 0; i < [candidates count]; i++)
	{
		if ([[candidates objectAtIndex:i] isEqualToString:candidate])
		{
			return;
		}
	}
	
	//Add the new candidate
	[candidates addObject:candidate];
	[candidates sortUsingSelector:@selector(compare:)];
}	

@end
