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
#import "PublicTripDetail.h"
#import "TrunkListViewController.h"
#import "TTSuggestionTableViewController.h"
#import "TTHashtagMentionColorization.h"
#import "TTCache.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "TrunkViewController.h"
#import "PhotoViewController.h"
#import "DLFPhotosPickerViewController.h"
#import "DLFPhotoCell.h"
#import "SocialUtility.h"
#import "TTAnalytics.h"
#import "GMImagePickerController.h"

#define OVERLAY_VIEW_TAG 121212121

@interface AddTripPhotosViewController ()  <UINavigationControllerDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate, UIPopoverPresentationControllerDelegate,TTSuggestionTableViewControllerDelegate,PhotoDelegate,DLFPhotosPickerViewControllerDelegate, GMImagePickerControllerDelegate>
@property NSMutableArray *photos;
@property (weak, nonatomic) IBOutlet UICollectionView *tripCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *submitTrunk;
@property NSInteger path;
@property BOOL alreadyTrip;
@property NSMutableArray *currentSelectionPhotos;
@property NSMutableArray *photoCaptions;
@property float amount;
//Facebook
@property (strong, nonatomic) IBOutlet UIButton *facebookPublishButton;
@property BOOL publishToFacebook;
@property (strong, nonatomic) NSMutableArray *facebookPhotos;

//############################################# MENTIONS ##################################################
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTSuggestionTableViewController *autocompletePopover;
@property (strong, nonatomic) NSString *previousComment;
//############################################# MENTIONS ##################################################

@end

@implementation AddTripPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self roundUploadButton];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
//if self.trip is valid then we are editing a trip, not creating a new one
    if (self.trip){
        self.alreadyTrip = YES;
    } else {
        self.alreadyTrip = NO;
    }
    self.title = NSLocalizedString(@"Add Photos",@"Add Photos");
    self.tripCollectionView.delegate = self;
    self.photos = [[NSMutableArray alloc]init];
    self.facebookPhotos = [[NSMutableArray alloc] init];
    self.photoCaptions = [[NSMutableArray alloc] init];
    self.currentSelectionPhotos= [[NSMutableArray alloc]init];
    self.tripCollectionView.backgroundColor = [TTColor tripTrunkClear];
    self.tripCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    PFUser *currentUser = [PFUser currentUser];
    if(self.trip.isPrivate || !currentUser[@"fbid"]){
        self.facebookPublishButton.enabled = NO;
        self.facebookPublishButton.selected = YES;
    }
    
    //This checks to see if there was a failure while uploading the last time
    //if so, it loads the PHAsset localIdentifiers and recreates the array and then we can restart the upload
    NSUserDefaults *uploadError = [NSUserDefaults standardUserDefaults];
    NSString *message = [uploadError stringForKey:@"uploadError"];
    
    if(message){
        NSArray *localIdentifiers = [uploadError arrayForKey:@"currentImageUpload"];
        NSString *tripId = [uploadError stringForKey:@"currentTripId"];
        BOOL currentFacebookUpload = [uploadError boolForKey:@"currentFacebookUpload"];
        self.photoCaptions = [NSMutableArray arrayWithArray:[uploadError arrayForKey:@"currentPhotoCaptions"]];
        
        NSMutableArray *sortPhotos = [[NSMutableArray alloc] init];
        NSMutableArray *captionedPhotos = [[NSMutableArray alloc] init];
        for(int li=0;li<localIdentifiers.count;li++){
            [sortPhotos addObject:@""];
        }
        
        if(localIdentifiers){
            PHFetchResult *savedAssets = [PHAsset fetchAssetsWithLocalIdentifiers:localIdentifiers options:nil];
            [savedAssets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
                Photo *photo = [[Photo alloc] init];
                photo.imageAsset = asset;
//                photo.caption = self.photoCaptions[idx];
                
                for(int li=0;li<localIdentifiers.count;li++){
                    if([asset.localIdentifier isEqualToString:localIdentifiers[li]]){
                        [sortPhotos replaceObjectAtIndex:li withObject:photo];
                    }
                }

            }];
            
            int li=0;
            for(Photo *p in sortPhotos){
                p.caption = self.photoCaptions[li];
                [captionedPhotos addObject:p];
                li++;
            }
            
            sortPhotos = captionedPhotos;
            
            if(currentFacebookUpload){
                self.publishToFacebook = YES;
                self.facebookPublishButton.selected = YES;
            }
            
            for(id p in sortPhotos){
                if(![p isKindOfClass:[Photo class]]){
                    [sortPhotos removeObject:p];
                }
            }
            
            self.photos = sortPhotos;
            
            if(tripId){
                PFQuery *query = [PFQuery queryWithClassName:@"Trip"];
                [query whereKey:@"objectId" equalTo:tripId];
                [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    self.trip = objects[0];
                }];
            }
        }
    }else{
        //clean up -> may not be necessary
        [uploadError setObject:nil forKey:@"currentFacebookUpload"];
        [uploadError setObject:nil forKey:@"currentPhotoCaptions"];
        [uploadError setObject:nil forKey:@"uploadError"];
        [uploadError setObject:nil forKey:@"currentTripId"];
        [uploadError synchronize];
    }
    
    
    //############################################# MENTIONS ##################################################
    [self buildMentionUsersCache];
    //############################################# MENTIONS ##################################################
}

-(void)roundUploadButton{
    [self.submitTrunk.layer setCornerRadius:10.0];
    [self.submitTrunk.layer setMasksToBounds:YES];
}


#pragma mark - Button Actions
- (IBAction)onDoneTapped:(id)sender {
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
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
                [view dontRefreshMapOnViewDidAppear];
                [view updateTripColorOnMap:self.trip isHot:hotness member:mem];
            }
            
            for (TrunkListViewController *view in controller.viewControllers)
            {
                if ([view isKindOfClass:[TrunkListViewController class]])
                {
                    [view reloadTrunkList:self.trip seen:NO addPhoto:YES photoRemoved:NO];
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
                        if (![view.viewedTrips containsObject:self.trip])
                        {
                            [view.viewedTrips addObject:self.trip];
                            
                        }
                    }
                }
            }
        }
    }

    
    
    [self uploadAllPhotos];
}

- (void)selectPhotosButtonPressed{
//    DLFPhotosPickerViewController *photosPicker = [[DLFPhotosPickerViewController alloc] init];
//    [photosPicker setPhotosPickerDelegate:self];
//    [photosPicker setMultipleSelections:YES];
//    [self presentViewController:photosPicker animated:YES completion:nil];
    
    
    GMImagePickerController *picker = [[GMImagePickerController alloc] init];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - DLFPhotosPickerViewDelegate

- (void)photosPickerDidCancel:(DLFPhotosPickerViewController *)photosPicker {
    [photosPicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)photosPicker:(DLFPhotosPickerViewController *)photosPicker detailViewController:(DLFDetailViewController *)detailViewController didSelectPhotos:(NSArray *)photos {
    NSLog(@"selected %d photos", (int)photos.count);
    for (PHAsset *asset in photos){
        Photo *photo = [[Photo alloc] init];
        photo.imageAsset = asset;
        [self.photos addObject:photo];
    }

    [photosPicker dismissViewControllerAnimated:YES completion:^{
        [self.tripCollectionView reloadData];
    }];
    
}

- (void)photosPicker:(DLFPhotosPickerViewController *)photosPicker detailViewController:(DLFDetailViewController *)detailViewController configureCell:(DLFPhotoCell *)cell indexPath:(NSIndexPath *)indexPath asset:(PHAsset *)asset {
    UIView *overlayView = [cell.contentView viewWithTag:OVERLAY_VIEW_TAG];
    if (indexPath.item%2 == 0) {
        if (!overlayView) {
            overlayView = [[UIView alloc] initWithFrame:cell.contentView.bounds];
            [overlayView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [overlayView setTag:OVERLAY_VIEW_TAG];
            [overlayView setBackgroundColor:[UIColor colorWithRed:0.000 green:0.000 blue:0.000 alpha:0.000]];
            [cell.contentView addSubview:overlayView];
            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        }
        [overlayView setHidden:NO];
    } else {
        [overlayView setHidden:YES];
    }
}

#pragma mark - GMImagePickerController
- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)assetArray
{
    
    NSLog(@"GMImagePicker: User ended picking assets. Number of selected items is: %lu", (unsigned long)assetArray.count);
    
    for (PHAsset *asset in assetArray){
        Photo *photo = [[Photo alloc] init];
        photo.imageAsset = asset;
        [self.photos addObject:photo];
    }
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self.tripCollectionView reloadData];
    }];


}


-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
{
    NSLog(@"GMImagePicker: User pressed cancel button");
}

#pragma mark - CTAssetsPickerController Delegate Methods

//-(void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
//
//    for (PHAsset *asset in assets){
//        Photo *photo = [[Photo alloc] init];
//        photo.imageAsset = asset;
//        [self.photos addObject:photo];
//    }
//    [self.tripCollectionView reloadData];
//    [self dismissViewControllerAnimated:YES completion:nil];
//
//}

#pragma mark - Saving Photos

- (void)uploadAllPhotos { //FIXME: Handle error handling better on lost trunks here
    
    [self.trip.publicTripDetail fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        //clear the saved upload details. If it creashes again, these will be resaved
        NSUserDefaults *uploadError = [NSUserDefaults standardUserDefaults];
        NSMutableArray *localIdentifiers = [[NSMutableArray alloc] init];
        
        for(Photo *photo in self.photos){
            [localIdentifiers addObject:photo.imageAsset.localIdentifier];
            if(photo.caption)
                [self.photoCaptions addObject:photo.caption];
            else [self.photoCaptions addObject:@""];
        }
        
        NSLog(@"%@",localIdentifiers);
        
        if(self.publishToFacebook)
            [uploadError setObject:@"YES" forKey:@"currentFacebookUpload"];
        else [uploadError setObject:nil forKey:@"currentFacebookUpload"];
        
        [uploadError setObject:localIdentifiers forKey:@"currentImageUpload"];
        [uploadError setObject:self.photoCaptions forKey:@"currentPhotoCaptions"];
        [uploadError setObject:nil forKey:@"uploadError"];
        [uploadError setObject:nil forKey:@"currentTripId"];
        [uploadError synchronize];
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
                    NSLog(@"Error yo %@", error);
                    [ParseErrorHandlingController handleError:error];
                } else {
                    [[TTUtility sharedInstance] internetConnectionFound];
                }
                
            }];
            [self savePhotosToParse];
            
        } else {
            
            [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error){
                    [ParseErrorHandlingController handleError:error];
                    self.trip.publicTripDetail.photoCount = originalCount;
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                    UIAlertView *alertView = [[UIAlertView alloc] init];
                    alertView.delegate = self;
                    alertView.title = NSLocalizedString(@"Something went wrong. Please try again.",@"Something went wrong. Please try again.");
                    alertView.backgroundColor = [TTColor tripTrunkLightBlue];
                    [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                    [alertView show];
                } else {
                    [[TTUtility sharedInstance] internetConnectionFound];
                    [self savePhotosToParse];
                    
                }
            }];
            
        }
    }];
}

- (void)savePhotosToParse{

    // TODO: pass the whole array into the utility
    // Then recursively upload each photo so it's one at a time instead of all in a row.
    
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
        
        // Upload the photo - this method will also handle publish to facebook if needed
        if(photo.imageAsset.mediaType == 2){
            [[TTUtility sharedInstance] uploadVideo:photo photosCount:0 toFacebook:NO block:^(PFObject *video) {
                photo.video = video;
                [[TTUtility sharedInstance] uploadPhoto:photo photosCount:0 toFacebook:NO block:^(Photo *photo) {
                    PFObject *countIncrement = [PFObject objectWithClassName:@"PublicTripDetail"];
                    [countIncrement incrementKey:@"photoCount" byAmount:[NSNumber numberWithInt:1]];
                    [countIncrement save];
                    
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    NSArray *identifiers = [defaults arrayForKey:@"currentImageUpload"];
                    NSMutableArray *localIdentifiers = [NSMutableArray arrayWithArray:identifiers];
                    int i = 0;
                    
                    for(NSString *li in localIdentifiers){
                        if([li isEqualToString:photo.imageAsset.localIdentifier]){
                            [localIdentifiers removeObjectAtIndex:i];
                            [self.photoCaptions removeObjectAtIndex:i];
                            break;
                        }
                        i++;
                    }
                    
                    [defaults setObject:self.photoCaptions forKey:@"currentPhotoCaptions"];
                    [defaults setObject:localIdentifiers forKey:@"currentImageUpload"];
                    [defaults synchronize];
                    
                    
                    // If the photo has a caption, we need to add that as a comment so it shows up in the comments list. Otherwise we're done!
                    if (photo.caption && ![photo.caption isEqualToString:@""]) {
                        // This photo has a caption, so we need to deal with creating a comment object & checking for mentions.
                        [SocialUtility addComment:photo.caption forPhoto:photo isCaption:YES block:^(BOOL succeeded, PFObject *object, PFObject *commentObject, NSError *error) {
                            if (!error && commentObject) {
                                [TTAnalytics trunkCreated:self.photos.count numOfMembers:self.trunkMembers.count];
                                [self updateMentionsInDatabase:commentObject];
                            }
                        }];
                    }
                }];
            }];
        }else{
            [[TTUtility sharedInstance] uploadPhoto:photo photosCount:(int)self.photos.count toFacebook:self.publishToFacebook block:^(Photo *savedPhoto) {
                PFObject *countIncrement = [PFObject objectWithClassName:@"PublicTripDetail"];
                [countIncrement incrementKey:@"photoCount" byAmount:[NSNumber numberWithInt:1]];
                [countIncrement save];
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSArray *identifiers = [defaults arrayForKey:@"currentImageUpload"];
                NSMutableArray *localIdentifiers = [NSMutableArray arrayWithArray:identifiers];
                int i = 0;
                
                for(NSString *li in localIdentifiers){
                    if([li isEqualToString:photo.imageAsset.localIdentifier]){
                        [localIdentifiers removeObjectAtIndex:i];
                        [self.photoCaptions removeObjectAtIndex:i];
                        break;
                    }
                    i++;
                }
                
                [defaults setObject:self.photoCaptions forKey:@"currentPhotoCaptions"];
                [defaults setObject:localIdentifiers forKey:@"currentImageUpload"];
                [defaults synchronize];
                
                
                // If the photo has a caption, we need to add that as a comment so it shows up in the comments list. Otherwise we're done!
                if (savedPhoto.caption && ![savedPhoto.caption isEqualToString:@""]) {
                    // This photo has a caption, so we need to deal with creating a comment object & checking for mentions.
                    [SocialUtility addComment:savedPhoto.caption forPhoto:savedPhoto isCaption:YES block:^(BOOL succeeded, PFObject *object, PFObject *commentObject, NSError *error) {
                        if (!error && commentObject) {
                            [TTAnalytics trunkCreated:self.photos.count numOfMembers:self.trunkMembers.count];
                            [self updateMentionsInDatabase:commentObject];
                        }
                    }];
                }
            }];
        }
    }
    
    // NOTE: This stuff will be executed BEFORE the photo uploads finish because of they async nature of uploading.
    
    /* THIS IS A HACK
     * Because of issues grouping photosAdded notifications (Matt added 5 photos, instead of Matt added a photo, 5 times)
     * We are just saving an object that will notifiy the server to send the notification
     * Eventually this should be done properly and the client shouldn't get any say in sending notifications, CloudCode should handle it all.
     
     UPDATE (NEW HACK):
     I moved the count increment to happen after each upload: lines 292-294
     I changed the photoCount to always be 0 so CC won't add to it
     */
//    NSNumber *count = [NSNumber numberWithInteger: self.photos.count];
    PFObject *photosAddedNotification = [PFObject objectWithClassName:@"PushNotification"];
    [photosAddedNotification setObject:[NSNumber numberWithInt:0] forKey:@"photoCount"];
    [photosAddedNotification setObject:self.trip forKey:@"trip"];
    [photosAddedNotification setObject:self.trip.name forKey:@"tripName"];
    [photosAddedNotification setObject:[PFUser currentUser] forKey:@"fromUser"];
    [photosAddedNotification saveInBackground];
    
    
    
    // TODO: Set title image
    
    if (!self.isTripCreation) {
        // This came from the Trunk view, so pop back to it.
        [self.navigationController popViewControllerAnimated:YES];
        [[self navigationController] setNavigationBarHidden:NO animated:YES];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else {
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

-(void)updateTripDetailForUploadingError:(int)errorCount{
    [self.trip.publicTripDetail fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (self.photos.count > 0){
            if (!self.trip.publicTripDetail){
                self.trip.publicTripDetail = [[PublicTripDetail alloc]init];
            }
            self.trip.publicTripDetail.mostRecentPhoto = [NSDate date];
            self.trip.publicTripDetail.photoCount = self.trip.publicTripDetail.photoCount + (int)self.photos.count -errorCount;
        }
        [self.trip.publicTripDetail saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error){
                NSLog(@"Error yo %@", error);
                [ParseErrorHandlingController handleError:error];
            } else {
                [[TTUtility sharedInstance] internetConnectionFound];
            }
            
        }];
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
//        [self onAddCaptionTapped:self]; FIXME
        return NO;
    }
    
    return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - self.amount, self.view.frame.size.width, self.view.frame.size.height);
    
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + self.amount, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.amount = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    self.amount = self.amount - self.navigationController.navigationBar.frame.size.height - 10;
}



#pragma mark - Collection View
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    int cellSize = (screenWidth/3)-24;
    return CGSizeMake(cellSize,cellSize);
}



-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count + 1;
}

-(PhotoCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
        if (indexPath.row == 0){ //add photo
        cell.tripImageView.image = [UIImage imageNamed:@"add"];
        cell.captionImageView.hidden = YES;
        [cell.layer setCornerRadius:15.0];
        [cell.layer setMasksToBounds:YES];
    } else{ //photos selected
//        Photo *photo = [self.photos objectAtIndex:indexPath.row-1];
//        if(photo.caption){
//            if([photo.caption isEqualToString:@""])
//                photo.caption = nil;
//        }
//        [cell.layer setCornerRadius:0.0];
//        [cell.layer setMasksToBounds:YES];
//        cell.tripImageView.caption = photo.caption;
//        [[PHImageManager defaultManager] requestImageForAsset:photo.imageAsset
//                                                   targetSize:CGSizeMake(200, 200)
//                                                  contentMode:PHImageContentModeAspectFill
//                                                      options:nil
//                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
//                                                    // Set the image.
//                                                    // TODO: Use a weak cell reference
//                                                    cell.tripImageView.image = result;
//                                                }];
//        //we change the design if the photo has a caption or not
//        if(photo.caption){
//            cell.captionImageView.hidden = NO;
//        } else {
//            cell.captionImageView.hidden = YES;
//        }
        
        Photo *video = [self.photos objectAtIndex:indexPath.row-1];
        [cell.layer setCornerRadius:0.0];
        [cell.layer setMasksToBounds:YES];
        cell.backgroundColor = [UIColor blackColor];
        
        [cell layoutIfNeeded];
    }
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){ // add photos
        [self selectPhotosButtonPressed];
    } else { //add captio to selected photos
        self.path = indexPath.row-1;
        [self performSegueWithIdentifier:@"addPhotoCaption" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addPhotoCaption"]) {
        PhotoViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        vc.photo = [self.photos objectAtIndex:self.path];
        vc.trip = self.trip;
        vc.arrayInt = (int)self.path;
        vc.photos = self.photos;
        vc.fromAddPhotosViewController = YES;
//      vc.trunkMembers = self.members; FIXME need to pass members we selected from view before
    }
}

#pragma mark - Editing/Adding Caption to Photo

/**
 *  Adds the caption
 *
 *
 */
-(void)captionWasAdded:(NSString *)caption{
    if (caption != nil || ![caption isEqualToString:@""]){
        Photo *photo = [self.photos objectAtIndex:self.path];
        photo.caption = [self separateMentions:caption];
        [self.photos replaceObjectAtIndex:self.path withObject:photo];
        [self.tripCollectionView reloadData];
    } else {
        [self removedSelectedPhotoCaption];
    }
}

/**
 *  Removes the caption
 *
 *
 */
-(void)removedSelectedPhotoCaption{
    Photo *photo = [self.photos objectAtIndex:self.path];
    photo.caption = nil;
    [self.photos replaceObjectAtIndex:self.path withObject:photo];
    [self.tripCollectionView reloadData];
}

/**
 * Deletes the photo
 *
 *
 */
- (void)deleteSelectedPhoto{ //FIXME need to implment
    [self.photos removeObjectAtIndex:self.path];
    [self.tripCollectionView reloadData];
}

- (IBAction)toggleFacebookPublishButtonTapped:(id)sender {
    self.publishToFacebook = !self.publishToFacebook;
    
    if(self.publishToFacebook)
        self.facebookPublishButton.selected = YES;
    else self.facebookPublishButton.selected = NO;
    
}


//############################################# MENTIONS ##################################################
-(void)updateMentionsInDatabase:(PFObject*)object{
    if(!self.previousComment)
        self.previousComment = @"";
    self.autocompletePopover = [[self storyboard] instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
    [self.autocompletePopover saveMentionToDatabase:object comment:[self.photos objectAtIndex:0][@"caption"] previousComment:self.previousComment photo:[self.photos objectAtIndex:0] members:self.trunkMembers];

//    [self.autocompletePopover removeMentionFromDatabase:object comment:self.caption.text previousComment:self.previousComment];
}

#pragma mark - UITextViewDelegate
//As the user types, check for a @mention and display a popup with a list of users to autocomplete
- (void)textViewDidChange:(UITextView *)textView{
    
    if ([textView.text length] > 1){

        NSString *code = [textView.text substringFromIndex: [textView.text length] - 2];
        if ([code isEqualToString:@" "]){
            [textView setKeyboardType:UIKeyboardTypeDefault];
        }
    }
    
    //get the word that the user is currently typing
    NSRange cursorPosition = [textView selectedRange];
    NSString* substring = [textView.text substringToIndex:cursorPosition.location];
    NSString* lastWord = [[substring componentsSeparatedByString:@" "] lastObject];
    
    //Display the Popover if there is a @ plus a letter typed and only if it is not already showing
    if([self displayAutocompletePopover:lastWord]){
        if(!self.autocompletePopover.delegate){
            //Instantiate the view controller and set its size
            self.autocompletePopover = [[self storyboard] instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
            self.autocompletePopover.modalPresentationStyle = UIModalPresentationPopover;
            
            //force the popover to display like an iPad popover otherwise it will be full screen
            self.popover  = self.autocompletePopover.popoverPresentationController;
            self.popover.delegate = self;
//            self.popover.sourceView = self.caption;
//            self.popover.sourceRect = [self.caption bounds];
            self.popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
            
            if([[TTCache sharedCache] mentionUsers] && [[TTCache sharedCache] mentionUsers].count > 0){
                
                self.autocompletePopover.friendsArray = [NSMutableArray arrayWithArray:[[TTCache sharedCache] mentionUsers]];
                
                self.autocompletePopover.mentionText = lastWord;
                [self.autocompletePopover updateAutocompleteTableView];
                //If there are friends to display, now show the popup on the screen
                if(self.autocompletePopover.displayFriendsArray.count > 0 || self.autocompletePopover.displayFriendsArray != nil){
                    self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], [self.autocompletePopover preferredHeightForPopover]);
                    self.autocompletePopover.delegate = self;
                    [self presentViewController:self.autocompletePopover animated:YES completion:nil];
                }
                
            }else{
            
                if(!self.trunkMembers)
                    self.trunkMembers = [[NSArray alloc] init];
                
                Photo *photo = [self.photos objectAtIndex:self.path];
                if(!photo)
                    photo = [[Photo alloc] init];
                
                //Build the friends list for the table view in the popover and wait
                NSDictionary *data = @{
                                       @"trunkMembers" : self.trunkMembers,
                                       @"trip" : self.trip,
                                       @"photo" : photo
                                       };
                [self.autocompletePopover buildPopoverList:data block:^(BOOL succeeded, NSError *error){
                    if(succeeded){
                        [[TTCache sharedCache] setMentionUsers:self.autocompletePopover.friendsArray];
                        //send the current word to the Popover to use for comparison
                        self.autocompletePopover.mentionText = lastWord;
                        [self.autocompletePopover updateAutocompleteTableView];
                        //If there are friends to display, now show the popup on the screen
                        if(self.autocompletePopover.displayFriendsArray.count > 0 || self.autocompletePopover.displayFriendsArray != nil){
                            self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], [self.autocompletePopover preferredHeightForPopover]);
                            self.autocompletePopover.delegate = self;
                            [self presentViewController:self.autocompletePopover animated:YES completion:nil];
                        }
                    }else{
                        NSLog(@"Error: %@",error);
                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"textViewDidChange:"];
                    }
                }];
                
            }
            
        }
    }
    
    //Update the table view in the popover but only if it is currently displayed
    if([self updateAutocompletePopover:lastWord]){
        self.autocompletePopover.mentionText = lastWord;
        [self.autocompletePopover updateAutocompleteTableView];
    }
    
    //Remove the popover if a space is typed
    if([self dismissAutocompletePopover:lastWord]){
        [self dismissViewControllerAnimated:YES completion:nil];
        self.popover.delegate = nil;
        self.autocompletePopover = nil;
    }
    
//    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.caption.text];
//    [self.caption setSelectedRange:NSMakeRange(cursorPosition.location, 0)];
}

//Only true if user has typed an @ and a letter and if the popover is not showing
-(BOOL)displayAutocompletePopover:(NSString*)lastWord{
    return [lastWord containsString:@"@"] && ![lastWord isEqualToString:@"@"] && !self.popover.delegate;
}

//Only true if the popover is showing and the user typed a space
-(BOOL)dismissAutocompletePopover:(NSString*)lastWord{
    return self.popover.delegate && ([lastWord hasSuffix:@" "] || [lastWord isEqualToString:@""]);
}

//Only true if the popover is showing and there are friends to show in the table view and the @mention isn't broken
-(BOOL)updateAutocompletePopover:(NSString*)lastWord{
    return self.popover.delegate && self.autocompletePopover.displayFriendsArray.count > 0 && ![lastWord isEqualToString:@""];
}

//Dismiss the popover and reset the delegates
-(void)removeAutocompletePopoverFromSuperview{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.popover.delegate = nil;
    self.autocompletePopover = nil;
}

#pragma mark - TTSuggestionTableViewControllerDelegate
//The popover is telling this view controller to dismiss it
- (void)popoverViewControllerShouldDissmissWithNoResults{
    [self removeAutocompletePopoverFromSuperview];
}

//replace the currently typed word with the the username
-(void)insertUsernameAsMention:(NSString*)username{
    //Get the currently typed word
//    NSRange cursorPosition = [self.caption selectedRange];
//    NSString* substring = [self.caption.text substringToIndex:cursorPosition.location];
//    NSString* lastWord = [[substring componentsSeparatedByString:@" "] lastObject];
//    //get a mutable copy of the current caption
//    NSMutableString *caption = [NSMutableString stringWithString:self.caption.text];
//    //create the replacement range of the typed mention
//    NSRange mentionRange = NSMakeRange(cursorPosition.location-[lastWord length], [lastWord length]);
//    //replace that typed @mention with the user name of the user they want to mention
//    NSString *mentionString = [caption stringByReplacingCharactersInRange:mentionRange withString:[NSString stringWithFormat:@"%@ ",username]];
//    
//    //display the new caption
//    self.caption.text = mentionString;
//    //dismiss the popover
//    [self removeAutocompletePopoverFromSuperview];
//    //reset the font colors and make sure the cursor is right after the mention. +1 to add a space
//    self.caption.attributedText = [TTHashtagMentionColorization colorHashtagAndMentionsWithBlack:YES text:self.caption.text];
//    [self.caption setSelectedRange:NSMakeRange(cursorPosition.location-[lastWord length]+[username length]+1, 0)];
//    self.autocompletePopover.delegate = nil;
}

//Adjust the height of the popover to fit the number of usernames in the tableview
-(void)adjustPreferredHeightOfPopover:(NSUInteger)height{
    self.autocompletePopover.preferredContentSize = CGSizeMake([self.autocompletePopover preferredWidthForPopover], height);
}

- (NSString*)getUsernameFromLink:(NSString*)link{
    return [link substringFromIndex:1];
}

//-(NSString*)separateMentions:(NSString*)comment{
//    if(![comment containsString:@"@"])
//        return comment;
//
//    NSArray *array = [comment componentsSeparatedByString:@"@"];
//    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
//    return [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
//}

-(NSString*)separateMentions:(NSString*)comment{
    if(![comment containsString:@"@"])
        return comment;
    
    //separate the mentions
    NSArray *array = [comment componentsSeparatedByString:@"@"];
    NSString *spacedMentions = [array componentsJoinedByString:@" @"];
    spacedMentions = [spacedMentions stringByReplacingOccurrencesOfString:@"  @" withString:@" @"];
    
    //make all mentions lowercase
    array = [spacedMentions componentsSeparatedByString:@" "];
    NSMutableArray *lcArray = [[NSMutableArray alloc] init];
    for(NSString *string in array){
        //check if this is a mention
        if(![string isEqualToString:@""]){
            if([[string substringToIndex:1] isEqualToString:@"@"]){
                [lcArray addObject:[string lowercaseString]];
            }else{
                [lcArray addObject:string];
            }
        }
    }
    return [lcArray componentsJoinedByString:@" "];
}

#pragma mark - UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

-(void)buildMentionUsersCache{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.autocompletePopover = [storyboard instantiateViewControllerWithIdentifier:@"TTSuggestionTableViewController"];
    
    //This is the prevent a crash
    if(!self.trunkMembers)
        self.trunkMembers = [[NSArray alloc] init];
    
    //make sure current user is in the array
    NSMutableArray *members = [NSMutableArray arrayWithArray:self.trunkMembers];
    if(![self array:members containsPFObjectById:[PFUser currentUser]]){
        //if not, add the user to the array
        [members addObject:[PFUser currentUser]];
    }
    
    //set trunkMembers to new array
    self.trunkMembers = members;
    
    //Added this to prevent a crash but may want to use fetchIfNeeded
    if(!self.trip)
        self.trip = [[Trip alloc] init];
    
    //Added this to prevent a crash but may want to use fetchIfNeeded
    Photo *photo = [[Photo alloc] init];
    photo.user = [PFUser currentUser];
    photo.trip = self.trip;
    
    //Build the friends list for the table view in the popover and wait
    NSDictionary *data = @{
                           @"trunkMembers" : self.trunkMembers,
                           @"trip" : self.trip,
                           @"photo" : photo
                           };
    [self.autocompletePopover buildPopoverList:data block:^(BOOL succeeded, NSError *error){
        if(succeeded){
            [[TTCache sharedCache] setMentionUsers:self.autocompletePopover.friendsArray];
        }else{
            NSLog(@"Error: %@",error);
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"buildMentionUsersCache:"];
        }
    }];
}

//Check if the object's objectId matches the objectId of any member of the array.
- (BOOL) array:(NSArray *)array containsPFObjectById:(PFObject *)object{
    for (PFObject *arrayObject in array){
        if ([[arrayObject objectId] isEqual:[object objectId]]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - UIPopoverControllerDelegate
- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController{
    self.popover.delegate = nil;
    self.autocompletePopover = nil;
}

//############################################# MENTIONS ##################################################

@end
