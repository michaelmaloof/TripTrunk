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
@property (weak, nonatomic) IBOutlet UILabel *borderLabel;
@property NSMutableArray *currentSelectionPhotos;


@end

@implementation AddTripPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.constraintLabel.hidden = YES;
    
//if self.trip is valid then we are editing a trip, not creating a new one
    if (self.trip){
        self.alreadyTrip = YES;
    } else {
        self.alreadyTrip = NO;
        
    }
    self.title = NSLocalizedString(@"Add Photos",@"Add Photos");
    self.tripCollectionView.delegate = self;
    self.photos = [[NSMutableArray alloc]init];
    self.currentSelectionPhotos= [[NSMutableArray alloc]init];
    self.tripCollectionView.backgroundColor = [UIColor clearColor];
    self.tripCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    
//we hide all these things and only show them if the user has selected a photo to write a caption for
    self.caption.text = @"";
    self.caption.hidden = YES;
    self.borderLabel.hidden = YES;

    self.borderLabel.hidden = YES;
    self.cancelCaption.hidden = YES;
    self.addCaption.hidden = YES;
    self.remove.hidden = YES;
    self.delete.hidden = YES;
    self.selectedPhoto.hidden = YES;
    
    
    self.caption.delegate = self;
}



#pragma mark - Button Actions
- (IBAction)onDoneTapped:(id)sender {
    self.plusPhoto.hidden = YES;
    self.submitTrunk.hidden = YES;
    
    [self uploadAllPhotos];
}

- (IBAction)libraryTapped:(id)sender {
    
    // 10 photo upload limit, so make sure they haven't already picked 10 photos. At some point we should let them load more but warn them if they arent connected to the wifi
    
    if (self.photos.count >= 10) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Limit Reached",@"Limit Reached")
                                                        message:NSLocalizedString(@"You can only upload 10 photos at a time. Upload these first, then you can add more",@"You can only upload 10 photos at a time. Upload these first, then you can add more")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    else
    {
//this presents the imagepicker, which allows users to select the photos they want to add to the trunk
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = NO;
        [picker setTitle:NSLocalizedString(@"Select Photo",@"Select Photo")];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; //for now, we only let users upload photos in the library. They can't take a photo within the app
        picker.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        picker.navigationBar.tintColor = [UIColor whiteColor];
        
        [self presentViewController:picker animated:YES completion:NULL];
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UINavigationItem *ipcNavBarTopItem;
    
// add done button to right side of nav bar
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(photoPickerDoneAction)];
// add cancel button to left side of nav bar
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                    action:@selector(imagePickerControllerDidCancel)];

    UINavigationBar *bar = navigationController.navigationBar;
    [bar setHidden:NO];
    ipcNavBarTopItem = bar.topItem;
    ipcNavBarTopItem.title = @"";
    ipcNavBarTopItem.rightBarButtonItem = doneButton;
    ipcNavBarTopItem.leftBarButtonItem = cancelButton;
}


-(void)photoPickerDoneAction{
//the user is done selecting photos so we first go through and make sure none of the photos the selected are the same as photos that they've laready selected. This prevents duplicate photos being uploaded. self.currentSelectionPhotos are the photos the user selected while in the image picker. self.photos are the photos that will be uploaded to the trunk and are currently being shown in self.tripCollectionView
    for (Photo *photo in self.currentSelectionPhotos){
        BOOL same = NO;
        for (Photo *forPhoto in self.photos)
            if ([forPhoto.imageUrl isEqualToString:photo.imageUrl]){
                same = YES;
            }
        
        if (same == NO){
            [self.photos addObject:photo];
        }
    }

//once we add the photos from the image picker (self.currentSelectionPhotos) to the photos that will be uploaded (self.photos) we remove all the photos from self.currentSelectionPhotos since the user has finished and closed the image picker
    [self.currentSelectionPhotos removeAllObjects];
    
//reload the collectionview to show the new photos the user has added to be uploaded
    [self.tripCollectionView reloadData];

//dissmis the imagepicker
    [self.navigationController.viewControllers.lastObject dismissViewControllerAnimated:YES completion:NULL];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
}

#pragma mark - Image Picker delegates
//the user has tapped an image in the image picker

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
//first we add the photos the user has already selected to upload (currently showing in the collection view) to the array that will store the photos the user taps from the library. This is so we can indicate later which photos the user has already selected.
    for (Photo *selectedPhoto in self.photos){
        [self.currentSelectionPhotos addObject:selectedPhoto];
    }
    
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

//if the user has already tapped this image then we want to remove it. This code remebers which photo to remove
    Photo *photoToDelete = [[Photo alloc]init];
    BOOL photoSelected = NO;
    for (Photo *forPhoto in self.currentSelectionPhotos){
        if ([forPhoto.imageUrl isEqualToString:photo.imageUrl]){
            photoSelected = YES;
            photoToDelete = forPhoto;
        }
    }

//remove the photo if the user no longer wants to upload it
    if (photoSelected == YES){
        [self.currentSelectionPhotos removeObject:photoToDelete];
//add the photo if the user wants to upload it
    } else {
        [self.currentSelectionPhotos addObject:photo];
    }
    
    
}

//the user canceled and doesn't want to upload any of the photos in the image picker
-(void)imagePickerControllerDidCancel{
    [self.navigationController.viewControllers.lastObject dismissViewControllerAnimated:YES completion:NULL];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;

}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo{
}


#pragma mark - Saving Photos

- (void)uploadAllPhotos {
    
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
    // TODO: Set title image
    
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

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y -120, self.view.frame.size.width, self.view.frame.size.height);
    
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 120, self.view.frame.size.width, self.view.frame.size.height);
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
    
//we change the design if the photo has a caption or not
    if(photo.caption){
        cell.captionImageView.image = [UIImage imageNamed:@"checkCircle"];
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
        [self.addCaption setTitle:NSLocalizedString(@"Update",@"Update") forState:UIControlStateNormal];
        self.remove.hidden = NO;
    }
//we unhide all these so that the user can write and edit captions
    self.addCaption.hidden = NO;
    self.caption.hidden = NO;
    self.borderLabel.hidden = NO;

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

/**
 *  Add a caption to the photo
 *
 *
 */
- (IBAction)onAddCaptionTapped:(id)sender
{
    [self.view endEditing:YES];
    if (![self.caption.text isEqual: @""])
    {

        Photo *photo = [self.photos objectAtIndex:self.path];
        photo.caption = self.caption.text;
        [self.photos replaceObjectAtIndex:self.path withObject:photo];
       
        self.caption.text = nil;
        
        [self.addCaption setTitle:NSLocalizedString(@"Add",@"Add") forState:UIControlStateNormal];
   

        self.selectedPhoto.hidden = YES;
        self.tripCollectionView.hidden = NO;
        self.delete.hidden = YES;
        self.plusPhoto.hidden = NO;
        self.submitTrunk.hidden = NO;
        self.cancelCaption.hidden = YES;
        self.remove.hidden = YES;
        self.caption.hidden = YES;
        self.borderLabel.hidden = YES;

        self.addCaption.hidden = YES;
        [self.tripCollectionView reloadData];
        
        [self.navigationItem setHidesBackButton:NO animated:YES];

    }
    
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc] init];
        alertView.delegate = self;
        alertView.title = NSLocalizedString(@"No caption is typed",@"No caption is typed");
        alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
        [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
        [alertView show];
    }
    
}

/**
 *  Cancel the changes made to the caption
 *
 *
 */
- (IBAction)onCancelCaptionTapped:(id)sender {
    [self.view endEditing:YES];
    
    self.selectedPhoto.hidden = YES;
    self.tripCollectionView.hidden = NO;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.borderLabel.hidden = YES;

    self.addCaption.hidden = YES;
    [self.addCaption setTitle:NSLocalizedString(@"Add",@"Add") forState:UIControlStateNormal];
    self.caption.text = @"";
    self.remove.hidden = YES;
    self.delete.hidden = YES;
    [self.navigationItem setHidesBackButton:NO animated:YES];

}

/**
 *  Removes the caption
 *
 *
 */
- (IBAction)onRemoveTapped:(id)sender {
    
    [self.view endEditing:YES];
    
    self.selectedPhoto.hidden = YES;
    self.tripCollectionView.hidden = NO;
    self.plusPhoto.hidden = NO;
    self.submitTrunk.hidden = NO;
    self.cancelCaption.hidden = YES;
    self.caption.hidden = YES;
    self.borderLabel.hidden = YES;

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

/**
 * Deletes the photo
 *
 *
 */
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
    self.borderLabel.hidden = YES;

    self.addCaption.hidden = YES;
    self.remove.hidden = YES;
    self.caption.text = nil;
    [self.navigationItem setHidesBackButton:NO animated:YES];

    [self.tripCollectionView reloadData];
    
}

@end
