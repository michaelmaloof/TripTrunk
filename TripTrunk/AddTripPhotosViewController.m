//
//  AddTripPhotosViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/20/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddTripPhotosViewController.h"
#import <Parse/Parse.h>
#import "Trip.h"
#import "PhotoCollectionViewCell.h"
#import "Photo.h"

@interface AddTripPhotosViewController ()  <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property UIImagePickerController *PickerController;
@property CGFloat HeightOfButtons;
@property NSMutableArray *photos;
@property UIImage *image2;
@property (weak, nonatomic) IBOutlet UICollectionView *tripCollectionView;

@end

@implementation AddTripPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.photos = [[NSMutableArray alloc]init];
    self.tripCollectionView.backgroundColor = [UIColor clearColor];
    self.tripCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.title = self.tripName;

}

-(void)viewDidAppear:(BOOL)animated{
    [self.tripCollectionView reloadData];
}

- (IBAction)onDoneTapped:(id)sender {
    [self parseTrip];
    [self parsePhotos];
    
}

-(void)parseTrip {
    Trip *trip = [[Trip alloc]init];
    trip.name = self.tripName;
    trip.city = self.tripCity;
    trip.user = [PFUser currentUser].username;
    trip.startDate = self.startDate;
    trip.endDate = self.endDate;
    trip.state = self.tripState;
    trip.country = self.tripCountry;
    
    [trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         [self dismissViewControllerAnimated:YES completion:^{
             
         }];
     }];
}

-(void)parsePhotos {
    for (UIImage *image in self.photos){
        [self addImageData:UIImagePNGRepresentation(image)];
    }
}

- (void)addImageData:(NSData *)imageData
{
    PFFile *file = [PFFile fileWithData:imageData];
    PFUser *user = [PFUser currentUser];
    Photo *photo = [Photo object];
    
    photo.likes = 0;
    photo.imageFile = file;
    photo.name = [user objectForKey:@"name"];
    photo.fbID = [user objectForKey:@"fbId"];
    photo.user = [PFUser currentUser];
    
    [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
    }];
    
}


- (IBAction)libraryTapped:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
}


#pragma mark - Image Picker delegates

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self.photos addObject:image];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}



-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}

#pragma mark - CollectionView


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
    
}


-(PhotoCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.tripImage.image = [self.photos objectAtIndex:indexPath.row];
    return cell;
    
}




@end
