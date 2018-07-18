//
//  TTAddPhotosViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 11/27/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#define distanceThreshold 25
#define timeframeThresholdInDays 7
#define maximumVideoLengthAllowedBeforeForcedEdit 15.0

#import "TTAddPhotosViewController.h"
#import <Photos/Photos.h>
#import "TTPhotoPicker.h"
#import "TTAddPhotosViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "TTOnboardingButton.h"
#import "TTFont.h"
#import "TTPhotosToAddViewCell.h"
#import "TTUtility.h"
#import "SocialUtility.h"
#import "TTAnalytics.h"
#import "TTTimelineViewController.h"
#import "TTMainTabBarController.h"

@interface TTAddPhotosViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UIVideoEditorControllerDelegate>
@property (strong, nonatomic) PHFetchResult *assets;
@property (strong, nonatomic) NSMutableArray *filteredAssets;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator; //<---------------------------------
@property (strong, nonatomic) IBOutlet TTPhotoPicker *collectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *photosToAddCollectionView;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *addButton;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *backButton;
@property (strong, nonatomic) NSMutableArray *photosToAdd;
@property (strong, nonatomic) CLLocation *location;
@property NSIndexPath *editingVideoAtIndexPath;
//@property NSInteger path;
@property NSUInteger taskCount;
@property BOOL publishToFacebook; //<---------------------------------
@property BOOL isNewAsset; //<-------- or figure out why didSaveEditedVideoToPath: is being called twice
@end

@implementation TTAddPhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.photosToAdd = [[NSMutableArray alloc] init];
    self.filteredAssets = [[NSMutableArray alloc] init];
    self.publishToFacebook = NO; //<------------------------------------------------------------------- ?
    self.taskCount = 0;
    self.location = [[CLLocation alloc] initWithLatitude:self.trip.lat longitude:self.trip.longitude];
    if([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized){
        [self reloadAssets];
    }else{
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
//            [self showNeedAccessMessage];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)reloadAssets{
//    [self.activityIndicator startAnimating];
    self.assets = nil;
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[
                                     [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
                                     ];
    self.assets = [PHAsset fetchAssetsWithOptions:fetchOptions];
    
    [self filterAssetsBasedOnLocation];
    [self.collectionView reloadData];
//    [self.activityIndicator stopAnimating];
}

-(void)filterAssetsBasedOnLocation{
    for(PHAsset *asset in self.assets){
        if(asset.location != nil){
            CLLocationDistance distance = [self.location distanceFromLocation:asset.location];
            if((distance/1609.344) <= distanceThreshold && [self timeIntervalIsBelowThreshold:asset.creationDate])
               [self.filteredAssets addObject:asset];
        }
    }
}

-(BOOL)timeIntervalIsBelowThreshold:(NSDate*)creationDate{
    NSDate* date = [NSDate date];
    NSTimeInterval distanceBetweenDates = [date timeIntervalSinceDate:creationDate];
    NSInteger daysBetweenDates = distanceBetweenDates / 86400;
    
    return daysBetweenDates<=timeframeThresholdInDays;
}

-(void)syncCellSelectionWithFilteredAsset:(PHAsset*)asset withState:(BOOL)state{
    int x = 0;
    for(PHAsset *a in self.filteredAssets){
        if(a == asset){
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:x inSection:0];
            TTAddPhotosViewCell *cell = (TTAddPhotosViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.checkmark.hidden = state;
            break;
        }
        x++;
    }
}

-(void)syncCellSelectionWithUnfilteredAsset:(PHAsset*)asset withState:(BOOL)state{
    int x = 0;
    for(PHAsset *a in self.assets){
        if(a == asset){
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:x inSection:1];
            TTAddPhotosViewCell *cell = (TTAddPhotosViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.checkmark.hidden = state;
            break;
        }
        x++;
    }
}

#pragma mark - UIAlertView
-(void)showNeedAccessMessage{ //<-------------- need this?
    
    UIAlertController * alert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Image picker",@"Image picker")
                                                                  message:NSLocalizedString(@"App need get access to photos",@"App need get access to photos")
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action){
        NSLog(@"you pressed the Yes button");
    }];
    
    UIAlertAction* noButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",@"Cancel")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action){
        NSLog(@"you pressed cencel button");
    }];
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if(collectionView == self.collectionView){
        if(section == 0)
            return self.filteredAssets.count;
        else return self.assets.count;
    }else{
        return self.photosToAdd.count;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    double num = (kScreenWidth/3)-2;
    if(collectionView == self.collectionView)
        return CGSizeMake(num, num);
    else return CGSizeMake(60, 60);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    double num = (kScreenWidth/3)-2;
    if(collectionView == self.collectionView){
        if(indexPath.section == 0){
            PHAsset *asset = self.filteredAssets[indexPath.row];
            TTAddPhotosViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
            cell.videoIcon.hidden = YES;
            
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(num, num) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                cell.image.image = result;
                cell.image.contentMode = UIViewContentModeScaleAspectFill;
            }];
            
            if(asset.mediaType == PHAssetMediaTypeVideo)
                cell.videoIcon.hidden = NO;

            cell.checkmark.hidden = [self checkCellForCheckMarkState:asset andIndexPath:indexPath];
            return cell;
        }else{
            PHAsset *asset = self.assets[indexPath.row];
            TTAddPhotosViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
            cell.videoIcon.hidden = YES;
            
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(num, num) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                cell.image.image = result;
                cell.image.contentMode = UIViewContentModeScaleAspectFill;
            }];
            
            if(asset.mediaType == PHAssetMediaTypeVideo)
                cell.videoIcon.hidden = NO;
            
            cell.checkmark.hidden = [self checkCellForCheckMarkState:asset andIndexPath:indexPath];
            return cell;
        }
    }else{ //<-----photosToAddCollectionView
        TTPhotosToAddViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
        Photo *media = self.photosToAdd[indexPath.row];
        if(media.imageAsset.mediaType == PHAssetMediaTypeVideo)
            cell.video_icon.hidden = NO;
        else cell.video_icon.hidden = YES;
        
        if(media.editedPath){
            if(media.image){
                cell.image.image = media.image;
            }else{
                NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:media.editedPath];
                AVURLAsset *asset = [AVURLAsset assetWithURL:fileURL];
                AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                imageGenerator.appliesPreferredTrackTransform = YES;
                CGImageRef cgImage = [imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil];
                cell.image.image = [UIImage imageWithCGImage:cgImage];
                media.image = [UIImage imageWithCGImage:cgImage];
            }
        }else{
            if(media.image){
                cell.image.image = media.image;
                cell.image.contentMode = UIViewContentModeScaleAspectFill;
            }else{
                [[PHImageManager defaultManager] requestImageForAsset:media.imageAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    cell.image.image = result;
                    cell.image.contentMode = UIViewContentModeScaleAspectFill;
                    media.image = result;
                }];
            }
        }
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if(collectionView == self.collectionView){
        self.isNewAsset = YES;
        TTAddPhotosViewCell *cell = (TTAddPhotosViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
        if(cell.checkmark.hidden){ //<----------- SELECT PHOTO ----------------
            cell.checkmark.hidden = NO;
            if(indexPath.section==0){
                Photo *media = [[Photo alloc] init];
                media.imageAsset = self.filteredAssets[indexPath.row];
                if(media.imageAsset.mediaType == PHAssetMediaTypeImage){
                    [self.photosToAdd addObject:media];
                    [self syncCellSelectionWithUnfilteredAsset:self.filteredAssets[indexPath.row] withState:NO];
                }else{
                    if(media.imageAsset.duration > maximumVideoLengthAllowedBeforeForcedEdit){
                        [self beginVideoTruncation:media inSection:0 andIndex:(NSInteger)indexPath.row withCompletion:^(BOOL success) {
                            if(success){
                                [self syncCellSelectionWithUnfilteredAsset:self.filteredAssets[indexPath.row] withState:NO];
                            }else{
                                cell.checkmark.hidden = YES;
                                NSString *text = NSLocalizedString(@"Unable to edit this video. Sorry for the inconvenience.", @"Unable to edit this video. Sorry for the inconvenience.");
                                [self simpleErrorNotificationWithText:text];
                            }
                        }];
                    }else{
                        [self.photosToAdd addObject:media];
                        [self syncCellSelectionWithUnfilteredAsset:self.filteredAssets[indexPath.row] withState:NO];
                    }
                }
            }else{
                Photo *media = [[Photo alloc] init];
                media.imageAsset = self.assets[indexPath.row];
                if(media.imageAsset.mediaType == PHAssetMediaTypeImage){
                    [self.photosToAdd addObject:media];
                    if([self.collectionView numberOfItemsInSection:0]>0)
                        [self syncCellSelectionWithFilteredAsset:self.assets[indexPath.row] withState:NO];
                }else{
                    if(media.imageAsset.duration > maximumVideoLengthAllowedBeforeForcedEdit){
                        [self beginVideoTruncation:media inSection:1 andIndex:(NSInteger)indexPath.row withCompletion:^(BOOL success) {
                            if(success){
                                if([self.collectionView numberOfItemsInSection:0]>0)
                                    [self syncCellSelectionWithFilteredAsset:self.assets[indexPath.row] withState:NO];
                            }else{
                                cell.checkmark.hidden = YES;
                                NSString *text = NSLocalizedString(@"Unable to edit this video. Sorry for the inconvenience.", @"Unable to edit this video. Sorry for the inconvenience.");
                                [self simpleErrorNotificationWithText:text];
                            }
                        }];
                    }else{
                        [self.photosToAdd addObject:media];
                        [self syncCellSelectionWithFilteredAsset:self.assets[indexPath.row] withState:NO];
                    }
                }
            }
        }else{ //<----------- DESELECT PHOTO ----------------
            cell.checkmark.hidden = YES;
            if(indexPath.section==0){
                for(Photo *p in self.photosToAdd){
                    if(p.imageAsset == self.filteredAssets[indexPath.row]){
                        [self.photosToAdd removeObject:p];
                        break;
                    }
                }
            }else{
                for(Photo *p in self.photosToAdd){
                    if(p.imageAsset == self.assets[indexPath.row]){
                        [self.photosToAdd removeObject:p];
                        break;
                    }
                }
            }
            
            [self syncCellSelectionWithFilteredAsset:self.assets[indexPath.row] withState:YES];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.photosToAddCollectionView reloadData];
        });
        
        if(self.photosToAdd.count > 0){
            self.photosToAddCollectionView.hidden = NO;
            self.addButton.hidden = NO;
        }else{
            self.photosToAddCollectionView.hidden = YES;
            self.addButton.hidden = YES;
        }
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    if(collectionView == self.collectionView)
        return 2;
    else return 1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *theView;
    if(collectionView == self.collectionView){
        if(kind == UICollectionElementKindSectionHeader){
            theView = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
            if(indexPath.section == 0){
            NSString *headerString = NSLocalizedString(@"Add New Content", @"Add New Content");
            NSString *subheadString = NSLocalizedString(@"Recently Taken", @"Recently Taken");
            NSString *textString = NSLocalizedString(@"Here is some recent content taken near this trunk's location. Select which ones to add.", @"Here is some recent content taken near this trunk's location. Select which ones to add.");
            [theView addSubview:[self headerLabel:headerString]];
            [theView addSubview:[self subheadLabel:subheadString]];
            [theView addSubview:[self headerTextLabel:textString]];
            }else{
                NSString *subheadString = NSLocalizedString(@"Camera Roll", @"Camera Roll ");
                [theView addSubview:[self subheadLabel:subheadString]];
            }
        }
    }
    
    return theView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    if(collectionView == self.collectionView){
        if(section == 0)
            return CGSizeMake(kScreenWidth, 150);
        else return CGSizeMake(kScreenWidth, 89);
    }else{
        return CGSizeMake(0, 0);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    return CGSizeMake(0,0);
}

-(BOOL)checkCellForCheckMarkState:(PHAsset*)asset andIndexPath:(NSIndexPath*)indexPath{
    BOOL status = YES;
    for(Photo *a in self.photosToAdd){
        if(a.imageAsset == asset){
            status = NO;
            break;
        }
    }
    return status;
}

#pragma mark - UICollectionView Header Content
-(UILabel*)headerLabel:(NSString*)text{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 21, kScreenWidth, 21)];
    label.font = [TTFont TT_AddContent_header];
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    [label setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

    return label;
}

-(UILabel*)subheadLabel:(NSString*)text{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 68, kScreenWidth-16, 21)];
    label.font = [TTFont TT_AddContent_subhead];
    label.text = text;
    [label setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    
    return label;
}

-(UITextView*)headerTextLabel:(NSString*)text{
    UITextView *textview = [[UITextView alloc] initWithFrame:CGRectMake(12, 87, kScreenWidth-12, 126)];
    textview.font = [TTFont TT_AddContent_text];
    textview.textColor = [TTColor tripTrunkDarkGray];
    textview.text = text;
    return textview;
}

#pragma mark - Save Photos/Videos
- (void)convertVideoToMediumQuailtyWithInputURL:(NSURL*)inputURL
                                      outputURL:(NSURL*)outputURL
                                        handler:(void (^)(AVAssetExportSession*))handler
{
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         handler(exportSession);
     }];
}

- (void)uploadAllPhotos { //FIXME: Handle error handling better on lost trunks here
    
    [self.trip.publicTripDetail fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        //clear the saved upload details. If it creashes again, these will be resaved
        NSUserDefaults *uploadError = [NSUserDefaults standardUserDefaults];
        NSMutableArray *localIdentifiers = [[NSMutableArray alloc] init];
        
        for(Photo *photo in self.photosToAdd){
            if(photo.imageAsset.localIdentifier != nil)
                [localIdentifiers addObject:photo.imageAsset.localIdentifier];
//FIXME: Are we doing captions? <-----------------------------------------------------
//            if(photo.caption)
//                [self.photoCaptions addObject:photo.caption];
//            else [self.photoCaptions addObject:@""];
        }
        
        if(self.publishToFacebook)
            [uploadError setObject:@"YES" forKey:@"currentFacebookUpload"];
        else [uploadError setObject:nil forKey:@"currentFacebookUpload"];
        
        [uploadError setObject:localIdentifiers forKey:@"currentImageUpload"];
//FIXME: Are we doing captions? <-----------------------------------------------------
//        [uploadError setObject:self.photoCaptions forKey:@"currentPhotoCaptions"];
        [uploadError setObject:nil forKey:@"uploadError"];
        [uploadError setObject:nil forKey:@"currentTripId"];
        [uploadError synchronize];
        int originalCount = self.trip.publicTripDetail.photoCount;
        
        if (self.photosToAdd.count > 0){
            if (!self.trip.publicTripDetail){
                self.trip.publicTripDetail = [[PublicTripDetail alloc]init];
            }
            self.trip.publicTripDetail.mostRecentPhoto = [NSDate date];
            self.trip.publicTripDetail.photoCount = self.trip.publicTripDetail.photoCount + (int)self.photosToAdd.count;
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
                    NSString *text = NSLocalizedString(@"Something went wrong. Please try again.",@"Something went wrong. Please try again.");
                    [self simpleErrorNotificationWithText:text];
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
    
    for (Photo *photo in self.photosToAdd)
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
        if(photo.imageAsset.mediaType == PHAssetMediaTypeVideo){
            
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            [options setVersion:PHVideoRequestOptionsVersionCurrent];
            [options setDeliveryMode:PHVideoRequestOptionsDeliveryModeHighQualityFormat];
            [options setNetworkAccessAllowed:YES];
            
            [[PHImageManager defaultManager] requestAVAssetForVideo:photo.imageAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                
                //load the video but check for a trimmed video first.
                NSString *pathToVideo;
                if(photo.editedPath)
                    pathToVideo = photo.editedPath;
                else pathToVideo = [(AVURLAsset *)asset URL].absoluteString;
//                __block NSString *path = photo.editedPath;
                
                NSURL *videoURL = [NSURL URLWithString:pathToVideo];
                NSString *randString = [NSString stringWithFormat:@"video-%f.mov",[[NSDate date] timeIntervalSince1970]];
                NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:randString]];
                [self convertVideoToMediumQuailtyWithInputURL:videoURL outputURL:outputURL handler:^(AVAssetExportSession *exportSession)
                 {
                     if (exportSession.status == AVAssetExportSessionStatusCompleted){
                         NSLog(@"completed\n");
                         photo.editedPath = outputURL.absoluteString;
                         [[TTUtility sharedInstance] uploadVideo:photo photosCount:(int)self.photosToAdd.count toFacebook:self.publishToFacebook block:^(PFObject *video) {
                             photo.video = video;
                             
                             //remove compressed or trimmed video from temp directory
                             NSFileManager *manager = [NSFileManager defaultManager];
                             NSURL *deletePath = [NSURL URLWithString:photo.editedPath];
                             [manager removeItemAtPath:[deletePath path] error:nil];
                             photo.editedPath = nil;
                             [[TTUtility sharedInstance] uploadPhoto:photo photosCount:(int)self.photosToAdd.count toFacebook:NO block:^(Photo *photo) {
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
//FIXME: Are we doing captions? <-----------------------------------------------------
//                                         [self.photoCaptions removeObjectAtIndex:i];
                                         break;
                                     }
                                     i++;
                                 }
                                 
//FIXME: Are we doing captions? <-----------------------------------------------------
//                                 [defaults setObject:self.photoCaptions forKey:@"currentPhotoCaptions"];
                                 [defaults setObject:localIdentifiers forKey:@"currentImageUpload"];
                                 [defaults synchronize];
                                 
                                 
                                 // If the photo has a caption, we need to add that as a comment so it shows up in the comments list. Otherwise we're done!
                                 if (photo.caption && ![photo.caption isEqualToString:@""]) {
                                     // This photo has a caption, so we need to deal with creating a comment object & checking for mentions.
                                     [SocialUtility addComment:photo.caption forPhoto:photo isCaption:YES block:^(BOOL succeeded, PFObject *object, PFObject *commentObject, NSError *error) {
                                         if (!error && commentObject) {
                                             [TTAnalytics trunkCreated:self.photosToAdd.count numOfMembers:self.trunkMembers.count];
//FIXME: Are we doing mentions? <-----------------------------------------------------
//                                             [self updateMentionsInDatabase:commentObject];
                                         }
                                     }];
                                 }
                                 
                                 [self uploadTasksCompleted];
                                 
                             }];
                         }];
                     }else{
                         NSLog(@"Video compression error: %@",exportSession.error);
                         //Upload uncompressed video, This could be large
                         [[TTUtility sharedInstance] uploadVideo:photo photosCount:0 toFacebook:self.publishToFacebook block:^(PFObject *video) {
                             photo.video = video;
                             photo.editedPath = nil;
                             [[TTUtility sharedInstance] uploadPhoto:photo photosCount:(int)self.photosToAdd.count toFacebook:NO block:^(Photo *photo) {
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
//FIXME: Are we doing captions? <-----------------------------------------------------
//                                         [self.photoCaptions removeObjectAtIndex:i];
                                         break;
                                     }
                                     i++;
                                 }
//FIXME: Are we doing captions? <-----------------------------------------------------
//                                 [defaults setObject:self.photoCaptions forKey:@"currentPhotoCaptions"];
                                 [defaults setObject:localIdentifiers forKey:@"currentImageUpload"];
                                 [defaults synchronize];
                                 
                                 
                                 // If the photo has a caption, we need to add that as a comment so it shows up in the comments list. Otherwise we're done!
                                 if (photo.caption && ![photo.caption isEqualToString:@""]) {
                                     // This photo has a caption, so we need to deal with creating a comment object & checking for mentions.
                                     [SocialUtility addComment:photo.caption forPhoto:photo isCaption:YES block:^(BOOL succeeded, PFObject *object, PFObject *commentObject, NSError *error) {
                                         if (!error && commentObject) {
                                             [TTAnalytics trunkCreated:self.photosToAdd.count numOfMembers:self.trunkMembers.count];
//FIXME: Are we doing mentions? <-----------------------------------------------------
//                                             [self updateMentionsInDatabase:commentObject];
                                         }
                                     }];
                                 }
                                 
                                 [self uploadTasksCompleted];
                             }];
                         }];
                     }
                 }];
                
            }];
            
        }else{
            [[TTUtility sharedInstance] uploadPhoto:photo photosCount:(int)self.photosToAdd.count toFacebook:self.publishToFacebook block:^(Photo *savedPhoto) {
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
//FIXME: Are we doing captions? <-----------------------------------------------------
//                        [self.photoCaptions removeObjectAtIndex:i];
                        break;
                    }
                    i++;
                }
                
//FIXME: Are we doing captions? <-----------------------------------------------------
//                [defaults setObject:self.photoCaptions forKey:@"currentPhotoCaptions"];
                [defaults setObject:localIdentifiers forKey:@"currentImageUpload"];
                [defaults synchronize];
                
                
                // If the photo has a caption, we need to add that as a comment so it shows up in the comments list. Otherwise we're done!
                if (savedPhoto.caption && ![savedPhoto.caption isEqualToString:@""]) {
                    // This photo has a caption, so we need to deal with creating a comment object & checking for mentions.
                    [SocialUtility addComment:savedPhoto.caption forPhoto:savedPhoto isCaption:YES block:^(BOOL succeeded, PFObject *object, PFObject *commentObject, NSError *error) {
                        if (!error && commentObject) {
                            [TTAnalytics trunkCreated:self.photosToAdd.count numOfMembers:self.trunkMembers.count];
//FIXME: Are we doing mentions? <-----------------------------------------------------
//                            [self updateMentionsInDatabase:commentObject];
                        }
                    }];
                }
                
                [self uploadTasksCompleted];
                
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
    [photosAddedNotification save];
    
}

-(void)updateTripDetailForUploadingError:(int)errorCount{
    [self.trip.publicTripDetail fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        
        if (self.photosToAdd.count > 0){
            if (!self.trip.publicTripDetail){
                self.trip.publicTripDetail = [[PublicTripDetail alloc]init];
            }
            self.trip.publicTripDetail.mostRecentPhoto = [NSDate date];
            self.trip.publicTripDetail.photoCount = self.trip.publicTripDetail.photoCount + (int)self.photosToAdd.count -errorCount;
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

#pragma mark - VideoEditorController delegate
- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath{
    NSLog(@"video edited: %@",editedVideoPath);

    //<------------ STUPID HACK (isNewAsset)---------------------------------
    if(self.isNewAsset){
        PHAsset *originalAsset;
        if(self.editingVideoAtIndexPath.section == 0)
            originalAsset = self.filteredAssets[self.editingVideoAtIndexPath.row];
        else originalAsset = self.assets[self.editingVideoAtIndexPath.row];
        Photo *media = [[Photo alloc] init];
        media.editedPath = editedVideoPath;
        media.imageAsset = originalAsset;
        
        [self.photosToAdd addObject:media];
        self.isNewAsset = NO;
    }
    //<------------ STUPID HACK (isNewAsset)---------------------------------
    
    [editor.presentingViewController dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.photosToAddCollectionView reloadData];
        });
        
        if(self.photosToAdd.count > 0){
            self.photosToAddCollectionView.hidden = NO;
            self.addButton.hidden = NO;
        }
    }];
}

- (void)videoEditorController:(UIVideoEditorController *)editor didFailWithError:(NSError *)error{
    NSLog(@"Error trimming video");
    [editor.presentingViewController dismissViewControllerAnimated:YES completion:^{
//        [self.collectionView reloadData];
        if(self.photosToAdd.count == 0){
            self.photosToAddCollectionView.hidden = YES;
            self.addButton.hidden = YES;
        }
        
//FIXME: WE HAVE TO UNCHECK THE BOX <-----------------------------------------------
    }];
}

- (void)videoEditorControllerDidCancel:(UIVideoEditorController *)editor{
    NSLog(@"User canceled video truncation.");
    [editor.presentingViewController dismissViewControllerAnimated:YES completion:^{
        //        [self.collectionView reloadData];
        if(self.photosToAdd.count == 0){
            self.photosToAddCollectionView.hidden = YES;
            self.addButton.hidden = YES;
        }
        
//FIXME: WE HAVE TO UNCHECK THE BOX <-----------------------------------------------
    }];
}

-(void)beginVideoTruncation:(Photo*)video inSection:(NSInteger)section andIndex:(NSInteger)index withCompletion:(void(^)(BOOL success))completion{
//    NSString *message = NSLocalizedString(@"Would you like to Trim this video or set the caption?","Would you like to Trim this video or set the caption?");
//    NSString *trimActionString = NSLocalizedString(@"Trim Video", @"Trim Video");
//    NSString *setCaptionActionString = NSLocalizedString(@"Set Caption", @"Set Caption");
//    NSString *cancelActionString = NSLocalizedString(@"Cancel", @"Cancel");
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleActionSheet];
//    UIAlertAction *trimAction = [UIAlertAction actionWithTitle:trimActionString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        UIVideoEditorController* videoEditor = [[UIVideoEditorController alloc] init];
        videoEditor.delegate = self;
        
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        [options setVersion:PHVideoRequestOptionsVersionCurrent];
        [options setDeliveryMode:PHVideoRequestOptionsDeliveryModeHighQualityFormat];
        [options setNetworkAccessAllowed:YES];
        
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:video.imageAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            
            NSString *pathToVideo = [(AVURLAsset *)asset URL].absoluteString;
            pathToVideo = [pathToVideo stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            if ([UIVideoEditorController canEditVideoAtPath:pathToVideo]){
                videoEditor.videoPath = pathToVideo;
                videoEditor.videoMaximumDuration = maximumVideoLengthAllowedBeforeForcedEdit;
//                self.editingVideoAtIndex = index;
//                self.editingVideoInSection = section;
                NSIndexPath *setIndexPath = [NSIndexPath indexPathForRow:index inSection:section];
                self.editingVideoAtIndexPath = setIndexPath;
                
                [self presentViewController:videoEditor animated:YES completion:^{
                    completion(YES);
                }];
            }else{
                NSLog( @"can't edit video at %@", pathToVideo );
                completion(NO);
            }
            
            
        }];
//    }];
//    UIAlertAction *captionAction = [UIAlertAction actionWithTitle:setCaptionActionString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
//        self.path = index;
//        [self performSegueWithIdentifier:@"addPhotoCaption" sender:self];
//    }];
//    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelActionString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
//        
//    }];
//    
//    [alert addAction:trimAction];
//    [alert addAction:captionAction];
//    [alert addAction:cancelAction];
//    [self presentViewController:alert animated:YES completion:nil];
}

-(void)simpleErrorNotificationWithText:(NSString*)text{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:text preferredStyle:UIAlertControllerStyleAlert];
    NSString *cancelActionString = NSLocalizedString(@"Okay", @"Okay");

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelActionString style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
    
        }];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
}

-(void)uploadTasksCompleted{
    
    self.taskCount++;
    
    if(self.photosToAdd.count == self.taskCount){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateTrunksAfterNew" object:nil];
        if ([(NSObject*)self.delegate respondsToSelector:@selector(photoUploadCompleted:)]){
            [self.delegate photoUploadCompleted:self.photosToAdd];
            
            if(self.newTrip){
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Home" bundle:nil];
                TTMainTabBarController *profileViewController = (TTMainTabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"TTMainTabBarController"];
                [self.navigationController pushViewController:profileViewController animated:YES];
            }else{
               [self.navigationController popViewControllerAnimated:YES];
            }
            
        }else{
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Home" bundle:nil];
            TTMainTabBarController *profileViewController = (TTMainTabBarController *)[storyboard instantiateViewControllerWithIdentifier:@"TTMainTabBarController"];
            [self.navigationController pushViewController:profileViewController animated:YES];
            
//            NSArray * controllerArray = [[self navigationController] viewControllers];
//            //FIXME: Do we need this anymore?
//            for (UIViewController *controller in controllerArray){
//                if([controller isKindOfClass:[TTTimelineViewController class]]){
//                    [self.navigationController popToViewController:controller animated:YES];
//                    break;
//                }
//            }
        }
        
    }
}


#pragma mark - UIButton Actions
- (IBAction)addSelectedPhototsToTrunk:(id)sender {
    [self disableUploadButton];
    [self uploadAllPhotos];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)enableUploadButton{
    self.backButton.enabled = YES;
    self.backButton.alpha = 1.0;
    self.addButton.enabled = YES;
    self.addButton.alpha = 1.0;
}

-(void)disableUploadButton{
    self.backButton.enabled = NO;
    self.backButton.alpha = 0;
    self.addButton.enabled = NO;
    self.addButton.alpha = 0;
}

@end
