//
//  ReportedBug.h
//  TripTrunk
//
//  Created by Michael Maloof on 4/3/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>


@interface ReportedBug : PFObject <PFSubclassing>

@property NSString *email;
@property NSString *bug;
@property NSString *version;
@property PFUser *user;
@property BOOL isKnownAbout;
@property BOOL isFixed;



@end
