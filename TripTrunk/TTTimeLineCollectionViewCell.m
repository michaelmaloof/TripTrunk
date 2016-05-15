//
//  TTTimeLineCollectionViewCell.m
//  TripTrunk
//
//  Created by Michael Maloof on 2/15/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTTimeLineCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation TTTimeLineCollectionViewCell
- (void)awakeFromNib {
    [self.userprofile.layer setCornerRadius:20.0f];
    [self.userprofile.layer setMasksToBounds:YES];
    [self.userprofile.layer setBorderWidth:2.0f];
    self.userprofile.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);

    [self.image1.layer setCornerRadius:25.0f];
    [self.image1.layer setMasksToBounds:YES];
    [self.image1.layer setBorderWidth:3.0f];
    [self.image1.layer setBorderColor: [[UIColor colorWithRed:142.0/255.0 green:211.0/255.0 blue:253.0/255.0 alpha:1.0] CGColor]];
    [self.image1 setBackgroundColor:[UIColor colorWithRed:142.0/255.0 green:211.0/255.0 blue:253.0/255.0 alpha:1.0]];
    
    [self.image2.layer setCornerRadius:25.0f];
    [self.image2.layer setMasksToBounds:YES];
    [self.image2.layer setBorderWidth:3.0f];
    [self.image2.layer setBorderColor: [[UIColor colorWithRed:255.0/255.0 green:192.0/255.0 blue:159.0/255.0 alpha:1.0] CGColor]];
    [self.image2 setBackgroundColor:[UIColor colorWithRed:255.0/255.0 green:192.0/255.0 blue:159.0/255.0 alpha:1.0]];

    
    [self.image3.layer setCornerRadius:25.0f];
    [self.image3.layer setMasksToBounds:YES];
    [self.image3.layer setBorderWidth:3.0f];
    [self.image3.layer setBorderColor: [[UIColor colorWithRed:252.0/255.0 green:245.0/255.0 blue:199.0/255.0 alpha:1.0] CGColor]];
    [self.image3 setBackgroundColor:[UIColor colorWithRed:252.0/255.0 green:245.0/255.0 blue:199.0/255.0 alpha:1.0]];

    
    [self.image4.layer setCornerRadius:25.0f];
    [self.image4.layer setMasksToBounds:YES];
    [self.image4.layer setBorderWidth:3.0f];
    [self.image4.layer setBorderColor: [[UIColor colorWithRed:173.0/255.0 green:247.0/255.0 blue:182.0/255.0 alpha:1.0] CGColor]];
    [self.image4 setBackgroundColor:[UIColor colorWithRed:173.0/255.0 green:247.0/255.0 blue:182.0/255.0 alpha:1.0]];

    
    [self.image5.layer setCornerRadius:25.0f];
    [self.image5.layer setMasksToBounds:YES];
    [self.image5.layer setBorderWidth:3.0f];
    [self.image5.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.image5 setBackgroundColor:[UIColor blackColor]];

    
    [self.imageBUtton.layer setCornerRadius:25.0f];
    [self.imageBUtton.layer setMasksToBounds:YES];
    
    [self.labelButton.layer setCornerRadius:25.0f];
    [self.labelButton.layer setMasksToBounds:YES];
    self.labelButton.alpha = .7;

}




@end
