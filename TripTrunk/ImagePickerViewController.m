//
//  ImagePickerViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 10/17/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "ImagePickerViewController.h"
#import "ImagePickerCollectionViewCell.h"
#import "Photo.h"
#import <Parse/Parse.h>



@interface ImagePickerViewController ()
@property NSMutableArray *assets;
@property NSMutableArray *assetURLDictionaries;
@property NSMutableArray *tappedCells;

@end

static int count=0;


@implementation ImagePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.photoCollectionView.delegate = self;
    self.tappedCells = [[NSMutableArray alloc]init];
    [self getAllPictures];
}

-(void)viewWillAppear:(BOOL)animated{
    
    UINavigationBar *myNav = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, 320, 60)];
    [UINavigationBar appearance].barTintColor = [UIColor colorWithRed:(95.0/255.0) green:(148.0/255.0) blue:(172.0/255.0) alpha:1];
    [self.view addSubview:myNav];
    
    UIBarButtonItem *doneItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:@selector(doneTapped) ];
    
    
    
    UIBarButtonItem *cancelItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                     style:UIBarButtonItemStylePlain
                                    target:nil
                                    action:@selector(cancelTapped)];
    
    
    UINavigationItem *navigItem = [[UINavigationItem alloc] initWithTitle:@"Select Photos"];
    navigItem.rightBarButtonItem = doneItem;
    navigItem.leftBarButtonItem = cancelItem;
    myNav.items = [NSArray arrayWithObjects: navigItem,nil];
    [UIBarButtonItem appearance].tintColor = [UIColor whiteColor];
}

-(void)doneTapped{
    [self.delegate imagesWereSelected:self.photosToAdd];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelTapped {
        [self dismissViewControllerAnimated:YES completion:nil];
}

-(ImagePickerCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImagePickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, self.view.frame.size.width/4, self.view.frame.size.width/4);
    Photo *photo = [self.assets objectAtIndex:indexPath.row];
    cell.ImageView.autoresizingMask = NO;
    cell.ImageView.autoresizesSubviews = NO;
    cell.ImageView.frame = CGRectMake(cell.ImageView.frame.origin.x, cell.ImageView.frame.origin.y, self.view.frame.size.width/4, self.view.frame.size.width/4);
    cell.ImageView.image = photo.image;
    cell.ImageView.clipsToBounds = YES;
    NSNumber *number = [NSNumber numberWithInt:(int)indexPath.row];
    if ([self.tappedCells containsObject:number]){
        cell.isSelected = YES;
        cell.ImageView.alpha = .3;
    }else {
        cell.isSelected = NO;
        cell.ImageView.alpha = 1;
    }
    return cell;
    
}



- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.frame.size.width/4, self.view.frame.size.width/4);
}



-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    Photo *image = [self.assets objectAtIndex:indexPath.row];
    BOOL duplicate = NO;
    NSNumber *number = [NSNumber numberWithInt:(int)indexPath.row];
    NSArray *arrayPath = [[NSArray alloc]initWithObjects:indexPath, nil];

    for (Photo *photo in self.photosToAdd){
        if ([image.imageUrl isEqualToString:photo.imageUrl]){
            duplicate = YES;
        }
    }
    
    if (duplicate == NO){
        [self.photosToAdd addObject:image];
        [self.tappedCells addObject:number];
    } else {
        [self.photosToAdd removeObject:image];
        [self.tappedCells removeObject:number];
    }
    
    
    [self.photoCollectionView reloadItemsAtIndexPaths:arrayPath];
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

-(void)getAllPictures
{
    self.assets = [[NSMutableArray alloc]init];
    imageArray=[[NSArray alloc] init];
    mutableArray =[[NSMutableArray alloc]init];
    self.assetURLDictionaries = [[NSMutableArray alloc] init];
    
    library = [[ALAssetsLibrary alloc] init];
    
    void (^assetEnumerator)( ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result != nil) {
            if([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                
                NSURL *url= result.defaultRepresentation.url;
                [self.assetURLDictionaries addObject:url];

                
                [library assetForURL:url
                         resultBlock:^(ALAsset *asset) {
                             [mutableArray addObject:[UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage]]];
                             
                             if ([mutableArray count]==count)
                             {
                                 imageArray=[[NSArray alloc] initWithArray:mutableArray];
                                 [self allPhotosCollected:imageArray];
                             }
                         }
                        failureBlock:^(NSError *error){ NSLog(@"operation was not successfull!"); } ];
                
            }
        }
    };
    
    NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
    
    void (^ assetGroupEnumerator) ( ALAssetsGroup *, BOOL *)= ^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            [group enumerateAssetsUsingBlock:assetEnumerator];
            [assetGroups addObject:group];
            count=(int)[group numberOfAssets];
        }
    };
    
    assetGroups = [[NSMutableArray alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll
                           usingBlock:assetGroupEnumerator
                         failureBlock:^(NSError *error) {NSLog(@"There is an error");}];
}

-(void)allPhotosCollected:(NSArray*)imgArray
{
    int count = 0;
    for (UIImage *image in imgArray){
        Photo *photo = [Photo object];
        photo.image = image;
        
        // set the reference URL now so we have it for uploading the raw image data
        NSURL *url  = (NSURL*)[self.assetURLDictionaries objectAtIndex:count];
        photo.imageUrl = [url absoluteString];
            // Set all the generic trip info on the Photo object
        PFUser *user = [PFUser currentUser];
        photo.likes = 0;
        photo.trip = self.trip;
        photo.userName = user.username;
        photo.user = user;
        photo.usersWhoHaveLiked = [[NSMutableArray alloc] init];
        photo.tripName = self.trip.name;
        photo.city = self.trip.city;
        count += 1;
        [self.assets addObject:photo];
        [self checkDuplicates:photo];

    }
    [self.photoCollectionView reloadData];

}

-(void)checkDuplicates:(Photo*)photo{
    
    for (Photo *photo in self.assets){
        for (Photo *image in self.photosToAdd){
            if ([photo.imageUrl isEqualToString:image.imageUrl]){
                 NSNumber *number =[[NSNumber alloc]initWithInt:(int)[self.assets indexOfObject:photo]];
                [self.tappedCells addObject:number];
            }
        }
        
        }
}


@end
