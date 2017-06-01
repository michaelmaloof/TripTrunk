//
//  TTCitySearchTextField.h
//  TripTrunk
//
//  Created by Michael Cannell on 5/23/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TTCitySearchTextFieldDelegate;

@interface TTCitySearchTextField : UITextField

@property (nonatomic, weak) id<TTCitySearchTextFieldDelegate> csdelegate;

@end


@protocol TTCitySearchTextFieldDelegate <NSObject>

@required
-(void)displayCitySearchPopoverFromView:(NSArray*)results;
-(void)dismissCitySearchPopoverFromView;
-(void)resetCitySearchTextField;

@end
