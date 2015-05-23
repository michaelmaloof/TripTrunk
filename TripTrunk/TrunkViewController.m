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
#import "AddTripPhotosViewController.h"


@interface TrunkViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate>
@property NSArray *photos;
@property NSMutableArray *trunkAlbum;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *photoLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDate;
@property (weak, nonatomic) IBOutlet UILabel *endDate;
@property (weak, nonatomic) IBOutlet UIButton *memberButton;
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
    self.trunkAlbum = [[NSMutableArray alloc]init];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.title = self.trip.name;
    self.cityLabel.text = self.trip.city;
    self.stateCountryLabel.text = [NSString stringWithFormat:@"%@ %@, %@",self.trip.city, self.trip.state,self.trip.country];
    self.photoLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.photos.count];
    self.startDate.text = self.trip.startDate;
    self.endDate.text = self.trip.endDate;
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    if ([[PFUser currentUser].username isEqualToString:self.trip.user]) {

    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [self queryParseMethod];
    
}


-(TrunkCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TrunkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];

    if(indexPath.row == 0)
    {
        cell.photo.image = [UIImage imageNamed:@"Plus Square"];
    }
    
    else if (indexPath.row > 0)
    {
        cell.tripPhoto = [self.photos objectAtIndex:indexPath.row -1];
        [self convertPhoto:cell indexPath:indexPath];
    
    }
    

    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count + 1;
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
    Photo *photo = [self.photos objectAtIndex:indexPath.row -1];
    PFFile *file = photo.imageFile;
    cell.photo.file = file;
    [cell.photo.file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            cell.photo.image = [UIImage imageWithData:data];
            [self.trunkAlbum addObject:cell.photo.image];
        }
    }];
}
     
- (IBAction)onPhotoTapped:(id)sender {
    for (UIImage *image in self.trunkAlbum){
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = @"Saved Trunk photos to phone";
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"OK"];
    [alertView show];

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Edit"]) {
        AddTripViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
    else if([segue.identifier isEqualToString:@"photo"]){
        PhotoViewController *vc = segue.destinationViewController;
        vc.photo = [self.photos objectAtIndex:self.path.row -1];
        self.path = nil;
    }
    
    else if ([segue.identifier isEqualToString:@"addPhotos"]) {
        AddTripPhotosViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row > 0)
    {
        self.path = indexPath;
        [self performSegueWithIdentifier:@"photo" sender:self];
    }
    
    else if (indexPath.row == 0)
    {
        [self performSegueWithIdentifier:@"addPhotos" sender:self];
    }
}


     





















@end
