//
//  TTUsernameSort.m
//  TripTrunk
//
//  Created by Michael Cannell on 9/29/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTUsernameSort.h"
#import <Parse/Parse.h>

@implementation TTUsernameSort

//FIXME: There has to be a better way to do this!!!
-(NSMutableArray*)sortResultsByUsername:(NSArray*)results searchTerm:(NSString*)searchTerm{
    NSMutableArray *matches = [[NSMutableArray alloc] init];
    NSMutableArray *usernames = [[NSMutableArray alloc] init];
    NSMutableArray *firstNames = [[NSMutableArray alloc] init];
    NSMutableArray *lastNames = [[NSMutableArray alloc] init];
    searchTerm = [searchTerm lowercaseString];
    for(PFUser *user in results){
        if([[user.username lowercaseString] hasPrefix:searchTerm]){
            [matches addObject:user];
        }else if([user.username containsString:searchTerm]){
            [usernames addObject:user];
        }else if([user[@"firstNameLowercase"] containsString:searchTerm]){
            [firstNames addObject:user];
        }else if([user[@"lastNameLowercase"] containsString:searchTerm]){
            [lastNames addObject:user];
        }
        
    }
    
    NSArray *sortedMatchArray = [self sortedArray:matches key:@"username"];
    NSArray *sortedUsernameArray = [self sortedArray:usernames key:@"username"];
    NSArray *sortedFirstNameArray = [self sortedArray:firstNames key:@"lowercaseName"];
    NSArray *sortedLastNameArray = [self sortedArray:lastNames key:@"lowercaseName"];
    
    NSMutableArray *sortedArray = [[NSMutableArray alloc] init];
    [sortedArray addObjectsFromArray:sortedMatchArray];
    [sortedArray addObjectsFromArray:sortedUsernameArray];
    [sortedArray addObjectsFromArray:sortedFirstNameArray];
    [sortedArray addObjectsFromArray:sortedLastNameArray];
    
    return sortedArray;
}

-(NSArray*)sortedArray:(NSArray*)theArray key:(NSString*)key{
    NSSortDescriptor *firstDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:firstDescriptor, nil];
    NSArray *sortedArray = [theArray sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;
}

@end
