//
//  TTCreateTrunkViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 2/16/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#define distanceThreshold 25
#define timeframeThresholdInDays 7
#define maximumVideoLengthAllowedBeforeForcedEdit 15.0
#define MAX_HIGHLIGHTED_PHOTOS 4

static NSString *const kCityString  = @"City";
static NSString *const kStateString  = @"State";
static NSString *const kCountryString  = @"Country";

#import "TTCreateTrunkViewController.h"
#import "TTOnboardingButton.h"

@interface TTCreateTrunkViewController ()
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) PHFetchResult *assets;
@property (strong, nonatomic) NSMutableArray *filteredAssets;
@property (strong, nonatomic) IBOutlet UIImageView *mainPhoto;
@property (strong, nonatomic) IBOutlet UIImageView *subPhoto1;
@property (strong, nonatomic) IBOutlet UIImageView *subPhoto2;
@property (strong, nonatomic) IBOutlet UIImageView *subPhoto3;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) IBOutlet UIImageView *mainVideoIcon;
@property (strong, nonatomic) IBOutlet UIImageView *subPhoto1VideoIcon;
@property (strong, nonatomic) IBOutlet UIImageView *subPhoto2VideoIcon;
@property (strong, nonatomic) IBOutlet UIImageView *subPhoto3VideoIcon;
@property (nonatomic, copy) NSString *cityString;
@end

@implementation TTCreateTrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.location = [[CLLocation alloc] init];
    if([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized){
        [self reloadAssets];
    }else{
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            //            [self showNeedAccessMessage];
            [self reloadAssets];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reloadAssets{
    //    [self.activityIndicator startAnimating];
    self.assets = nil;
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[
                                     [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
                                     ];
    self.assets = [PHAsset fetchAssetsWithOptions:fetchOptions];
    
    [self filterAssetsBasedOnLocation];
    for(int i=0; self.assets.count; i++){
        PHAsset *asset = self.assets[i];
        if(i==0){
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(375, 315) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                self.mainPhoto.image = result;
                self.mainPhoto.contentMode = UIViewContentModeScaleAspectFill;
                if(asset.mediaType == PHAssetMediaTypeVideo)
                    self.mainVideoIcon.hidden = NO;
                
                if(asset.location != nil){
                    CLGeocoder *geocoder = [CLGeocoder new];
                    [geocoder reverseGeocodeLocation:asset.location completionHandler:^(NSArray *placemarks, NSError *error) {
                        CLPlacemark *placemark = [placemarks lastObject];
                        self.cityString = placemark.addressDictionary[kCityString];
                        // or equivalent
                        self.locationLabel.text = [NSString stringWithFormat:@"%@, %@, %@",placemark.addressDictionary[kCityString],placemark.addressDictionary[kStateString],placemark.addressDictionary[kCountryString]];
                    }];
                }
            }];
        }
        //FIXME: change this to a photoset and populate that way. This way is stupid
        if(i==1){
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(127, 127) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                self.subPhoto1.image = result;
                self.subPhoto1.contentMode = UIViewContentModeScaleAspectFill;
                if(asset.mediaType == PHAssetMediaTypeVideo)
                    self.subPhoto1VideoIcon.hidden = NO;
            }];
        }
        
        if(i==2){
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(127, 127) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                self.subPhoto2.image = result;
                self.subPhoto2.contentMode = UIViewContentModeScaleAspectFill;
                if(asset.mediaType == PHAssetMediaTypeVideo)
                    self.subPhoto2VideoIcon.hidden = NO;
            }];
        }
        
        if(i==3){
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(127, 127) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                self.subPhoto3.image = result;
                self.subPhoto3.contentMode = UIViewContentModeScaleAspectFill;
                if(asset.mediaType == PHAssetMediaTypeVideo)
                    self.subPhoto3VideoIcon.hidden = NO;
            }];
        }
        
        if(i==MAX_HIGHLIGHTED_PHOTOS-1)
            break;
    }
    //    [self.activityIndicator stopAnimating];
}

-(void)filterAssetsBasedOnLocation{
    for(PHAsset *asset in self.assets){
        if(asset.location != nil){
            CLLocationDistance distance = [self.location distanceFromLocation:asset.location];
            if((distance/1609.344) <= distanceThreshold && [self timeIntervalIsBelowThreshold:asset.creationDate])
                [self.filteredAssets addObject:asset];
        }
    }
}

-(BOOL)timeIntervalIsBelowThreshold:(NSDate*)creationDate{
    NSDate* date = [NSDate date];
    NSTimeInterval distanceBetweenDates = [date timeIntervalSinceDate:creationDate];
    NSInteger daysBetweenDates = distanceBetweenDates / 86400;
    
    return daysBetweenDates<=timeframeThresholdInDays;
}

- (IBAction)createTrunkWasTapped:(TTOnboardingButton*)sender {
    [self performSegueWithIdentifier:@"pushToTrunkName" sender:self];
}

- (IBAction)backButtonWasTapped:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
