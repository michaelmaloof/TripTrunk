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

#import "UIImageView+AFNetworking.h"


@interface TrunkViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, UICollectionViewDelegateFlowLayout>

/**
 *  Array holding Photo objects for the photos in this trunk
 */
@property NSArray *photos;
@property (weak, nonatomic) IBOutlet UILabel *constraintLabel;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
//@property (weak, nonatomic) IBOutlet UILabel *photoLabel;
@property (weak, nonatomic) IBOutlet UILabel *startDate;
@property (weak, nonatomic) IBOutlet UILabel *endDate;
@property (weak, nonatomic) IBOutlet UIButton *memberButton;
@property (weak, nonatomic) IBOutlet UILabel *stateCountryLabel;
@property NSIndexPath *path;
@property PFImageView *imageview;
@property int photosOriginal;
@property BOOL isMember;
@property (weak, nonatomic) IBOutlet UIButton *lock;
@property (weak, nonatomic) IBOutlet UIButton *cloud;

@end

@implementation TrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.constraintLabel.hidden = YES;
    self.cloud.hidden = YES;

    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
    self.navigationController.navigationItem.rightBarButtonItem = nil;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self refreshTripDataViews];

    [[self navigationItem] setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@""
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil]];
    
    self.photos = [[NSArray alloc] init];
    
    // Load initial data
    [self checkIfIsMember];
    [self queryParseMethod];
    

    // Add observer for when uploading is finished.
    // TTUtility posts the notification when the uploader is done so that we know to refresh the view to show new pictures
    // Notification is also used if a photo is deleted.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryParseMethod)
                                                 name:@"parsePhotosUpdatedNotification"
                                               object:nil];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0,0,0, 0);
}


-(void)viewDidAppear:(BOOL)animated{
    
    [self refreshTripDataViews];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [[self.tabBarController.viewControllers objectAtIndex:0] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:1] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:2] setTitle:@""];
    [[self.tabBarController.viewControllers objectAtIndex:3] setTitle:@""];
}


- (IBAction)lockTapped:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = @"Private Trunk";
    alertView.message = @"Only the Trunk Creator and Trunk Members can see that this trunk exists";
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"Ok"];
    alertView.tag = 4;
    [alertView show];
}

- (void)refreshTripDataViews {
    // Putting all this here so that if the trip is Edited then the UI will refresh
    self.title = self.trip.name;
    if (self.trip.isPrivate) {
        self.lock.hidden = NO;
    }
    else {
        self.lock.hidden = YES;
    }
    
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

#pragma mark - Queries

-(void)checkIfIsMember{
    
    if ([[PFUser currentUser].objectId isEqualToString:self.trip.creator.objectId])
    {
        self.isMember = YES;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(editTapped)];
    }
    else
    {
        self.collectionView.hidden = YES;
        PFQuery *memberQuery = [PFQuery queryWithClassName:@"Activity"];
        [memberQuery whereKey:@"trip" equalTo:self.trip];
        [memberQuery whereKey:@"type" equalTo:@"addToTrip"];
        [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
        [memberQuery whereKey:@"toUser" equalTo:[PFUser currentUser]];
        
        [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(!error)
            {
                NSMutableArray *members = [NSMutableArray arrayWithArray:objects];
                if (members.count == 0 || members == nil){
                    self.isMember = NO;
                    self.collectionView.hidden = NO;
                } else {
                    self.isMember = YES;
                    [self.collectionView reloadData];
                    self.collectionView.hidden = NO;
                    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Leave"
                                                                                              style:UIBarButtonItemStylePlain
                                                                                             target:self
                                                                                             action:@selector(leaveTrunk)];
                }
                
            }else
            {
                NSLog(@"Error: %@",error);
            }
            
        }];
    }

}

-(void)queryParseMethod{
    
    NSLog(@"TrunkViewController - queryParseMethod");
    
    PFQuery *findPhotosUser = [PFQuery queryWithClassName:@"Photo"];
    [findPhotosUser whereKey:@"trip" equalTo:self.trip];
    [findPhotosUser orderByDescending:@"createdAt"];
    
    [findPhotosUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            // Objects is an array of Parse Photo objects
            self.photos = [NSArray arrayWithArray:objects];
            
            if (self.photos.count > 0){
                self.cloud.hidden = NO;
            }
            
            [self.collectionView reloadData];
            
        }else
        {
            NSLog(@"Error: %@",error);
        }


    }];

}

#pragma mark - Button Actions 

- (IBAction)onPhotoTapped:(id)sender {
    
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = @"Save Trunk photos to phone?";
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"No"];
    [alertView addButtonWithTitle:@"Download"];
    alertView.tag = 3;
    [alertView show];

}

- (IBAction)membersButtonPressed:(id)sender {
    TrunkMembersViewController *vc = [[TrunkMembersViewController alloc] initWithTrip:self.trip];
    vc.isMember = self.isMember;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)editTapped{
    [self performSegueWithIdentifier:@"Edit" sender:self];
}

-(void)leaveTrunk{
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = [NSString stringWithFormat:@"Are you sure you want to delete yourself from this Trunk? Once done, you'll be unable to join the Trunk unless reinvited"];
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:@"Dismiss"];
    [alertView addButtonWithTitle:@"Leave Trunk"];
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
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                        message:@"Failed to leave trunk. Try Again."
                                                                       delegate:self
                                                              cancelButtonTitle:@"Okay"
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

#pragma mark - UICollectionView Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.isMember == NO) {
       return self.photos.count;
    } else {
        return self.photos.count + 1;
    }
}



- (TrunkCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TrunkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.photo.frame = CGRectMake(cell.photo.frame.origin.x, cell.photo.frame.origin.y, self.view.frame.size.width/3, self.view.frame.size.width/3);

    
    if(indexPath.item == 0 && self.isMember == YES)
    {
        cell.photo.image = [UIImage imageNamed:@"Plus Square"];
    }
    
    // This is the images
//    else if (indexPath.item > 0)
    else
    {
        if (self.isMember == YES) {
            cell.tripPhoto = [self.photos objectAtIndex:indexPath.item -1];
        } else {
             cell.tripPhoto = [self.photos objectAtIndex:indexPath.item];
        }
        
        // mattschoch 6/10 - commented out because we're setting the photo below with UIKit+AFNetworking method.
        //        [self convertPhoto:cell indexPath:indexPath];
        
        
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSString *urlString = [[TTUtility sharedInstance] thumbnailImageUrl:cell.tripPhoto.imageUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        UIImage *placeholderImage = [UIImage imageNamed:@"Load"];
        [cell.photo setContentMode:UIViewContentModeScaleAspectFill];
        __weak TrunkCollectionViewCell *weakCell = cell;
        
        NSInteger index = indexPath.item;
        
        [cell.photo setImageWithURLRequest:request
                          placeholderImage:placeholderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {

                                       // Set the image to the Photo object in the array
                                       
                                       if (self.isMember == YES) {
                                           [(Photo *)[self.photos objectAtIndex:index - 1] setImage:image];

                                       } else {
                                           [(Photo *)[self.photos objectAtIndex:index] setImage:image];

                                       }
                                       
                                       weakCell.photo.image = image;
                                       [weakCell setNeedsLayout];
                                       
                                   } failure:nil];
        return weakCell;
        
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{

    return CGSizeMake(self.view.frame.size.width/3, self.view.frame.size.width/3);
}



#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.item == 0 && self.isMember == YES)
    {
        [self performSegueWithIdentifier:@"addPhotos" sender:self];
    }
    
    else
    {
        self.path = indexPath;
        NSLog(@"didSelectItemAtIndexPath: %ld", (long)indexPath.item);
        
        [self performSegueWithIdentifier:@"photo" sender:self];
    }
    
}


#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"Edit"]) {
        AddTripViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
    else if([segue.identifier isEqualToString:@"photo"]){
        PhotoViewController *vc = segue.destinationViewController;
        if (self.isMember == YES) {
        vc.photo = [self.photos objectAtIndex:self.path.item -1];
        } else {
            vc.photo = [self.photos objectAtIndex:self.path.item];
        }
        vc.photos = self.photos;
        vc.arrayInt = self.path.item - 1;
        self.path = nil;
    }
    
    else if ([segue.identifier isEqualToString:@"addPhotos"]) {
        AddTripPhotosViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
}

-(void)dealloc {
    // remove the observer here so it keeps listening for it until the view is dealloc'd, not just when it disappears
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
























         
         
         
         
         
