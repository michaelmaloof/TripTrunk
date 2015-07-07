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

#import "UIImageView+AFNetworking.h"


@interface TrunkViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate>

/**
 *  Array holding Photo objects for the photos in this trunk
 */
@property NSArray *photos;
/**
 *  Array holding the UIImage Thumbnails for this trunk
 */
@property NSMutableArray *trunkThumbnails;
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
    
    if (self.trip.isPrivate) {
        self.lock.hidden = NO;
    }
    else {
        self.lock.hidden = YES;
    }
    self.title = self.trip.name;
    self.stateCountryLabel.text = [NSString stringWithFormat:@"%@, %@",self.trip.city, self.trip.country];
    self.startDate.text = self.trip.startDate;
    
    self.endDate.text = @"";
    if (![self.trip.startDate isEqualToString:self.trip.endDate]){
        self.endDate.text = self.trip.endDate;
    }
    
    [[self navigationItem] setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@""
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil]];
    
    self.photos = nil;
    self.photos = [[NSArray alloc] init];
    
    // Load initial data
    [self checkIfIsMember];
    [self queryParseMethod];


}

-(void)viewDidAppear:(BOOL)animated{
    
    // Add observer for when uploading is finished.
    // TTUtility posts the notification when the uploader is done so that we know to refresh the view to show new pictures
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryParseMethod)
                                                 name:@"parsePhotosUpdatedNotification"
                                               object:nil];
    
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
            self.trunkThumbnails = [[NSMutableArray alloc] initWithCapacity:self.photos.count]; // initialize to the length of the photos list
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

-(void)deleteFromTrunk
{
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Activity"];
    [followingQuery whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [followingQuery whereKey:@"type" equalTo:@"addToTrip"];
    [followingQuery whereKey:@"content" equalTo:self.trip.city];
    [followingQuery whereKey:@"trip" equalTo:self.trip];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if(error)
         {
             NSLog(@"Error: %@",error);
         }
         else
         {
             [self removeActivityRow:objects];
         }
     }];
}

-(void)removeActivityRow:(NSArray*)objects{
    PFObject *object = [objects objectAtIndex:0];
    [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         [self.navigationController popToRootViewControllerAnimated:YES];
     }];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (alertView.tag == 2)
    {
        if (buttonIndex == 1) {
            [self deleteFromTrunk];
        }
    }
    // DOWNLOADING IMAGES
    //TODO: don't download images in the list. Download full-res from server
    else
    {
        if (buttonIndex == 1)
        {
            [[TTUtility sharedInstance] downloadPhotos:self.photos];
//            for (UIImage *image in self.trunkThumbnails)
//            {
//                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
//                
//            }
//            UIAlertView *alertView = [[UIAlertView alloc] init];
//            alertView.delegate = self;
//            alertView.title = @"Photos have been saved";
//            alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
//            [alertView addButtonWithTitle:@"Sweet!"];
//            [alertView show];
        }
    }
}

#pragma mark - UICollectionView Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSLog(@"numberOfItems: %lu", self.photos.count + 1);
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
                                       
                                       NSLog(@"adding Photo to cell at index: %lu", indexPath.item - 1);
                                       NSLog(@"trunkThumbnails Count: %lu", self.trunkThumbnails.count);

                                       //TODO: This is a BUG
                                       // Images can finish downloading in a different order, so this array gets mis-ordered easily.
                                       [self.trunkThumbnails addObject:image];
                                       
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
        //TODO: VC.Image sets the WRONG image.
        // It could be just from having a "photo" without an imageUrl though, so maybe it works.
        // I think it works, but it can crash sometimes from an index-out-of-range exception
        vc.image = [self.trunkThumbnails objectAtIndex:self.path.item -1];
        vc.photos = self.photos;
        vc.trunkAlbum = self.trunkThumbnails;
        vc.arrayInt = self.path.item-1;
        self.path = nil;
    }
    
    else if ([segue.identifier isEqualToString:@"addPhotos"]) {
        AddTripPhotosViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
}


#pragma mark - viewWillDissappear

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
























         
         
         
         
         
