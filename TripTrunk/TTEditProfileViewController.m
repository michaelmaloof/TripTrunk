//
//  TTEditProfileViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 7/18/18.
//  Copyright © 2018 Michael Maloof. All rights reserved.
//

#import "TTEditProfileViewController.h"
#import "TTOnboardingButton.h"
#import "TTCitySearchTextField.h"
#import "TTCitySearchResultsTableViewController.h"
#import "TTAnalytics.h"
#import "TTRoundedImage.h"
#import "UIImageView+AFNetworking.h"
#import <MapKit/MapKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "TTUtility.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface TTEditProfileViewController () <TTCitySearchTextFieldDelegate, UIPopoverPresentationControllerDelegate,TTCitySearchResultsDelegate,UITextFieldDelegate,UITextViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) IBOutlet UISwitch *privateSwitch;
@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet TTCitySearchTextField *location;
@property (strong, nonatomic) IBOutlet UITextView *bio;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *facebookButton;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) TTCitySearchResultsTableViewController *citySearchPopover;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property BOOL meetsMinimumRequirements;
@property (strong, nonatomic) TTPlace *place;
@property (strong, nonatomic) IBOutlet TTRoundedImage *profilePicture;
@property (strong, nonatomic) IBOutlet GMSMapView *googleMapView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) NSDictionary *info;
@property BOOL profilePicUpdated;
@property BOOL updatePrivacy;
@property BOOL startEdit;
@property (nonatomic)BOOL isFBUser;
@end

@implementation TTEditProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarController.tabBar.hidden = YES;
    self.citySearchPopover = [[TTCitySearchResultsTableViewController alloc] init];
    
    self.location.csdelegate = self;
    self.citySearchPopover.srdelegate = self;
    
    self.user = [PFUser currentUser];
    [self initMap];
    
    self.firstName.text = self.user[@"firstName"];
    self.lastName.text = self.user[@"lastName"];
    self.email.text = self.user[@"email"];
    self.location.text = self.user[@"hometown"];
    self.bio.text = self.user[@"bio"];
    self.privateSwitch.on = self.user[@"private"]==0?NO:YES;
    self.profilePicture.image = self.profilePic;
    
    self.profilePicUpdated = NO;
    self.startEdit = YES;
    
    if(self.user[@"fbid"])
       [self.facebookButton setTitle:@"Linked" forState:UIControlStateNormal];
    else [self.facebookButton setTitle:@"Tap to link" forState:UIControlStateNormal];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveChangesWasTapped:(TTOnboardingButton *)sender {
    
    BOOL validated = YES;
    
    if(![self validateNameWithAlert:YES])
        validated = NO;
    
    if(validated && ![self validateEmailAddressIsValidFormat:self.email.text showAlert:YES])
        validated = NO;
    
    if(validated && ![self validateLocationWithAlert:YES])
        validated = NO;
    
    if(validated && ![self validateBioWithAlert:YES])
        validated = NO;
    
    if(validated){
        self.user[@"firstName"] = self.firstName.text;
        self.user[@"firstNameLowercase"] = [self.firstName.text lowercaseString];
        self.user[@"lastName"] = self.lastName.text;
        self.user[@"lastNameLowercase"] = [self.lastName.text lowercaseString];
        self.user[@"name"] = [NSString stringWithFormat:@"%@ %@",self.firstName.text,self.lastName.text];
        self.user[@"lowercaseName"] = [NSString stringWithFormat:@"%@ %@",[self.firstName.text lowercaseString],[self.lastName.text lowercaseString]];
        self.user[@"email"] = self.email.text;
        self.user[@"hometown"] = self.location.text;
        self.user[@"bio"] = self.bio.text;
        
        NSString *hometown = self.user[@"hometown"];
        [[TTUtility sharedInstance] locationsForSearch:hometown block:^(NSArray *objects, NSError *error) {
            if(!error){
                PFGeoPoint *hometownGeopoint = [[PFGeoPoint alloc] init];
                TTPlace *place = [[TTPlace alloc] init];
                place = objects[0];
                hometownGeopoint.latitude = place.latitude;
                hometownGeopoint.longitude = place.longitude;
                self.user[@"hometownGeoPoint"] = hometownGeopoint;
                [self shouldSaveUserAndClose:self.user block:^(BOOL succeeded, NSError *error) {
                    if(succeeded){
                        if(self.updatePrivacy){
                            [self changeUserPrivacyWithBlock:^(BOOL succeeded, NSError *error) {
                                [self.navigationController popViewControllerAnimated:YES];
                            }];
                        }else{
                            [self.navigationController popViewControllerAnimated:YES];
                        }
                        
                    }else{
                        UIAlertController * showAlert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                                          message:error.localizedDescription
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction* okayButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"Okay")
                                                                             style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction * action){
                                                                               NSLog(@"you pressed cencel button");
                                                                           }];
                        
                        [showAlert addAction:okayButton];
                        [self presentViewController:showAlert animated:YES completion:nil];
                    }
                }];
            }else{
                UIAlertController * showAlert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                                  message:NSLocalizedString(@"There was an issue trying to update your profile. Please try again. We're sorry for the inconvenience.",@"There was an issue trying to update your profile. Please try again. We're sorry for the inconvenience.")
                                                                           preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* okayButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"Okay")
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action){
                                                                       NSLog(@"you pressed cencel button");
                                                                   }];
                
                [showAlert addAction:okayButton];
                [self presentViewController:showAlert animated:YES completion:nil];
            }
        }];
    }
}

- (IBAction)beginEditingLocation:(TTCitySearchTextField *)sender {
    if(self.startEdit){
        self.location.text= @"";
        self.startEdit = NO;
    }else{
        [self.location resignFirstResponder];
        self.startEdit = YES;
    }
}

- (IBAction)linkUnlinkFacebook:(UIButton *)sender {
    if(self.user[@"fbid"]){
        self.user[@"fbid"] = @"";
        [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [self.facebookButton setTitle:@"Tap to link" forState:UIControlStateNormal];
        }];
    }else{
        //List of permissions we want from the user's facebook to link tp the parse user. We don't need the email since we won't be changing their current email to their facebook email.
        NSArray *permissionsArray = @[ @"email", @"public_profile", @"user_friends"];
        
        //Make sure the user isnt already linked with facebook
        if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
            [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withReadPermissions:permissionsArray block:^(BOOL succeeded, NSError * _Nullable error){
                if (error){
                    //ERROR HANDLE: User Was Unable to link with facebook please try again or contact austin
                    UIAlertView *alertView = [[UIAlertView alloc] init];
                    alertView.delegate = self;
                    alertView.title = NSLocalizedString(@"Something went wrong",@"Something went wrong");
                    alertView.message = NSLocalizedString(@"Please try again or contact austinbarnard@triptrunkapp.com.",@"Please try again or contact austinbarnard@triptrunkapp.com.");
                    alertView.backgroundColor = [TTColor tripTrunkLightBlue];
                    [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                    [alertView show];
                    
                }else{ //succesfully connected the parse user to their facebook account
                    
                    //we need to logout the user and log them back in for the fbid in parse to update. Its annoying and we should see if we can fix it.
                    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error){
                        if (error){
                            //ERROR HANDLE: tell the user we linked the acccount succefully but you need to log back in with the login with facebook option for the link to go into effect
                            [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
                                UIAlertView *alertView = [[UIAlertView alloc] init];
                                alertView.delegate = self;
                                alertView.title = NSLocalizedString(@"Your Facebook account was linked!. Please log back in using Facebook to continue.",@"Your Facebook account was linked!. Please log back in using Facebook to continue.");
                                alertView.backgroundColor = [TTColor tripTrunkLightBlue];
                                [alertView addButtonWithTitle:NSLocalizedString(@"OK",@"OK")];
                                [alertView show];
                                [self.facebookButton setTitle:@"Linked" forState:UIControlStateNormal];
                                [self loginWithFacebook];
                            }];
                            
                        }
                        
                    }];
                }
            }];
        }
    }
}

- (IBAction)backButtonWasTapped:(TTOnboardingButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)privacySwitchChangeAction:(UISwitch *)sender {
    if(self.updatePrivacy)
        self.updatePrivacy = NO;
    else self.updatePrivacy = YES;
}

- (IBAction)editPictureWasTapped:(UIButton *)sender {
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.delegate = self;
    self.imagePicker.allowsEditing = YES;
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (IBAction)screenTapAction:(UITapGestureRecognizer *)sender {
    [self dismissKeyboard];
}

-(void)shouldSaveUserAndClose:(PFUser *)user block:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    // Ensure it's the current user so we don't accidentally let people change other people's info.
    if ([user.objectId isEqualToString:[PFUser currentUser].objectId]) {
        [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if(!self.profilePicUpdated){
                if(succeeded)
                    completionBlock(YES,nil);
                else completionBlock(NO,error);
            }
                
            if(!error){
                NSString *imageUrl = [NSString stringWithFormat:@"%@", self.info[UIImagePickerControllerReferenceURL]];
                NSURL *assetUrl = [NSURL URLWithString:imageUrl];
                NSArray *urlArray = [[NSArray alloc] initWithObjects:assetUrl, nil];
                PHAsset *imageAsset = [[PHAsset fetchAssetsWithALAssetURLs:urlArray options:nil] firstObject];
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                [options setVersion:PHImageRequestOptionsVersionOriginal];
                [options setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
                
                [[PHImageManager defaultManager] requestImageDataForAsset:imageAsset
                                                                  options:options
                                                            resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                                // Calls the method to actually upload the image and save the User to parse
                                                                [[TTUtility sharedInstance] uploadProfilePic:imageData forUser:self.user block:^(BOOL succeeded, NSError *error) {
                                                                    if(succeeded)
                                                                        completionBlock(YES,nil);
                                                                    else completionBlock(NO,error);
                                                                }];
                                                                
                                                            }];
                
            }else{
                if(error.code == 203){
                    //Create 'email address invalid' alert view
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                    message:NSLocalizedString(@"This email address is already in use.", @"This email address is already in use.")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                          otherButtonTitles:nil, nil];
                    //Show alert view
                    alert.tag = 0;
                    [alert show];
                    self.user[@"email"] = NSLocalizedString(@"<Error: please update>",@"<Error: please update>");
                    [[self presentedViewController] dismissViewControllerAnimated:YES completion:nil];
                }

                else if (error.code != 120){
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Updating User Info",@"Error Updating User Info")
                                                                    message:NSLocalizedString(@"Please try again later.", @"Please try again later.")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                          otherButtonTitles:nil, nil];
                    alert.tag = 0;
                    [alert show];
                }
                
                completionBlock(NO,error);

            }
        }];
    }
}

-(void)privacyChanged:(PFUser *)user{
    if ([self.user.objectId isEqualToString:user.objectId]){
        [self.user setValue:[user valueForKey:@"private"] forKey:@"private"];
    }
}

-(void)loginWithFacebook{
    //Added to prevent facebook 304 error. This will clear the current user that wasn't logged out correctly
    FBSDKLoginManager *logMeOut = [[FBSDKLoginManager alloc] init];
    [logMeOut logOut];
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"email", @"public_profile", @"user_friends"];
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (error) {
            NSString *errorString = [error userInfo][@"error"];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"_loginWithFacebook:"];
            NSLog(@"%@",errorString);
            NSLog(@"%@",error);
            return;
        }
        if (!user) {
            NSLog(@"Uh oh. The user cancelled the Facebook login.");
        } else if (user.isNew) {
            self.isFBUser = YES;
        } else {
            if ([user objectForKey:@"fbid"] == nil) {
                FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"/v2.12/me/" parameters:@{@"fields": @"id"}];
                [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                    if (!error) {
                        // result is a dictionary with the user's Facebook data
                        NSDictionary *userData = (NSDictionary *)result;
                        PFUser *user = [PFUser currentUser];
                        NSString *fbid = [userData objectForKey:@"id"];
                        if (fbid){
                            [user setObject:fbid forKey:@"fbid"];
                            [user saveInBackground];
                        }
                    }else{
                        [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"_loginWithFacebook:"];
                    }
                }];
            }
            // Make sure the user has a TripTrunk username
            if (![user valueForKey:@"completedRegistration"] || [[user valueForKey:@"completedRegistration"] boolValue] == FALSE) {
                self.isFBUser = YES;
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"updateMapAfterLogin" object:nil];
                [self dismissViewControllerAnimated:YES completion:^{
                }];
            }
        }
    }];
}

-(void)changeUserPrivacyWithBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    if (self.privateSwitch.isOn) {
        // Become Private
        [PFCloud callFunctionInBackground:@"becomePrivate" withParameters:nil block:^(id  _Nullable object, NSError * _Nullable error) {
            if (error){
                NSLog(@"Error becoming private: %@", error);
                self.navigationItem.rightBarButtonItem.enabled = YES;
                self.title = NSLocalizedString(@"Edit Profile", @"Edit Profile");
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                completionBlock(NO,error);
            }else{
                completionBlock(YES,nil);
            }
        }];
    }else {
        // Become Public
        [PFCloud callFunctionInBackground:@"becomePublic" withParameters:nil block:^(id  _Nullable object, NSError * _Nullable error) {
            if(error){
                NSLog(@"Error becoming public: %@", error);
                self.navigationItem.rightBarButtonItem.enabled = YES;
                self.title = NSLocalizedString(@"Edit Profile", @"Edit Profile");
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                completionBlock(NO,error);
            }else{
                completionBlock(YES,nil);
            }
        }];
        
    }
}

#pragma mark - TTCitySearchTextFieldDelegate
-(void)displayCitySearchPopoverFromView:(NSArray*)results{
    
    if(self.popover.delegate == nil){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        self.citySearchPopover = [storyboard instantiateViewControllerWithIdentifier:@"TTCitySearchResultsTableViewController"];
        self.citySearchPopover.searchResults = results;
        self.citySearchPopover.modalPresentationStyle = UIModalPresentationPopover;
        
        //force the popover to display like an iPad popover otherwise it will be full screen
        self.popover  = self.citySearchPopover.popoverPresentationController;
        self.popover.delegate = self;
        self.popover.sourceView = self.location;
        self.popover.sourceRect = [self.location bounds];
        self.popover.permittedArrowDirections = UIPopoverArrowDirectionDown;
        
        self.citySearchPopover.preferredContentSize = CGSizeMake([self.citySearchPopover preferredWidthForPopover], [self.citySearchPopover preferredHeightForPopover]);
        self.citySearchPopover.srdelegate = self;
        [self presentViewController:self.citySearchPopover animated:YES completion:nil];
    }else{
        self.citySearchPopover.searchResults = results;
        self.citySearchPopover.preferredContentSize = CGSizeMake([self.citySearchPopover preferredWidthForPopover], [self.citySearchPopover preferredHeightForPopover]);
        [self.citySearchPopover reloadTable];
    }
}

-(void)dismissCitySearchPopoverFromView{
    self.popover.delegate = nil;
    [self.citySearchPopover dismissViewControllerAnimated:YES completion:nil];
}

-(void)resetCitySearchTextField{
    self.meetsMinimumRequirements = NO;
//    self.nextButton.hidden = YES;
}

#pragma mark - UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller{
    // Return no adaptive presentation style, use default presentation behaviour
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverController{
    self.popover.delegate = nil;
}

#pragma mark - TTCitySearchResultsDelegate
-(void)didSelectTableRow:(TTPlace*)selectedCity{
    self.place = selectedCity;
    [self.location setText:[selectedCity.name stringByReplacingOccurrencesOfString:@", USA" withString:@""]];
    [self.location resignFirstResponder];
    self.meetsMinimumRequirements = YES;
//    self.nextButton.hidden = NO;
    [self dismissCitySearchPopoverFromView];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField.text isEqualToString:@""]){
        return NO;
    }else{
        return YES;
    }
}

#pragma mark - GoogleMapView
-(void)initMap{
    double mapOffset = -1.0; //<------determine if the map should offset because a point is below the photos
    
    //Map View of trunk location
    //    self.googleMapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 0, 375, 200)];
    PFGeoPoint *geoPoint = self.user[@"hometownGeoPoint"];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:geoPoint.latitude+mapOffset
                                                            longitude:geoPoint.longitude
                                                                 zoom:7];
    
    self.googleMapView.camera = camera;
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *styleUrl = [mainBundle URLForResource:@"style" withExtension:@"json"];
    NSError *error;
    
    GMSMapStyle *style = [GMSMapStyle styleWithContentsOfFileURL:styleUrl error:&error];
    
    if (!style) {
        NSLog(@"The style definition could not be loaded: %@", error);
    }
    
    self.googleMapView.mapStyle = style;
    self.googleMapView.userInteractionEnabled = NO;
    
    [self addPointToMapWithGeoPoint:geoPoint];
    NSArray *city = [self.user[@"hometown"] componentsSeparatedByString:@","];
    [self addLabelToMapWithGeoPoint:geoPoint AndText:city[0]];
}

//FIXME: THIS NEEDS TO MOVE TO UTILITY
#pragma mark - Marker Creation Code
-(GMSMarker*)createMapMarkerWithGeoPoint:(PFGeoPoint*)geoPoint{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    
    return marker;
}

-(CGPoint)createMapPointWithGeoPoint:(PFGeoPoint*)geoPoint{
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
    CGPoint point = [self.googleMapView.projection pointForCoordinate:marker.position];
    
    return point;
}

-(void)addPointToMapWithGeoPoint:(PFGeoPoint*)geoPoint{
    CGPoint point = [self createMapPointWithGeoPoint:geoPoint];
    
    UIImageView *dot =[[UIImageView alloc] initWithFrame:CGRectMake(point.x-10,point.y-10,20,20)];
    dot.image=[UIImage imageNamed:@"bluedot"];
    
    [self.googleMapView addSubview:dot];
}

-(void)addFlagToMapWithGeoPoint:(PFGeoPoint*)geoPoint{
    CGPoint point = [self createMapPointWithGeoPoint:geoPoint];
    
    UIImageView *flag =[[UIImageView alloc] initWithFrame:CGRectMake(point.x-10,point.y-20,20,20)];
    flag.image=[UIImage imageNamed:@"map_point_flag"];
    flag.tag = 1000;
    [self.googleMapView addSubview:flag];
}

-(void)addLabelToMapWithGeoPoint:(PFGeoPoint*)geoPoint AndText:(NSString*)text{
    CGPoint point = [self createMapPointWithGeoPoint:geoPoint];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(point.x-10,point.y+3,100,21)];
    label.font = [TTFont tripTrunkFont8];
    label.textColor = [TTColor tripTrunkDarkGray];
    label.text = text;
    
    [self.googleMapView addSubview:label];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:3.0];
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:3.0];
    return YES;
}

-(void)dismissKeyboard{
    [self.firstName resignFirstResponder];
    [self.lastName resignFirstResponder];
    [self.email resignFirstResponder];
}

-(void)keyboardWillShowNotification{
    [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:3.0];
}

#pragma mark - dataVerification
-(BOOL)validateEmailAddressIsValidFormat:(NSString*)emailAddress showAlert:(BOOL)showAlert{
    NSString *expression = @"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$";
    NSError *error = NULL;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:emailAddress options:0 range:NSMakeRange(0, [emailAddress length])];
    
    if(!match){
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                      message:NSLocalizedString(@"Invalid Email Address",@"Invalid Email Address")
                                                               preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okayButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"Okay")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action){
                                                             NSLog(@"you pressed cencel button");
                                                         }];

        [alert addAction:okayButton];
        
        if(showAlert)
            [self presentViewController:alert animated:YES completion:nil];
        
        return NO;
    }
    
    self.email.text = [self trim:self.email.text];
    return YES;
}

-(BOOL)validateNameWithAlert:(BOOL)alert{
    if(self.firstName.text !=nil && ![self.firstName.text isEqualToString:@""] && ![self.firstName.text isEqualToString:@" "]
       && self.lastName.text !=nil && ![self.lastName.text isEqualToString:@""] && ![self.lastName.text isEqualToString:@" "]){
        self.firstName.text = [self trim:self.firstName.text];
        self.lastName.text = [self trim:self.lastName.text];
        return YES;
    }
    
    UIAlertController * showAlert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                  message:NSLocalizedString(@"Invalid First/Last Name",@"Invalid First/Last Name")
                                                           preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okayButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"Okay")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action){
                                                           NSLog(@"you pressed cencel button");
                                                       }];
    
    [showAlert addAction:okayButton];
    
    if(alert)
        [self presentViewController:showAlert animated:YES completion:nil];
    
    return NO;
}

-(BOOL)validateLocationWithAlert:(BOOL)alert{
    if(self.location.text !=nil && ![self.location.text isEqualToString:@""])
        return YES;
    
    UIAlertController * showAlert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                      message:NSLocalizedString(@"Invalid Location",@"Invalid Location")
                                                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okayButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"Okay")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action){
                                                           NSLog(@"you pressed cencel button");
                                                       }];
    
    [showAlert addAction:okayButton];
    
    if(alert)
        [self presentViewController:showAlert animated:YES completion:nil];
    
    return NO;
}

-(BOOL)validateBioWithAlert:(BOOL)alert{
    self.bio.text = [self trim:self.bio.text];
    return YES;
}

-(NSString *)trim:(NSString *) strInput{
    return [strInput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo{
    //FIXME: The cropping isn't being retained on this
    self.profilePicture.image = image;
    self.profilePic = image;
    self.info = editingInfo;
    self.profilePicUpdated = YES;
    [picker dismissViewControllerAnimated:YES completion:^{
        //nada
    }];
    
}

@end
