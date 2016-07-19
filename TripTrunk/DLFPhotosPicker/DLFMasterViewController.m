//
//  MasterViewController.m
//  PhotosPicker
//
//  Created by  on 11/26/14.
//  Copyright (c) 2014 Delightful. All rights reserved.
//

#import "DLFMasterViewController.h"
#import "DLFDetailViewController.h"
#import "DLFAssetsLayout.h"
#import <Photos/Photos.h>

@interface DLFMasterViewController () <PHPhotoLibraryChangeObserver>

@property NSMutableArray *objects;

@property (strong) NSArray *collectionsFetchResults;
@property (strong) NSArray *collectionsLocalizedTitles;

@property (nonatomic) NSArray *collectionsArrays;

@end

@implementation DLFMasterViewController

static NSString * const AllPhotosReuseIdentifier = @"AllPhotosCell";
static NSString * const CollectionCellReuseIdentifier = @"CollectionCell";

static NSString * const AllPhotosSegue = @"showAllPhotos";
static NSString * const CollectionSegue = @"showCollection";

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        [options setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(localizedTitle)) ascending:YES]]];
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:options];
        self.collectionsFetchResults = @[topLevelUserCollections, smartAlbums];
        self.collectionsLocalizedTitles = @[NSLocalizedString(@"Albums", @""), NSLocalizedString(@"Smart Albums", @"")];
        [self excludeEmptyCollections];
        
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        self.title = NSLocalizedString(@"Albums", nil);
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleDone target:self action:@selector(didTapCancelButton:)];
        [self.navigationItem setLeftBarButtonItem:cancelButton];
        
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:AllPhotosReuseIdentifier];
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CollectionCellReuseIdentifier];
        [self.tableView setDataSource:self];
        [self.tableView setDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)didTapCancelButton:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(masterViewController:didTapCancelButton:)]) {
        [self.delegate masterViewController:self didTapCancelButton:sender];
    }
}

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DLFDetailViewController *detailViewController = [[segue.destinationViewController viewControllers] firstObject];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    if ([segue.identifier isEqualToString:AllPhotosSegue]) {
        detailViewController.assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        detailViewController.title = NSLocalizedString(@"Photos", @"Photos");
    } else if ([segue.identifier isEqualToString:CollectionSegue]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NSArray *fetchResult = self.collectionsArrays[indexPath.section - 1];
        PHCollection *collection = fetchResult[indexPath.row];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            detailViewController.assetsFetchResults = assetsFetchResult;
            detailViewController.assetCollection = assetCollection;
            detailViewController.title = collection.localizedTitle;
        }
    }
    if (self.delegate) {
        [detailViewController setDelegate:(id)self.delegate];
    }
    
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DLFDetailViewController *detailViewController = [[DLFDetailViewController alloc] initWithCollectionViewLayout:[[DLFAssetsLayout alloc] init]];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
    if (indexPath.section == 0) {
        detailViewController.assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        detailViewController.title = NSLocalizedString(@"Photos", @"Photos");
    } else {
        NSArray *fetchResult = self.collectionsArrays[indexPath.section - 1];
        PHCollection *collection = fetchResult[indexPath.row];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
            detailViewController.assetsFetchResults = assetsFetchResult;
            detailViewController.assetCollection = assetCollection;
            detailViewController.title = collection.localizedTitle;
        }
    }
    if (self.delegate) {
        [detailViewController setDelegate:(id)self.delegate];
    }
    UINavigationController *detailNavVC = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    [self.splitViewController showDetailViewController:detailNavVC sender:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1 + self.collectionsArrays.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (section == 0) {
        numberOfRows = 1; // "All Photos" section
    } else {
        NSArray *collections = self.collectionsArrays[section - 1];
        numberOfRows = collections.count;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSString *localizedTitle = nil;
    
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:AllPhotosReuseIdentifier forIndexPath:indexPath];
        localizedTitle = NSLocalizedString(@"Photos", @"Photos");
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CollectionCellReuseIdentifier forIndexPath:indexPath];
        NSArray *results = self.collectionsArrays[indexPath.section - 1];
        PHCollection *collection = results[indexPath.row];
        localizedTitle = collection.localizedTitle;
    }
    cell.textLabel.text = localizedTitle;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    if (section > 0) {
        title = self.collectionsLocalizedTitles[section - 1];
    }
    return title;
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableArray *updatedCollectionsFetchResults = nil;
        
        for (PHFetchResult *collectionsFetchResult in self.collectionsFetchResults) {
            PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:collectionsFetchResult];
            if (changeDetails) {
                if (!updatedCollectionsFetchResults) {
                    updatedCollectionsFetchResults = [self.collectionsFetchResults mutableCopy];
                }
                [updatedCollectionsFetchResults replaceObjectAtIndex:[self.collectionsFetchResults indexOfObject:collectionsFetchResult] withObject:[changeDetails fetchResultAfterChanges]];
            }
        }
        
        if (updatedCollectionsFetchResults) {
            self.collectionsFetchResults = updatedCollectionsFetchResults;
            [self excludeEmptyCollections];
            [self.tableView reloadData];
        }
        
    });
}

- (BOOL)hasImageTypeAssetInCollection: (PHAssetCollection *)collection {
    PHFetchOptions *assetOptions = [[PHFetchOptions alloc] init];
    [assetOptions setPredicate:[NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage]];
    PHFetchResult *countResult = [PHAsset fetchAssetsInAssetCollection:collection options:assetOptions];
    
    return countResult.count > 0;
}

- (NSMutableArray *)doExtractAssetCollectionsFrom: (PHCollectionList *) collectionList {
    NSMutableArray *filteredCollections = [NSMutableArray array];
    
    PHFetchOptions *collectionOptions = [[PHFetchOptions alloc] init];
    [collectionOptions setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(localizedTitle)) ascending:YES]]];
    PHFetchResult *result = [PHCollection fetchCollectionsInCollectionList:collectionList options:collectionOptions];
    
    [result enumerateObjectsUsingBlock:^(PHCollection *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[PHAssetCollection class]]) {
            if ([self hasImageTypeAssetInCollection:(PHAssetCollection *)obj]) {
                [filteredCollections addObject:obj];
            }
        } else if ([obj isKindOfClass:[PHCollectionList class]]) {
            NSMutableArray *array = [self doExtractAssetCollectionsFrom:(PHCollectionList *)obj];
            [filteredCollections addObjectsFromArray:array];
        }
    }];
    
    return filteredCollections;
}

- (void)excludeEmptyCollections {
    NSMutableArray *collectionsArray = [NSMutableArray array];
    for (PHFetchResult *result in self.collectionsFetchResults) {
        NSMutableArray *filteredCollections = [NSMutableArray array];
        [result enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL *stop) {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            [options setPredicate:[NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage]];
            if ([obj isKindOfClass:[PHAssetCollection class]]) {
                if ([self hasImageTypeAssetInCollection:(PHAssetCollection *)obj]) {
                    [filteredCollections addObject:obj];
                }
            } else if ([obj isKindOfClass:[PHCollectionList class]]) {
                NSMutableArray *array = [self doExtractAssetCollectionsFrom:(PHCollectionList *)obj];
                [filteredCollections addObjectsFromArray: array];
            }
        }];
        [collectionsArray addObject:filteredCollections];
    }
    self.collectionsArrays = collectionsArray;
}

@end
