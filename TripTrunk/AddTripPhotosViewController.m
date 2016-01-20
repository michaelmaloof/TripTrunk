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
#import "HomeMapViewController.h"
#import <CTAssetsPickerController/CTAssetsPickerController.h>
#import "PublicTripDetail.h"
#import "TrunkListViewController.h"

@interface AddTripPhotosViewController ()  <UINavigationControllerDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate, CTAssetsPickerControllerDelegate>
@property NSMutableArray *photos;
@property (weak, nonatomic) IBOutlet UICollectionView *tripCollectionView;
@property (weak, nonatomic) IBOutlet UITextView *caption;
@property (weak, nonatomic) IBOutlet UIButton *addCaption;
@property (weak, nonatomic) IBOutlet UIButton *cancelCaption;
@property (weak, nonatomic) IBOutlet UIButton *selectPhotosButton;
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
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.selectPhotosButton.hidden = YES;
    self.submitTrunk.hidden = YES;
    
    if (self.photos.count > 0){
        self.trip.publicTripDetail.mostRecentPhoto = [NSDate date];
    }
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (HomeMapViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[HomeMapViewController class]])
            {
                BOOL hotness;
                if (self.photos.count > 0){
                    hotness = YES;
                } else {
                    hotness = NO;
                }
                BOOL mem;

                if (view.user == nil || [view.user.objectId isEqualToString:[PFUser currentUser].objectId] ){
                    if (self.isTripCreation == YES){
                        mem = YES;
                    } else {
                        mem = NO;
                    }
                } else {
                    mem = NO;
                }
                [view dontRefreshMap];
                [view updateTrunkColor:self.trip isHot:hotness member:mem];
            }
            
            for (TrunkListViewController *view in controller.viewControllers)
            {
                if ([view isKindOfClass:[TrunkListViewController class]])
                {
                    [view reloadTrunkList:self.trip seen:NO];
                }
            }
        }
        
    }
    
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (HomeMapViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[HomeMapViewController class]])
            {
                if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                    if (view == (HomeMapViewController*)controller.viewControllers[0]){
                        if (![view.viewedTrunks containsObject:self.trip])
                        {
                            [view.viewedTrunks addObject:self.trip];
                            
                        }
                    }
                }
            }
        }
    }

    
    
    [self uploadAllPhotos];
}

- (IBAction)selectPhotosButtonPressed:(id)sender {
    
    // request authorization status
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        dispatch_async(dispatch_get_main_queue(), ^{
            // Navigation Bar apperance
            UINavigationBar *navBar = [UINavigationBar appearanceWhenContainedIn:[CTAssetsPickerController class], nil];
            
            // tint color
            navBar.tintColor = [UIColor whiteColor];
            
            // init picker
            CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
            
            // set delegate
            picker.delegate = self;
            
            // present picker
            [self presentViewController:picker animated:YES completion:nil];
        });
    }];
    
}

#pragma mark - CTAssetsPickerController Delegate Methods

-(void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {

    for (PHAsset *asset in assets){
        Photo *photo = [[Photo alloc] init];
        photo.imageAsset = asset;
        [self.photos addObject:photo];
    }
    [self.tripCollectionView reloadData];
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

#pragma mark - Saving Photos

- (void)uploadAllPhotos { //FIXME: Handle error handling better on lost trunks here
    
    int originalCount = self.trip.publicTripDetail.photoCount;

    
    if (self.photos.count > 0){
        if (!self.trip.publicTripDetail){
            self.trip.publicTripDetail = [[PublicTripDetail alloc]init];
        }
            self.trip.publicTripDetail.mostRecentPhoto = [NSDate date];
            self.trip.publicTripDetail.photoCount = self.trip.publicTripDetail.photoCount + (int)self.photos.count;
    }
    
    if (![[PFUser currentUser].objectId isEqualToString:self.trip.creator.objectId]){
        [self.trip.publicTripDetail saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error){
                NSLog(@"Error yo");
            } else {
                NSLog(@"Error no");

            }
            
        }];
        [self savePhotosToParse];

    } else {
    
        [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error){
                self.trip.publicTripDetail.photoCount = originalCount;
                self.navigationItem.rightBarButtonItem.enabled = YES;
                UIAlertView *alertView = [[UIAlertView alloc] init];
                alertView.delegate = self;
                alertView.title = NSLocalizedString(@"Something went wrong. Please try again.",@"Something went wrong. Please try again.");
                alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                [alertView show];
            } else {
                [self savePhotosToParse];
    
            }
        }];
    
    }
}

-(void)savePhotosToParse{
    for (Photo *photo in self.photos)
    {
        // Set all the trip info on the Photo object
        photo.user = [PFUser currentUser];
        photo.userName = [[PFUser currentUser] username];
        photo.trip = self.trip;
        photo.likes = 0;
        photo.usersWhoHaveLiked = [[NSMutableArray alloc] init];
        photo.tripName = self.trip.name;
        photo.city = self.trip.city;
        
        for (UINavigationController *controller in self.tabBarController.viewControllers)
        {
            for (HomeMapViewController *view in controller.viewControllers)
            {
                if ([view isKindOfClass:[HomeMapViewController class]])
                {
                    if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                        if (view == (HomeMapViewController*)controller.viewControllers[0]){
                            
//                            [view.viewedPhotos addObject:photo.objectId];
                            
                        }
                    }
                }
            }
        }

        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        [options setVersion:PHImageRequestOptionsVersionCurrent];
        [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
        [options setNetworkAccessAllowed:YES];
        
        [[PHImageManager defaultManager] requestImageDataForAsset:photo.imageAsset
                                                          options:options
                                                    resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                        // Calls the method to actually upload the image and save the Photo to parse
                                                        [[TTUtility sharedInstance] uploadPhoto:photo withImageData:imageData];
                                                    }];
    }
    
    /* THIS IS A HACK
     * Because of issues grouping photosAdded notifications (Matt added 5 photos, instead of Matt added a photo, 5 times)
     * We are just saving an object that will notifiy the server to send the notification
     * Eventually this should be done properly and the client shouldn't get any say in sending notifications, CloudCode should handle it all.
     */
    NSNumber *count = [NSNumber numberWithInteger: self.photos.count];
    PFObject *photosAddedNotification = [PFObject objectWithClassName:@"PushNotification"];
    [photosAddedNotification setObject:count forKey:@"photoCount"];
    [photosAddedNotification setObject:self.trip forKey:@"trip"];
    [photosAddedNotification setObject:self.trip.name forKey:@"tripName"];
    [photosAddedNotification setObject:[PFUser currentUser] forKey:@"fromUser"];
    [photosAddedNotification saveInBackground];
    
    
    
    // TODO: Set title image
    
    if (!self.isTripCreation) {
        // This came from the Trunk view, so pop back to it.
        NSLog(@"Trip Photos Added, not trip creation so pop back one view");
        
        [self.navigationController popViewControllerAnimated:YES];
        [[self navigationController] setNavigationBarHidden:NO animated:YES];
        self.navigationItem.rightBarButtonItem.enabled = YES;
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
            
            self.navigationItem.rightBarButtonItem.enabled = YES;
            
        });
        
        
    }
    
    self.navigationItem.rightBarButtonItem.enabled = YES;

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
    cell.tripImageView.caption = photo.caption;
    cell.backgroundColor = [UIColor whiteColor];
    
    
    [[PHImageManager defaultManager] requestImageForAsset:photo.imageAsset
                                               targetSize:CGSizeMake(200, 200)
                                              contentMode:PHImageContentModeAspectFill
                                                  options:nil
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                
                                                // Set the image.
                                                // TODO: Use a weak cell reference
                                                cell.tripImageView.image = result;

                                                
                                            }];
    
//we change the design if the photo has a caption or not
    if(photo.caption){
        cell.captionImageView.image = [UIImage imageNamed:@"checkCircle"];
    }
    
    else{
         cell.captionImageView.image = [UIImage imageNamed:@"Plus Circle"];
    }
    [cell layoutIfNeeded];
    
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
    self.selectPhotosButton.hidden = YES;
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
        self.selectPhotosButton.hidden = NO;
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
    self.selectPhotosButton.hidden = NO;
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
    self.selectPhotosButton.hidden = NO;
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
    self.selectPhotosButton.hidden = NO;
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
}

@end
