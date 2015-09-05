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
#import "AddTripFriendsViewController.h"
#import "TTUtility.h"
#import "AddTripViewController.h"
#import <Photos/Photos.h>

@interface AddTripPhotosViewController ()  <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate >
@property UIImagePickerController *PickerController;
@property NSMutableArray *photos;
@property (weak, nonatomic) IBOutlet UICollectionView *tripCollectionView;
@property (weak, nonatomic) IBOutlet UITextView *caption;
@property (weak, nonatomic) IBOutlet UIButton *addCaption;
@property (weak, nonatomic) IBOutlet UIButton *cancelCaption;
@property (weak, nonatomic) IBOutlet UIButton *plusPhoto;
@property (weak, nonatomic) IBOutlet UIButton *submitTrunk;
@property (weak, nonatomic) IBOutlet UIButton *remove;
@property (weak, nonatomic) IBOutlet UIButton *delete;
@property (weak, nonatomic) IBOutlet UIImageView *selectedPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *backGroundImage;
@property NSInteger path;
@property BOOL alreadyTrip;
@property (weak, nonatomic) IBOutlet UILabel *constraintLabel;

@end

@implementation AddTripPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.constraintLabel.hidden = YES;
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    if (self.trip){
        self.alreadyTrip = YES;
    } else {
        self.alreadyTrip = NO;
        
    }
    self.title = @"Add Photos";
    self.tripCollectionView.delegate = self;
    self.photos = [[NSMutableArray alloc]init];
    self.tripCollectionView.backgroundColor = [UIColor clearColor];
    self.tripCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.caption.text = @"";
    self.caption.hidden = YES;
    self.cancelCaption.hidden = YES;
    self.addCaption.hidden = YES;
    self.remove.hidden = YES;
    self.delete.hidden = YES;
    self.selectedPhoto.hidden = YES;
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    self.caption.delegate = self;
}

//-(void)viewDidAppear:(BOOL)animated{
//    self.tripCollectionView.hidden = NO;
//    self.plusPhoto.hidden = NO;
//    self.submitTrunk.hidden = NO;
//}


-(void)viewWillAppear:(BOOL)animated {
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
}

#pragma mark - Button Actions
- (IBAction)onDoneTapped:(id)sender {
    self.plusPhoto.hidden = YES;
    self.submitTrunk.hidden = YES;
    
    if (!self.trip) {
        // This shouldn't happen, trip should always be set from the previous view controler
        [self saveParseTrip];
    }
//    [[self navigationController] setNavigationBarHidden:YES animated:YES]; we dont need this now 
    [self uploadAllPhotos];
}

- (IBAction)libraryTapped:(id)sender {
    
    // 10 photo upload limit, so make sure they haven't already picked 10 photos.
    
    if (self.photos.count >= 10) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Limit Reached"
                                                        message:@"You can only upload 10 photos at a time. Upload these first, then you can add more"
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    else
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = NO;
        [picker setTitle:@"Select Photo"];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        picker.navigationBar.tintColor = [UIColor whiteColor];
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
        [self presentViewController:picker animated:YES completion:NULL];
    }
}


#pragma mark - Image Picker delegates

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    Photo *photo = [Photo object];
    photo.image = info[UIImagePickerControllerOriginalImage];
    
    // set the reference URL now so we have it for uploading the raw image data
    photo.imageUrl = [NSString stringWithFormat:@"%@", info[UIImagePickerControllerReferenceURL]];
    
    // Set all the generic trip info on the Photo object
    PFUser *user = [PFUser currentUser];
    photo.likes = 0;
    photo.trip = self.trip;
    photo.userName = user.username;
    photo.user = user;
    photo.usersWhoHaveLiked = [[NSMutableArray alloc] init];
    photo.tripName = self.trip.name;
    photo.city = self.trip.city;
    
    
    [self.photos addObject:photo];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self.tripCollectionView reloadData];

}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

}

#pragma mark - Saving Photos

-(void)saveParseTrip {
    self.title = @"Uploading Photos..";
    
    self.trip = [[Trip alloc]init];
    self.trip.name = self.tripName;
    self.trip.city = self.tripCity;
    self.trip.user = [PFUser currentUser].username;
    self.trip.creator = [PFUser currentUser];
    self.trip.startDate = self.startDate;
    self.trip.endDate = self.endDate;
    self.trip.state = self.tripState;
    self.trip.country = self.tripCountry;
    self.trip.isPrivate = self.isPrivate;
    
    if (self.trip.mostRecentPhoto == nil){
        NSString *date = @"01/01/1200";
        NSDateFormatter *format = [[NSDateFormatter alloc]init];
        [format setDateFormat:@"yyyy-MM-dd"];
        self.trip.mostRecentPhoto = [format dateFromString:date];
    }
    
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if(error) {
             //FIXME Check to see if actually works
             self.plusPhoto.hidden = NO;
             self.submitTrunk.hidden = NO;
             UIAlertView *alertView = [[UIAlertView alloc] init];
             alertView.delegate = self;
             alertView.title = @"No internet connection to save trip";
             alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
             [alertView addButtonWithTitle:@"OK"];
             [alertView show];
             [[self navigationController] setNavigationBarHidden:NO animated:YES];
             
         } else {
             if (self.photos.count == 0) {
                 [self dismissViewControllerAnimated:YES completion:NULL];
                 [[self navigationController] setNavigationBarHidden:NO animated:YES];
             }
         }
     }];
}

- (void)uploadAllPhotos {
    self.title = @"Uploading Photos..";
    
    for (Photo *photo in self.photos)
    {
        // Uses the Photos framework to get the raw image data from the local asset library url, then uploads that
        // This fixes the issue of using UIImageJPEGRepresentation which increases file size
        NSURL *assetUrl = [NSURL URLWithString:photo.imageUrl];
        NSArray *urlArray = [[NSArray alloc] initWithObjects:assetUrl, nil];
        PHAsset *imageAsset = [[PHAsset fetchAssetsWithALAssetURLs:urlArray options:nil] firstObject];
//        PHAsset *imageAsset = [[PHAsset fetchAssetsWithLocalIdentifiers:urlArray options:nil] firstObject];

        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        [options setVersion:PHImageRequestOptionsVersionCurrent];
        [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
        [options setNetworkAccessAllowed:YES];
        
        [[PHImageManager defaultManager] requestImageDataForAsset:imageAsset
                                                          options:options
                                                    resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                        // Calls the method to actually upload the image and save the Photo to parse
                                                        [[TTUtility sharedInstance] uploadPhoto:photo withImageData:imageData];
                                                    }];
    }
    
    self.trip.mostRecentPhoto = [NSDate date];
    
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if(error) NSLog(@"Error saving trip in uploadAllPhotos: %@", error);
         
         if (succeeded) {
             
             // TODO: Set title image
             self.title = @"TripTrunk";
             
             if (!self.isTripCreation) {
                 // This came from the Trunk view, so pop back to it.
                 NSLog(@"Trip Photos Added, not trip creation so pop back one view");
                 [self.navigationController popViewControllerAnimated:YES];
                 [[self navigationController] setNavigationBarHidden:NO animated:YES];
             }
             else {
                 NSLog(@"Trip Photos Added, is trip creation so pop to Root View");
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     // Now pop to the root view of the other map view controller and set that as the selected tab.
                     UINavigationController *target = [[self.tabBarController viewControllers] objectAtIndex:0];
                     [target popToRootViewControllerAnimated:YES];
                     [self.tabBarController setSelectedIndex:0];

                     // Pop to the root view controller of the add Trip tab as well
                     UINavigationController *triptab = [[self.tabBarController viewControllers] objectAtIndex:2];
                     [triptab popToRootViewControllerAnimated:NO];
                     
                     // Tell the AddTripViewController that we've finished so it should now reset the form on that screen.
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"resetTripFromNotification" object:nil];
                     
                     
                 });
                 

                 
             }
         }
     }];
}


#pragma mark - Keyboard Events
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSRange resultRange = [text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch];
    if ([text length] == 1 && resultRange.location != NSNotFound) {
        [textView resignFirstResponder];
        [self onAddCaptionTapped:self];
        return NO;
    }
    
    return YES;
}

#pragma mark - Collection View


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}


-(PhotoCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    Photo *photo = [self.photos objectAtIndex:indexPath.row];
    cell.tripImageView.image = photo.image;
    cell.tripImageView.caption = photo.caption;
    cell.backgroundColor = [UIColor whiteColor];

    if(photo.caption){
        cell.captionImageView.image = [UIImage imageNamed:@"Check circle"];
    }
    
    else{
         cell.captionImageView.image = [UIImage imageNamed:@"Plus Circle"];
    }

    
    return cell;
    
}



-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    self.path = indexPath.row;
    Photo *photo = [self.photos objectAtIndex:indexPath.row];
    
    if (photo.caption) {
        self.caption.text = photo.caption;
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
    self.tripCollectionView.hidden = YES;
    self.selectedPhoto.image = photo.image;
    
    [self.navigationItem setHidesBackButton:YES animated:YES];

}


#pragma mark - Editing/Adding Caption to Photo

- (IBAction)onAddCaptionTapped:(id)sender
{
    [self.view endEditing:YES];
    if (![self.caption.text isEqual: @""])
    {

        Photo *photo = [self.photos objectAtIndex:self.path];
        photo.caption = self.caption.text;
        [self.photos replaceObjectAtIndex:self.path withObject:photo];
       
        self.caption.text = nil;
        
        [self.addCaption setTitle:@"Add" forState:UIControlStateNormal];
   

        self.selectedPhoto.hidden = YES;
        self.tripCollectionView.hidden = NO;
        self.delete.hidden = YES;
        self.plusPhoto.hidden = NO;
        self.submitTrunk.hidden = NO;
        self.cancelCaption.hidden = YES;
        self.remove.hidden = YES;
        self.caption.hidden = YES;
        self.addCaption.hidden = YES;
        [self.tripCollectionView reloadData];
        
        [self.navigationItem setHidesBackButton:NO animated:YES];

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
    [self.view endEditing:YES];
    
    self.selectedPhoto.hidden = YES;
    self.tripCollectionView.hidden = NO;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    [self.addCaption setTitle:@"Add" forState:UIControlStateNormal];
    self.caption.text = @"";
    self.remove.hidden = YES;
    self.delete.hidden = YES;
    [self.navigationItem setHidesBackButton:NO animated:YES];

}

- (IBAction)onRemoveTapped:(id)sender { //FIXME Doesn't remove caption
    
    [self.view endEditing:YES];
    
    self.selectedPhoto.hidden = YES;
    self.tripCollectionView.hidden = NO;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    Photo *photo = [self.photos objectAtIndex:self.path];
    photo.caption = nil;
    self.caption.text = nil;
    [self.photos replaceObjectAtIndex:self.path withObject:photo];
    self.remove.hidden = YES;
    self.delete.hidden = YES;
    [self.navigationItem setHidesBackButton:NO animated:YES];

    [self.tripCollectionView reloadData];


}

- (IBAction)onDeleteTapped:(id)sender {
    [self.view endEditing:YES];
    
    self.tripCollectionView.hidden = NO;
    self.selectedPhoto.hidden = YES;
    [self.photos removeObjectAtIndex:self.path];
    self.delete.hidden = YES;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.addCaption.hidden = YES;
    self.remove.hidden = YES;
    self.caption.text = nil;
    [self.navigationItem setHidesBackButton:NO animated:YES];

    [self.tripCollectionView reloadData];
    
}

@end
