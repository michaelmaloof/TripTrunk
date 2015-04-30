//
//  PhotoViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/29/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "PhotoViewController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface PhotoViewController ()
@property (weak, nonatomic) IBOutlet PFImageView *imageView;


@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.photo.userName;
    PFFile *file = self.photo.imageFile;
    self.imageView.file = file;
    [self.imageView loadInBackground];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSavePhotoTapped:(id)sender {
    
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
}


@end
