//
//  TutorialViewController.m
//  TripTrunk
//
//  Created by Bradley Walker on 10/23/15.
//  Copyright © 2015 Michael Maloof. All rights reserved.
//

#import "TutorialViewController.h"

@interface TutorialViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextDoneButton;
@property (strong, nonatomic) IBOutlet UIScrollView *masterScrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageIndicator;
@property UIColor *navbarItemTextDefaultColor;
@end

#define screenHeight [[UIScreen mainScreen] bounds].size.height
#define screenWidth [[UIScreen mainScreen] bounds].size.width
#define visibleScreenHeight [[UIScreen mainScreen] bounds].size.height - 44

@implementation TutorialViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"TutorialViewController" bundle:nil];
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navbarItemTextDefaultColor = [TTColor tripTrunkWhite];
    //Set Master Scroll Size
    [self.masterScrollView setFrame:CGRectMake(0.0,
                                               0.0,
                                               screenWidth,
                                               screenHeight)];
    [self.masterScrollView setContentSize:CGSizeMake(screenWidth * 5,
                                                     screenHeight)];

    //Create Tutorial Pages

    //**Page 1**
    UIImageView *page1Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial1"]];
    [page1Image setContentMode:UIViewContentModeScaleAspectFill];
    [page1Image setFrame:CGRectMake(0, 44.0, screenWidth - 20, visibleScreenHeight)];
    page1Image.layer.zPosition = 2;
    [self.masterScrollView addSubview:page1Image];

    //**Page 2**
    UIImageView *page2Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial2"]];
    [page2Image setContentMode:UIViewContentModeScaleAspectFill];
    [page2Image setFrame:CGRectMake(screenWidth + 10 , 44.0, screenWidth - 10, visibleScreenHeight)];
    [self.masterScrollView addSubview:page2Image];
    page2Image.layer.zPosition = 0;


    //**Page 3**
    UIImageView *page3Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial3"]];
    [page3Image setContentMode:UIViewContentModeScaleAspectFill];
    [page3Image setFrame:CGRectMake((screenWidth + 5) * 2, 44.0, screenWidth, visibleScreenHeight)];
    page3Image.layer.zPosition = 1;

    [self.masterScrollView addSubview:page3Image];

    //**Page 4**
    UIImageView *page4Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial4"]];
    [page4Image setContentMode:UIViewContentModeScaleAspectFill];
    [page4Image setFrame:CGRectMake((screenWidth* 3) + 6, 44.0, screenWidth, visibleScreenHeight)];
    page4Image.layer.zPosition = 2;

    [self.masterScrollView addSubview:page4Image];
    
    //**Page 5**
    UIImageView *page5Image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tutorial5"]];
    [page5Image setContentMode:UIViewContentModeScaleAspectFill];
    [page5Image setFrame:CGRectMake((screenWidth * 4)+10, 44.0, screenWidth, visibleScreenHeight)];
    [self.masterScrollView addSubview:page5Image];
    page5Image.layer.zPosition = 3;


    [self.masterScrollView setDelegate:self];
    [self.masterScrollView setPagingEnabled:YES];
    [self.masterScrollView setScrollEnabled:YES];
    [self.masterScrollView setUserInteractionEnabled:YES];
    [self.masterScrollView setShowsHorizontalScrollIndicator:NO];
    [self.masterScrollView setShowsVerticalScrollIndicator:NO];

    //Configure page indicator dots
    [self.pageIndicator setNumberOfPages:5];

    //Configure nav bar buttons
    [self.navigationBar setBackgroundColor:[TTColor subPhotoBlue]];
    [self.backButton setTitle:@"Back"];
    [self.backButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.navbarItemTextDefaultColor, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [self.backButton setTintColor:[TTColor tripTrunkClear]];
    [self.backButton setEnabled:NO];
    [self.nextDoneButton setTitle:@"Next"];
    [self.nextDoneButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.navbarItemTextDefaultColor, NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Master Scroll View Delegate Methods
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.pageIndicator setCurrentPage:self.masterScrollView.contentOffset.x / screenWidth];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //Determine whether to hide or show the Back button
    if (self.masterScrollView.contentOffset.x / screenWidth == 0)
    {
        [self.backButton setTintColor:[TTColor tripTrunkClear]];
        [self.backButton setEnabled:NO];
    }
    else if (self.masterScrollView.contentOffset.x / screenWidth > 0)
    {
        [self.backButton setTintColor:nil];
        [self.backButton setEnabled:YES];
    }

    //Determine whether Right nav bar button is titled "Next" or "Done"
    if (self.masterScrollView.contentOffset.x / screenWidth == 4)
    {
        [self.nextDoneButton setStyle:UIBarButtonItemStyleDone];
        [self.nextDoneButton setTitle:@"Done"];
    }
    else
    {
        [self.nextDoneButton setStyle:UIBarButtonItemStylePlain];
        [self.nextDoneButton setTitle:@"Next"];
    }
}

#pragma mark - Navigation Controls
//Navigate to previous tutorial screen
- (IBAction)scrollTutorialPages:(UIBarButtonItem *)tutorialNavButton
{
    if (tutorialNavButton.tag == 1 && self.masterScrollView.contentOffset.x > 0)
    {
        [self.masterScrollView scrollRectToVisible:CGRectMake(screenWidth * ((self.masterScrollView.contentOffset.x / screenWidth) - 1),
                                                              0.0,
                                                              screenWidth,
                                                              screenHeight) animated:YES];
        [self.pageIndicator setCurrentPage:self.pageIndicator.currentPage - 1];
    }
    else if (tutorialNavButton.tag == 2 && self.masterScrollView.contentOffset.x < screenWidth * 4)
    {
        [self.masterScrollView scrollRectToVisible:CGRectMake(screenWidth * (1 + (self.masterScrollView.contentOffset.x / screenWidth)),
                                                              0.0,
                                                              screenWidth,
                                                              screenHeight) animated:YES];
        [self.pageIndicator setCurrentPage:self.pageIndicator.currentPage + 1];
    }
    else if (tutorialNavButton.style == UIBarButtonItemStyleDone)
    {
        //Update User "Tutorial Viewed" Bool to Yes
        [[PFUser currentUser] setValue:@YES forKeyPath:@"tutorialViewed"];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            
            [self.delegate userCompletedTutorial];

            //Dismiss View Controller
            [self dismissViewControllerAnimated:YES
                                     completion:nil];
        }];
    }
}

#pragma mark - Tutorial View Delegate Methods
- (void)userCompletedTutorial
{

}

@end
