//
//  ActivityListViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 7/27/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "ActivityListViewController.h"
#import "UIImageView+AFNetworking.h"

#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "UserProfileViewController.h"
#import "TTUtility.h"

#define USER_CELL @"user_table_view_cell"

@interface ActivityListViewController ()

@property (strong, nonatomic) NSArray *activities;

@end

@implementation ActivityListViewController

- (id)initWithLikes:(NSArray *)likes;
{
    self = [super init];
    if (self) {
        _activities = [[NSArray alloc] initWithArray:likes];
        self.title = @"Likers";
    }
    return self;
}

- (id)initWithComments:(NSArray *)comments;
{
    self = [super init];
    if (self) {
        _activities = [[NSArray alloc] initWithArray:comments];
    }
    return self;
}

- (id)initWithActivities:(NSArray *)activities;
{
    self = [super init];
    if (self) {
        _activities = [[NSArray alloc] initWithArray:activities];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(closeView)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _activities.count;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
//    [cell setDelegate:self];
    
    // We assume fromUser contains the full PFUser object
    PFUser *user = [[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"];
    NSURL *picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];
    [cell setUser:user];
    
    [cell.followButton setHidden:YES];

    
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    __weak UserTableViewCell *weakCell = cell;
    
    [cell.profilePicImageView setImageWithURLRequest:request
                                    placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 
                                                 [weakCell.profilePicImageView setImage:image];
                                                 [weakCell setNeedsLayout];
                                                 
                                             } failure:nil];
    return weakCell;
    
}

#pragma mark - Table view delegate

// On Row Selection, push to the user's profile
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UserProfileViewController *vc = [[UserProfileViewController alloc] initWithUser:[[_activities objectAtIndex:indexPath.row] valueForKey:@"fromUser"]];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
    
}

#pragma mark - Dismiss View

- (void)closeView
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
