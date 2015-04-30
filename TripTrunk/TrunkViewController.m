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
#import "AddTripViewController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "PhotoViewController.h"


@interface TrunkViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property NSArray *photos;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *photoLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDate;
@property (weak, nonatomic) IBOutlet UILabel *endDate;
@property (weak, nonatomic) IBOutlet UILabel *memberLabel;
@property (weak, nonatomic) IBOutlet UILabel *cityLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateCountryLabel;
@property NSIndexPath *path;
@property PFImageView *imageview;


@end

@implementation TrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.trip.name;
    self.photos = [[NSArray alloc]init];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.cityLabel.text = self.trip.city;
    self.stateCountryLabel.text = [NSString stringWithFormat:@"%@, %@",self.trip.state,self.trip.country];
    self.photoLabel.text = [NSString stringWithFormat:@"Photos: %lu", (unsigned long)self.photos.count];
    self.startDate.text = self.trip.startDate;
    self.endDate.text = self.trip.endDate;
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    [self queryParseMethod];
}


-(TrunkCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TrunkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.tripPhoto = [self.photos objectAtIndex:indexPath.row];
    [self convertPhoto:cell indexPath:indexPath];
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

- (IBAction)onEditTapped:(id)sender {
    [self performSegueWithIdentifier:@"Edit" sender:self];
}

-(void)queryParseMethod{
    
    PFQuery *findPhotosUser = [PFQuery queryWithClassName:@"Photo"];
    [findPhotosUser whereKey:@"tripName" equalTo:self.trip.name];
    [findPhotosUser whereKey:@"city" equalTo:self.trip.city];
    [findPhotosUser whereKey:@"userName" equalTo:self.trip.user];
    
    [findPhotosUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            self.photos = [NSArray arrayWithArray:objects];
            [self.collectionView reloadData];

            
        }else
        {
            NSLog(@"Error: %@",error);
        }


    }];

}

-(void)convertPhoto:(TrunkCollectionViewCell*)cell indexPath:(NSIndexPath*)indexPath {
    Photo *photo = [self.photos objectAtIndex:indexPath.row];
    PFFile *file = photo.imageFile;
    cell.photo.file = file;
    [cell.photo loadInBackground];
}
     
- (IBAction)onPhotoTapped:(id)sender {
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Edit"]) {
        AddTripViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
    if([segue.identifier isEqualToString:@"photo"]){
        PhotoViewController *vc = segue.destinationViewController;
        vc.photo = [self.photos objectAtIndex:self.path.row];
        self.path = nil;
    }
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    self.path = indexPath;
    [self performSegueWithIdentifier:@"photo" sender:self];
}


     





















@end
