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


@interface TrunkViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate>

/**
 *  Array holding Photo objects for the photos in this trunk
 */
@property NSArray *photos;

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
@property (weak, nonatomic) IBOutlet UIImageView *lock;

@end

@implementation TrunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"Trip Name is: %@", self.trip.name);

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
    
    self.photos = nil;
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

-(void)viewDidAppear:(BOOL)animated{
    
    [self refreshTripDataViews];
    
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
    self.stateCountryLabel.text = [NSString stringWithFormat:@"%@, %@",self.trip.city, self.trip.country];
    self.startDate.text = self.trip.startDate;
    
    self.endDate.text = @"";
    if (![self.trip.startDate isEqualToString:self.trip.endDate]){
        self.endDate.text = self.trip.endDate;
    }
}

#pragma mark - Queries

-(void)checkIfIsMember{
    
    if ([[PFUser currentUser].username isEqualToString:self.trip.user])
    {
        self.isMember = YES;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                                  style:UIBarButtonItemStyleBordered
                                                                                 target:self
                                                                                 action:@selector(editTapped)];
    }
    else
    {
    
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
                } else {
                    self.isMember = YES;
                    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Leave"
                                                                                              style:UIBarButtonItemStyleBordered
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
    [findPhotosUser whereKey:@"tripName" equalTo:self.trip.name];
    [findPhotosUser whereKey:@"city" equalTo:self.trip.city];
    [findPhotosUser orderByDescending:@"createdAt"];
    
    [findPhotosUser findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error)
        {
            // Objects is an array of Parse Photo objects
            self.photos = [NSArray arrayWithArray:objects];
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
            [[TTUtility sharedInstance] downloadPhotos:self.photos];
        }
    }
}

#pragma mark - UICollectionView Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count + 1;
}

- (TrunkCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TrunkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    
    if(indexPath.item == 0)
    {
        cell.photo.image = [UIImage imageNamed:@"Plus Square"];
    }
    // This is the images
    else if (indexPath.item > 0)
    {
        cell.tripPhoto = [self.photos objectAtIndex:indexPath.item -1];
        
        // mattschoch 6/10 - commented out because we're setting the photo below with UIKit+AFNetworking method.
        //        [self convertPhoto:cell indexPath:indexPath];
        
        
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSString *urlString = [[TTUtility sharedInstance] thumbnailImageUrl:cell.tripPhoto.imageUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        UIImage *placeholderImage = [UIImage imageNamed:@"photo134"];
        [cell.photo setContentMode:UIViewContentModeScaleAspectFill];
        __weak TrunkCollectionViewCell *weakCell = cell;
        
        [cell.photo setImageWithURLRequest:request
                          placeholderImage:placeholderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {

                                       // Set the image to the Photo object in the array
                                       [(Photo *)[self.photos objectAtIndex:indexPath.item - 1] setImage:image];
                                       
                                       weakCell.photo.image = image;
                                       [weakCell setNeedsLayout];
                                       
                                   } failure:nil];
        return weakCell;
        
    }
    return cell;
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.item > 0)
    {
        self.path = indexPath;
        NSLog(@"didSelectItemAtIndexPath: %ld", (long)indexPath.item);
        
        [self performSegueWithIdentifier:@"photo" sender:self];
    }
    
    else if (indexPath.item == 0 && self.isMember == NO)
    {
        UIAlertView *alertView = [[UIAlertView alloc] init];
        alertView.delegate = self;
        alertView.title = [NSString stringWithFormat:@"Only members may add photos. Contact %@ to be made a member of this trunk", self.trip.user];
        alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
        [alertView addButtonWithTitle:@"OK"];
        [alertView show];
    }
    
    else if (indexPath.item == 0 && self.isMember == YES)
    {
        [self performSegueWithIdentifier:@"addPhotos" sender:self];
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
        vc.photo = [self.photos objectAtIndex:self.path.item -1];
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
























         
         
         
         
         
