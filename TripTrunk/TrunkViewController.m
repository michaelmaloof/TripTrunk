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
#import "TrunkMembersViewController.h"
#import "TTUtility.h"
#import "SocialUtility.h"
#import "UserCellCollectionViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "AddTripFriendsViewController.h"
#import "UserProfileViewController.h"
#import "HomeMapViewController.h"
#import "TrunkListViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>

@interface TrunkViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UICollectionViewDelegateFlowLayout, MemberListDelegate, UITextViewDelegate, PhotoDelegate,UIActionSheetDelegate>

/**
 *  Array holding Photo objects for the photos in this trunk
 */
@property (weak, nonatomic) IBOutlet UIImageView *totalLikeHeart;
@property (weak, nonatomic) IBOutlet UILabel *totalLikeButton;
@property NSMutableArray *photos;
@property NSMutableArray *members;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
//@property (weak, nonatomic) IBOutlet UILabel *photoLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDate;
@property (weak, nonatomic) IBOutlet UILabel *endDate;
@property (weak, nonatomic) IBOutlet UILabel *stateCountryLabel;
@property NSIndexPath *path;
@property PFImageView *imageview;
@property int photosOriginal;
@property BOOL isMember;
@property (weak, nonatomic) IBOutlet UICollectionView *memberCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *memberCollectionWidth;
@property BOOL firstLoadDone;
@property int likes;
@property UITextView *descriptionTextView;
@property NSMutableArray *loadingMembers;
@property NSMutableArray *photosSeen;
@property int numberOfImagesPerRow;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scrollViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@end

@implementation TrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.totalLikeButton.hidden = YES;
    self.totalLikeButton.adjustsFontSizeToFitWidth = YES;
    self.totalLikeHeart.hidden = YES;
    self.memberCollectionView.hidden = YES;
    self.navigationController.navigationItem.rightBarButtonItem = nil;
    self.collectionView.backgroundColor = [TTColor tripTrunkClear];
    self.memberCollectionView.backgroundColor = [TTColor tripTrunkClear];
    self.descriptionTextView = [[UITextView alloc]init];
    self.descriptionTextView.hidden = YES;
    //FIXME: Move this to TTFont
    [self.descriptionTextView setFont:[TTFont tripTrunkFont20]];
    self.descriptionTextView.backgroundColor = [TTColor tripTrunkOffWhite];
    self.descriptionTextView.textColor = [TTColor tripTrunkBlue];
    self.descriptionTextView.frame = CGRectMake(self.view.frame.origin.x + 10, self.view.frame.origin.y + 75, self.view.frame.size.width - 20, self.view.frame.size.height -150);
    self.descriptionTextView.editable = NO;
    self.descriptionTextView.selectable = NO;
    self.descriptionTextView.scrollEnabled = YES;
    self.descriptionTextView.delegate = self;
    [self refreshTripDataViews];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.trip.creator fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
            [self.trip.publicTripDetail fetchIfNeededInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (self.trip.publicTripDetail.totalLikes > 0) {
                        self.totalLikeButton.tintColor = [TTColor tripTrunkWhite];
                        self.totalLikeButton.textColor = [TTColor tripTrunkWhite];
                        self.totalLikeButton.text = [NSString stringWithFormat:@"%d", self.trip.publicTripDetail.totalLikes];
                        self.totalLikeButton.hidden = NO;
                        self.totalLikeHeart.hidden = NO;
                    }
                    else{
                        self.totalLikeButton.hidden = YES;
                        self.totalLikeHeart.hidden = YES;
                    }
                });
            }];
            
        }];
    });

    self.photos = [[NSMutableArray alloc] init];
    self.members = [[NSMutableArray alloc] init];
    self.numberOfImagesPerRow = 3;
    // Load initial data
    [self checkIfIsMember];
    // Add observer for when uploading is finished.
    // TTUtility posts the notification when the uploader is done so that we know to refresh the view to show new pictures
    // Notification is also used if a photo is deleted.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryNewlyAddedPhoto)
                                                 name:@"parsePhotosUpdatedNotification"
                                               object:nil];
    
    self.loadingMembers = [[NSMutableArray alloc]init];
    
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
                        self.photosSeen = [[NSMutableArray alloc]init];
                        self.photosSeen = view.viewedPhotos;
                    }
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
                [view userHasViewedTrip:self.trip];
            }
        }
    }
    
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (TrunkListViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[TrunkListViewController class]])
            {
                [view reloadTrunkList:self.trip seen:YES addPhoto:NO photoRemoved:NO];
            }
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    self.tabBarController.tabBar.hidden = NO;
    [self.memberCollectionView reloadData];
}

-(void)viewDidAppear:(BOOL)animated{
    
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKeyExists:@"fromUser"];
    [query whereKeyExists:@"toUser"];
    [query whereKey:@"type" equalTo:@"like"];
    [query whereKey:@"trip" equalTo:self.trip];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError * _Nullable error) {
        if (number < 1){
            self.totalLikeButton.hidden = YES;
            self.totalLikeHeart.hidden = YES;
        } else {
            [self.totalLikeButton setTintColor:[TTColor tripTrunkWhite]];
            self.totalLikeButton.textColor = [TTColor tripTrunkWhite];
            self.totalLikeButton.text = [NSString stringWithFormat:@"%d", number];
            self.totalLikeButton.hidden = NO;
            self.totalLikeHeart.hidden = NO;
        }
    }];
    
    [self setPhotosSeenLoop];
    [self refreshTripDataViews];
    
}

-(void)setPhotosSeenLoop{
    for (UINavigationController *controller in self.tabBarController.viewControllers)
    {
        for (HomeMapViewController *view in controller.viewControllers)
        {
            if ([view isKindOfClass:[HomeMapViewController class]])
            {
                if (controller == (UINavigationController*)self.tabBarController.viewControllers[0]){
                    if (view == (HomeMapViewController*)controller.viewControllers[0]){
                        
                        self.photosSeen = [[NSMutableArray alloc]init];
                        self.photosSeen = view.viewedPhotos;
                    }
                }
            }
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    
    self.navigationItem.titleView = nil;
    
    if (self.trip.publicTripDetail == nil){
        self.trip.publicTripDetail = [[PublicTripDetail alloc]init];
        self.trip.publicTripDetail.mostRecentPhoto = [NSDate date];
        self.trip.publicTripDetail.photoCount = (int)self.photos.count;
        self.trip.publicTripDetail.totalLikes = 0;
        self.trip.publicTripDetail.trip = self.trip;
        [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            NSLog(@"saved");
        }];
    } else if (self.trip.publicTripDetail.trip == nil){
        self.trip.publicTripDetail.trip = self.trip;
        [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            NSLog(@"saved");
        }];
    }
}

- (IBAction)lockTapped:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title =NSLocalizedString(@"Private Trunk", @"Private Trunk");
    alertView.message = NSLocalizedString(@"Only the Trunk Creator and Trunk Members can see that this trunk exists",@"Only the Trunk Creator and Trunk Members can see that this trunk exists");
    alertView.backgroundColor = [TTColor tripTrunkLightBlue];
    [alertView addButtonWithTitle:NSLocalizedString(@"Ok",@"Ok")];
    alertView.tag = 4;
    [alertView show];
}

- (void)refreshTripDataViews {
    // Putting all this here so that if the trip is Edited then the UI will refresh
    self.title  = self.trip.name;
    if (![self.trip.descriptionStory isEqualToString:@""] ||  self.trip.descriptionStory != nil){
        UIButton *navButton =  [UIButton buttonWithType:UIButtonTypeCustom];
        navButton.frame = CGRectMake(0, 0, 100, 40);
        [navButton setTitle:self.title forState:UIControlStateNormal];
        [navButton setTintColor:[TTColor tripTrunkBlue]];
        [navButton addTarget:self
                      action:@selector(titleTapped)
            forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = navButton;
    }
    self.descriptionTextView.text = self.trip.descriptionStory;
    [self.view addSubview:self.descriptionTextView];
    [self displayTrunkTitle];
    self.stateCountryLabel.adjustsFontSizeToFitWidth = YES;
    if ([self.trip.country isEqualToString:@"United States"]){
        self.stateCountryLabel.text = [NSString stringWithFormat:@"%@, %@ %@",self.trip.city, self.trip.state, self.trip.country];
    } else {
        self.stateCountryLabel.text = [NSString stringWithFormat:@"%@, %@",self.trip.city, self.trip.country];
    }
    self.startDate.text = self.trip.startDate;
    
    self.endDate.text = @"";
    if (![self.trip.startDate isEqualToString:self.trip.endDate]){
        self.endDate.text = self.trip.endDate;
    }
    
}

-(void)displayTrunkTitle{
    if (self.trip.isPrivate) {
        [self displayPrivateTrunkTitle];
    }
    else {
        [self displayPublicTrunk];
    }
}

-(void)displayPrivateTrunkTitle{
    CGFloat offsetY = -5.0;
    NSString *namePlusSpace = [NSString stringWithFormat:@"%@  ",self.trip.name];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:namePlusSpace];
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
    textAttachment.image = [UIImage imageNamed:@"lock"];
    textAttachment.bounds = CGRectMake(0, offsetY, textAttachment.image.size.width*.8, textAttachment.image.size.height*.8);
    NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
    [attributedString replaceCharactersInRange:NSMakeRange(namePlusSpace.length-1, 1) withAttributedString:attrStringWithImage];
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [TTColor tripTrunkBlue], NSForegroundColorAttributeName,
                                                           [TTFont tripTrunkFontBold38], NSFontAttributeName, nil]];
    UILabel *lblTitle = [[UILabel alloc] init];
    lblTitle.attributedText = attributedString;
    lblTitle.backgroundColor = [TTColor tripTrunkWhite];
    lblTitle.textColor = [TTColor tripTrunkBlue];
    lblTitle.font = [TTFont tripTrunkFontBold38];
    [lblTitle sizeToFit];
    self.navigationItem.titleView = lblTitle;
}

-(void)displayPublicTrunk{
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [TTColor tripTrunkBlue], NSForegroundColorAttributeName,
                                                           [TTFont tripTrunkFontBold38], NSFontAttributeName, nil]];
    UILabel *lblTitle = [[UILabel alloc] init];
    lblTitle.text = self.trip.name;
    lblTitle.backgroundColor = [TTColor tripTrunkWhite];
    lblTitle.textColor = [TTColor tripTrunkBlue];
    lblTitle.font = [TTFont tripTrunkFontBold38];
    [lblTitle sizeToFit];
    self.navigationItem.titleView = lblTitle;
}

-(void)titleTapped{
    
    if ([self.trip.descriptionStory length] > 0){
        if (self.descriptionTextView.tag == 0){
            self.descriptionTextView.hidden = NO;
            self.descriptionTextView.tag = 1;
        }else {
            self.descriptionTextView.hidden = YES;
            self.descriptionTextView.tag = 0;
        }
        
    } else {
        self.descriptionTextView.hidden = YES;

    }
}


#pragma mark - Queries

-(void)checkIfIsMember{
    self.addPhotoButton.hidden = YES;
    // If the user is the creator, then they see the Edit button, not a Leave button.
    if ([[PFUser currentUser].objectId isEqualToString:self.trip.creator.objectId])
    {
        self.isMember = YES;
        self.addPhotoButton.hidden = NO;
    }
    
    if (self.firstLoadDone == NO){
        self.collectionView.hidden = YES;
    }
    PFQuery *memberQuery = [PFQuery queryWithClassName:@"Activity"];
        [memberQuery whereKeyExists:@"fromUser"];
        [memberQuery whereKeyExists:@"toUser"];
        [memberQuery whereKey:@"trip" equalTo:self.trip];
        [memberQuery whereKey:@"type" equalTo:@"addToTrip"];
        [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
        [memberQuery includeKey:@"toUser"];
        [memberQuery setLimit:210];
    
        [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(!error)
            {
                [[TTUtility sharedInstance] internetConnectionFound];
                [self memberCollectionViewMethod:objects];
                
            }else
            {
                [ParseErrorHandlingController handleError:error];
                NSLog(@"Error: %@",error);
            }
            
        }];
}

-(void)memberWasRemoved:(PFUser *)sender{
    PFUser *userCheck;
    for (PFUser *user in self.members){
        if ([user.objectId isEqualToString:sender.objectId]){
            userCheck = user;
        }
    }
    [self.members removeObject:userCheck];
    [self.memberCollectionView reloadData];
}

-(void)memberCollectionViewMethod:(NSArray*)objects{
    
    __block BOOL hasCreator = false;
    for (PFObject *activity in objects)
    {
        PFUser *ttUser = activity[@"toUser"];
        if([ttUser.objectId isEqualToString:self.trip.creator.objectId]){
            [self.members insertObject:ttUser atIndex:0];
            hasCreator = YES;
        } else {
            [self.members addObject:ttUser];
        }
        if ([ttUser.objectId isEqualToString:[PFUser currentUser].objectId])
        {
            self.isMember = YES;
            self.addPhotoButton.hidden = NO;
        }
        
    }
    
    if (hasCreator == NO){
        [self.members insertObject:self.trip.creator atIndex:0];

    }
    
    if (self.isMember == YES)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"moreIcon"] style:UIBarButtonItemStylePlain  target:self action:@selector(moreTapped)];
    }
    
    self.collectionView.hidden = NO;
    NSInteger memberWidthTotal = (self.members.count + 1) * 60;
    if ( self.members.count + 1 > 5){
        self.memberCollectionWidth.constant = self.view.frame.size.width;
        self.memberCollectionView.hidden = NO;

    } else {
        self.memberCollectionWidth.constant = memberWidthTotal;
        self.memberCollectionView.hidden = NO;

    }

    if (self.firstLoadDone == NO){
        [self queryParseMethod];
    }
    [self.memberCollectionView reloadData];

}

-(void)queryParseMethod{
    
    PFQuery *findPhotosUser = [PFQuery queryWithClassName:@"Photo"];
    [findPhotosUser whereKey:@"trip" equalTo:self.trip];
    [findPhotosUser orderByDescending:@"createdAt"];
    [findPhotosUser includeKey:@"trip.creator"];
    [findPhotosUser includeKey:@"trip"];
    [findPhotosUser includeKey:@"user"];
    [findPhotosUser setLimit:1000];
    
    [findPhotosUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            [[TTUtility sharedInstance] internetConnectionFound];
            // Objects is an array of Parse Photo objects
            self.photos = [NSMutableArray arrayWithArray:objects];
            //update photo count when it is not right 
            if ((int)self.photos.count != self.trip.publicTripDetail.photoCount){
                self.trip.publicTripDetail.photoCount = (int)self.photos.count;
                [self.trip saveInBackground];
            }
            [self.collectionView reloadData];
            CGPoint collectionViewPosition = [self.scrollView convertPoint:CGPointZero fromView:self.collectionView];
            NSInteger imageHeight = self.view.frame.size.width/self.numberOfImagesPerRow;
            NSInteger numOfRows = self.photos.count/self.numberOfImagesPerRow;
            if(self.photos.count % self.numberOfImagesPerRow != 0)
                numOfRows++;
            NSInteger heightOfScroll = imageHeight*numOfRows+collectionViewPosition.y;
            
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, heightOfScroll);
            self.scrollViewHeightConstraint.constant = heightOfScroll;
            self.contentViewHeightConstraint.constant = heightOfScroll;
        }
    }];

}

-(void)queryNewlyAddedPhoto{
    PFQuery *findPhoto = [PFQuery queryWithClassName:@"Photo"];
    [findPhoto whereKey:@"trip" equalTo:self.trip];
    [findPhoto orderByDescending:@"createdAt"];
    [findPhoto includeKey:@"trip.creator"];
    [findPhoto includeKey:@"trip"];
    [findPhoto includeKey:@"user"];
    [findPhoto setLimit:1];
    [findPhoto findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            [[TTUtility sharedInstance] internetConnectionFound];
            Photo *photo = [self.photos objectAtIndex:0];
            Photo *newPhoto = [objects objectAtIndex:0];
            
            if (![photo.objectId isEqualToString:newPhoto.objectId]){
                [self.photos insertObject:newPhoto atIndex:0];
            }
            
            if ((int)self.photos.count != self.trip.publicTripDetail.photoCount){
                self.trip.publicTripDetail.photoCount = (int)self.photos.count;
                [self.trip saveInBackground];
            }
            [self.collectionView reloadData];
            CGPoint collectionViewPosition = [self.scrollView convertPoint:CGPointZero fromView:self.collectionView];
            NSInteger imageHeight = self.view.frame.size.width/self.numberOfImagesPerRow;
            NSInteger numOfRows = self.photos.count/self.numberOfImagesPerRow;
            if(self.photos.count % self.numberOfImagesPerRow != 0)
                numOfRows++;
            NSInteger heightOfScroll = imageHeight*numOfRows+collectionViewPosition.y;
            
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, heightOfScroll);
            self.scrollViewHeightConstraint.constant = heightOfScroll;
            self.contentViewHeightConstraint.constant = heightOfScroll;
        }
    }];
}

#pragma mark - Button Actions 

-(void)downloadTrunkPhotos{
    
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = NSLocalizedString(@"Save Trunk photos to phone?",@"Save Trunk photos to phone?");
    alertView.backgroundColor = [TTColor tripTrunkLightBlue];
    [alertView addButtonWithTitle:NSLocalizedString(@"No",@"No")];
    [alertView addButtonWithTitle:NSLocalizedString(@"Download",@"Download")];
    alertView.tag = 3;
    [alertView show];

}

-(void)moreTapped{
    UIActionSheet *actionSheet;
    
    if ([self.trip.creator.objectId isEqualToString:[PFUser currentUser].objectId]){
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Download Trunk Photos",@"Download Trunk Photos"),NSLocalizedString(@"Edit Trunk",@"Edit Trunk"),nil];
        
    }
    
    else if (self.isMember == YES) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Download Trunk Photos",@"Download Trunk Photos"),NSLocalizedString(@"Leave Trunk",@"Leave Trunk"),nil];
    }
    
    [actionSheet showInView:self.view];

}

-(void)editTapped{
    [self performSegueWithIdentifier:NSLocalizedString(@"Edit",@"Edit") sender:self];
    self.descriptionTextView.hidden = YES;
}

-(void)leaveTrunk{
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete yourself from this Trunk? Once done, you'll be unable to join the Trunk unless reinvited",@"Are you sure you want to delete yourself from this Trunk? Once done, you'll be unable to join the Trunk unless reinvited")];
    alertView.backgroundColor = [TTColor tripTrunkLightBlue];
    [alertView addButtonWithTitle:NSLocalizedString(@"Dismiss",@"Dismiss")];
    [alertView addButtonWithTitle:NSLocalizedString(@"Leave Trunk",@"Leave Trunk")];
    alertView.tag = 2;
    
    [alertView show];
}



- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Okay button pressed
    if (buttonIndex == 1) {
        // Delete self from trunk
        if (alertView.tag == 2) {
            [SocialUtility removeUser:[PFUser currentUser] fromTrip:self.trip block:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
                else if (error) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                        message:NSLocalizedString(@"Failed to leave trunk. Try Again.",@"Failed to leave trunk. Try Again.")
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                              otherButtonTitles:nil, nil];
                    [alertView show];
                }
            }];
        }
        // DOWNLOADING IMAGES
        else if (alertView.tag == 3) {
            
            if (self.photos.count > 0){
                [[TTUtility sharedInstance] downloadPhotos:self.photos];
            }
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // button index == 2 then it cancels the action
    if (buttonIndex == 0){
        [self downloadTrunkPhotos];
    } else if (buttonIndex == 1){
           if ([self.trip.creator.objectId isEqualToString:[PFUser currentUser].objectId]){
               [self editTapped];
           } else {
               [self leaveTrunk];
           }
    }
}

#pragma mark - UICollectionView Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.collectionView){
        return self.photos.count;
        
    } else {
        if (self.isMember == YES){
            if (self.trip.isPrivate == NO){
                return self.members.count +1;
            } else if (self.trip.isPrivate == YES){
                return self.members.count +1;
            } else {
                return self.members.count +1;
            }
        } else {
            return self.members.count +1;
        }
    }
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.collectionView){
        TrunkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
        cell.logo.hidden = YES;
        cell.photo.image = nil;
        [cell.photo setContentMode:UIViewContentModeScaleAspectFill];
        cell.photo.clipsToBounds = YES;
        cell.photo.translatesAutoresizingMaskIntoConstraints = NO;
        cell.photo.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        cell.tripPhoto = [self.photos objectAtIndex:indexPath.item];
        cell.backgroundColor = [TTColor tripTrunkBlue];
        NSDate *lastOpenedApp = [PFUser currentUser][@"lastUsed"];
        NSTimeInterval lastPhotoInterval = [lastOpenedApp timeIntervalSinceDate:cell.tripPhoto.createdAt];
        if (lastPhotoInterval < 0)
        {
            if (![self.photosSeen containsObject:cell.tripPhoto.objectId]){
                cell.logo.hidden = NO;
            } else{
                cell.logo.hidden = YES;
            }
        }
            // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
            NSString *urlString = [[TTUtility sharedInstance] thumbnailImageUrl:cell.tripPhoto.imageUrl];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
            UIImage *placeholderImage = nil;
            __weak TrunkCollectionViewCell *weakCell = cell;
            [weakCell.photo setContentMode:UIViewContentModeScaleAspectFill];
            weakCell.photo.clipsToBounds = YES;
            weakCell.photo.translatesAutoresizingMaskIntoConstraints = NO;
            weakCell.photo.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            NSInteger index = indexPath.item;
            [cell.photo setImageWithURLRequest:request
                              placeholderImage:placeholderImage
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                           // Set the image to the Photo object in the array
                                           [(Photo *)[self.photos objectAtIndex:index] setImage:image];
                                           weakCell.photo.image = image;
                                           [weakCell layoutIfNeeded];
                                       } failure:nil];
            return weakCell;
            return cell;
    } else {
        UserCellCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell2" forIndexPath:indexPath];
        cell.profileImage.image = nil;
        NSInteger index = indexPath.item;
        [cell.profileImage setContentMode:UIViewContentModeScaleAspectFill];
        __weak UserCellCollectionViewCell *weakCell = cell;
        if (indexPath.item == 0){
            cell.profileImage.alpha = 1;
            cell.profileImage.image = [UIImage imageNamed:@"members"];
        }else {
            PFUser *possibleFriend = [[PFUser alloc]init];
            if (self.isMember == NO){
                possibleFriend = [self.members objectAtIndex:index - 1];
            } else if (self.isMember == YES && self.trip.isPrivate == NO) {
                possibleFriend = [self.members objectAtIndex:index - 1];
            } else if (self.isMember == YES && self.trip.isPrivate == YES){
                possibleFriend = [self.members objectAtIndex:index - 1];
            } else {
                possibleFriend = [self.members objectAtIndex:index - 1];

            }
            
            if ([self.loadingMembers containsObject:possibleFriend]){
                cell.profileImage.alpha = .5;
            } else {
                cell.profileImage.alpha = 1;
            }

            // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
            NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:possibleFriend[@"profilePicUrl"]]];
            NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
            
            [cell.profileImage setImageWithURLRequest:request
                                            placeholderImage:nil
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                         
                                                         [weakCell.profileImage setImage:image];
                                                         [weakCell setNeedsLayout];
                                                         
                                                     } failure:nil];
        }
        return weakCell;
        
        return cell;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.collectionView){
        return CGSizeMake((self.view.frame.size.width/3)-1, (self.view.frame.size.width/3)-1);
    } else {
        return CGSizeMake(50, 50);
    }
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView == self.collectionView){
        self.path = indexPath;
        [self performSegueWithIdentifier:@"photo" sender:self];
    } else {
        if (indexPath.item == 0){
            TrunkMembersViewController *vc = [[TrunkMembersViewController alloc] initWithTrip:self.trip];
            vc.delegate = self;
            vc.tripMembers = self.members;
            vc.isMember = self.isMember;
            [self.navigationController pushViewController:vc animated:YES];
        }else {
            PFUser *user = [[PFUser alloc]init];
            if (self.isMember == NO){
                user = [self.members objectAtIndex:indexPath.row -1];
            } else if (self.isMember == YES && self.trip.isPrivate == NO) {
                user = [self.members objectAtIndex:indexPath.row -1];
            } else if (self.isMember == YES && self.trip.isPrivate == YES){
                user = [self.members objectAtIndex:indexPath.row -1];
            } else {
                user = [self.members objectAtIndex:indexPath.row -1];
            }
            if (user) {
                UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:user];
                [self.navigationController pushViewController:vc animated:YES];
            }
            
        }
    }
    
}


-(void)memberWasAdded:(id)sender{
    self.firstLoadDone = YES;
    
    self.collectionView.hidden = NO;
    
    int count;
    if (self.isMember == YES){
        count =1;
    } else {
        count = 0;
    }
        
    NSInteger memberWidthTotal = (self.members.count + 1) * 60;
    NSInteger oneThirdView = self.view.frame.size.width / 1.5;
    if (oneThirdView < memberWidthTotal){
        self.memberCollectionWidth.constant = self.view.frame.size.width;
        self.memberCollectionView.hidden = NO;
        
    } else {
        self.memberCollectionWidth.constant = memberWidthTotal;
        self.memberCollectionView.hidden = NO;
        
    }

    //FIXME Should only remove the member properly added
    [self.loadingMembers removeAllObjects];
    [self.memberCollectionView reloadData];

}

-(void)memberWasAddedTemporary:(PFUser *)profile{
    self.firstLoadDone = YES;
    [self.members addObject:profile];
    [self.loadingMembers addObject:profile];
    
    NSInteger memberWidthTotal = (self.members.count + 1) * 60;
    NSInteger oneThirdView = self.view.frame.size.width / 1.5;
    if (oneThirdView < memberWidthTotal){
        self.memberCollectionWidth.constant = self.view.frame.size.width;
        self.memberCollectionView.hidden = NO;
        
    } else {
        self.memberCollectionWidth.constant = memberWidthTotal;
        self.memberCollectionView.hidden = NO;
        
    }

    
    [self.memberCollectionView reloadData];
}

-(void)memberFailedToLoad:(PFUser*)sender{
    self.firstLoadDone = YES;
    [self.members removeObject:sender];
    [self.loadingMembers removeObject:sender];
    [self.memberCollectionView reloadData];
    NSString *title = NSLocalizedString(@"was unable to be added to",@"was unable to be added to");
    NSString *finalTitle = [NSString stringWithFormat:@"%@ %@ %@",sender.username, title, self.trip.name];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:finalTitle
                                                    message:NSLocalizedString(@"Please try again",@"Please try again")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                          otherButtonTitles:nil, nil];    
    [alert show];
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"Edit"]) {
        AddTripViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
    else if([segue.identifier isEqualToString:@"photo"]){
        PhotoViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        vc.photo = [self.photos objectAtIndex:self.path.item];
        vc.trip = self.trip;
        vc.arrayInt = (int)self.path.item;
        vc.trunkMembers = self.members;
        vc.photos = self.photos;
        self.path = nil;
    }
    
    else if ([segue.identifier isEqualToString:@"addPhotos"]) {
        AddTripPhotosViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
        vc.trunkMembers = self.members;
    }
    
}

-(void)dealloc {
    // remove the observer here so it keeps listening for it until the view is dealloc'd, not just when it disappears
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//fixme this cant be right. We need this to be cloud code to update the total
-(void)photoWasLiked:(BOOL)isFromError{

    int likes = [self.totalLikeButton.text intValue] + 1;
    [self.totalLikeButton setText:[NSString stringWithFormat:@"%d",likes]];
    [self.totalLikeButton setTintColor:[TTColor tripTrunkWhite]];
    self.totalLikeButton.textColor = [TTColor tripTrunkWhite];
    self.totalLikeButton.hidden = NO;
    self.totalLikeHeart.hidden = NO;
    
}

-(void)photoWasDeleted:(NSNumber*)likes photo:(Photo *)photo{
    [self.photos removeObject:photo];
    [self.collectionView reloadData];
}

-(void)photoWasViewed:(Photo *)photo{
    [self.photosSeen addObject:photo.objectId];
    [self.collectionView reloadData];
}

-(void)textViewDidChange:(UITextView *)textView{
    if ([textView.text length] > 1){

    NSString *code = [textView.text substringFromIndex: [textView.text length] - 2];
    if ([code isEqualToString:@" "]){
        [textView setKeyboardType:UIKeyboardTypeDefault];
    }
    }
}

- (IBAction)addPhotoWasTapped:(id)sender {
    [self performSegueWithIdentifier:@"addPhotos" sender:self];
}

@end


