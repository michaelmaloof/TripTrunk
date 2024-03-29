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
#import "TTUtility.h"
#import "TTCache.h"

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

    
    self.title = NSLocalizedString(@"Trunk Members",@"Trunk Members");
    
    if ((self.isMember == YES && self.trip.isPrivate == NO) || ([self.trip.creator.objectId isEqualToString:[PFUser currentUser].objectId])) {
//click plus on addmembers instead of this now
//        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add",@"Add")
//                                                                                  style:UIBarButtonItemStylePlain
//                                                                                 target:self
//                                                                                 action:@selector(addMembers)];

    }
    
    
    [self.tableView registerNib:[UINib nibWithNibName:@"UserTableViewCell" bundle:nil] forCellReuseIdentifier:USER_CELL];

    
    // initialize array for table view data source
    _tripMembers = [[NSMutableArray alloc] initWithArray:[[TTCache sharedCache] membersForTrip:self.trip]];
    

    
}
- (void)viewDidAppear:(BOOL)animated
{
    // Get the users for the list
    [self loadUsers];
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
    [memberQuery whereKey:@"toUser" notEqualTo:_trip.creator];
    [memberQuery setCachePolicy:kPFCachePolicyNetworkOnly];
    [memberQuery includeKey:@"toUser"];
    
    
    
    [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            NSLog(@"Error: %@",error);
        }
        else
        {
            [_tripMembers removeAllObjects]; // clear the array in case it already has stuff in it
            
            // These are Activity objects, so loop through and just pull out the "toUser" User objects.
            for (PFObject *activity in objects) {
                PFUser *user = activity[@"toUser"];
                if (![user[@"fbid"]isEqualToString:user[@"username"]]){
                    [_tripMembers addObject: user];
                }
            }
            
            // Cache the members
            [[TTCache sharedCache] setMembers:_tripMembers forTrip:self.trip];
            
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
            NSLog(@"Trunk Creator: %@", object);
            
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

                return 1;
            }

            return 0; // make sure we have the _tripCreator already otherwise we'll get an error here
            break;
        case 1:
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
            return NSLocalizedString(@"Trunk Creator",@"Trunk Creator");
            break;
        case 1:
            return NSLocalizedString(@"Trunk Members",@"Trunk Members");
        default:
            break;
    }
    return NSLocalizedString(@"Users",@"Users");
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
            if (indexPath.row >= 0) {
                picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:_tripCreator[@"profilePicUrl"]]];

                [cell setUser:_tripCreator];
            }
            break;
        }
            
        case 1: {
            if (indexPath.row >= 0) {
                PFUser *user = [_tripMembers objectAtIndex:indexPath.row];
                picUrl = [NSURL URLWithString:[[TTUtility sharedInstance] profileImageUrl:user[@"profilePicUrl"]]];

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
                                    placeholderImage:[UIImage imageNamed:@"defaultProfile"]
                                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                 
                                                 [weakCell.profilePicImageView setImage:image];
                                                 [weakCell setNeedsLayout];
                                                 
                                             } failure:nil];
    
    [weakCell.profilePicImageView.layer setCornerRadius:32.0f];
    [weakCell.profilePicImageView.layer setMasksToBounds:YES];
    [weakCell.profilePicImageView.layer setBorderWidth:10.0f];
    weakCell.profilePicImageView.layer.borderColor = (__bridge CGColorRef _Nullable)([UIColor whiteColor]);
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        // You can't remove the trip creator. If they want to leave, they have to delete the trip
        return NO;
    }
    else
    {
        // User's can delete themselves, and trip creators can delete anyone.
        PFUser *user = [_tripMembers objectAtIndex:indexPath.row];
        if ([user.objectId isEqualToString:[[PFUser currentUser] objectId]]
            || [[PFUser currentUser].objectId isEqualToString:self.tripCreator.objectId]) {
            return YES;
        }
    }
    // Otherwise, no deleting
    return NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PFUser *user = [_tripMembers objectAtIndex:indexPath.row];
        if (indexPath.section > 0) {
            [SocialUtility removeUser:user fromTrip:self.trip block:^(BOOL succeeded, NSError *error) {
                if (error) {
                    NSLog(@"Error removing user: %@", error);
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error") message:NSLocalizedString(@"Couldn't remove user, try again",@"Couldn't remove user, try again")  delegate:self cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay") otherButtonTitles:nil, nil];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alert show];
                        [self loadUsers]; // reload the data so we still show the attempted-to-delete comment
                    });
                }
                else {
                    NSLog(@"User Deleted");
                    [self.delegate memberWasRemoved:user];
                }
            }];
            // Remove from the array and reload the data separately from actually deleting so that we can give a responsive UI to the user.
            [_tripMembers removeObjectAtIndex:indexPath.row];
            [tableView reloadData];
        }
    }
    else {
        NSLog(@"Unhandled Editing Style: %ld", (long)editingStyle);
    }
}


#pragma mark - UserTableViewCellDelegate

- (void)cell:(UserTableViewCell *)cellView didPressFollowButton:(PFUser *)user;
{
    
    if ([cellView.followButton isSelected]) {
        // Unfollow
        [cellView.followButton setSelected:NO]; // change the button for immediate user feedback
        [SocialUtility unfollowUser:user];
    }
    else {
        // Follow
        [cellView.followButton setSelected:YES];
        
        [SocialUtility followUserInBackground:user block:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
            }
            if (!succeeded) {
                NSLog(@"Follow NOT success");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Follow Failed",@"Follow Failed")
                                                                message:NSLocalizedString(@"Please try again",@"Please try again")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
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
    NSMutableArray *members = [[NSMutableArray alloc] initWithArray:self.tripMembers];
    [members addObject:self.tripCreator];
    AddTripFriendsViewController *vc = [[AddTripFriendsViewController alloc] initWithTrip:self.trip andExistingMembers:members];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
