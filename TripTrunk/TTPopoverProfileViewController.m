//
//  TTPopoverProfileViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 1/10/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTPopoverProfileViewController.h"
#import "TTRoundedImage.h"
#import "UIImageView+AFNetworking.h"
#import "SocialUtility.h"
#import "TTPopoverProfileViewCell.h"

@interface TTPopoverProfileViewController () <UICollectionViewDataSource,UICollectionViewDelegate>
@property (strong, nonatomic) IBOutlet TTRoundedImage *profilePicture;
@property (strong, nonatomic) IBOutlet UILabel *firstLastName;
@property (strong, nonatomic) IBOutlet UILabel *username;
@property (strong, nonatomic) IBOutlet UITextView *userBio;
@property (strong, nonatomic) IBOutlet UILabel *followersCount;
@property (strong, nonatomic) IBOutlet UILabel *trunksCount;
@property (strong, nonatomic) IBOutlet UILabel *followingCount;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UILabel *initialsLabel;
@property (strong, nonatomic) NSArray *photos;
@end

@implementation TTPopoverProfileViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [SocialUtility loadUserImages:self.user withLimit:6 block:^(NSArray *objects, NSError *error) {
        if(!error){
            self.photos = objects;
            [self.collectionView reloadData];
        }else{
            NSLog(@"Error loading popover profile images: %@",error);
        }
    }];
    self.firstLastName.text = [NSString stringWithFormat:@"%@ %@",self.user[@"firstName"],self.user[@"lastName"]];
    self.username.text = self.user.username;
    self.userBio.text = self.user[@"userBio"];
    
    
    if(self.user[@"profilePicUrl"]){
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.user[@"profilePicUrl"]]];
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        __weak TTRoundedImage *profilePicture = self.profilePicture;
        [profilePicture setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            profilePicture.image = image;
        } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
            self.initialsLabel.text = [self getInitialsForMissingProfilePictureFromUser:self.user];
            self.initialsLabel.hidden = NO;
        }];
    }else{
        self.initialsLabel.text = [self getInitialsForMissingProfilePictureFromUser:self.user];
        self.initialsLabel.hidden = NO;
    }
    
    [self refreshSocialStatCounts];
}

-(NSString*)getInitialsForMissingProfilePictureFromUser:(PFUser*)user{
    return [NSString stringWithFormat:@"%@%@",[user[@"firstName"] substringToIndex:1],[user[@"lastName"] substringToIndex:1]];;
}

-(void)refreshSocialStatCounts{
    //FIXME: CACHE THESE
    [SocialUtility followerCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.followersCount.text = [NSString stringWithFormat:@"%i",count];
        });
    }];
    
    [SocialUtility followingCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.followingCount.text = [NSString stringWithFormat:@"%i",count];
        });
    }];
    
    [SocialUtility trunkCount:_user block:^(int count, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.trunksCount.text = [NSString stringWithFormat:@"%i",count];
        });
    }];
}

#pragma mark - UICollectionViewDataSource
- (TTPopoverProfileViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    TTPopoverProfileViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.photo.image = [UIImage imageNamed:@"tt_square_placeholder"];
    cell.video_icon.hidden = YES;
    
    Photo *photo = self.photos[indexPath.row];
    [cell.photo setImageWithURL:[NSURL URLWithString:photo.imageUrl]];
    cell.photo.contentMode = UIViewContentModeScaleAspectFill;
    if(photo.video)
        cell.video_icon.hidden = NO;
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

#pragma mark - UICollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //nothing
}

@end
