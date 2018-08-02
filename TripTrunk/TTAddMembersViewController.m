//
//  TTAddMembersViewController.m
//  TripTrunk
//
//  Created by Michael Cannell on 12/27/17.
//  Copyright © 2017 Michael Maloof. All rights reserved.
//

#import "TTAddMembersViewController.h"
#import "TTAddMembersViewCell.h"
#import "TTUtility.h"
#import "SocialUtility.h"
#import "UIImageView+AFNetworking.h"
#import "TTFont.h"
#import "TTColor.h"
#import "TTUsernameSort.h"
#import "TTOnboardingTextField.h"
#import "TTOnboardingButton.h"
#import "TTPhotosToAddViewCell.h"
#import "TTPopoverProfileViewController.h"
#import "TTRoundedImage.h"
#import "TTTrunkLocationViewController.h"
#import "TTAnalytics.h"
#import "TTAddPhotosViewController.h"

@interface TTAddMembersViewController () <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UIPopoverPresentationControllerDelegate,UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSMutableArray *searchResults;
@property BOOL isSearching;
//@property (strong,nonatomic) NSArray *friends;
@property (strong, nonatomic) NSMutableArray *membersToAdd;
@property (strong,nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet TTOnboardingTextField *searchTextField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *searchFieldTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;
@property (strong, nonatomic) IBOutlet UITextView *trunkName;
@property (strong, nonatomic) IBOutlet UICollectionView *membersCollectionView;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTPopoverProfileViewController *popoverProfileViewController;
@property (strong, nonatomic) IBOutlet TTOnboardingButton *actionButton;
@end

@implementation TTAddMembersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.trunkName.text = self.trip.name;
    self.tableView.backgroundColor = [TTColor tripTrunkBackgroundLightBlue];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        self.friends = [NSMutableArray arrayWithArray:users];
        [SocialUtility followers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
            [self.friends arrayByAddingObjectsFromArray:users];
            [self.tableView reloadData];
        }];
        
    }];
    
    self.membersToAdd = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section NS_AVAILABLE_IOS(6_0){
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section NS_AVAILABLE_IOS(6_0){
}

- (UIView*) tableView: (UITableView*) tableView viewForHeaderInSection: (NSInteger)  section
{
    UIView* view = [[UIView alloc] init];
    [view sizeToFit];
    view.backgroundColor = [TTColor tripTrunkBackgroundLightBlue];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(32, 45, kScreenWidth, 21)];
    label.text = NSLocalizedString(@"All Friends", @"All Friends");
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [TTFont TT_AddMembers_header];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [view addSubview:label];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 85;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 80;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;{
    return self.friends.count;
}

- (TTAddMembersViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    __weak TTAddMembersViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.profileImage.image = [UIImage imageNamed:@"tt_square_placeholder"];
    cell.name.text = @"";
    cell.checkmark.hidden = YES;
    cell.initialsLabel.hidden = YES;
    cell.backgroundColor = [TTColor tripTrunkBackgroundLightBlue];
    
    PFUser *user = self.friends[indexPath.row];
    cell.name.text = user[@"name"];
    if([self.membersToAdd containsObject:user])
        cell.checkmark.hidden = NO;
    cell.checkmark.tag = indexPath.row;
    cell.profileImage.tag = indexPath.row;
    if(user[@"profilePicUrl"]){
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:user[@"profilePicUrl"]]];
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        [cell.profileImage setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            cell.profileImage.image = image;
        } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
            cell.initialsLabel.text = [self getInitialsForMissingProfilePictureFromUser:user];
            cell.initialsLabel.hidden = NO;
        }];
    }else{
        cell.initialsLabel.text = [self getInitialsForMissingProfilePictureFromUser:user];
        cell.initialsLabel.hidden = NO;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    TTAddMembersViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if(cell.checkmark.hidden){ //<----------- SELECT USER ----------------
        cell.checkmark.hidden = NO;
        [self.membersToAdd addObject:self.friends[indexPath.row]];
        self.membersCollectionView.hidden = NO;
        [self.membersCollectionView reloadData];
    }else{
        cell.checkmark.hidden = YES;
        [self.membersToAdd removeObject:self.friends[indexPath.row]];
        [self.membersCollectionView reloadData];
        if(self.membersToAdd.count == 0)
            self.membersCollectionView.hidden = YES;
    }
    
    [self setNextButtonTitle];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
}

-(NSString*)getInitialsForMissingProfilePictureFromUser:(PFUser*)user{
    return [NSString stringWithFormat:@"%@%@",[user[@"firstName"] substringToIndex:1],[user[@"lastName"] substringToIndex:1]];;
}

#pragma mark - Friend Search
- (void)filterResults:(NSString *)searchTerm {
    if (![searchTerm isEqualToString:@""]){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissKeyboard) object:nil];
        
        //     Gets all the users who have blocked this user. Hopefully it's 0!
        PFQuery *blockQuery = [PFQuery queryWithClassName:@"BlockedUsers"];
        [blockQuery whereKey:@"blockedUser" equalTo:[PFUser currentUser]];
        
        PFQuery *usernameQuery = [PFUser query];
        [usernameQuery whereKeyExists:@"username"];  //this is based on whatever query you are trying to accomplish
        [usernameQuery whereKey:@"username" containsString:searchTerm];
        [usernameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]];
        [usernameQuery whereKeyExists:@"completedRegistration"]; // Make sure we don't get half-registered users with the weird random usernames
        
        PFQuery *nameQuery = [PFUser query];
        [nameQuery whereKeyExists:@"lowercaseName"];  //this is based on whatever query you are trying to accomplish
        [nameQuery whereKeyExists:@"completedRegistration"];// Make sure we don't get half-registered users with the weird random usernames
        [nameQuery whereKey:@"lowercaseName" containsString:[searchTerm lowercaseString]];
        [nameQuery whereKey:@"username" notEqualTo:[[PFUser currentUser] username]]; // exclude currentUser
        
        PFQuery *query = [PFQuery orQueryWithSubqueries:@[usernameQuery, nameQuery]];
        query.limit = 10;
        //FIXME SEARCH NEEDS A SKIP OR ITLL KEEP RETURNING THE SAME ONES
        
        [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            
            if (error){
                [ParseErrorHandlingController handleError:error];
            } else {
                self.searchResults = [[NSMutableArray alloc] init];
                [self.searchResults addObjectsFromArray:objects];
                TTUsernameSort *us = [[TTUsernameSort alloc] init];
                NSArray *sortedArray = [us sortResultsByUsername:self.searchResults searchTerm:searchTerm];
                self.searchResults = [NSMutableArray arrayWithArray:sortedArray];
                self.isSearching = YES;
                self.friends = [NSMutableArray arrayWithArray:sortedArray];
                [self.tableView reloadData];
                [self performSelector:@selector(dismissKeyboard) withObject:nil afterDelay:2.0];
                [[TTUtility sharedInstance] internetConnectionFound];
            }
        }];
    }
}

- (void)keyboardWillShow:(NSNotification *)notification {
    //move the search field and collectionview up
    [self.view layoutIfNeeded];
    self.searchFieldTopConstraint.constant = 117;
    self.tableViewTopConstraint.constant = 137;
    
    [UIView animateWithDuration:1.00
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];
}

-(void)dismissKeyboard{
    [self.searchTextField resignFirstResponder];
    if([self.searchTextField.text isEqualToString:@""]){
        [self.view layoutIfNeeded];
        self.searchFieldTopConstraint.constant = 179;
        self.tableViewTopConstraint.constant = 199;
    
        [UIView animateWithDuration:.25
                     animations:^{
                         [self.view layoutIfNeeded];
                     }];
    }
}



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if(![event touchesForView:self.searchTextField]){
            [self dismissKeyboard];
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"touch ended");
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [self filterResults:[textField.text stringByAppendingString:string]];
    return YES;
}

#pragma mark - UICollectionViewDelegate
- (TTPhotosToAddViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    __weak TTPhotosToAddViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.image.image = [UIImage imageNamed:@"tt_square_placeholder"];
    cell.initialsLabel.hidden = YES;
    
    PFUser *user = self.membersToAdd[indexPath.row];
    if(user[@"profilePicUrl"]){
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:user[@"profilePicUrl"]]];
        [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
        [cell.image setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            cell.image.image = image;
        } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
            cell.initialsLabel.text = [self getInitialsForMissingProfilePictureFromUser:user];
            cell.initialsLabel.hidden = NO;
        }];
    }else{
        cell.initialsLabel.text = [self getInitialsForMissingProfilePictureFromUser:user];
        cell.initialsLabel.hidden = NO;
    }
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.membersToAdd.count;
}

#pragma mark - UIButtons
- (IBAction)backButtonWasPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)skipWasPressed:(id)sender {
    if([self.delegate isKindOfClass:[TTTrunkLocationViewController class]]) //FIXME: verify that this works
        [self createNewTrunkAndAddMembers];
    else [self addMembersToExistingTrunk];
}

- (IBAction)longPressToViewProfileAsPreview:(UILongPressGestureRecognizer*)gesture {
    if(gesture.state == UIGestureRecognizerStateBegan){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Profile" bundle:nil];
        self.popoverProfileViewController = (TTPopoverProfileViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ProfilePopoverView"];
        CGPoint touchPoint = [gesture locationInView:self.view];
        UIView* touchedView = [self.view hitTest:touchPoint withEvent:nil];
        if([touchedView isKindOfClass:[TTRoundedImage class]] || [touchedView isKindOfClass:[UIImageView class]]){
            self.popoverProfileViewController.user = self.friends[touchedView.tag];
            self.popoverProfileViewController.modalPresentationStyle = UIModalPresentationPopover;
            self.popoverProfileViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            
            //force the popover to display like an iPad popover otherwise it will be full screen
            self.popover  = self.popoverProfileViewController.popoverPresentationController;
            self.popover.delegate = self;
            self.popover.sourceView = self.view;
            self.popover.sourceRect = CGRectMake(27,140,320,380);
            self.popover.permittedArrowDirections = 0;
            
            self.popoverProfileViewController.preferredContentSize = CGSizeMake(320,380);
            self.popoverProfileViewController.popoverPresentationController.sourceView = self.view;
            self.popoverProfileViewController.popoverPresentationController.sourceRect = CGRectMake(27,140,320,380);
            
            //HACK because modalTransitionStyle doesn't work on fade in
            CATransition* transition = [CATransition animation];
            transition.duration = 0.5;
            transition.type = kCATransitionFade;
            [self.view.window.layer addAnimation:transition forKey:kCATransition];
            
            [self presentViewController:self.popoverProfileViewController animated:NO completion:nil];
        }
    }
    
    if(gesture.state == UIGestureRecognizerStateEnded){
        [self.popoverProfileViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIModalPopoverDelegate
- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController: (UIPresentationController * ) controller {
    return UIModalPresentationNone;
}

#pragma mark -
-(void)setNextButtonTitle{
    NSString *skipText = NSLocalizedString(@"SKIP", @"SKIP");
    NSString *nextText;
    if([self.delegate isKindOfClass:[TTTrunkLocationViewController class]]) //FIXME: verify that this works
        nextText = NSLocalizedString(@"CREATE & INVITE", @"CREATE & INVITE");
    else nextText = NSLocalizedString(@"ADD MEMBERS", @"ADD MEMBERS");
    
    if(self.membersToAdd.count > 0){
        self.actionButton.hidden = NO;
        [self.actionButton setTitle:nextText forState:UIControlStateNormal];
    }else{
        if([self.delegate isKindOfClass:[TTTrunkLocationViewController class]])
            [self.actionButton setTitle:skipText forState:UIControlStateNormal];
        else self.actionButton.hidden = YES;
    }
    
    
}

-(void)createNewTrunkAndAddMembers{

    PFACL *tripACL = [PFACL ACLWithUser:[PFUser currentUser]];

    if (!self.trip.isPrivate)
        [tripACL setPublicReadAccess:YES];
    
    // Private Trip, set the ACL permissions so only the creator has access - and when members are invited then they'll get READ access as well.
    // TODO: only update ACL if private status changed during editing.
    if (self.trip.isPrivate) {
        [tripACL setPublicReadAccess:NO];
        [tripACL setReadAccess:YES forUser:self.trip.creator];
        [tripACL setWriteAccess:YES forUser:self.trip.creator];
    }else{
        // Only add the friendsOf_ role to the ACL if the trunk is NOT private! A private trunk shouldn't be visible to followers. just trunk members
        // This fixes the shitty bug that was live at launch.
        NSString *roleName = [NSString stringWithFormat:@"friendsOf_%@", [[PFUser currentUser] objectId]];
        [tripACL setReadAccess:YES forRoleWithName:roleName];
    }
    
    self.trip.ACL = tripACL;
    
    if(!self.trip.publicTripDetail)
        self.trip.publicTripDetail = [[PublicTripDetail alloc]init];
    
//    if(self.membersToAdd.count == 0)
        self.trip.publicTripDetail.memberCount = 1;
//    else self.trip.publicTripDetail.memberCount = (int)self.membersToAdd.count;
    
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
         dispatch_async(dispatch_get_main_queue(), ^{
             
             if(error) {
                 [ParseErrorHandlingController handleError:error];
                 [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"createNewTrunkAndAddMembers:"];
                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                     message:NSLocalizedString(@"Please Try Again",@"Please Try Again")
                                                                    delegate:self
                                                           cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                           otherButtonTitles:nil, nil];
//                 alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
                 [alertView show];
             }else{
                 [[TTUtility sharedInstance] internetConnectionFound];
                 //trip needs to be saved after the publicTripDetail is created otherwise we get a loop error
                 PFQuery *query = [PFQuery queryWithClassName:@"PublicTripDetail"];
                 [query getObjectInBackgroundWithId:self.trip.publicTripDetail.objectId block:^(PFObject *pfObject, NSError *error) {
                     [pfObject setObject:self.trip forKey:@"trip"];
                     [pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                         PFUser *user = [PFUser currentUser];
                         NSString *hometown = user[@"hometown"];
                         [[TTUtility sharedInstance] locationsForSearch:hometown block:^(NSArray *objects, NSError *error) {
                             if(!error){
                                 PFGeoPoint *hometownGeopoint = [[PFGeoPoint alloc] init];
                                 TTPlace *place = [[TTPlace alloc] init];
                                 place = objects[0];
                                 hometownGeopoint.latitude = place.latitude;
                                 hometownGeopoint.longitude = place.longitude;
                                 PFObject *detail = self.trip.publicTripDetail;
                                 detail[@"homeAtCreation"] = hometownGeopoint;
                                 self.trip[@"homeAtCreation"] = hometownGeopoint;
                                 [detail saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                     if(succeeded)
                                         NSLog(@"hometown geopoint suceeded");
                                     else NSLog(@"hometown geopoint failed");
                                     
                                     [self.trip saveInBackground];
                                     
                                     [self addMembersToNewlyCreatedTrunk];
                                 }];
                             }
                         }];
                         
                         
                         
                     }];
                 }];

             }
         });
     }];
    
}

-(void)addMembersToExistingTrunk{
    NSMutableArray *users = [self idsFromUsers:self.membersToAdd];
    NSMutableArray *newUsers = [[NSMutableArray alloc] init];
    NSArray *existingMembers = [self idsFromUsers:self.existingMembersOfTrunk];
    
    for(id user in users){
        if(![existingMembers containsObject:user])
            [newUsers addObject:user];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   newUsers, @"users",
                                   [PFUser currentUser].objectId, @"fromUserId",
                                   self.trip.objectId, @"tripId",
                                   self.trip.creator.objectId, @"tripCreatorId",
                                   [NSNumber numberWithBool:self.trip.isPrivate], @"private",
                                   [NSString stringWithFormat:@"%@", self.trip.city], @"content",
                                   [NSNumber numberWithDouble:self.trip.lat], @"latitude",
                                   [NSNumber numberWithDouble:self.trip.longitude], @"longitude",
                                   self.trip.gpID, @"gpID",
                                   nil];

    [PFCloud callFunctionInBackground:@"AddMembersToTrip" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
        if(!error){
            //THIS INCREMENTS THE MEMBER COUNT BY 1number of members added
            //This needs to be moved to AddMembersToTrip in CC
            PublicTripDetail *ptdId = self.trip.publicTripDetail;
            PFQuery *query = [PFQuery queryWithClassName:@"PublicTripDetail"];
            [query getObjectInBackgroundWithId:ptdId.objectId block:^(PFObject *pfObject, NSError *error) {
                int count = 0;
                if(pfObject[@"memberCount"])
                    count = [pfObject[@"memberCount"] intValue];
                
                count = count+(int)self.membersToAdd.count;
                [pfObject setObject:[NSNumber numberWithInt:count] forKey:@"memberCount"];
                [pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MembersAdded" object:nil];
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            }];
            ///-----------------------------^
        }else{
            NSString *errorString = [NSString stringWithFormat:@"%@",error];
            NSArray *errorArray = [errorString componentsSeparatedByString:@"\" UserInfo="];
            NSArray *errorMessage = [errorArray[0] componentsSeparatedByString:@"ERROR: "];
            NSString *errorMessageString = NSLocalizedString(errorMessage[1], errorMessage[1]); //FIXME: This is wrong
            UIAlertController * alert=[UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                                                          message:errorMessageString
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* okButton = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", @"Ok")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action){
                                                                 NSLog(@"you pressed ok button");
                                                                 [self.navigationController popViewControllerAnimated:YES];
                                                             }];
        
            [alert addAction:okButton];
            [self presentViewController:alert animated:YES completion:nil];
            [TTAnalytics errorOccurred:[NSString stringWithFormat:@"%@",error] method:@"addMembersToExistingTrunk:"];
        }
    }];
}

-(void)addMembersToNewlyCreatedTrunk{
    NSArray *users = [[self idsFromUsers:self.membersToAdd] arrayByAddingObject:[PFUser currentUser].objectId];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   users, @"users",
                                   [PFUser currentUser].objectId, @"fromUserId",
                                   self.trip.objectId, @"tripId",
                                   self.trip.creator.objectId, @"tripCreatorId",
                                   [NSNumber numberWithBool:self.trip.isPrivate], @"private",
                                   [NSString stringWithFormat:@"%@", self.trip.city], @"content",
                                   [NSNumber numberWithDouble:self.trip.lat], @"latitude",
                                   [NSNumber numberWithDouble:self.trip.longitude], @"longitude",
                                   self.trip.gpID, @"gpID",
                                   nil];
    
    [PFCloud callFunctionInBackground:@"AddMembersToTrip" withParameters:params block:^(id  _Nullable object, NSError * _Nullable error) {
        if(!error){
            //THIS INCREMENTS THE MEMBER COUNT BY 1number of members added
            //This needs to be moved to AddMembersToTrip in CC
            PublicTripDetail *ptdId = self.trip.publicTripDetail;
            PFQuery *query = [PFQuery queryWithClassName:@"PublicTripDetail"];
            [query getObjectInBackgroundWithId:ptdId.objectId block:^(PFObject *pfObject, NSError *error) {
                int count = 0;
                if(pfObject[@"memberCount"])
                    count = [pfObject[@"memberCount"] intValue];
                
                count = count+(int)self.membersToAdd.count;
                [pfObject setObject:[NSNumber numberWithInt:count] forKey:@"memberCount"];
                [pfObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    [self performSegueWithIdentifier:@"pushToAddPhotos" sender:self];
                }];
            }];
            ///-----------------------------^
        }else{
            //HANDLE THIS ERROR
        }
    }];
}

- (NSMutableArray *)idsFromUsers:(NSArray *)users{
    NSMutableArray *idList = [[NSMutableArray alloc] initWithCapacity:users.count];
    for (PFUser *user in users) {
        [idList addObject:user.objectId];
    }
    return idList;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"pushToAddPhotos"]){
        TTAddPhotosViewController *photoViewController = segue.destinationViewController;
        photoViewController.trip = self.trip;
        photoViewController.trunkMembers = self.membersToAdd;
        photoViewController.newTrip = YES;
//        photoViewController.delegate = self;
    }
}



@end
