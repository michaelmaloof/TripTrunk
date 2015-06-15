//
//  TrunkMembersViewController.m
//  TripTrunk
//
//  Created by Matt Schoch on 5/31/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "TrunkMembersViewController.h"
#import "UIImageView+AFNetworking.h"

#import "AddTripFriendsViewController.h"
#import "SocialUtility.h"
#import "UserTableViewCell.h"
#import "UserProfileViewController.h"

#define USER_CELL @"user_table_view_cell"

@interface TrunkMembersViewController () <UserTableViewCellDelegate>

@property (strong, nonatomic) NSMutableArray *tripMembers;
@property (nonatomic) BOOL isFollowing;
@property (strong, nonatomic) PFUser *tripCreator;
@property (strong, nonatomic) Trip *trip;

@end

@implementation TrunkMembersViewController

- (id)initWithTrip:(Trip *)trip
{
    self = [super init]; // nil is ok if the nib is included in the main bundle
    if (self) {
        _trip = trip;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Trip Members";
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Members"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(addMembers)];
    
    
    // initialize array for table view data source
    _tripMembers = [[NSMutableArray alloc] init];
    

    
}
- (void)viewDidAppear:(BOOL)animated
{
    // Get the users for the list
    [self loadUsers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Loads all users who are part of this trunk. First, it queries the Activity model to get members in this trunk, then it queries the Trip model to get the trip creator
 */
- (void)loadUsers
{
    
    // Query all user's that are in this trip
    PFQuery *memberQuery = [PFQuery queryWithClassName:@"Activity"];
    [memberQuery whereKey:@"trip" equalTo:_trip];
    [memberQuery whereKey:@"type" equalTo:@"addToTrip"];
    [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [memberQuery includeKey:@"toUser"];
    
    [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
        }
        else
        {
            NSLog(@"%@", objects);
            
            [_tripMembers removeAllObjects]; // clear the array in case it already has stuff in it
            
            // These are Activity objects, so loop through and just pull out the "toUser" User objects.
            for (PFObject *activity in objects) {
                PFUser *user = activity[@"toUser"];
                [_tripMembers addObject: user];
            }
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
    }];
    
    // Get the Trip Creator
    //TODO: Chnage trip.user to be a pointer, not a username String
    // After trip.user is a pointer, we no longer need a separate query to get the creator, it will be part of the Trip object
    PFQuery *creatorQuery = [PFUser query];
    [creatorQuery whereKey:@"username" equalTo:_trip.user];
    [creatorQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
        }
        else
        {
            NSLog(@"%@", object);
            
            _tripCreator = (PFUser *)object;
            
            // Reload the tableview. probably doesn't need to be on the ui thread, but just to be safe.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
    }];
    
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // The first section is the trip creator
    switch (section) {
        case 0:
            if (_tripCreator) {
                NSLog(@"Number of rows in section 0: 1");

                return 1;
            }
            NSLog(@"Number of rows in section 0: 0");

            return 0; // make sure we have the _tripCreator already otherwise we'll get an error here
            break;
        case 1:
            NSLog(@"Number of rows in section 1: %lu", (unsigned long)_tripMembers.count);
            return _tripMembers.count;
            break;
        default:
            break;
    }
    
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Trip Creator";
            break;
        case 1:
            return @"Trip Members";
        default:
            break;
    }
    return @"Users";
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    

    UserTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:USER_CELL forIndexPath:indexPath];
    [cell setDelegate:self];
    NSURL *picUrl;
    
    // Section 0 is the Trip Creator, so make sure we set the cell differently.
    switch (indexPath.section) {
        case 0: {
            NSLog(@"TripCreator: %@", _tripCreator.username);
            if (indexPath.row >= 0) {
                picUrl = [NSURL URLWithString:_tripCreator[@"profilePicUrl"]];
                [cell setUser:_tripCreator];
            }
            break;
        }
            
        case 1: {
            NSLog(@"tripMembers");
            if (indexPath.row >= 0) {
                PFUser *user = [_tripMembers objectAtIndex:indexPath.row];
                picUrl = [NSURL URLWithString:user[@"profilePicUrl"]];
                [cell setUser:user];
            }
            break;
        }
    }

    //TODO: Get follow status asynchronously and display the correct follow button whenever we get the result back.
    [cell.followButton setHidden:YES]; // Hide the follow button until we get the correct status
    [cell.followButton setSelected:_isFollowing];

    
    // This ensures Async image loading & the weak cell reference makes sure the reused cells show the correct image
    NSURLRequest *request = [NSURLRequest requestWithURL:picUrl];
    __weak UserTableViewCell *weakCell = cell;
    
    [cell.profilePicImageView setImageWithURLRequest:request
                                    placeholderImage:nil
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 
                                                 [weakCell.profilePicImageView setImage:image];
                                                 [weakCell setNeedsLayout];
                                                 
                                             } failure:nil];
    return weakCell;
    
}

#pragma mark - Table view delegate

// On Row Selection, push to the user's profile
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    

    UserProfileViewController *vc;
    
    if (indexPath.section == 0) {
        vc = [[UserProfileViewController alloc] initWithUser:_tripCreator];
    }
    else
    {
        vc = [[UserProfileViewController alloc] initWithUser:[_tripMembers objectAtIndex:indexPath.row]];
        
    }
    
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
    
}

#pragma mark - UserTableViewCellDelegate

- (void)cell:(UserTableViewCell *)cellView didPressFollowButton:(PFUser *)user;
{
    
    if ([cellView.followButton isSelected]) {
        // Unfollow
        NSLog(@"Attempt to unfollow %@",user.username);
        [cellView.followButton setSelected:NO]; // change the button for immediate user feedback
        [SocialUtility unfollowUser:user];
    }
    else {
        // Follow
        NSLog(@"Attempt to follow %@",user.username);
        [cellView.followButton setSelected:YES];
        
        [SocialUtility followUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
            }
            if (!succeeded) {
                NSLog(@"Follow NOT success");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Follow Failed"
                                                                message:@"Please try again"
                                                               delegate:self
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil, nil];
                
                [cellView.followButton setSelected:NO];
                [alert show];
            }
            else
            {
                NSLog(@"Follow Succeeded");
            }
        }];
    }
}

// Pushes to the Add Friends view controller
- (void)addMembers
{
    AddTripFriendsViewController *vc = [[AddTripFriendsViewController alloc] initWithTrip:self.trip];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
