//
//  AddTripPhotosViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/20/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddTripPhotosViewController.h"
#import <Parse/Parse.h>
#import "PhotoCollectionViewCell.h"
#import "Photo.h"
#import "TripImageView.h"

@interface AddTripPhotosViewController ()  <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate >
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
@property NSMutableArray *photosCounter;
//@property NSMutableArray *tripPhotos;
@property (weak, nonatomic) IBOutlet UIButton *remove;
@property (weak, nonatomic) IBOutlet UIButton *delete;
@property (weak, nonatomic) IBOutlet UIImageView *selectedPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *backGroundImage;

@end

@implementation AddTripPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.trip)
    {
        self.title = self.trip.name;
    }
    
    else
    {
        self.title = @"Photos From Trip";
    }
    
    self.photos = [[NSMutableArray alloc]init];
    self.photosCounter = [[NSMutableArray alloc]init];
//    self.tripPhotos = [[NSMutableArray alloc]init];
    self.tripCollectionView.backgroundColor = [UIColor clearColor];
    self.tripCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.caption.text = @"";
    self.title = self.tripName;
    self.caption.hidden = YES;
    self.cancelCaption.hidden = YES;
    self.addCaption.hidden = YES;
    self.remove.hidden = YES;
    self.delete.hidden = YES;
    self.selectedPhoto.hidden = YES;
        
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
        
    
}

-(void)viewDidAppear:(BOOL)animated{
    self.tripCollectionView.hidden = NO;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    [self.tripCollectionView reloadData];
}

- (IBAction)onDoneTapped:(id)sender {
    
    if (!self.trip) {
        [self parseTrip];
    }
    [self parsePhotos];
    self.plusPhoto.hidden = YES;
    self.submitTrunk.hidden = YES;
    
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
             if(error) {
                 //FIXME Check to see if actually works
                 self.plusPhoto.hidden = NO;
                 self.submitTrunk.hidden = NO;
                 UIAlertView *alertView = [[UIAlertView alloc] init];
                 alertView.delegate = self;
                 alertView.title = @"No internet connection.";
                 alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                 [alertView addButtonWithTitle:@"OK"];
                 [alertView show];
             }
     }];
}

-(void)parsePhotos {
    

//    for (TripImageView *tripImage in self.tripPhotos)
        for (TripImageView *tripImageView in self.photos)
    {
        [self addImageData:UIImagePNGRepresentation(tripImageView.image) string:tripImageView.caption];
        [self addToCounterArray:tripImageView];
    }
    
    if (self.photosCounter.count == self.photos.count){
        [self dismissViewControllerAnimated:YES completion:nil];
        self.photos = nil;
        self.photosCounter = nil;
    }
}

-(void)addToCounterArray:(TripImageView*)trip{
    [self.photosCounter addObject:trip];
}

- (void)addImageData:(NSData *)imageData string:(NSString*)caption
{
    PFFile *file = [PFFile fileWithData:imageData];
    PFUser *user = [PFUser currentUser];
    Photo *photo = [Photo object];
    
    photo.likes = 0;
    photo.imageFile = file;
    photo.fbID = [user objectForKey:@"fbId"];
    photo.userName = [PFUser currentUser].username;
    photo.user = [PFUser currentUser];
    NSMutableArray *localArray = [[NSMutableArray alloc] init];
    photo.usersWhoHaveLiked = localArray;
    
    if(!self.trip) {
        photo.tripName = self.tripName;
        photo.city = self.tripCity;
    } else if (self.trip) {
        photo.tripName = self.trip.name;
        photo.city = self.trip.city;
    }
    photo.caption = caption;
    
    [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if(error) {
            self.plusPhoto.hidden = NO;
            self.submitTrunk.hidden = NO;
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.delegate = self;
            alertView.title = @"No internet connection.";
            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
            [alertView addButtonWithTitle:@"OK"];
            [alertView show];
        } else {
            if (!self.trip)
            {
                [self dismissViewControllerAnimated:YES completion:NULL];
            }
            else if (self.trip)
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }];
    
}


- (IBAction)libraryTapped:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self presentViewController:picker animated:YES completion:NULL];
}


#pragma mark - Image Picker delegates

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
//        UIImage *image = info[UIImagePickerControllerOriginalImage];
//        [self.photos addObject:image];
//        [picker dismissViewControllerAnimated:YES completion:NULL];
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    TripImageView *tripImageView = [[TripImageView alloc]init];
    tripImageView.image = image;
    [self.photos addObject:tripImageView];
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
    TripImageView *tripImageView = [self.photos objectAtIndex:indexPath.row];
    cell.tripImageView.image = tripImageView.image;

    
    return cell;
    
}


//didSelect
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    self.path = indexPath;
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[self.tripCollectionView cellForItemAtIndexPath:self.path];
    
    if (cell.tripImageView.caption) {
        self.caption.text = cell.tripImageView.caption;
        [self.addCaption setTitle:@"Update" forState:UIControlStateNormal];
        self.remove.hidden = NO;
    }
    
    self.addCaption.hidden = NO;
    self.caption.hidden = NO;
    self.cancelCaption.hidden = NO;
    self.plusPhoto.hidden = YES;
    self.submitTrunk.hidden = YES;
    self.delete.hidden = NO;
    self.selectedPhoto.hidden = NO;
    cell.backgroundColor = [UIColor whiteColor];
    self.tripCollectionView.hidden = YES;
    self.selectedPhoto.image = cell.tripImageView.image;
}

- (IBAction)onAddCaptionTapped:(id)sender {
    
    if (![self.caption.text isEqual: @""])
    {
    self.selectedPhoto.hidden = YES;
    self.tripCollectionView.hidden = NO;
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[self.tripCollectionView cellForItemAtIndexPath:self.path];
    cell.captionImageView.image = [UIImage imageNamed:@"Check circle"];
    cell.tripImageView.caption = self.caption.text;
    [self.photos replaceObjectAtIndex:self.path.row withObject:cell.tripImageView];
    self.delete.hidden = YES;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.remove.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    self.path = nil;
    self.caption.text = @"";
    [self.addCaption setTitle:@"Add" forState:UIControlStateNormal];
    cell.backgroundColor = [UIColor colorWithRed:228.0/255.0 green:117.0/255.0 blue:98.0/255.0 alpha:1.0];
        
        
    }
    
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] init];
        alertView.delegate = self;
        alertView.title = @"No caption is typed";
        alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
        [alertView addButtonWithTitle:@"OK"];
        [alertView show];
    }
    
}

- (IBAction)onCancelCaptionTapped:(id)sender {
    self.selectedPhoto.hidden = YES;
    self.tripCollectionView.hidden = NO;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    [self.addCaption setTitle:@"Add" forState:UIControlStateNormal];
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[self.tripCollectionView cellForItemAtIndexPath:self.path];
    self.caption.text = @"";
    cell.backgroundColor = [UIColor colorWithRed:228.0/255.0 green:117.0/255.0 blue:98.0/255.0 alpha:1.0];
    self.path= nil;
    self.remove.hidden = YES;
    self.delete.hidden = YES;
}

- (IBAction)onRemoveTapped:(id)sender {
    self.selectedPhoto.hidden = YES;
    self.tripCollectionView.hidden = NO;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[self.tripCollectionView cellForItemAtIndexPath:self.path];
    cell.captionImageView.image = [UIImage imageNamed:@"Plus Circle"];
    cell.tripImageView.caption = nil;
    [self.photos replaceObjectAtIndex:self.path.row withObject:cell.tripImageView];
    [self.photos addObject:cell.tripImageView.image];
    cell.backgroundColor = [UIColor colorWithRed:228.0/255.0 green:117.0/255.0 blue:98.0/255.0 alpha:1.0];
    self.path= nil;
    self.remove.hidden = YES;
    self.delete.hidden = YES;

}

- (IBAction)onDeleteTapped:(id)sender {
    self.tripCollectionView.hidden = NO;
    self.selectedPhoto.hidden = YES;
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[self.tripCollectionView cellForItemAtIndexPath:self.path];
     cell.backgroundColor = [UIColor colorWithRed:228.0/255.0 green:117.0/255.0 blue:98.0/255.0 alpha:1.0];
    [self.photos replaceObjectAtIndex:self.path.row withObject:cell.tripImageView];
    self.path= nil;
    self.delete.hidden = YES;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    self.remove.hidden = YES;
    self.caption.text = @"";
    [self.tripCollectionView reloadData];
    
}
@end
