/**************************************************************/
/* ktopits  -                                                 */
/* ApiDetailiewController.m                                   */
/* KT 01-MAY-2014                                             */
/**************************************************************/

#import "ApiDetailViewController.h"
#import "JsonUtils.h"

@interface ApiDetailViewController () {
	id detailItem;
	id responseItem;
	UIBarButtonItem * barButton;

	BOOL detailArrayReady;
	NSMutableArray * detailArray0;
	NSMutableArray * detailArray1;
	NSMutableArray * detailArray2;

	UIAlertView * detailAlertView;
	UIPopoverController *masterPopoverController;
	UINavigationController * mySplitNavController;
}

@end




@implementation ApiDetailViewController

@synthesize detailItem;
@synthesize detailType;
@synthesize responseItem;
@synthesize barButton;

@synthesize detailArrayReady;
@synthesize detailArray0;
@synthesize detailArray1;
@synthesize detailArray2;


@synthesize detailAlertView;
@synthesize masterPopoverController;
@synthesize mySplitNavController;

#define SECTION_META 0
#define SECTION_SET  1
#define SECTION_GET  2
#define SECTION_ALL  3

#define KEY_ID			@"id"
#define KEY_NAME		@"name"
#define KEY_VALUE		@"value"
#define KEY_HREF		@"href"
#define KEY_METADATA    @"__metadata"
#define KEY__DATE       @"__DATE"
#define KEY__BODY       @"__BODY"
#define KEY__SCOPE      @"__SCOPE"


//========================================================================================
#pragma mark - Initialize and one-time LOAD/UNLOAD
//========================================================================================
static NSString * prefix = @"[DETAIL] ";
static 	UIColor * colorP1;
static 	UIColor * colorP2;
static NSDateFormatter *dateFormatter = nil;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Detail", @"Detail");
    }
    return self;
}
- (void)viewDidLoad
{
    NSLog(@"%@*viewDidLoad",prefix);
    [super viewDidLoad];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;		//ios 6 and 7
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;	//ios 7 only

	[[ApiMachine shared] setDelegate2:self];
	colorP1 = [[UIColor colorWithRed:(240/255.0) green:(240/255.0) blue:(240/255.0) alpha:100] retain];
	colorP2 = [[UIColor colorWithRed:(251/255.0) green:(251/255.0) blue:(251/255.0) alpha:100] retain];
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (void)dealloc
{
    [self.detailItem release];
    [self.masterPopoverController release];
    [super dealloc];
}


//Set the HREF URL
- (void)setDetailItem:(id)newDetailItem
{
	NSString * type = nil;
	id newItem = newDetailItem;
	if (newDetailItem == nil)
		type = @"nil";
	else if ([newDetailItem isKindOfClass:[NSDictionary class]])
		type = @"Dictionary";
	else if ([newDetailItem isKindOfClass:[NSArray class]])
		type = @"Array";
	else if ([newDetailItem isKindOfClass:[NSString class]]) {
		NSRange match = [newDetailItem rangeOfString:@"<html>"];
		if ((match.location!=NSNotFound)||(match.length!=0))
			type = @"HTML";
		else if ([NSURL URLWithString:newDetailItem]!=nil)
			type = @"URL";
		else {
			id objects = [jsonUtils decode:newDetailItem];
			if ([objects isKindOfClass:[NSDictionary class]]) {
				type = @"Dictionary2";
				newItem = objects;
			}
			else if ([objects isKindOfClass:[NSArray class]]) {
				type = @"Array2";
				newItem = objects;
			}
			else {
				type = @"Text";
			}
		}
	}
	self.detailType = type;

    NSLog(@"%@=>setDetailItem = %@ (%p)",prefix,(type==nil)?@"?Unknown?":type,newItem);
//    if (self.detailItem != newItem) {
		detailItem = newItem;		//Do NOT USE self. else recurse!
		if (type!=nil)
      		[self configureView];	//Update for new View
//    }
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}



//========================================================================================
#pragma mark - View Appear
//========================================================================================

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"%@*viewWillAppear = \"%@\"",prefix,self.title);
    [super viewWillAppear:animated];
//    [self configureView];
#if 0
	UIImageView *whiteoutView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ApiDetailBackground.png"]];
	whiteoutView.alpha = 0.75f;
	self.tableView.backgroundView = whiteoutView;
	[whiteoutView release];
#endif
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%@*viewDidAppear",prefix);
}
- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"%@*viewWillDisappear",prefix);
    [super viewWillDisappear:animated];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"%@*viewDidDisappear",prefix);
}

//>>>>IPHONE ONLY USES MASTER!  IPAD ONLY USES DETAIL.

- (BOOL)shouldAutorotate {
    return YES;
}
-(NSUInteger)supportedInterfaceOrientations {
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft |
            UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskPortraitUpsideDown);
}
- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	BOOL xfull=((toInterfaceOrientation==UIInterfaceOrientationPortrait)||(toInterfaceOrientation==UIInterfaceOrientationPortraitUpsideDown))?NO:YES;
	NSLog(@"%@ WillRotateTo: X%@(%li)",prefix,xfull?@"=":@"||",(long)toInterfaceOrientation);
	[[ApiMachine shared] willRefreshWebView];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	BOOL xfull=((fromInterfaceOrientation==UIInterfaceOrientationPortrait)||(fromInterfaceOrientation==UIInterfaceOrientationPortraitUpsideDown))?NO:YES;
	NSLog(@"%@ DidRotateFrom: X%@(%li)",prefix,xfull?@"=":@"||",(long)fromInterfaceOrientation);
	[[ApiMachine shared] didRefreshWebView];
}



//========================================================================================
#pragma mark - Initialize and one-time LOAD/UNLOAD
//========================================================================================

//-------------
// Configure for requested DICTIONARY ID ITEM (user, site, device)
//-------------
- (void)configureView {
	self.detailArrayReady = NO;
	if (self.detailArray0== nil)
        self.detailArray0 = [[NSMutableArray alloc] init];
	[self.detailArray0 removeAllObjects];
	if (self.detailArray1== nil)
        self.detailArray1 = [[NSMutableArray alloc] init];
	[self.detailArray1 removeAllObjects];
	if (self.detailArray2== nil)
        self.detailArray2 = [[NSMutableArray alloc] init];
	[self.detailArray2 removeAllObjects];
	
	[self.tableView reloadData];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForGateway) object:nil];

	if ([self.detailType isEqualToString:@"URL"]) {
		[self performSelector:@selector(waitForGateway) withObject:nil afterDelay:0.5];
	}
	else if ([self.detailItem isKindOfClass:[NSDictionary class]]) {
		self.responseItem = self.detailItem;
		self.detailArrayReady = YES;
		[self performSelector:@selector(buildDetailArray) withObject:nil afterDelay:0.0];
	}
	else {
		self.detailArrayReady = YES;
	}
}

//-------------
// DO a GET on the requested REST command ITEM 
//-------------

- (void)waitForGateway {
	if (self.detailItem==nil)
		return;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForGateway) object:nil];
	[[ApiMachine shared] forceHTTPget:self.detailItem];
	NSLog(@"%@Force===> \"%@\"",prefix,self.detailItem);
    [[ApiMachine shared] startTheMachine:NO];
}

- (void) apigeeGateway:(ApigeeGateway *)apigeeGateway forceID:(id)force  time:(float)timex {
	NSLog(@"%@Force<=== GET \"%@\"",prefix,force);
	self.responseItem = [force objectForKey:@"d"];
	[[ApiMachine shared] forceHTTPget:nil];
	self.detailArrayReady = YES;
	[self performSelector:@selector(buildDetailArray) withObject:nil afterDelay:0.0];
}




-(NSString *)shrinkString:(NSString *)string {
	NSString * foo = nil;
	NSString * output = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	output = [output stringByReplacingOccurrencesOfString:@" = " withString:@"="];
	while (![foo isEqualToString:output]) {
		foo = output;
		output = [output stringByReplacingOccurrencesOfString:@"  " withString:@" "];
	}
	output = [output stringByReplacingOccurrencesOfString:@"{ " withString:@"{"];
	output = [output stringByReplacingOccurrencesOfString:@"} " withString:@"}"];
	output = [output stringByReplacingOccurrencesOfString:@"[ " withString:@"["];
	output = [output stringByReplacingOccurrencesOfString:@"] " withString:@"]"];
	output = [output stringByReplacingOccurrencesOfString:@"( " withString:@"("];
	output = [output stringByReplacingOccurrencesOfString:@") " withString:@")"];
	return output;
}


- (void)buildDetailArray {
	NSArray * allkeys = [self.responseItem allKeys];
	NSInteger insertAt = 0;

	//---------------------------------
	//LOOP for SECTION 0,1 STUFF (Token Fields)
	//---------------------------------
	for (NSString * key in allkeys) {
		//-------------------------
		id value = [self.responseItem objectForKey:key];
		NSString * output = [NSString stringWithFormat:@"%@ = %@",key,(value==nil)?@"":value];
		output = [self shrinkString:output];
		if ([key isEqualToString:KEY_METADATA]) {
			[self.detailArray1 insertObject:output atIndex:insertAt++];
		}
		else if ([key isEqualToString:KEY__DATE]) {
			NSDate * newDate = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
			NSTimeInterval elapsed = [newDate timeIntervalSinceNow] * -1;
			output = [NSString stringWithFormat:@"%@> %@ (%+.0f)",key,(value==nil)?@"":[dateFormatter stringFromDate:newDate],elapsed];
			[self.detailArray0 insertObject:output atIndex:insertAt++];
		}
		else if ([key isEqualToString:KEY__BODY]) {
			NSString * output = [NSString stringWithFormat:@"%@> %@",key,(value==nil)?@"":value];
			[self.detailArray0 insertObject:output atIndex:insertAt];
		}
		else if ([key isEqualToString:KEY__SCOPE]) {
			NSString * output = [NSString stringWithFormat:@"%@> %@",key,(value==nil)?@"":value];
			[self.detailArray0 insertObject:output atIndex:insertAt];
		}
		else if (([value isKindOfClass:[NSDictionary class]]) && ([value objectForKey:@"__deferred"]!=nil)) {
			[self.detailArray1 insertObject:output atIndex:insertAt];
		}
		else if (!self.detailArrayReady) {
			[self.detailArray0 addObject:output];
		}
		else
			[self.detailArray1 addObject:output];
		//-------------------------
	}
	
	//---------------------------------
	//LOOP for SECTION 2 STUFF (all of the SET POINTS)
	//---------------------------------
	for (NSString * key in allkeys) {
//		NSLog(@"%@ KEY=%@",prefix,key);
		//-------------------------
		// limit,total,state,cacheStatus,offset,messages
		//-------------------------
		if ([key isEqualToString:@"DeviceInfo"]) {
			//product = {item=value;...}
			id objects = [self.responseItem objectForKey:key];
			id devinfo = [objects objectForKey:@"Capabilities"];
//			id points = [ApigeeJsonUtils decode:];
			NSEnumerator *enumerator = [devinfo keyEnumerator];
			id keyx;
			while ((keyx = [enumerator nextObject])) {
				NSString * output = [NSString stringWithFormat:@"%@ = %@",keyx,[devinfo valueForKey:keyx]];
				[self.detailArray2 addObject:output];
			}
		}
		else if ([key isEqualToString:@"Capabilities"]) {
			//product = {item=value;...}
			id objects = [self.responseItem objectForKey:key];
			NSEnumerator *enumerator = [objects keyEnumerator];
			id keyx;
			while ((keyx = [enumerator nextObject])) {
				NSString * output = [NSString stringWithFormat:@"%@ = %@",keyx,[objects valueForKey:keyx]];
				[self.detailArray2 addObject:output];
			}
		}
		else if ([key isEqualToString:@"messagesxxx"]) {
			//points = [feed,feed,...]
			id point  = [self.responseItem objectForKey:key];
			NSArray * feeds = [point objectForKey:@"results"];
			for (NSString * feed in feeds) {
				[self.detailArray2 addObject:feed];
			}
		}
		else if ([key isEqualToString:@"messages"]) {
			//results = [dict,dict,...]
			NSArray * messagex  = [self.responseItem objectForKey:key];
			for (NSDictionary * mesg in messagex) {
				NSString * string = [jsonUtils encode:mesg];
				if (string!=nil)
				[self.detailArray2 addObject:[self shrinkString:string]];	//Add NSDictionary of UiserID params
			}
		}
		else if ([key isEqualToString:@"recipients"]) {
			//results = [dict,dict,...]
			NSArray * messagex  = [self.responseItem objectForKey:key];
			for (NSDictionary * mesg in messagex) {
#if 1
				NSString * string = [jsonUtils encode:mesg];
				if (string!=nil)
					[self.detailArray2 addObject:[self shrinkString:string]];	//Add NSDictionary of UiserID params
#else
				NSString * string = [NSString stringWithFormat:@"%@",mesg];
				if (string!=nil) {
					[self.detailArray2 addObject:string];	//Add NSDictionary of UiserID params
				}
#endif
			}
		}
		//-------------------------
	}
	
	[self.tableView reloadData];
}


//========================================================================================
#pragma mark - TableView
//========================================================================================

static  NSInteger cellRowFor4 = 86;//56; //32
static  NSInteger cellRowFor3 = 64;//56; //32
//static  NSInteger cellRowFor2 = 42; //32
//static  NSInteger cellRowFor1 = 28; //32

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if ([ApiMachine shared].webViewRunning)
		return 0;
	self.tableView.sectionHeaderHeight =0;
	self.tableView.sectionFooterHeight = 12;
	if (self.tableView.rowHeight != cellRowFor3)
		self.tableView.rowHeight = cellRowFor3;
	if (self.detailArray0.count==0) {
		if (self.tableView.rowHeight != cellRowFor4)
			self.tableView.rowHeight = cellRowFor4;
	}
//	NSLog(@"%@HELL Section0=%i  Section1=%i  Section2=%i",prefix,self.detailArray0.count,self.detailArray1.count,self.detailArray2.count);
    return SECTION_ALL;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger rows = 0;
	if (self.detailItem==nil) {
	}
	else if (self.detailArrayReady) {
		if (section ==SECTION_META)
			rows = self.detailArray0.count;
		else if (section ==SECTION_SET) {
			if ((self.detailArray0.count==0)&&(self.detailArray1.count==0))
				rows = 1;
			else
				rows = self.detailArray1.count;
		}
		else if (section ==SECTION_GET)
			rows = self.detailArray2.count;
	}
	else {
		if (section ==SECTION_META)
			rows = 1;
	}
//	NSLog(@"%@HELL Section:%i Rows=%i",prefix,section,rows);
	return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	cell.backgroundColor = (indexPath.row&1) ? colorP1 : colorP2;
	cell.accessoryType = UITableViewCellAccessoryNone;

    return (UITableViewCell *)cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//	NSLog(@"%@CELL Section:%i Row:%i",prefix,indexPath.section,indexPath.row);
	cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:13.0];
	cell.textLabel.textColor = [UIColor darkGrayColor];
	cell.textLabel.highlightedTextColor = [UIColor blackColor];
	cell.textLabel.adjustsFontSizeToFitWidth = NO;
	cell.textLabel.numberOfLines = 1;
	if (self.detailArray0.count==0) {
		cell.textLabel.numberOfLines = 4;
		cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
	}
	cell.textLabel.text = @"???";
	
	if (!self.detailArrayReady) {
		//Single Item in META
		if ([self.detailItem isKindOfClass:[NSString class]]) {
    		cell.textLabel.text = self.detailItem;
			cell.textLabel.textColor = [UIColor blueColor];
		}
	}
	else if ((indexPath.section==SECTION_META)&&(self.detailArray0.count==0)&&(self.detailArray1.count==0)) {
		if ([self.detailItem isKindOfClass:[NSString class]]) {
    		cell.textLabel.text = self.detailItem;
		}
	}
	else if ((indexPath.section==SECTION_SET)&&(self.detailArray0.count==0)&&(self.detailArray1.count==0)) {
		if ([self.detailItem isKindOfClass:[NSString class]]) {
    		cell.textLabel.text = self.detailItem;
		}
	}
	else if ((indexPath.section==SECTION_META)&&(self.detailArray0.count>0)) {
		cell.textLabel.numberOfLines = 4;
		cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
		cell.textLabel.adjustsFontSizeToFitWidth = NO;
		cell.textLabel.text = [self.detailArray0 objectAtIndex:indexPath.row];
	}
	else if ((indexPath.section==SECTION_SET)&&(self.detailArray1.count>0)) {
		cell.textLabel.numberOfLines = 4;
		cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
		cell.textLabel.adjustsFontSizeToFitWidth = NO;
		cell.textLabel.text = [self.detailArray1 objectAtIndex:indexPath.row];
		cell.textLabel.textColor = [UIColor blackColor];
	}
	else if ((indexPath.section==SECTION_GET)&&(self.detailArray2.count>0)) {
		cell.textLabel.text = [self.detailArray2 objectAtIndex:indexPath.row];
		cell.textLabel.textColor = [UIColor blackColor];
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
		return nil;
}




//========================================================================================
//========================================================================================
#pragma mark - Split view
//========================================================================================
//========================================================================================


- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController
		  withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController {
	
	self.barButton = barButtonItem;
	self.barButton.title = [ApiMachine shared].heading;
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
//	self.mySplitNavController = [splitController.viewControllers objectAtIndex:1];
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController
  		invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
	self.barButton = nil;
    self.masterPopoverController = nil;
//	self.mySplitNavController = nil;//[splitController.viewControllers objectAtIndex:1];
}

@end
