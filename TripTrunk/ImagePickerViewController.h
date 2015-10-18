//
//  ImagePickerViewController.h
//  TripTrunk
//
//  Created by Michael Maloof on 10/17/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTBaseViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "Trip.h"

@protocol ImagePickerDelegate
-(void)imagesWereSelected:(NSMutableArray*)images;

@end

@interface ImagePickerViewController : TTBaseViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    ALAssetsLibrary *library;
    NSArray *imageArray;
    NSMutableArray *mutableArray;
}

@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *Done;
@property NSMutableArray *photosToAdd;
@property Trip *trip;
@property NSString *tripName;
@property NSString *tripCity;
@property NSString *tripCountry;
@property NSString *tripState;

@property id<ImagePickerDelegate> delegate;


-(void)allPhotosCollected:(NSArray*)imgArray;

@end


