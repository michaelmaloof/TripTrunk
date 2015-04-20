//
//  AddPhotoViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/20/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddPhotoViewController.h"

@interface AddPhotoViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property UIImage *chosenImage;
@property UIImagePickerController *PickerController;
@property CGFloat HeightOfButtons;

@end

@implementation AddPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

-(void)viewWillAppear:(BOOL)animated
{
    
    if(self.chosenImage == NULL)
    {
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:NULL];
        
    }else{
        [self performSegueWithIdentifier:@"CameraSegue" sender:self];
        
        
    }
}


#pragma mark - Image Picker delegates

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.chosenImage = info[UIImagePickerControllerEditedImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}




-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
//    PhotoDetailViewController *photodetailcontroller = segue.destinationViewController;
//    photodetailcontroller.photoDetailImage = self.chosenImage;
//    self.chosenImage = NULL;
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self.tabBarController setSelectedIndex:0];
    
}



@end
