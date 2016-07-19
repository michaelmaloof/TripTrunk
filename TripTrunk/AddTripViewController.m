//
//  AddTripViewController.m
//  TripTrunk
//
//  Created by Michael Maloof on 4/18/15.
//  Copyright (c) 2015 Michael Maloof. All rights reserved.
//

#import "AddTripViewController.h"
#import "AddTripPhotosViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AddTripFriendsViewController.h"
#import "MSTextField.h"
#import "SocialUtility.h"
#import "TTUtility.h"
#import "CitySearchViewController.h"
#import "HomeMapViewController.h"
#import "TrunkListViewController.h"
#import "ActivityListViewController.h"
#import "UserProfileViewController.h"

@interface AddTripViewController () <UIAlertViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, CitySearchViewControllerDelegate, UITextViewDelegate>

// Text Views
@property (weak, nonatomic) IBOutlet UITextView *tripNameTextView;
@property (weak, nonatomic) IBOutlet UITextView *startTripTextView;
@property (weak, nonatomic) IBOutlet UITextView *endTripTextView;
@property (weak, nonatomic) IBOutlet UITextView *locationTextView;
// Date Pickers
@property (strong, nonatomic) UIDatePicker *datePicker;
//Buttons
@property (weak, nonatomic) IBOutlet UIButton *delete; //delete the trunk
@property (weak, nonatomic) IBOutlet UIButton *public; //make trunk public
@property (weak, nonatomic) IBOutlet UIButton *private; // make trunk private
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBar;
@property (weak, nonatomic) IBOutlet UIButton *descriptionButton; //No Longer Implemented but will make a return
// Date Properties
@property NSDateFormatter *formatter;
// Trunk
@property BOOL needsCityUpdate; // if the trunk already exists and we changed the city of the trip
@property BOOL needsNameUpdate; // if the trunk already exists and we changed the name of the trip
@property BOOL isEditing; // if the trunk already exists and we're editing it
@property (strong, nonatomic) NSString *city; //the city the trunk occured in
@property (strong, nonatomic) NSString *state; //the state/region the trunk occured in
@property (strong, nonatomic) NSString *country; //the country the trunk occured in
@property BOOL isPrivate;
// Location Manager
@property (strong, nonatomic) CLLocationManager *locationManager;
// Labels
@property (weak, nonatomic) IBOutlet UILabel *publicTrunkLabel; //@"Public"
@property (weak, nonatomic) IBOutlet UILabel *publicTrunkDescription;
@property (weak, nonatomic) IBOutlet UILabel *privateTrunkLabel; //@"Private"
@property (weak, nonatomic) IBOutlet UILabel *privateTrunkDescription;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *trunkNameHeightConstraint;

@end

@implementation AddTripViewController

- (void)viewDidLoad {
    //FIXME sometimes segue takes too long to occur or doesnt happen at all. maybe shouldnt check here?
    [super viewDidLoad];
    [self setUpDatesAndTextViews];
    [self setUpCurrentUsersLocation];
    [self determineEditingVsCreationMode];
    [self setupDatePicker];
    [self checkPublicPrivate];
    [self addGestures];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
}

-(void)viewDidLayoutSubviews{
    NSString *trunkName = NSLocalizedString(@"Trunk Name", @"Trunk Name");
    if(![self.tripNameTextView.text isEqualToString:trunkName])
        [self updateTextViewSize:self.tripNameTextView];
}

#pragma mark - Initial Setup


/**
 *  Determine if this is the user editing an exisiting trunk or creating a new one
 *
 *
 */
-(void)determineEditingVsCreationMode{
    //if self.trip is not nil then it means the user is editing a trunk and not creating a new one.
    if (self.trip) {
        [self setUpTrunkEditing];
    }
    //if self.trip is  nil then it means the user is creating a new trunk and not simply editing one
    else {
        [self setUpTrunkCreation];
        [self setTrunkNameEmptyState];
    }
}

/**
 *  Sets up the ability for the user to edit an exisiting trunk
 *
 *
 */
-(void)setUpTrunkEditing{
    _isEditing = YES;
    self.title  = NSLocalizedString(@"Trunk Details",@"Trunk Details");
    //if they're editing the trunk we fill in the text fields with the correct info
    self.tripNameTextView.font = [TTFont tripTrunkFontHuge];
    self.tripNameTextView.text = self.trip.name;
    self.tripNameTextView.textAlignment = NSTextAlignmentCenter;
    self.locationTextView.text = [NSString stringWithFormat:@"%@, %@, %@", self.trip.city, self.trip.state, self.trip.country];
    self.startTripTextView.text = self.trip.startDate;
    self.startTripTextView.textAlignment = NSTextAlignmentCenter;
    self.endTripTextView.text = self.trip.endDate;
    self.endTripTextView.textAlignment = NSTextAlignmentCenter;
    self.city = self.trip.city;
    self.state = self.trip.state;
    self.country = self.trip.country;
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Update",@"Update");
    self.navigationItem.rightBarButtonItem.tag = 1;
    self.navigationItem.leftBarButtonItem.tag = 1;
    self.delete.hidden = NO;
    //currently we don't want users being able to change a trunk tp public or private once the trunk has been created
    self.public.hidden = YES;
    self.private.hidden = YES;
    self.publicTrunkLabel.hidden = YES;
    self.publicTrunkDescription.hidden = YES;
    self.privateTrunkLabel.hidden = YES;
    self.privateTrunkDescription.hidden = YES;
    self.cancelBar.title = NSLocalizedString(@"Cancel",@"Cancel");
    self.cancelBar.enabled = YES;
}

-(void)addGestures{
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setPublic)];
    [recognizer setNumberOfTapsRequired:1];
    self.publicTrunkDescription.userInteractionEnabled = YES;
    [self.publicTrunkDescription addGestureRecognizer:recognizer];
    
    UITapGestureRecognizer *recognizerTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setPublic)];
    [recognizer setNumberOfTapsRequired:1];
    self.publicTrunkLabel.userInteractionEnabled = YES;
    [self.publicTrunkLabel addGestureRecognizer:recognizerTwo];
    
    UITapGestureRecognizer *recognizerThree = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setPrivate)];
    [recognizer setNumberOfTapsRequired:1];
    self.privateTrunkLabel.userInteractionEnabled = YES;
    [self.privateTrunkLabel addGestureRecognizer:recognizerThree];
    
    UITapGestureRecognizer *recognizerFour = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(setPrivate)];
    [recognizer setNumberOfTapsRequired:1];
    self.privateTrunkDescription.userInteractionEnabled = YES;
    [self.privateTrunkDescription addGestureRecognizer:recognizerFour];

}

-(void)setTrunkNameEmptyState{
    NSString *trunkName = NSLocalizedString(@"Trunk Name", @"Trunk Name");
    self.tripNameTextView.font = [TTFont tripTrunkFont14];
    self.tripNameTextView.text = [NSString stringWithFormat:@"%@",trunkName];
    self.tripNameTextView.textAlignment = NSTextAlignmentCenter;
    self.trunkNameHeightConstraint.constant = 30;
}

/**
 *  Sets up the ability for the user to createa a new trunk
 *
 *
 */
-(void)setUpTrunkCreation{
    _isEditing = NO;
    self.title  = NSLocalizedString(@"Add New Trunk", @"Add New Trunk");
    [self tabBarTitle];
    [self setOriginalDateTextViews];
    self.trip = [[Trip alloc] init];
    self.cancelBar.title = @"";
    self.cancelBar.enabled = FALSE;
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Next", @"Next");
    self.navigationItem.rightBarButtonItem.tag = 0;
    self.navigationItem.leftBarButtonItem.tag = 0;
    self.delete.hidden = YES;
}

/**
 *  Sets up the date textViews to original states (Select Start Date & Select End Date)
 *
 *
 */
-(void)setOriginalDateTextViews{
    //FIXME How do I format this without weird spaces
    [self.startTripTextView setTextAlignment:NSTextAlignmentRight];
    [self.endTripTextView setTextAlignment:NSTextAlignmentLeft];
    self.startTripTextView.text = @"Select \nStart Date";
    self.endTripTextView.text = @"Select \nEnd Date";
    [self.startTripTextView setFont:[TTFont tripTrunkFont14]];
    [self.endTripTextView setFont:[TTFont tripTrunkFont14]];
}

/**
 *  Sets up the user's current location
 *
 *
 */
-(void)setUpCurrentUsersLocation{
    //FIXME This may not be necessary anymore since we no longer need the users location
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
    self.locationManager.delegate = self;
}

/**
 *  Sets up the date pickers design for selecting the start and end dates of the trunks
 *
 *
 */
- (void)setupDatePicker {
    self.datePicker = [[UIDatePicker alloc] init];
    [self.datePicker setValue:[TTColor tripTrunkRed] forKey:@"textColor"];
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    [self.datePicker addTarget:self
                        action:@selector(dateChanged:)
              forControlEvents:UIControlEventValueChanged];
    // Generic Flexible Space
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    // Start Date Toolbar
    UIToolbar *startTripToolbar= [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.datePicker.frame.size.width, 40)];
    UIBarButtonItem *barButtonNext = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done")
                                                                      style:UIBarButtonItemStyleDone target:self action:@selector(dismissPickerView:)];
    self.datePicker.backgroundColor = [TTColor tripTrunkWhite];
    //Set Title of Start Date Picker
    UILabel *startLabel = [[UILabel alloc] init];
    [startLabel setText:NSLocalizedString(@"Start Date",@"Start Date")];
    [startLabel setFont:[TTFont tripTrunkFont16]];
    [startLabel setTextColor:[TTColor tripTrunkBlue]];
    [startLabel sizeToFit];
    UIBarButtonItem *labelbutton = [[UIBarButtonItem alloc] initWithCustomView:startLabel];
    startTripToolbar.items = [[NSArray alloc] initWithObjects:labelbutton, space, barButtonNext,nil];
    barButtonNext.tintColor=[TTColor tripTrunkBlue];;
    self.startTripTextView.inputView = self.datePicker; // set the textfield to use the picker instead of a keyboard
    self.startTripTextView.inputAccessoryView = startTripToolbar;

    // End Date Toolbar
    UIToolbar *endTripToolbar= [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.datePicker.frame.size.width, 40)];
    UIBarButtonItem *barButtonDone = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done")
                                                                      style:UIBarButtonItemStyleDone target:self action:@selector(dismissPickerView:)];
    //Set Title of End Date Picker
    UILabel *endLabel = [[UILabel alloc] init];
    [endLabel setText:NSLocalizedString(@"End Date", @"End Date")];
    [endLabel setFont:[TTFont tripTrunkFont16]];
    [endLabel setTextColor:[TTColor tripTrunkBlue]];
    [endLabel sizeToFit];
    UIBarButtonItem *endLabelButton = [[UIBarButtonItem alloc] initWithCustomView:endLabel];
    endTripToolbar.items = [[NSArray alloc] initWithObjects:endLabelButton, space, barButtonDone, nil];
    barButtonDone.tintColor= [TTColor tripTrunkBlue];
    self.endTripTextView.inputView = self.datePicker;
    self.endTripTextView.inputAccessoryView = endTripToolbar;
}

/**
 *  Update the screen based on if the trunk is private or public on viewDidLoad
 *
 *
 */
-(void)checkPublicPrivate{
    if (self.trip.isPrivate == NO || self.trip == nil)
    {
        [self makeTrunkPublic];
    }
    else {
        [self makeTrunkPrivate];
    }
}

/**
 *  Setup ability to select dates and type in the textviews
 *
 *
 */
-(void)setUpDatesAndTextViews{
    self.startTripTextView.delegate = self;
    self.endTripTextView.delegate = self;
    self.tripNameTextView.delegate = self;
    self.locationTextView.delegate = self;
    self.formatter = [[NSDateFormatter alloc]init];
    [self.formatter setDateFormat:@"MM/dd/yyyy"];
    self.startTripTextView.tintColor = [UIColor clearColor];
    self.endTripTextView.tintColor = [UIColor clearColor];
}

#pragma mark - Trunk Privacy

/**
 *  Make the Trunk private (only Trunk members can see it)
 *
 *
 */
-(void)makeTrunkPrivate{
    [self.public setImage:[UIImage imageNamed:@"unlockedGray"] forState:UIControlStateNormal];
    [self.private setImage:[UIImage imageNamed:@"lock"] forState:UIControlStateNormal];
    self.public.tag = 0;
    self.private.tag = 1;
    self.privateTrunkLabel.textColor = [TTColor tripTrunkRed];
    self.privateTrunkDescription.textColor = [TTColor tripTrunkRed];
    self.publicTrunkLabel.textColor = [TTColor tripTrunkGray];
    self.publicTrunkDescription.textColor = [TTColor tripTrunkGray];
}

/**
 *  Make the Trunk public (all users can see it)
 *
 *
 */
-(void)makeTrunkPublic{
    [self.public setImage:[UIImage imageNamed:@"unlocked"] forState:UIControlStateNormal];
    [self.private setImage:[UIImage imageNamed:@"lockedGray"] forState:UIControlStateNormal];
    self.public.tag = 1;
    self.private.tag = 0;
    self.publicTrunkLabel.textColor = [TTColor tripTrunkRed];
    self.publicTrunkDescription.textColor = [TTColor tripTrunkRed];
    self.privateTrunkLabel.textColor = [TTColor tripTrunkGray];
    self.privateTrunkDescription.textColor = [TTColor tripTrunkGray];
}

#pragma mark - TextView Delegate Methods

//move the view up and down if the user starts typing to adjust for the keyboard
-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if (textView != self.tripNameTextView){
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y -60, self.view.frame.size.width, self.view.frame.size.height);
    } else {
        NSString *trunkName = NSLocalizedString(@"Trunk Name", @"Trunk Name");
        self.tripNameTextView.font = [TTFont tripTrunkFontHuge];
        NSString *nameCheck = [self.tripNameTextView.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        if ([nameCheck isEqualToString:trunkName]){
            self.tripNameTextView.text = @"";
            self.tripNameTextView.textAlignment = NSTextAlignmentCenter;
        }
    }
}

-(void)textViewDidEndEditing:(UITextView *)textView{
    if (textView != self.tripNameTextView){
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 60, self.view.frame.size.width, self.view.frame.size.height);
    } else {
        NSString *trunkName = NSLocalizedString(@"Trunk Name", @"Trunk Name");
        NSString *space = [self.tripNameTextView.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        if ([space isEqualToString:@""] || [space isEqualToString:trunkName]){
            [self setTrunkNameEmptyState];
        }
    }
}

-(void)textViewDidChange:(UITextView *)textView{
    if ([textView.text length] > 1){
        NSString *code = [textView.text substringFromIndex: [textView.text length] - 2];
        if ([code isEqualToString:@" "]){
            [textView setKeyboardType:UIKeyboardTypeDefault];
        }
    }
    if (textView == self.tripNameTextView){
        [self updateTextViewSize:textView];
    }
}

-(void)updateTextViewSize:(UITextView *)textView{
    id<UITextInputTokenizer> tokenizer = textView.tokenizer;
    UITextPosition *pos = textView.endOfDocument;
    NSInteger lines = 0;
    
    while (true){
        UITextPosition *lineEnd = [tokenizer positionFromPosition:pos toBoundary:UITextGranularityLine inDirection:UITextStorageDirectionBackward];
        
        if([textView comparePosition:pos toPosition:lineEnd] == NSOrderedSame){
            pos = [tokenizer positionFromPosition:lineEnd toBoundary:UITextGranularityCharacter inDirection:UITextStorageDirectionBackward];
            
            if([textView comparePosition:pos toPosition:lineEnd] == NSOrderedSame) break;
            
            continue;
        }
        
        lines++; pos = lineEnd;
    }
    
    if(lines < 4){
        self.trunkNameHeightConstraint.constant = lines*57;
        textView.contentInset = UIEdgeInsetsMake(lines*lines*2.5,0,lines*lines*-2.5,0);
    }else{
        lines--;
        NSString *str = textView.text;
        NSString *truncatedString = [str substringToIndex:[str length]-1];
        textView.text = truncatedString;
    }
    textView.textAlignment = NSTextAlignmentCenter;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if(textView.frame.size.height==171 && [text isEqualToString:@"\n"])
        return NO;
    
    if(textView.frame.size.height>171)
        return NO;
    
    return textView.text.length + (text.length - range.length) <= 33;
}

//we adjusts the designs of the textfield based on which one the user is typing in
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    //if the date is nil it means the users on the current date but never scrolled, so set it for them since by default Apple doesnt
    if (textView == self.endTripTextView) {
        self.datePicker.tag = 1;
        if (self.trip.endDate == nil){
            [self.endTripTextView setTextAlignment:NSTextAlignmentCenter];
            [self.formatter stringFromDate:[NSDate date]];
            NSString *endDate = [self.formatter stringFromDate:self.datePicker.date];
            self.endTripTextView.text = [NSString stringWithFormat:@"\n%@",endDate];
            self.trip.endDate = [self.formatter stringFromDate:[NSDate date]];
            self.endTripTextView.textAlignment = NSTextAlignmentCenter;
        }
        return YES;
    }
    else if (textView == self.startTripTextView){
        self.datePicker.tag = 0;
        if (self.trip.startDate == nil){
            [self.startTripTextView setTextAlignment:NSTextAlignmentCenter];
            [self.formatter stringFromDate:[NSDate date]];
            NSString *startDate = [self.formatter stringFromDate:self.datePicker.date];
            self.startTripTextView.text = [NSString stringWithFormat:@"\n%@",startDate];
            self.trip.startDate = [self.formatter stringFromDate:[NSDate date]];
            self.startTripTextView.textAlignment = NSTextAlignmentCenter;

        }
        return YES;
    }
    else if ([textView isEqual:self.locationTextView]) {
        [textView resignFirstResponder];
        CitySearchViewController *searchView = [[CitySearchViewController alloc] init];
        searchView.delegate = self;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:searchView];
        [self presentViewController:navController animated:YES completion:nil];
        return NO;
    }
    
    else {
        return  YES;
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    UITextView *tv = object;
    //Center vertical alignment
    //CGFloat topCorrect = ([tv bounds].size.height - [tv contentSize].height * [tv zoomScale])/2.0;
    //topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
    //tv.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
    
    //Bottom vertical alignment
    CGFloat topCorrect = ([tv bounds].size.height - [tv contentSize].height);
    topCorrect = (topCorrect <0.0 ? 0.0 : topCorrect);
    tv.contentOffset = (CGPoint){.x = 0, .y = -topCorrect};
}

#pragma mark - CitySearchViewController Delegate

//if they select location we present a view that allows the user to search for locations
- (void)citySearchDidSelectLocation:(NSString *)location {
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    __block BOOL iserror = NO;
    
    [[TTUtility sharedInstance] locationDetailsForLocation:location block:^(NSDictionary *locationDetails, NSError *error) {
        
        if (error){
            self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
            [self tabBarTitle];
            [self notEnoughInfo:NSLocalizedString(@"Something seems to have gone wrong. Please try again later and make sure you're connected to the internet.",@"Something seems to have gone wrong. Please try again later and make sure you're connected to the internet.")];
        }else{
            //Certain locations are messed up with our third party city selector so we manually fix them here
           if ([location isEqualToString:@"Barcelona, CT, Spain"]){
                self.city = @"Barcelona";
                self.state =@"Catalonia";
                self.country = @"Spain";
            } else if ([location isEqualToString:@"Sao Paulo, SP, Brazil"]){
                self.city = @"Sao Paulo";
                self.state =@"Sao Paulo";
                self.country = @"Brazil";
            }else if ([location isEqualToString:@"Taipei, TP, Taiwan"]){
                self.city = @"Taipei";
                self.state =@"Taipei City";
                self.country = @"Taiwan";
            }else if ([location isEqualToString:@"Freeport, FP, The Bahamas"]){
                self.city = @"Freeport";
                self.state =@"Bahamas";
                self.country = @"Bahamas";
//            }else if ([location isEqualToString:@"Manila, MM, Philippines"]){
            }else if ([location containsString:@"Manila, MM, Philippines"]){ //if you do isEqual it wont work
                self.city = @"Manila";
                self.state =@"MM";
                self.country = @"Philippines";
            }else if (locationDetails != nil){
                self.city = locationDetails[@"geobytescity"];
                self.state = locationDetails[@"geobytesregion"];
                self.country = locationDetails[@"geobytescountry"];
            }else {
                iserror = YES;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (iserror == NO){
                    self.locationTextView.text = [NSString stringWithFormat:@"%@, %@, %@", self.city, self.state, self.country];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location Unavailable",@"Location Unavailable")
                                                                    message:NSLocalizedString(@"We apologize. Please try another location.",@"We apologize. Please try another location.")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Okay", @"Okay")
                                                          otherButtonTitles:nil, nil];
                    alert.tag = 69;
                    [alert show];
                }
            });
        }
    }];
    
}

#pragma mark - Keyboard delegate methods

// The following method needed to dismiss the keyboard after input with a click anywhere on the screen outside text boxes
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}


#pragma mark - Date Picker
/**
 *  If the user changed the dates of the trip
 *
 *
 */
- (void)dateChanged:(id)sender {
    
    if (self.datePicker.tag == 0) {
        [self.formatter stringFromDate:self.datePicker.date];
        NSString *startDate = [self.formatter stringFromDate:self.datePicker.date];
        self.startTripTextView.text = [NSString stringWithFormat:@"\n%@",startDate];
        self.trip.startDate = [self.formatter stringFromDate:self.datePicker.date];
        self.startTripTextView.textAlignment = NSTextAlignmentCenter;
    }
    else if (self.datePicker.tag == 1) {
        [self.formatter stringFromDate:self.datePicker.date];
        NSString *endDate = [self.formatter stringFromDate:self.datePicker.date];
        self.endTripTextView.text = [NSString stringWithFormat:@"\n%@",endDate];
        self.trip.endDate = [self.formatter stringFromDate:self.datePicker.date];
        self.endTripTextView.textAlignment = NSTextAlignmentCenter;
    }
}

-(void)dismissPickerView:(id)sender
{
    if (self.datePicker.tag == 0) {
        [self.endTripTextView becomeFirstResponder];
    }
    else {
        [self.view endEditing:YES];
    }
}

#pragma mark - Button Actions

- (IBAction)onCancelTapped:(id)sender {
    if (self.navigationItem.leftBarButtonItem.tag == 0)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)onNextTapped:(id)sender
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSString *city = NSLocalizedString(@"City", @"City");
    NSString *trunkName = NSLocalizedString(@"Trunk Name", @"Trunk Name");
    NSString *nameCheck = [self.tripNameTextView.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    if ([self.tripNameTextView.text isEqualToString:@""] || [nameCheck containsString:trunkName]){
        [self notEnoughInfo:NSLocalizedString(@"Please name your trunk.",@"Please name your trunk.")];
        self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else if ([self.locationTextView.text isEqualToString:@""] || [self.locationTextView.text isEqualToString:city]){
        [self notEnoughInfo:NSLocalizedString(@"Please give your trunk a location.",@"Please give your trunk a location.")];
        self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else if ([self.trip.startDate isEqualToString:@""] || [self.trip.endDate isEqualToString:@""] || self.trip.startDate == nil || self.trip.endDate == nil){
        [self notEnoughInfo:NSLocalizedString(@"Please give your trunk a start and end date.",@"Please give your trunk a start and end date.")];
        self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }else {
        //FIXME dont do this every time they click next. only if they changed location text fields
        self.title = NSLocalizedString(@"Verifying Location...",@"Verifying Location...");
        //take the location the user typed in, make sure its a real location and meets the correct requirements
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        NSString *address = self.locationTextView.text;
        //hack because MM isnt a valid address for apple.
        if ([address isEqualToString:@"Manila, MM, Philippines"]){
            address = @"Manila, Philippines";
        }

        [geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error)
         {
             if (placemarks == nil && error)
             {
                 NSLog(@"Error geocoding address: %@ withError: %@",address, error);
                 // TODO: Set title image
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                 [self tabBarTitle];
                 [self notEnoughInfo:NSLocalizedString(@"Something seems to have gone wrong. Please try again later.",@"Something seems to have gone wrong. Please try again later.")];
                 self.navigationItem.rightBarButtonItem.enabled = YES;
             } else if (placemarks == nil && !error) {
                 NSLog(@"Error geocoding address: %@ withError: %@",address, error);
                 // TODO: Set title image
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                 [self tabBarTitle];
                 [self notEnoughInfo:NSLocalizedString(@"Something is currently wrong with this location. Please try a different location.",@"Something is currently wrong with this location. Please try a different location.")];
                 self.navigationItem.rightBarButtonItem.enabled = YES;
             } else if (placemarks.count == 0){
                 NSLog(@"Error geocoding address: %@ withError: %@",address, error);
                 // TODO: Set title image
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                 [self tabBarTitle];
                 [self notEnoughInfo:NSLocalizedString(@"Something is currently wrong with this location. Please try a different location.",@"Something is currently wrong with this location. Please try a different location.")];
                 self.navigationItem.rightBarButtonItem.enabled = YES;
             }
             
             else if (!error)
             {
                 //make sure the user filled in all the correct text fields
                 if (![self.tripNameTextView.text isEqualToString:@""] && ![self.locationTextView.text isEqualToString:@""] && ![self.startTripTextView.text isEqualToString:@""] && ![self.endTripTextView.text isEqualToString:@""])
                 {
                     // Trip Input has correct data - save the trip!
                     
                     CLPlacemark *placemark = placemarks.firstObject;
                     
                     if ([self.locationTextView.text isEqualToString:@"Rincon, Puerto Rico, Puerto Rico"]){
                         self.trip.lat = 18.338371;
                         self.trip.longitude = -67.251679;
                         self.trip.state = @"Puerto Rico";
                         self.trip.city = @"Rincon";
                         self.trip.country = @"Puerto Rico";
                     } else {
                         
                         self.trip.lat = placemark.location.coordinate.latitude;
                         self.trip.longitude = placemark.location.coordinate.longitude;
                         self.trip.country = placemark.country;
          
                    
                         if (placemark.locality == nil){
                             [self setTripCityName:placemark.administrativeArea];
                             self.trip.state = placemark.administrativeArea;
                         } else{
                             [self setTripCityName:placemark.locality];
                             self.trip.state = placemark.administrativeArea;
                             
                         }
                         
                     }
                     [self parseTrip];
                     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                 }
                 
                 else
                 {
                     [self notEnoughInfo:NSLocalizedString(@"Please fill out all boxes",@"Please fill out all boxes")];
                     self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                     [self tabBarTitle];
                     self.navigationItem.rightBarButtonItem.enabled = YES;
                 }
             }
             self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
             [self tabBarTitle];
             return;
         }];
    }
}

- (IBAction)onDeleteWasTapped:(id)sender {
    
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = NSLocalizedString(@"Are you sure you want to delete this Trunk?",@"Are you sure you want to delete this Trunk?");
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:NSLocalizedString(@"No",@"No")];
    [alertView addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete")];
    alertView.tag = 0;
    [alertView show];
    [self tabBarTitle];
    
}

- (IBAction)publicTapped:(id)sender {
    [self setPublic];
}


- (IBAction)privateTapped:(id)sender {
    [self setPrivate];
}

-(void)setPrivate{
    if (self.private.tag == 0)
    {
        [self makeTrunkPrivate];
        self.isPrivate = YES;
    }
}

-(void)setPublic{
    if (self.public.tag == 0)
    {
        self.isPrivate = NO;
        [self makeTrunkPublic];
    }
}

/**
 * Clears textfields
 *
 *
 */
- (void)resetForm {
    // Initialize the view with no data
    [self setTrunkNameEmptyState];
    [self setOriginalDateTextViews];
    self.locationTextView.text = @"City";
    if (!_isEditing) {
        self.trip = [[Trip alloc] init];
    }
}

#pragma mark - Trunk Info

// Sets the cityname for self.trip, and if it changed then sets the global flag to tell use we changed the cityname
// This is mainly so we know if we need to update the Activity models with a new city or not.
- (BOOL)setTripCityName:(NSString *)cityName
{
    if (![self.trip.city isEqualToString:cityName]) {
        self.trip.city = cityName;
        _needsCityUpdate = YES;
    }
    else{
        return NO;
    }
    return YES;
}

- (BOOL)setTripName:(NSString *)name
{
    if (![self.trip.name isEqualToString:name]) {
        self.trip.name = name;
        _needsNameUpdate = YES;
    }
    else{
        return NO;
    }
    return YES;
}

- (void)notEnoughInfo:(NSString*)message {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    alertView.title = message;
    alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
    [alertView addButtonWithTitle:NSLocalizedString(@"Ok", @"Ok")];
    [alertView show];
    
    [self tabBarTitle];
}

#pragma mark - AlertView

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 0){
        if (buttonIndex == 1){
            //FIXME this needs to return if it was a success or not
            [SocialUtility deleteTrip:self.trip];
            dispatch_async(dispatch_get_main_queue(), ^{

            NSMutableArray *locationArray = [[NSMutableArray alloc]init];
            for (UINavigationController *controller in self.tabBarController.viewControllers){
                for (UIViewController *view in controller.viewControllers){
                    if ([view isKindOfClass:[HomeMapViewController class]]){
                        [locationArray addObject:view];
                        CLLocation *location = [[CLLocation alloc]initWithLatitude:self.trip.lat longitude:self.trip.longitude];
                        [(HomeMapViewController*)view dontRefreshMap];
                        [(HomeMapViewController*)view checkToDeleteCity:location trip:self.trip];
                    } else if ([view isKindOfClass:[ActivityListViewController class]]){
                        [(ActivityListViewController*)view trunkWasDeleted:self.trip];
                    } else if ([view isKindOfClass:[UserProfileViewController class]]){
                        [(UserProfileViewController*)view trunkWasDeletedFromAddTripViewController:self.trip];
                    }
                }
            }
            });

            NSMutableArray *locationArray2 = [[NSMutableArray alloc]init];
            for (UIViewController *vc in self.navigationController.viewControllers){
                if ([vc isKindOfClass:[HomeMapViewController class]]){
                    [locationArray2 addObject:vc];
                }
            }
            if (locationArray2.count > 0){
                [self.navigationController popToViewController:[locationArray2 lastObject] animated:YES];
            }
                //TODO: needs to be the whole tab bar not just the nav controller
                NSMutableArray *listArray = [[NSMutableArray alloc]init];
                for (UIViewController *vc in self.navigationController.viewControllers){
                    if ([vc isKindOfClass:[TrunkListViewController class]]){
                        [(TrunkListViewController*)vc deleteItemOnTrunkList:self.trip];
                        [listArray addObject:vc];
                        //TODO Delete not working on list
                    }
                }
            if (listArray.count > 0){
                [self.navigationController popToViewController:[listArray lastObject] animated:YES];
            } else {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            }
    }
}

#pragma mark - Parse
/**
 *  Save the trip to Parse
 *
 *
 */
-(void)parseTrip {
    //FIXME Should only parse if things have been changed
    [self setTripName: self.tripNameTextView.text];
    self.trip.user = [PFUser currentUser].username;
    //FIXME Why do we have a NSDATE start on trip but not end?
    self.trip.start = [self.formatter dateFromString:self.trip.startDate];
    self.trip.creator = [PFUser currentUser];
    // Ensure start date is after end date
    NSTimeInterval startTimeInterval = [[self.formatter dateFromString:self.trip.startDate] timeIntervalSince1970];
    NSTimeInterval endTimeInterval = [[self.formatter dateFromString:self.trip.endDate] timeIntervalSince1970];
    if(startTimeInterval > endTimeInterval){
        [self notEnoughInfo:NSLocalizedString(@"Your start date must happen on or before the end date",@"Your start date must happen on or before the end date")];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        self.navigationItem.rightBarButtonItem.enabled = YES;
        return;
    }
//if the most recent photo is nil then we set the date to a long time ago. This way we know the dot on the trunk is blue. I didnt want to leave a nil value in parse.
    if (self.trip.publicTripDetail.mostRecentPhoto == nil){
        NSString *date = @"01/01/1200";
        NSDateFormatter *format = [[NSDateFormatter alloc]init];
        [format setDateFormat:@"yyyy-MM-dd"];
        self.trip.publicTripDetail.mostRecentPhoto = [format dateFromString:date];
    }
    // If we're editing an existing trip AND we changed the city, we need to update any Activities for this trip to include the new city name.
    if (_isEditing && _needsCityUpdate) {
        [SocialUtility updateActivityContent:self.trip.city forTrip:self.trip];
    }
    // If we're editing an existing trip AND we changed the name, we need to update any Photos for this trip to include the new name.
    if (_isEditing && (_needsNameUpdate || _needsCityUpdate)) {
        [SocialUtility updatePhotosForTrip:self.trip];
    }
    PFACL *tripACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [[PFUser currentUser] fetch]; // Fetch the currentu
    //    // If the user is Private then it's not a Publicly Readable Trip. Only people in their FriendsOf role can see it.
    if (self.trip.isPrivate != 1){
        self.trip.isPrivate = self.isPrivate;
    }
    if (self.trip.isPrivate == NO) {
        [tripACL setPublicReadAccess:YES];
    }
    // Private Trip, set the ACL permissions so only the creator has access - and when members are invited then they'll get READ access as well.
    // TODO: only update ACL if private status changed during editing.
    if (self.trip.isPrivate == YES) {
        [tripACL setPublicReadAccess:NO];
        [tripACL setReadAccess:YES forUser:self.trip.creator];
        [tripACL setWriteAccess:YES forUser:self.trip.creator];
        // If this is editing a trip, we need to all existing members to the Read ACL.
        if (_isEditing) {
            // TODO: Add all Trunk Members to READ ACL.
        }
    }
    else {
        // Only add the friendsOf_ role to the ACL if the trunk is NOT private! A private trunk shouldn't be visible to followers. just trunk members
        // This fixes the shitty bug that was live at launch.
        NSString *roleName = [NSString stringWithFormat:@"friendsOf_%@", [[PFUser currentUser] objectId]];
        [tripACL setReadAccess:YES forRoleWithName:roleName];
    }
    
    self.trip.ACL = tripACL;
    

    if(!self.trip.publicTripDetail){
        self.trip.publicTripDetail = [[PublicTripDetail alloc]init];
    }

    
    [self.trip saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         
         if(error) {
             [ParseErrorHandlingController handleError:error];
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",@"Error")
                                                                 message:NSLocalizedString(@"Please Try Again",@"Please Try Again")
                                                                delegate:self
                                                       cancelButtonTitle:NSLocalizedString(@"Okay",@"Okay")
                                                       otherButtonTitles:nil, nil];
             alertView.backgroundColor = [UIColor colorWithRed:131.0/255.0 green:226.0/255.0 blue:255.0/255.0 alpha:1.0];
             [alertView show];
             
             
         }
         else
         {
             [[TTUtility sharedInstance] internetConnectionFound];
             if (self.navigationItem.leftBarButtonItem.tag == 0)
             {
                 [self performSegueWithIdentifier:@"addFriends" sender:self];
                 self.navigationItem.rightBarButtonItem.enabled = YES;
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");

             }
             
             else {
                 [self.navigationController popViewControllerAnimated:YES];
                 self.title  = NSLocalizedString(@"Add New Trunk",@"Add New Trunk");
                 self.navigationItem.rightBarButtonItem.enabled = YES;

             }
         }
         // TODO: Set title image
         [self tabBarTitle];
         
     }];
    
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    AddTripFriendsViewController *vc = segue.destinationViewController;
    vc.trip = self.trip;
    vc.isTripCreation = YES;
    
    // Set up an observer that will be used to reset the form after trip completion
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetForm)
                                                 name:@"resetTripFromNotification"
                                               object:nil];

}

#pragma mark - Dealloc

- (void)dealloc {
    
    // Remove any observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
