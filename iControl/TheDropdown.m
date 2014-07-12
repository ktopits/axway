/**************************************************************/
/* KTopits  -                                                  */
/* TheDropdown.m                                           */
/* KT 09-MAY-2014                                             */
/**************************************************************/

#import "TheDropdown.h"

@implementation TheDropdown

@synthesize usingIOS7;
@synthesize masterViewController;
@synthesize myNoteLabel;
@synthesize myNoteView;
@synthesize promptArray;


static NSString * prefix = @"-[drp]   ";
static NSString * wallpaper = @"Dropdown.png";

#define ALPHAON 0.85
#define ALPHAOFF 0.00

#define DOWNTIME 1.0f
#define UPTIME 1.0f
#define NEXTTIME 0.5f

//========================================================================================
#pragma mark - SESSION Init, Dealloc
//========================================================================================

TheDropdown * theDropdownSelf = nil;				//Context Definition is here!

//*******************************************
// Here when Application is created (FROM MAIN THREAD)
//*******************************************
+ (TheDropdown *)shared {
	return theDropdownSelf;
}


- (id) init {
	self = [super init];		//create my context (so caller did not have to
	theDropdownSelf = [self retain];

	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	NSString *reqSysVer = @"7.0";
	self.usingIOS7	= ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	
	self.promptArray = [[NSMutableArray alloc] init];
	return self;
}

//*******************************************
// Here when WirelessBlueController is released
//*******************************************
- (void) dealloc
{
 	NSLog(@"%@--- dealloc",prefix);
	[self.promptArray release];
	[self release];
	theDropdownSelf = nil;
    [super dealloc];
}

- (void)useMasterViewController:(UIViewController *)view {
	self.masterViewController = view;
}

-(NSInteger)pendingPrompts {
	return self.promptArray.count;
}

/**********************************************************/
/* NOTIFCATIONS During BACKGROUND OR LOCKED               */
/**********************************************************/

BOOL fooanimate;
CGRect aframe;
CGRect bframe;

//Get current Label (for check if it is in use...)
-(NSString *)barfoo {
	return self.myNoteLabel.text;
}
-(void)foobar:(NSString *)msg {
	if (msg==nil) {
		if((self.myNoteLabel.text!=nil)&&(!fooanimate))
			[self barfoo1];
		return;
	}
	//Get TOP VIEW and Orientation
	BOOL portrait;
	CGRect statusFrame = [[UIApplication sharedApplication] statusBarFrame]; //RELATIVE TO HOME BUTTON!
	UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	if ((statusBarOrientation==UIInterfaceOrientationPortrait)||(statusBarOrientation==UIInterfaceOrientationPortraitUpsideDown))
		portrait = YES;
	else
		portrait = NO;
	
	UIView * topview;
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
#if 0
		//		topview = self.blue.nowView.parentViewController.view;
		//		topview = self.parentViewController.view;
		//		topview = self.navigationController.view;
#endif
		topview = self.masterViewController.navigationController.view;
	}
	else {
		topview = self.masterViewController.navigationController.view;
#if 0
		//case of iPad Portrait with POP over hidden.  Need info from DELEGATE...
		if (self.blue.splitMode==SplitModeDual) {
			topview = self.blue.nowView.parentViewController.view;		//local self.parentViewController.view = self.navigationController.view
		}
		else {
			if (self.blue.splitMode == SplitModePopView)
				topview = self.blue.navPopController.contentViewController.view;	//portrait + popover
			else if(self.blue.splitMode == SplitModePortrait) {
				topview = self.blue.navSplitController.parentViewController.view;
			}
		}
#endif
		statusFrame.size.height = 0;
		statusFrame.size.width  = 0;
	}
	//	NSLOG(@"%@ FOO orient=%i portrait=%i split=%i",prefix,statusBarOrientation,portrait,self.blue.splitMode);
	
	//status L=3 748x,0y   (20w 1024h)  T(0,0)(320w 748h)  ====> X=0 WID=1024,  Y=748 H=20
	//status L=4   0x,0y   (20w,1024h)  T(0,0)(320w 748h)  ====> X=0 WID=1024,  Y=0   H=20
#if 0
	aframe = statusFrame;
	NSLog(@"%@SFRAME(%i)= (%3.0fx,%3.0fy) %3.0fw x %3.0fh",prefix,statusBarOrientation,aframe.origin.x,aframe.origin.y,aframe.size.width,aframe.size.height);
	aframe = topview.frame;
	NSLog(@"%@TFRAME(%i)= (%3.0fx,%3.0fy) %3.0fw x %3.0fh",prefix,statusBarOrientation,aframe.origin.x,aframe.origin.y,aframe.size.width,aframe.size.height);
#endif
	
	
	//-----------------------------
	// Create the VIEW if not already created (generic gray rectangle)
	//-----------------------------
	if (self.myNoteView==nil) {
		//Build the Background BOX IMAGE
		aframe.size.height = 38;		//This doesn't change!  BBwirelessIN matches this 300x38 and 600 x 76
		aframe.size.width  = 310;		//This doesn't change!  BBwirelessIN matches this 300x38 and 600 x 76
		aframe.origin.x    = 0;
		aframe.origin.y    = 0;
		UIImageView * xview = [[UIImageView alloc] initWithFrame:aframe];
		xview.image = [UIImage imageNamed:wallpaper];
		xview.backgroundColor	= [UIColor grayColor];
		xview.alpha= ALPHAOFF;
		self.myNoteView = xview;
		
		//Build the LABEL to place INSIDE the BOX IMAGE
		aframe.size.height = self.myNoteView.frame.size.height - 4;
		aframe.size.width  = self.myNoteView.frame.size.width  - 4;
		aframe.origin.x  = ((self.myNoteView.frame.size.width  - aframe.size.width)/2.0);
//		NSLog(@"%@MFRAME(%i)= (%3.0fx,%3.0fy) %3.0fw x %3.0fh",prefix,statusBarOrientation,
//			  self.myNoteView.frame.origin.x,self.myNoteView.frame.origin.y,self.myNoteView.frame.size.width,self.myNoteView.frame.size.height);
		aframe.origin.y  = ((self.myNoteView.frame.size.height - aframe.size.height)/2.0);
		
		UILabel * xlabel = [[UILabel alloc] initWithFrame:aframe];
		xlabel.backgroundColor = [UIColor clearColor];
		xlabel.textColor = [UIColor blackColor];
		xlabel.shadowColor = [UIColor whiteColor];
		xlabel.shadowOffset = CGSizeMake(0.0, 1.0);
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			xlabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:13.0];
		else
			xlabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14.0];
		xlabel.text = nil;
		xlabel.textAlignment = NSTextAlignmentCenter;
		
		//Connect the DOTS....
		self.myNoteLabel = xlabel;
		[self.myNoteView addSubview:xlabel];
		[xview release];
		[xlabel release];
		//		NSLOG(@"%@ xview =%i label=%i",prefix,[xview retainCount],[xlabel retainCount]);
	}
	
	//-----------------------------
	//Compute OFFSET for show (BFRAME) and Hidden (AFRAME)
	//-----------------------------
	aframe = self.myNoteView.frame;
	
	if (portrait) {
		aframe.origin.x = (topview.frame.size.width - aframe.size.width)/2;
	}
	else {
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			aframe.origin.x = (topview.frame.size.width  - aframe.size.width)/2;
		else
			aframe.origin.x = (topview.frame.size.height - aframe.size.width)/2;
	}
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGRect navbar = self.masterViewController.navigationController.navigationBar.frame;
		aframe.origin.y = 0 + navbar.origin.y;
	}
	else if (self.usingIOS7) {
		CGRect navbar = self.masterViewController.navigationController.view.frame;
//		float y = navbar.origin.y;
		aframe.origin.y = 0 - navbar.origin.y;
	}
	else {
		aframe.origin.y = 0;
	}
	aframe.origin.y +=   statusFrame.size.height - aframe.size.height;
	
	
	bframe = aframe;
	bframe.origin.y += bframe.size.height + 2;
	self.myNoteView.frame = aframe;
	
	self.myNoteLabel.text = msg;
	[topview addSubview:self.myNoteView];
	self.myNoteView.hidden = NO;
	fooanimate = YES;
	[UIView animateWithDuration:DOWNTIME
					 animations:^ {
						 [UIView setAnimationBeginsFromCurrentState:NO];
						 self.myNoteView.frame = bframe;
						 self.myNoteView.alpha = ALPHAON;
					 }
					 completion:^(BOOL finished) {
//						 NSLog(@"%@ CompletedB=%i",prefix,finished);
						 fooanimate = NO;
					 }  ];
}
-(void)barfoo1 {
	fooanimate = YES;
	[UIView animateWithDuration:UPTIME
					 animations:^ {
						 [UIView setAnimationBeginsFromCurrentState:YES];
						 self.myNoteView.frame = aframe;
						 self.myNoteView.alpha = ALPHAOFF;
					 }
					 completion:^(BOOL finished) {
						 self.myNoteLabel.text = nil;
						 self.myNoteView.hidden = YES;
//						 NSLog(@"%@ CompletedA=%i",prefix,finished);
						 fooanimate = NO;
						 [self.myNoteView removeFromSuperview];
					 }  ];
}

/**********************************************************/
/* NAVBAR Prompt Management = ONLY WORKS IN WIRELESS VIEW */
/**********************************************************/

- (void) showTopPrompt {
	NSString * nextprompt = [self.promptArray objectAtIndex:0];
	//		NSLOG(@"%@ *PROMPT(%i)=%@",prefix,[self.promptArray count],nextprompt);
	[self foobar:nextprompt];
	//	self.navigationItem.prompt = nextprompt;
	[self performSelector:@selector(nextNavPrompt) withObject:nil afterDelay:NEXTTIME];
}
- (void) clearThePrompt {
	[self foobar:nil];
	//	self.navigationItem.prompt = nil;
}

//Put something into QUEUE
- (void) queNavPrompt:(NSString *)prompt  {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(queNavPrompt:) object:nil];
	//if real prompt add it
	if ((prompt!=nil)&&([prompt length]>0)) {
		[self.promptArray addObject:[NSString stringWithString:prompt]];
	}
	if ([self.promptArray count]==0)
		return;
	
	//Prompts available, but busy or not available - defer and recall
#if 1
	if (/*!(self.inView)||(self.background)||*/ ([[self barfoo] length]>0)/*||([self.navigationItem.prompt length]>0)*/) {
		[self performSelector:@selector(queNavPrompt:) withObject:nil afterDelay:4.0f]; //actuall 1+4+1 seconds
		return;
	}
#endif
	//Prompts available, nothing going on, and ready
	[self showTopPrompt];	//and call back to NextNavPrompt
}
//TimesUp on Display
- (void) nextNavPrompt {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(queNavPrompt:) object:nil];
#if 0
	if (/*!(self.inView)||*/(self.background)) {
		[self performSelector:@selector(nextNavPrompt) withObject:nil afterDelay:2.0f];
		return;
	}
#endif
	if ([[self barfoo] length]>0) {
		[self clearThePrompt];
		[self performSelector:@selector(nextNavPrompt) withObject:nil afterDelay:NEXTTIME];
		return;
	}
	//still active, clear TOP, and launch next
	if ([self.promptArray count]>0) {
		[self.promptArray removeObjectAtIndex:0];
		if ([self.promptArray count]>0) {
			[self showTopPrompt];
			return;
		}
	}
	[self clearThePrompt];
}

- (void) clearNavPrompts {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(queNavPrompt:) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(nextNavPrompt) object:nil];
	[self.promptArray removeAllObjects];
	[self clearThePrompt];
}

@end
