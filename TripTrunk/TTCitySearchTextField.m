//
//  TTCitySearchTextField.m
//  TripTrunk
//
//  Created by Michael Cannell on 5/23/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTCitySearchTextField.h"
#import "TTColor.h"
#import "TTCitySearchResultsTableViewController.h"
#import "TTHomeViewController.h"
#import "AppDelegate.h"

@interface TTCitySearchTextField() <UITextFieldDelegate,UIPopoverPresentationControllerDelegate,UIPopoverControllerDelegate>

@property (strong, nonatomic) TTCitySearchResultsTableViewController *citysearchPopover;
@property (strong, nonatomic) NSMutableArray *locationArray;

@end

@implementation TTCitySearchTextField

- (instancetype)initWithCoder:(NSCoder *)decoder{
    self = [super initWithCoder:decoder];
    if (self){
        self.delegate = self;
        self.citysearchPopover = [[TTCitySearchResultsTableViewController alloc] init];
        self.locationArray = [[NSMutableArray alloc] init];
    }else{
        return nil;
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds{
    return CGRectInset(bounds, 10.0f, 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds{
    return [self textRectForBounds:bounds];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[[TTColor tripTrunkBlack] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(2.0f,2.0f)];
    [self.layer setShadowOpacity:0.25f];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (self.csdelegate && [self.csdelegate respondsToSelector:@selector(resetCitySearchTextField)])
        [self.csdelegate resetCitySearchTextField];
    
    [self searchLocation:[textField.text stringByAppendingString:string]];
    
    return YES;
}

-(void)searchLocation:(NSString*)searchString{
    
    [[TTUtility sharedInstance] locationsForSearch:searchString block:^(NSArray *objects, NSError *error) {
        
        if (error){
            [self handleError];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"searchLocation:searchString:"];
        }
        
        [self.locationArray removeAllObjects];
        
        if (objects && objects.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.locationArray addObjectsFromArray:objects];
                if (self.csdelegate && [self.csdelegate respondsToSelector:@selector(displayCitySearchPopoverFromView:)])
                    [self.csdelegate displayCitySearchPopoverFromView:(NSArray*)self.locationArray];
            });
        }
    }];
}

-(void)handleError{
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = NSLocalizedString(@"Something Went Wrong :/",@"Something Went Wrong :/");
    alertView.message = NSLocalizedString(@"The search engine seems to have hiccuped. Please try again.",@"The search engine seems to have hiccuped. Please try again.");
    alertView.backgroundColor = [TTColor tripTrunkBlue];
    [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
    alertView.tag = 17;
    [alertView show];
}

@end
