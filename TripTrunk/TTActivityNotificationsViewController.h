//
//  TTActivityNotificationsViewController.h
//  TripTrunk
//
//  Created by Michael Cannell on 1/29/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTBaseViewController.h"

@interface TTActivityNotificationsViewController : TTBaseViewController
-(void)trunkWasDeleted:(Trip*)trip;   //?
-(void)photoWasDeleted:(Photo*)photo; //?


-(id)initWithLikes:(NSArray *)likes;
-(id)initWithActivities:(NSArray *)activities;
@end
