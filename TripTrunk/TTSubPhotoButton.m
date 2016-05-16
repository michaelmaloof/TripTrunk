//
//  TTSubPhotoButton.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/13/16.
//  Copyright © 2016 Michael Maloof. All rights reserved.
//

#import "TTSubPhotoButton.h"
#import "TTColor.h"

@implementation TTSubPhotoButton

- (void)awakeFromNib {
    [super awakeFromNib];

}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.layer setCornerRadius:25.0f];
    [self.layer setMasksToBounds:YES];
    [self.layer setBorderWidth:3.0f];
    switch([[self valueForKey:@"subPhotoIndex"] intValue]){
        case 0:
            break;
        case 1:
            [self.layer setBorderColor:[[TTColor subPhotoBlue] CGColor]];
            [self setBackgroundColor:[TTColor subPhotoBlue]];
            break;
        case 2:
            if(self.tag == 0){
                [self.layer setBorderColor:[[TTColor subPhotoPink] CGColor]];
                [self setBackgroundColor:[TTColor subPhotoPink]];
            }
            break;
        case 3:
            if(self.tag == 0){
                [self.layer setBorderColor:[[TTColor subPhotoTan] CGColor]];
                [self setBackgroundColor:[TTColor subPhotoTan]];
            }
            break;
        case 4:
            if(self.tag == 0){
                [self.layer setBorderColor:[[TTColor subPhotoGreen] CGColor]];
                [self setBackgroundColor:[TTColor subPhotoGreen]];
            }
            break;
        case 5:{
            [self.layer setBorderColor:[[TTColor subPhotoGray] CGColor]];
            [self setBackgroundColor:[TTColor subPhotoGray]];
            break;
        }
        default:
            break;
    }
}

@end
