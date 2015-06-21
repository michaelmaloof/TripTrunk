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

#import "UIImageView+AFNetworking.h"


@interface TrunkViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate>
@property NSArray *photos;
@property NSMutableArray *trunkAlbum;
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
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.lock.hidden = YES;
    if (self.trip.isPrivate == YES){
        self.lock.hidden = NO;
    }else{
        self.lock.hidden = YES;
    }
    self.title = self.trip.name;
    self.trunkAlbum = [[NSMutableArray alloc]init];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.title = self.trip.name;
    self.stateCountryLabel.text = [NSString stringWithFormat:@"%@ %@, %@",self.trip.city, self.trip.state,self.trip.country];
//    self.photoLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.photos.count];
    self.startDate.text = self.trip.startDate;
    self.endDate.text = self.trip.endDate;
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    
    [self checkIfIsMember];
    


}

-(void)viewDidAppear:(BOOL)animated{
    self.photos = nil;
    self.photos = [[NSArray alloc]init];

    
    if ([[PFUser currentUser].username isEqualToString:self.trip.user]) {
        
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(queryParseMethod)
                                                 name:@"parsePhotosUpdatedNotification"
                                               object:nil];
    
    [self queryParseMethod];
}

-(void)checkIfIsMember{
    
    if ([[PFUser currentUser].username isEqualToString:self.trip.user])
    {
        self.isMember = YES;
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
                }
                
            }else
            {
                NSLog(@"Error: %@",error);
            }
            
        }];
    }

}

-(TrunkCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TrunkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];

    if(indexPath.row == 0)
    {
        cell.photo.image = [UIImage imageNamed:@"Plus Square"];
    }
    // This is the images
    else if (indexPath.row > 0)
    {
        cell.tripPhoto = [self.photos objectAtIndex:indexPath.row -1];
        
        // mattschoch 6/10 - commented out because we're setting the photo below with UIKit+AFNetworking method.
//        [self convertPhoto:cell indexPath:indexPath];
        
        
        // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:cell.tripPhoto.imageUrl]];
        UIImage *placeholderImage = [UIImage new];
        __weak TrunkCollectionViewCell *weakCell = cell;
        
        [cell.photo setImageWithURLRequest:request
                                    placeholderImage:placeholderImage
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 
                                                 [self.trunkAlbum addObject:image];

                                                 weakCell.photo.image = image;
                                                 [weakCell setNeedsLayout];
                                                 
                                             } failure:nil];
        return weakCell;
    
    }
    return cell;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count + 1;
}

- (IBAction)onEditTapped:(id)sender {
    [self performSegueWithIdentifier:@"Edit" sender:self];
}

-(void)queryParseMethod{
    
    PFQuery *findPhotosUser = [PFQuery queryWithClassName:@"Photo"];
    [findPhotosUser whereKey:@"tripName" equalTo:self.trip.name];
    [findPhotosUser whereKey:@"city" equalTo:self.trip.city];
    [findPhotosUser whereKey:@"userName" equalTo:self.trip.user];
    
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

// mattschoch 6/10 - I think this method can be deleted?
-(void)checkPhotos
{
    int photoCount = (int)self.photos.count;
    if (self.photosOriginal != photoCount)
    {
        self.photosOriginal = photoCount;
        [self.collectionView reloadData];
    }
    

}

// mattschoch 6/10 - I think this method can be deleted as well - replaced with setting image in the cell
-(void)convertPhoto:(TrunkCollectionViewCell*)cell indexPath:(NSIndexPath*)indexPath {
    Photo *photo = [self.photos objectAtIndex:indexPath.row -1];
    PFFile *file = photo.imageFile;
    cell.photo.file = file;
    [cell.photo.file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            cell.photo.image = [UIImage imageWithData:data];
            [self.trunkAlbum addObject:cell.photo.image];
        }
    }];
}
     
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
    NSLog(@"membersButtonPressed");
    TrunkMembersViewController *vc = [[TrunkMembersViewController alloc] initWithTrip:self.trip];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Edit"]) {
        AddTripViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
    else if([segue.identifier isEqualToString:@"photo"]){
        PhotoViewController *vc = segue.destinationViewController;
        vc.photo = [self.photos objectAtIndex:self.path.row -1];
        //TODO: VC.Image sets the WRONG image.
        // It could be just from having a "photo" without an imageUrl though, so maybe it works.
        // I think it works, but it can crash sometimes from an index-out-of-range exception
        vc.image = [self.trunkAlbum objectAtIndex:self.path.row -1];
        self.path = nil;
    }
    
    else if ([segue.identifier isEqualToString:@"addPhotos"]) {
        AddTripPhotosViewController *vc = segue.destinationViewController;
        vc.trip = self.trip;
    }
    
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row > 0)
    {
        self.path = indexPath;
        
        [self performSegueWithIdentifier:@"photo" sender:self];
    }
    
    else if (indexPath.row == 0 && self.isMember == NO)
    {
        UIAlertView *alertView = [[UIAlertView alloc] init];
        alertView.delegate = self;
        alertView.title = [NSString stringWithFormat:@"Only members may add photos. Contact %@ to be made a member of this trunk", self.trip.user];
        alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
        [alertView addButtonWithTitle:@"OK"];
        [alertView show];
    }
    
    else if (indexPath.row == 0 && self.isMember == YES)
    {
        [self performSegueWithIdentifier:@"addPhotos" sender:self];
    }
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        for (UIImage *image in self.trunkAlbum){
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] init];
        alertView.delegate = self;
        alertView.title = @"Photos have been saved";
        alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
        [alertView addButtonWithTitle:@"Sweet!"];
        [alertView show];

    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




@end
