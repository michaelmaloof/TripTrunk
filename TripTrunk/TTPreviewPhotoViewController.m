//
//  TTPreviewPhotoViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 1/17/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTPreviewPhotoViewController.h"
#import "UIImageView+AFNetworking.h"

@interface TTPreviewPhotoViewController ()
@property (strong, nonatomic) IBOutlet TTRoundedImage *ProfilePic;
@property (strong, nonatomic) IBOutlet UILabel *firstLastName;
@property (strong, nonatomic) IBOutlet UILabel *username;
@property (strong, nonatomic) IBOutlet UIImageView *photoPreview;
@property (strong, nonatomic) IBOutlet UIImageView *video_icon;
@end

@implementation TTPreviewPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.photoPreview setImageWithURL:[NSURL URLWithString:self.photo.imageUrl]];
    [self.photo.user fetchInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        [self.ProfilePic setImageWithURL:[NSURL URLWithString:self.photo.user[@"profilePicUrl"]]];
        self.firstLastName.text = self.photo.user[@"name"];
    }];
    self.username.text = [NSString stringWithFormat:@"@%@",self.photo.userName];
    if(self.photo.video)
        self.video_icon.hidden = NO;
}

-(void)viewDidLayoutSubviews{
    self.photoPreview.contentMode = UIViewContentModeScaleAspectFill;
    self.ProfilePic.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
