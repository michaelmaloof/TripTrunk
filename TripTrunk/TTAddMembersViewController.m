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

@interface TTAddMembersViewController () <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,UICollectionViewDelegate,UICollectionViewDataSource>
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
    TTAddMembersViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.profileImage.image = [UIImage imageNamed:@"tt_square_placeholder"];
    cell.name.text = @"";
    cell.checkmark.hidden = YES;
    cell.backgroundColor = [TTColor tripTrunkBackgroundLightBlue];
    PFUser *user = self.friends[indexPath.row];
    cell.name.text = user[@"name"];
    [cell.profileImage setImageWithURL:[NSURL URLWithString:user[@"profilePicUrl"]]];
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
        if(self.membersToAdd.count ==0)
            self.membersCollectionView.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
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

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [self filterResults:[textField.text stringByAppendingString:string]];
    return YES;
}

- (TTPhotosToAddViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TTPhotosToAddViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.image.image = [UIImage imageNamed:@"square_placeholder"];
    PFUser *member = self.membersToAdd[indexPath.row];
    UIImageView *imageView;
    if(member[@"profilePicUrl"]){
        [cell.image setImageWithURL:[NSURL URLWithString:member[@"profilePicUrl"]]];
    }else{
        imageView.image = [UIImage imageNamed:@"tt_square_placeholder"];
        CGRect labelFrame = CGRectMake(10, 10, 40, 40);
        UILabel *initialsLabel = [[UILabel alloc] initWithFrame:labelFrame];
        initialsLabel.text = [NSString stringWithFormat:@"%@%@",[member[@"firstName"] substringToIndex:1],[member[@"lastName"] substringToIndex:1]];
        initialsLabel.font = [TTFont tripTrunkFont28];
        initialsLabel.numberOfLines = 1;
        initialsLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
        initialsLabel.adjustsFontSizeToFitWidth = YES;
        //            initialsLabel.adjustsLetterSpacingToFitWidth = YES;
        initialsLabel.minimumScaleFactor = 10.0f/12.0f;
        initialsLabel.clipsToBounds = YES;
        initialsLabel.backgroundColor = [UIColor clearColor];
        initialsLabel.textColor = [UIColor darkGrayColor];
        initialsLabel.textAlignment = NSTextAlignmentCenter;
        [imageView addSubview:initialsLabel];
    }
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [cell addSubview:imageView];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.membersToAdd.count;
}



@end
