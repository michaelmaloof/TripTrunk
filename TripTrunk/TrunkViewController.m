//
//  TrunkViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/26/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TrunkViewController.h"
#import "TrunkCollectionViewCell.h"
#import "Photo.h"

@interface TrunkViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property NSArray *photos;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation TrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.photos = [[NSArray alloc]init];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self queryParseMethod];
}


-(TrunkCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TrunkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.tripPhoto = [self.photos objectAtIndex:indexPath.row];
    
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

-(void)queryParseMethod{
    
    PFQuery *findPhotosTrip = [PFQuery queryWithClassName:@"Photo"];
    [findPhotosTrip whereKey:@"tripName" equalTo:self.trip.name];
    
    PFQuery *findPhotoUser = [PFQuery queryWithClassName:@"Photo"];
    [findPhotosTrip whereKey:@"userName" matchesKey:self.trip.user inQuery:findPhotosTrip];
    
    PFQuery *findPhotoCity = [PFQuery queryWithClassName:@"Photo"];
    [findPhotoCity whereKey:@"city" equalTo:self.trip.city];
    
    PFQuery *bothQueries = [PFQuery orQueryWithSubqueries:@[findPhotoUser,findPhotoCity]];
    
    [bothQueries findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            self.photos = [NSArray arrayWithArray:objects];
        }else
        {
            NSLog(@"Error: %@",error);
        }
        [self.collectionView reloadData];
    }];

}

@end
