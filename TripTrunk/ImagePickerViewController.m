//
//  ImagePickerViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 10/17/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "ImagePickerViewController.h"
#import "ImagePickerCollectionViewCell.h"


@interface ImagePickerViewController ()
@property NSArray *assets;
@property NSMutableArray *photosToAdd;

@end

static int count=0;


@implementation ImagePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.photoCollectionView.delegate = self;
    self.assets = [[NSArray alloc]init];
    self.photosToAdd = [[NSMutableArray alloc]init];
    [self getAllPictures];
 

}

- (IBAction)cancelWasTapped:(id)sender {
    
}

- (IBAction)doneWasTapped:(id)sender {
    
}

-(ImagePickerCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImagePickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyCell" forIndexPath:indexPath];
    cell.ImageView.image = [self.assets objectAtIndex:indexPath.row];
    return cell;
    
}



-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    UIImage *image = [self.assets objectAtIndex:indexPath.row];
    [self.photosToAdd addObject:image];
    
    
    
    
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

-(void)getAllPictures
{
    imageArray=[[NSArray alloc] init];
    mutableArray =[[NSMutableArray alloc]init];
    NSMutableArray* assetURLDictionaries = [[NSMutableArray alloc] init];
    
    library = [[ALAssetsLibrary alloc] init];
    
    void (^assetEnumerator)( ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result != nil) {
            if([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                
                NSURL *url= (NSURL*) [[result defaultRepresentation]url];
                
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
    self.assets = imgArray;
    [self.photoCollectionView reloadData];
    
}

@end
