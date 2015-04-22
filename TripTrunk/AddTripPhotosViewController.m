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
#import "TripImageView.h"

@interface AddTripPhotosViewController ()  <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property UIImagePickerController *PickerController;
@property CGFloat HeightOfButtons;
@property NSMutableArray *photos;
@property UIImage *image2;
@property (weak, nonatomic) IBOutlet UICollectionView *tripCollectionView;
@property (weak, nonatomic) IBOutlet UITextView *caption;
@property (weak, nonatomic) IBOutlet UIButton *addCaption;
@property (weak, nonatomic) IBOutlet UIButton *cancelCaption;
@property (weak, nonatomic) IBOutlet UIButton *plusPhoto;
@property (weak, nonatomic) IBOutlet UIButton *submitTrunk;
@property NSIndexPath *path;
@property NSMutableArray *photosToDelete;

@end

@implementation AddTripPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.photos = [[NSMutableArray alloc]init];
    self.photosToDelete = [[NSMutableArray alloc]init];
    self.tripCollectionView.backgroundColor = [UIColor clearColor];
    self.tripCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.caption.text = @"Photo caption";
    self.title = self.tripName;
    self.caption.hidden = YES;
    self.cancelCaption.hidden = YES;
    self.addCaption.hidden = YES;
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
    
    NSLog(@"array is %@", self.photos);
    
    for (TripImageView *tripImage in self.photos)
    {
        UIImage *image = [[UIImage alloc]init];
        image = tripImage.image;
        NSString *string = tripImage.caption;
        [self addImageData:UIImagePNGRepresentation(image) string:string];
        [self addToDeleteArray:tripImage];
    }
    
    for (TripImageView *tripImage in self.photosToDelete) {
        [self.photos removeObject:tripImage];
    }
    
    self.photosToDelete = nil;
    
    for (UIImage *image in self.photos){
        [self addImageData:UIImagePNGRepresentation(image)  string:nil];
    }
}

-(void)addToDeleteArray:(TripImageView*)trip{
    [self.photosToDelete addObject:trip];
}

- (void)addImageData:(NSData *)imageData string:(NSString*)caption
{
    PFFile *file = [PFFile fileWithData:imageData];
    PFUser *user = [PFUser currentUser];
    Photo *photo = [Photo object];
    
    photo.likes = 0;
    photo.imageFile = file;
    photo.name = [user objectForKey:@"name"];
    photo.fbID = [user objectForKey:@"fbId"];
    photo.user = [PFUser currentUser];
    photo.caption = caption;
    
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


//didSelect
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    self.path = indexPath;
    self.caption.hidden = NO;
    self.addCaption.hidden = NO;
    self.cancelCaption.hidden = NO;
    self.plusPhoto.hidden = YES;
    self.submitTrunk.hidden = YES;
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    NSLog(@"hey %@",cell.tripImage.caption);
    
    
}

- (IBAction)onAddCaptionTapped:(id)sender {
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[self.tripCollectionView cellForItemAtIndexPath:self.path];
    cell.captionImage.image = [UIImage imageNamed:@"Check circle"];
    cell.tripImage.caption = self.caption.text;
    [self.photos replaceObjectAtIndex:self.path.row withObject:cell.tripImage];
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    self.path = nil;
}

- (IBAction)onCancelCaptionTapped:(id)sender {
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    self.path= nil;
}


@end
