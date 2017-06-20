//
//  TTHomeMapViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 6/14/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTHomeMapViewController.h"
#import "TTHomeMapCollectionViewCell.h"
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>
@import GoogleMaps;

@interface TTHomeMapViewController ()
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation TTHomeMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    double mapOffset = 0.225;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:34.0522-mapOffset
                                                            longitude:-118.2437
                                                                 zoom:10];
    
    self.googleMapView.camera = camera;
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *styleUrl = [mainBundle URLForResource:@"style" withExtension:@"json"];
    NSError *error;
    
    GMSMapStyle *style = [GMSMapStyle styleWithContentsOfFileURL:styleUrl error:&error];
    
    if (!style) {
        NSLog(@"The style definition could not be loaded: %@", error);
    }
    
    self.googleMapView.mapStyle = style;
//    self.googleMapView.myLocationEnabled = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 5;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (TTHomeMapCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    TTHomeMapCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    return cell;
}


@end
