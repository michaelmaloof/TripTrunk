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

#define OVERLAY_VIEW_TAG 121212121

@interface AddTripPhotosViewController ()  <UINavigationControllerDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextViewDelegate, UIPopoverPresentationControllerDelegate,TTSuggestionTableViewControllerDelegate,PhotoDelegate,DLFPhotosPickerViewControllerDelegate>
@property NSMutableArray *photos;
@property (weak, nonatomic) IBOutlet UICollectionView *tripCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *submitTrunk;
@property NSInteger path;
@property BOOL alreadyTrip;
@property NSMutableArray *currentSelectionPhotos;
@property float amount;
//Facebook
@property (strong, nonatomic) IBOutlet UIButton *facebookPublishButton;
@property BOOL publishToFacebook;
@property (strong, nonatomic) NSMutableArray *facebookPhotos;

//############################################# MENTIONS ##################################################
//@property (weak, nonatomic) IBOutlet UITextView *caption;
//@property (weak, nonatomic) IBOutlet TTTAttributedLabel *captionLabel;
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
    self.currentSelectionPhotos= [[NSMutableArray alloc]init];
    self.tripCollectionView.backgroundColor = [TTColor tripTrunkClear];
    self.tripCollectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    PFUser *currentUser = [PFUser currentUser];
    if(self.trip.isPrivate || !currentUser[@"fbid"]){
        self.facebookPublishButton.enabled = NO;
        self.facebookPublishButton.selected = YES;
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
                [view dontRefreshMap];
                [view updateTrunkColor:self.trip isHot:hotness member:mem];
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

- (void)selectPhotosButtonPressed{
    
    // request authorization status
//    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
//        dispatch_async(dispatch_get_main_queue(), ^{
//            // Navigation Bar apperance
//            UINavigationBar *navBar = [UINavigationBar appearanceWhenContainedIn:[CTAssetsPickerController class], nil];
//            
//            // tint color
//            navBar.tintColor = [TTColor tripTrunkBlue];
//            
//            //Button attributes
//            UIBarItem *buttons = [UIBarButtonItem appearanceWhenContainedIn:[CTAssetsPickerController class], nil];
//            NSDictionary *attributes = @{NSFontAttributeName: [TTFont tripTrunkFont16]};
//            [buttons setTitleTextAttributes:attributes forState:UIControlStateNormal];
//            
//            // init picker
//            CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
//            
//            // set delegate
//            picker.delegate = self;
//            
//            // present picker
//            [self presentViewController:picker animated:YES completion:nil];
//        });
//    }];
    
    DLFPhotosPickerViewController *photosPicker = [[DLFPhotosPickerViewController alloc] init];
    [photosPicker setPhotosPickerDelegate:self];
    [photosPicker setMultipleSelections:YES];
    [self presentViewController:photosPicker animated:YES completion:nil];
    
}

#pragma mark - DLFPhotosPickerViewDelegate
//- (void)photosPicker:(DLFPhotosPickerViewController *)photosPicker detailViewController:(DLFDetailViewController *)detailViewController didSelectPhoto:(PHAsset *)photo {
//    [photosPicker dismissViewControllerAnimated:YES completion:^{
//        [self.tripCollectionView reloadData];
//    }];
//}

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

-(void)savePhotosToParse{
    
    __block int uploadingFailCount = 0;
    
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
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        [options setVersion:PHImageRequestOptionsVersionCurrent];
        [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
        [options setNetworkAccessAllowed:YES];
        
        [[PHImageManager defaultManager] requestImageDataForAsset:photo.imageAsset options:options
                                                    resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                        // Calls the method to actually upload the image and save the Photo to parse
                                                        [[TTUtility sharedInstance] uploadPhoto:photo withImageData:imageData block:^(BOOL succeeded, PFObject *commentObject, NSString* url, NSError *error) {
                                                            if(!error){
                                                                NSString *photoComment = @"";
                                                                if(commentObject){
                                                                    [self updateMentionsInDatabase:commentObject];
                                                                    photoComment = commentObject[@"content"];
                                                                }
                                                                
                                                                NSDictionary *photoDetails = @{@"url":url,
                                                                                               @"caption":photoComment};
                                                                [self.facebookPhotos addObject:photoDetails];
                                                                if((self.photos.count == self.facebookPhotos.count) && self.publishToFacebook){
                                                                    TrunkViewController *trunk = [[TrunkViewController alloc] init];
                                                                    [trunk initFacebookUpload:self.facebookPhotos];
                                                                }
                                                            }
                                                            else{
                                                                NSLog(@"Error: %@",error);
                                                                uploadingFailCount++;
                                                            }
                                                        }];
                                                    }];
    }
    
    if (uploadingFailCount > 0) {
        [self updateTripDetailForUploadingError:uploadingFailCount];
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


//-(void)uploadPhotosToFacebook{
//    //FIXME: Don't forget to handle the privacy issue
//    NSDictionary *params = @{
//                             @"url": self.facebookPhotos[0],
//                             };
//    /* make the API call */
//    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
//                                  initWithGraphPath:@"/me/photos"
//                                  parameters:params
//                                  HTTPMethod:@"POST"];
//    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
//                                          id result,
//                                          NSError *error) {
//        if(error)
//            NSLog(@"Error uploading to facebook: %@",error);
//        else NSLog(@"Facebook upload result: %@",result);
//    }];
//}

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
        Photo *photo = [self.photos objectAtIndex:indexPath.row-1];
        [cell.layer setCornerRadius:0.0];
        [cell.layer setMasksToBounds:YES];
        cell.tripImageView.caption = photo.caption;
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
            cell.captionImageView.hidden = NO;
        } else {
            cell.captionImageView.hidden = YES;
        }
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
