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
#import "TTPhotosToAddViewCell.h"
#import "TTPopoverProfileViewController.h"
#import "TTRoundedImage.h"

@interface TTAddMembersViewController () <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UIPopoverPresentationControllerDelegate,UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSMutableArray *searchResults;
@property BOOL isSearching;
@property (strong,nonatomic) NSArray *friends;
@property (strong, nonatomic) NSMutableArray *membersToAdd;
@property (strong,nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet TTOnboardingTextField *searchTextField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *searchFieldTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;
@property (strong, nonatomic) IBOutlet UITextView *trunkName;
@property (strong, nonatomic) IBOutlet UICollectionView *membersCollectionView;
@property (strong, nonatomic) UIPopoverPresentationController *popover;
@property (strong, nonatomic) TTPopoverProfileViewController *popoverProfileViewController;
@end

@implementation TTAddMembersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.trunkName.text = self.trip.name;
    self.tableView.backgroundColor = [TTColor tripTrunkBackgroundLightBlue];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [SocialUtility followingUsers:[PFUser currentUser] block:^(NSArray *users, NSError *error) {
        self.friends = [NSArray arrayWithArray:users];
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
        PFQuery *blockQuery = [PFQuery queryWithClassName:@"Block"];
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
                self.friends = [NSArray arrayWithArray:sortedArray];
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

@end
