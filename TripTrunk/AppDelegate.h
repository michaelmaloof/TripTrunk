//
//  AppDelegate.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/17/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)logout;

//NOTE: TripTrunk 4.0 isn't finished and is full of bugs. The code is messy and haphazard
//because I didn't have time to finish before the development was put on hold. The redesign is
//nearly done but the old design is still in the app and I wasn't able to remove it.
//Right now I am finishing all the bugs I can before rushing it up to the app store.
//The app has not gone through testing and has a bunch of bugs known and unknown.
//The redesign is also light on Google Analytics where the old design has it in every method.
//It needs to be added.
//It's sad to see TripTrunk end, or at least go on hold, especially before it can be cleaned up.

@end

