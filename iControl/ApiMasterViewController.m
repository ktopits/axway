/**************************************************************/
/* ktopitsAxway  -                                              */
/* ApiMasterViewController.m                                  */
/* KT 09-JUL-2014                                             */
/**************************************************************/


#import "ApiMasterViewController.h"
#import "ApiDetailViewController.h"
#import "ListTableViewCell.h"

#import "FeatureSettings.h"
#import "TheDropdown.h"
#import "JsonUtils.h"
#import "JsonUtils.h"
#if USE_BONJOUR
#import "BonjourManager.h"
#endif

#define OBJECTH_SECTION 0
#define OBJECTD_SECTION 1
#define OBJECTU_SECTION 2
#define OBJECTX_SECTIONS 3
#define USE_PUSH 0

//=================================================
#pragma mark - GOTIT Item Reference
//=================================================
@interface ICNGotit: NSObject {
	NSString     * name;		//Name for CELL NAMEFIELD and DETAIL Title
	NSString     * href;		//HREF for DETAIL to Use
	NSString     * imagex;		//Unique IMAGE name
	BOOL           dimit;		//dim this entry
	float          timex;		//seconds to load
	NSInteger      status;		//HTTP status code
	id             item;		//JSON/String/HTML/Array/...
}
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * href;
@property (nonatomic, retain) NSString * imagex;
@property (nonatomic        ) float timex;
@property (nonatomic        ) NSInteger status;
@property (nonatomic        ) BOOL dimit;
@property (nonatomic, retain) id item;
@end

@implementation ICNGotit
@synthesize name;
@synthesize href;
@synthesize imagex;
@synthesize timex;
@synthesize status;
@synthesize dimit;
@synthesize item;
@end
//================


//=================================================
#pragma mark - iPhone ROTATION management
//=================================================
//This is the RootViewController for iPhone
@interface UINavigationController (RotationAll)
-(NSUInteger)supportedInterfaceOrientations;
@end

@implementation UINavigationController (RotationAll)
-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}
@end
//================

//=================================================
#pragma mark - MASTER View Controller
//=================================================
@interface ApiMasterViewController () {
	BOOL masterArrayReady;
    NSMutableArray * objectH;
    NSMutableArray * objectD;
	UIActionSheet * myActionSheet;
	ListTableViewCell * listTableViewCell;
	UILabel * myfooter;
}
@end

@implementation ApiMasterViewController

@synthesize myActionSheet;
@synthesize myAlertView;
@synthesize listTableViewCell;
@synthesize myfooter;
@synthesize masterArrayReady;
@synthesize objectH;
@synthesize objectD;
@synthesize objectU;
@synthesize stockSymbol;
@synthesize gatewayAddress;
@synthesize scope_sms;
@synthesize scope_mms;
@synthesize scope_speech;
@synthesize scope_device;
@synthesize scope_location;
@synthesize scope_mim;
@synthesize scope_immn;
@synthesize detailSelection;
@synthesize cleanupOnRefresh;
@synthesize authButton;
@synthesize refreshButton;
@synthesize stopButton;
@synthesize portsJson;
#if USE_BONJOUR
@synthesize bonjourNames;			//All names
@synthesize bonjourName;			//Selected Name
@synthesize bonjourAddress;			//Resolved Address for Selected Name
@synthesize bonjourPort;
#endif

static NSString * prefix = @"[MASTER] ";

//=================================================
#pragma mark - Load/Unload View
//=================================================


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = [ApiMachine shared].heading;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
//7.0            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
			self.preferredContentSize = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}
							
- (void)dealloc
{
	[self.objectH release];
	[self.objectD release];
    [_detailViewController release];
    [super dealloc];
}

- (void)viewDidLoad
{
    NSLog(@"%@*viewDidLoad",prefix);
    [super viewDidLoad];
	
    self.stopButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelWebView:)] autorelease];
    self.refreshButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshObjects:)] autorelease];
    self.navigationItem.rightBarButtonItem = self.refreshButton;
	
    self.authButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(authorizationOptions:)] autorelease];
    self.navigationItem.leftBarButtonItem = self.authButton;

#if 1
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;		//ios 6 and 7
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;	//ios 7 only
#endif
	if (self.detailViewController!=nil)
		[[ApiMachine shared] useWebViewController:self.detailViewController];	//spilit with iPad
	else
		[[ApiMachine shared] useWebViewController:self];							//single with iPhone
    [[ApiMachine shared] setDelegate:self];

	self.cleanupOnRefresh = NO;
	[self initRequestedScopes];

	self.detailSelection = nil;
	self.stockSymbol = @"AXW";

#if USE_BONJOUR
	if ([BonjourManager shared]==nil) {
		BonjourManager *manager = [[BonjourManager alloc] init];
		manager.delegate = (id)self;
		[manager release];
		self.bonjourName = nil;
		self.bonjourAddress = nil;
		self.bonjourPort = -1;
		self.bonjourNames = [[NSMutableArray alloc] init];
		[[BonjourManager shared] bonjourSearch:nil];	//use default = axway_api
	}
#endif
}

#if USE_BONJOUR
// If SERVICE was DROPPED and RECONNECTED (aka VM PAUSE/RESUME) DNS-SD client will NOT know to re-register!
- (void) bonjourManager:(BonjourManager *)manager serviceAdded:(NSString *)serviceName {
	[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"<%@ Detected>",serviceName]];
	[self removeService:serviceName];
	[self.bonjourNames addObject:[NSString stringWithString:serviceName]];
}
//If SERVICE DROPS (off-line, disconnected) it is about a 5 minute timeout.  If Service STOPPED, then immediate
- (void) bonjourManager:(BonjourManager *)manager serviceDropped:(NSString *)serviceName {
	[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"<%@ Dropped>",serviceName]];
	[self removeService:serviceName];
}
-(BOOL)removeService:(NSString *)serviceName {
	for (NSInteger i=self.bonjourNames.count-1; i>=0; i--) {
		NSString * name = [self.bonjourNames objectAtIndex:i];
		if ([serviceName isEqualToString:name]) {
			[self.bonjourNames removeObjectAtIndex:i];
			return YES;
		}
	}
	return NO;
}
//Only called if something CHANGED
- (void) bonjourManager:(BonjourManager *)manager serviceReady:(NSInteger)count {
	[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"<Services=%li>",(long)count]];
	[self reselectService];
}

//Here because Bonjour services Channged (ADD/REMOVE)
-(void)reselectService {
	if (self.bonjourNames.count>0) {
		//Bonjour IS AVAILABLE
		for (NSString * serviceName in self.bonjourNames) {
			if ([serviceName isEqualToString:self.bonjourName]) {
				if (self.bonjourAddress==nil)
					[[BonjourManager shared] resolveBonjourService:self.bonjourName];
				return;
			}
		}
		self.bonjourName = [self.bonjourNames objectAtIndex:0];
		self.bonjourAddress = nil;
		self.bonjourPort = -1;
		[[BonjourManager shared] resolveBonjourService:self.bonjourName];
	}
	else {
		//Bonjour is NOT available
		if (self.bonjourName==nil)
			return;
		self.bonjourName = nil;
		self.bonjourAddress = nil;
		self.bonjourPort = -1;
		[[ApiMachine shared] checkHostGateway:nil save:NO];
	}
}
//Requested BONJURE service has been RESOLVED
- (void) bonjourManager:(BonjourManager *)manager serviceName:(NSString *)serviceName address:(NSString *)ipaddress port:(NSInteger)port txtrec:(NSDictionary *)txtrec {
	if (ipaddress==nil) {
		//Did NOT resolve
		[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"<%@ ?Failed>",serviceName]];
		[self removeService:serviceName];
		[self reselectService];
	}
	else if ([serviceName isEqualToString:self.bonjourName]) {
		//RESOLVE for MY request
		[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"<%@ Ready>",serviceName]];
		BOOL save = NO;
		if ((self.bonjourPort!=port) || (![self.bonjourAddress isEqualToString:ipaddress])) {
			self.bonjourAddress = [NSString stringWithString:ipaddress];
			self.bonjourPort = port;
			save = YES;
		}
		NSString * bonjureHost = [NSString stringWithFormat:@"%@:%li",self.bonjourAddress,(long)self.bonjourPort];
		[[ApiMachine shared] checkHostGateway:bonjureHost save:save];
	}
	else {
		//Unknown Resolve!
	}
}

#endif



-(void)cancelWebView:(id)sender {
    NSLog(@"%@*[cancelWebView]*",prefix);
	[self performSelector:@selector(waitForStock) withObject:nil afterDelay:0.0];
}

-(void)refreshObjects:(id)sender {
    NSLog(@"%@*[refreshObjects:%li]*",prefix,(long)self.cleanupOnRefresh);
	if (self.cleanupOnRefresh) {
		[self.objectH removeAllObjects];
		[self.objectD removeAllObjects];
		[self.objectU removeAllObjects];
		[self.tableView reloadData];
		
		if (self.detailViewController !=nil) {
			self.detailViewController.detailItem = nil;
			self.detailViewController.title = @"Detail";
			[self.detailViewController.tableView reloadData];
		}
		self.cleanupOnRefresh = NO;
	}
#if 1
	else {
		for (ICNGotit * gotit in self.objectH)
			gotit.dimit = YES;
		for (ICNGotit * gotit in self.objectD)
			gotit.dimit = YES;
		for (ICNGotit * gotit in self.objectU)
			gotit.dimit = YES;
		[self.tableView reloadData];
	}
#endif
	[self performSelector:@selector(waitForStock) withObject:nil afterDelay:0.5];
}
- (void)waitForStock {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForStock) object:nil];
	if (self.myAlertView == nil)
		[self performSelector:@selector(waitForIcontrol) withObject:nil afterDelay:0.0];
	else
		[self performSelector:@selector(waitForStock) withObject:nil afterDelay:0.5];
}

- (void)waitForIcontrol {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForIcontrol) object:nil];
	[[ApiMachine shared] forceHTTPget:nil];
    [[ApiMachine shared] startTheMachine:YES];
}

- (void)waitForQue {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForQue) object:nil];
	if ([TheDropdown shared].pendingPrompts>0) {
		[self performSelector:@selector(waitForQue) withObject:nil afterDelay:0.5];
		return;
	}
	[self authorizationOptions:nil];
}

//** DELEGATE **
- (void) apiMachine:(ApiMachine *)gateway authState:(NSInteger)state {
    if (state<AuthStateStart) {
        NSLog(@"%@[delegate] TOKEN AUTHORIZATION FAILED = %li",prefix,(long)state);
		[self performSelector:@selector(waitForQue) withObject:nil afterDelay:0.5];
    }
    else if (state==AuthStateTokenOK) {
        NSLog(@"%@[delegate] TOKEN AUTHORIZATION DONE = %li",prefix,(long)state);
    }
    else {
        NSLog(@"%@[delegate] TOKEN AUTHORIZATION WAITING = %li",prefix,(long)state);
    }
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"%@*viewWillAppear",prefix);
    [super viewWillAppear:animated];
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
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[[ApiMachine shared] willRefreshWebView];
	}
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	BOOL xfull=((fromInterfaceOrientation==UIInterfaceOrientationPortrait)||(fromInterfaceOrientation==UIInterfaceOrientationPortraitUpsideDown))?NO:YES;
	NSLog(@"%@ DidRotateFrom: X%@(%li)",prefix,xfull?@"=":@"||",(long)fromInterfaceOrientation);
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		[[ApiMachine shared] didRefreshWebView];
	}
}



//=================================================
#pragma mark - ApigeeGateway Delegate
//=================================================

- (NSString *) apiMachine:(ApiMachine *)apiMachine getString:(NSString *)string {
	return self.stockSymbol;
}

- (void) apiMachine:(ApiMachine *)apiMachine running:(NSInteger)flag {
	NSLog(@"%@[delegate] Gateway Machine = %@ (%li)",prefix,(flag!=0)?@"STARTED":@"STOPPED",(long)flag);
	if (flag&2) {
		self.navigationItem.leftBarButtonItem.enabled = NO;
		self.navigationItem.leftBarButtonItem = nil;
		self.navigationItem.rightBarButtonItem = self.stopButton;
		self.navigationItem.rightBarButtonItem.enabled = YES;
#if USE_BONJOUR
		[[BonjourManager shared] bonjourBrowserIdleLock];
#endif
	}
	else if (flag!=0) {
		self.navigationItem.leftBarButtonItem = self.authButton;
		self.navigationItem.leftBarButtonItem.enabled = NO;
		self.navigationItem.rightBarButtonItem = self.refreshButton;
		self.navigationItem.rightBarButtonItem.enabled = NO;
#if USE_BONJOUR
		[[BonjourManager shared] bonjourBrowserIdleLock];
#endif
	}
	else {
		self.navigationItem.leftBarButtonItem = self.authButton;
		self.navigationItem.leftBarButtonItem.enabled = YES;
		self.navigationItem.rightBarButtonItem = self.refreshButton;
		self.navigationItem.rightBarButtonItem.enabled = YES;
#if USE_BONJOUR
		[[BonjourManager shared] bonjourBrowserIdleUnlock];
#endif
	}
}

//Here when SERVER backend changed STRING
- (void) apiMachine:(ApiMachine *)apiMachine service:(NSInteger)type heading:(NSString *)heading {
	self.title = heading;
	if (self.detailViewController.barButton!=nil)
		self.detailViewController.barButton.title = heading;
}
//Here with a new TOKEN assigned JSON
static NSString * ICNToken = @"ICNToken.png";
- (void) apiMachine:(ApiMachine *)apiMachine token:(id)tokenJson time:(float)timex status:(NSInteger)status {
	NSInteger mobile = [[ApiMachine shared] readServiceSetting];
	NSString * token = @"App Token";
	if ((mobile&XDN_OAUTHSRVR_MASK)==XDN_OAUTHSRVR_QA)
		token = [token stringByAppendingString:@" /HTTP"];
	else if ((mobile&XDN_OAUTHSRVR_MASK)==XDN_OAUTHSRVR_PR)
		token = [token stringByAppendingString:@" /HTTPS"];
	[self insertNewObjectH:tokenJson time:timex name:token image:ICNToken status:status];
}
//Here with HTML
- (void) apiMachine:(ApiMachine *)apiMachine health:(NSString *)health time:(float)timex status:(NSInteger)status {
	[self insertNewObjectH:health time:timex name:@"App => GW" image:@"ICNHealthcheck.png" status:status];
}
- (void) apiMachine:(ApiMachine *)apiMachine ports:(id)ports time:(float)timex status:(NSInteger)status {
	if ([ports isKindOfClass:[NSDictionary class]]) {
		self.portsJson = ports;
		NSString * port;
		port = [portsJson valueForKey:@"admin_http"];
		if (port!=nil)
			[self insertNewObjectU:port time:0.0 name:@"Admin /HTTP" image:@"ICNAxway.png" https:0];
		port = [portsJson valueForKey:@"admin_https"];
		if (port!=nil)
			[self insertNewObjectU:port time:0.0 name:@"Admin /HTTPS" image:@"ICNAxway.png" https:1];
		port = [portsJson valueForKey:@"portal_http"];
		if (port!=nil)
			[self insertNewObjectU:port time:0.0 name:@"Portal /HTTP" image:@"ICNAxway.png" https:0];
		port = [portsJson valueForKey:@"portal_https"];
		if (port!=nil)
			[self insertNewObjectU:port time:0.0 name:@"Portal /HTTPS" image:@"ICNAxway.png" https:1];
		port = [portsJson valueForKey:@"reporter_http"];
		if (port!=nil)
			[self insertNewObjectU:port time:0.0 name:@"Analytics /HTTP" image:@"ICNAxway.png" https:0];
		port = [portsJson valueForKey:@"reporter_https"];
		if (port!=nil)
			[self insertNewObjectU:port time:0.0 name:@"Analytics /HTTPS" image:@"ICNAxway.png" https:1];
		port = [portsJson valueForKey:@"web_http"];
		if (port!=nil)
			[self insertNewObjectU:port time:0.0 name:@"WebSite /HTTP" image:@"ICNPorts.png" https:0];
		port = [portsJson valueForKey:@"web_https"];
		if (port!=nil)
			[self insertNewObjectU:port time:0.0 name:@"Website /HTTPS" image:@"ICNPorts.png" https:1];
	}
	[self insertNewObjectH:ports time:timex name:@"Port Configuration" image:@"ICNPreferences.png" status:status];
}
- (void) apiMachine:(ApiMachine *)apiMachine throttle:(NSString *)throttle time:(float)timex status:(NSInteger)status {
	BOOL ok = (status==200);
	[self insertNewObjectH:throttle time:timex name:(ok)?@"Throttle OK":@"Throttle WAIT!" image:@"ICNHistory.png" status:status];
}
- (void) apiMachine:(ApiMachine *)apiMachine stock:(id)response time:(float)timex status:(NSInteger)status {
	[self insertNewObjectH:response time:timex name:@"KPS Stock Check" image:@"ICNStocks.png" status:status];
}
- (void) apiMachine:(ApiMachine *)apiMachine basic:(id)response time:(float)timex status:(NSInteger)status {
	[self insertNewObjectH:response time:timex name:@"Basic HTTP Auth" image:@"ICNIdentity.png" status:status];
}


- (void) apiMachine:(ApiMachine *)apiMachine gwNet:(NSString *)health time:(float)timex status:(NSInteger)status {
	[self insertNewObjectD:health time:timex name:@"GW  => Internet" image:@"ICNInternet.png" status:status];
}
- (void) apiMachine:(ApiMachine *)apiMachine appNet:(NSString *)health time:(float)timex status:(NSInteger)status {
	[self insertNewObjectD:health time:timex name:@"APP => Internet" image:@"BBDeviceOFF.png" status:status];
}

- (void) apiMachine:(ApiMachine *)apiMachine google:(id)response time:(float)timex status:(NSInteger)status {
	[self insertNewObjectD:response time:timex name:@"OpenID Auth" image:@"ICNGoogle.png" status:status];
}
//Here with JSON
//- (void) apiMachine:(ApiMachine *)apiMachine mapID:(id)response time:(float)timex {
//	[self insertNewObjectD:response time:timex name:@"Basic Auth" image:@"ICNIdentity.png" status:status];
//}

#if 0
//Here with a MESSAGE JSON
- (void) apiMachine:(ApiMachine *)apiMachine deviceID:(id)message time:(float)timex {
	NSString * msgID       = [message objectForKey:@"messageId"];
	NSNumber * isIncomingX = [message objectForKey:@"isIncoming"];
	NSNumber * isUnreadX   = [message objectForKey:@"isUnread"];
	BOOL isIncoming = [isIncomingX integerValue];
	BOOL isUnread   = [isUnreadX   integerValue];
	NSString * image = @"";
	NSString * who = @"";
	NSDictionary * fromx = [message objectForKey:@"from"];
	NSString * from = [fromx objectForKey:@"value"];
#if 0
	//RCV = msgID rXX, isIncoming=1 isUnread=1
	//SND = msgID tXX, isIncoming=0 isUnread=0
	NSLog(@"%@ MSG \"%@\" Incoming %@ %i  Unread %@ %i",prefix,msgID,isIncomingX,isIncoming,isUnreadX,isUnread);
#endif
	if (isIncoming) {
		if (isUnread) {
			image = @"iconx_down.png";
		}
		else {
			image = @"iconx_down.png";
		}
		msgID = [NSString stringWithFormat:@"{%@} ◀︎%@",msgID,from];
	}
	else {
		image = @"iconx_up.png";
		NSArray * tox = [message objectForKey:@"recipients"];
		if (tox.count>0) {
			NSDictionary * tos = [tox objectAtIndex:0];
			who = [tos objectForKey:@"value"];
		}
		msgID = [NSString stringWithFormat:@"{%@} ▷%@",msgID,who];
	}
	[self insertNewObjectU:message time:0.0 name:msgID image:image];
}
#endif

//Here when detail view completed a force on the SELECTED item!
- (void) apiMachine:(ApiMachine *)apiMachine forceID:(id)force time:(float)timex {
	NSLog(@"%@Detail ForceGET sec:%li row:%li time:%0.3f",prefix,(long)self.detailSelection.section,(long)self.detailSelection.row,timex);
	ICNGotit * gotit = [self objectForIndexPath:self.detailSelection];
	gotit.timex = timex;
	[self.tableView reloadData];
}

#define KEY_METADATA  @"__metadata"
#define KEY_URI       @"uri"

- (void)insertNewObjectH:(id)json time:(float)timex name:(NSString *)name image:(NSString *)imagex status:(NSInteger)status {
    if (self.objectH==nil) {
        self.objectH = [[NSMutableArray alloc] init];
    }
	for (ICNGotit * got in self.objectH) {
		if ([got.imagex isEqualToString:imagex]) {
			BOOL reload = NO;
			if ([got.imagex isEqualToString:ICNToken]) {
				got.timex = timex;
				reload = YES;
			}
			if (got.timex!=timex) {
				got.timex = timex;
				reload = YES;
			}
			if (got.status!=status) {
				got.status = status;
				reload = YES;
			}
			if (![got.name isEqualToString:name]) {
				got.name = name;
				reload = YES;
			}
			if (got.dimit) {
				got.dimit = NO;
				reload = YES;
			}
			if (reload) {
				got.item = json;
				[self.tableView reloadData];
			}
			return;
		}
	}

	ICNGotit * gotit = [ICNGotit alloc];
	gotit.timex = timex;
	gotit.status = status;
	gotit.name = name;
	gotit.item = json;
	gotit.imagex = imagex;
	gotit.href = nil;
	gotit.dimit = NO;
	if ([json isKindOfClass:[NSDictionary class]]) {
		id meta = [json objectForKey:KEY_METADATA];
		if (meta!=nil)
			gotit.href = [meta objectForKey:KEY_URI];
	}

	NSInteger index = self.objectH.count;
    [self.objectH insertObject:gotit atIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:OBJECTH_SECTION];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
- (void)insertNewObjectD:(id)json time:(float)timex name:(NSString *)name  image:(NSString *)imagex status:(NSInteger)status {
    if (self.objectD==nil) {
        self.objectD = [[NSMutableArray alloc] init];
    }
	for (ICNGotit * got in self.objectD) {
		if ([got.imagex isEqualToString:imagex]) {
			BOOL reload = NO;
			if (got.timex!=timex) {
				got.timex = timex;
				reload = YES;
			}
			if (got.status!=status) {
				got.status = status;
				reload = YES;
			}
			if (![got.name isEqualToString:name]) {
				got.name = name;
				reload = YES;
			}
			if (got.dimit) {
				got.dimit = NO;
				reload = YES;
			}
			if (reload) {
				got.item = json;
				[self.tableView reloadData];
			}
			return;
		}
	}
	ICNGotit * gotit = [ICNGotit alloc];
	gotit.timex = timex;
	gotit.status = status;
	gotit.name = name;
	gotit.item = json;
	gotit.imagex = imagex;
	gotit.href = nil;
	gotit.dimit = NO;
	if ([json isKindOfClass:[NSDictionary class]]) {
		id meta = [json objectForKey:KEY_METADATA];
		if (meta!=nil)
			gotit.href = [meta objectForKey:KEY_URI];
	}

	NSInteger index = self.objectD.count;
    [self.objectD insertObject:gotit atIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:OBJECTD_SECTION];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
- (void)insertNewObjectU:(id)json time:(float)timex name:(NSString *)name  image:(NSString *)imagex https:(NSInteger)status {
    if (self.objectU==nil) {
        self.objectU = [[NSMutableArray alloc] init];
    }
	for (ICNGotit * got in self.objectU) {
		if ([got.name isEqualToString:name]) {
			BOOL reload = NO;
			if (got.timex!=timex) {
				got.timex = timex;
				reload = YES;
			}
			if (got.dimit) {
				got.dimit = NO;
				reload = YES;
			}
			if (reload) {
				got.item = json;
				[self.tableView reloadData];
			}
			return;
		}
	}
	ICNGotit * gotit = [ICNGotit alloc];
	gotit.timex = timex;
	gotit.name = name;
	gotit.item = json;
	gotit.imagex = imagex;
	gotit.href = nil;
	gotit.status = status;
	gotit.dimit = NO;

	NSInteger index = self.objectU.count;
    [self.objectU insertObject:gotit atIndex:index];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:OBJECTU_SECTION];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(ICNGotit *)objectForIndexPath:(NSIndexPath *)indexpath {
	if (indexpath.section == OBJECTH_SECTION) {
		return [self.objectH objectAtIndex:indexpath.row];
	}
	else if (indexpath.section == OBJECTD_SECTION) {
		return [self.objectD objectAtIndex:indexpath.row];
	}
	else if (indexpath.section == OBJECTU_SECTION) {
		return [self.objectU objectAtIndex:indexpath.row];
	}
	else {
		return nil;
	}
}



//=================================================
#pragma mark - TableView VIEW
//=================================================

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 10.0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 0.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	self.tableView.sectionFooterHeight = 4;
	self.tableView.sectionHeaderHeight = 2;
    return OBJECTX_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == OBJECTH_SECTION)
	    return self.objectH.count;
	else if (section == OBJECTD_SECTION)
		return self.objectD.count;
	else if (section == OBJECTU_SECTION)
		return self.objectU.count;
	else
		return 0;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString * cellIdentifier = @"ListTableViewCell";
	ListTableViewCell *cell = nil;
	if (cell == nil) {
		cell = (ListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	}
	if (cell == nil) {
		NSBundle * mainx = [NSBundle mainBundle];
		[mainx loadNibNamed:cellIdentifier owner:self options:nil];	//loads to IBOUTLET = xxxTableViewCell
		cell = self.listTableViewCell;
		self.listTableViewCell = nil;
	}
    return (UITableViewCell *)cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cellx forRowAtIndexPath:(NSIndexPath *)indexPath {

	ListTableViewCell *cell = (ListTableViewCell *)cellx;
	cell.nameField.tag = indexPath.row;		//save link back to this cell entry row number
	cell.listIcon.hidden = NO;
	cell.infoLabel.hidden = NO;
	cell.nameField.adjustsFontSizeToFitWidth = YES;

	ICNGotit * gotit = [self objectForIndexPath:indexPath];
	BOOL fail = NO;
	if (gotit.item==nil) {
		fail = YES;
	}
	else if ([gotit.item isKindOfClass:[NSString class]]) {
		NSString * failed = (NSString *)gotit.item;
		if (failed.length == 0) {
			fail=YES;
		}
	}
	else if ([gotit.item isKindOfClass:[NSDictionary class]]) {
		NSDictionary * failed = (NSDictionary *)gotit.item;
		if (failed.count == 0) {
			fail=YES;
		}
	}
	if (fail) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else if(indexPath.section == OBJECTU_SECTION) {
		cell.accessoryType = UITableViewCellAccessoryNone;//DetailButton;
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}


	if (gotit.dimit) {
		cell.nameField.textColor = [UIColor lightGrayColor];
		cell.highlighted = NO;
		[cell.activity stopAnimating];
	}
	else if ((gotit.timex==0.0)&&(gotit.status==0)&&(fail)&&(indexPath.section!=OBJECTU_SECTION)) {
		cell.nameField.textColor = [UIColor blackColor];
		cell.highlighted = YES;
		[cell.activity startAnimating];
	}
	else {
		cell.nameField.textColor = [UIColor grayColor];
		cell.highlighted = NO;
		[cell.activity stopAnimating];
	}
	cell.nameField.text = gotit.name;

	if ((gotit.status==0)||(gotit.status==1)||((gotit.status>=200)&&(gotit.status<=299))) {
		cell.redbarIcon.hidden = YES;
		if (gotit.timex<=0.0) {
			if ((indexPath.section==OBJECTU_SECTION)||(gotit.status==0))
				cell.infoLabel.text = @"";
			else
				cell.infoLabel.text = @"---";
			cell.infoLabel.textColor = [UIColor grayColor];
		}
		else {
			cell.infoLabel.text = [NSString stringWithFormat:@"%7.3f",gotit.timex];
			if (gotit.timex>=1.0)
				cell.infoLabel.textColor = [UIColor orangeColor];
			else if (gotit.timex>=0.500)
				cell.infoLabel.textColor = [UIColor blueColor];
			else
				cell.infoLabel.textColor = [UIColor blackColor];
		}
	}
	else {
		cell.redbarIcon.hidden = NO;
		cell.infoLabel.text = [NSString stringWithFormat:@"{ %li }",(long)gotit.status];
		cell.infoLabel.textColor = [UIColor redColor];
	}
	cell.listIcon.image = [UIImage imageNamed:gotit.imagex];
	cell.listIcon.highlightedImage = cell.listIcon.image;
}



- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.navigationItem.rightBarButtonItem.enabled == NO)
		return nil;
	ICNGotit * gotit = [self objectForIndexPath:indexPath];
	if ([gotit.item isKindOfClass:[NSString class]]) {
		NSString * failed = (NSString *)gotit.item;
		if (failed.length == 0)
			return nil;
	}
	return indexPath;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ICNGotit * gotit = [self objectForIndexPath:indexPath];
	NSLog(@"%@ Selected (S%li R%li) \"%@\"",prefix,(long)indexPath.section,(long)indexPath.row,gotit.name);
	if (indexPath.section==OBJECTU_SECTION) {
		NSString * host = [NSString stringWithFormat:@"%@://%@:%@",(gotit.status)?@"https":@"http",[[ApiMachine shared] getHostName],gotit.item];
		[self launchSafari:host];
		[self.detailViewController.tableView reloadData];
		return;
	}

	self.detailSelection = indexPath;
	
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[[ApiDetailViewController alloc] initWithNibName:@"ApiDetailViewController_iPhone" bundle:nil] autorelease];
			self.detailViewController.view.backgroundColor = [UIColor grayColor];
	    }
		//VIEW DID LOAD ALREADY CALLED IN DETAIL
		if (gotit.href!=nil)
			self.detailViewController.detailItem = gotit.href;
		else
			self.detailViewController.detailItem = gotit.item;
		self.detailViewController.title = gotit.name;//newTitle;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    } else {
		if (gotit.href!=nil)
			self.detailViewController.detailItem = gotit.href;
		else
			self.detailViewController.detailItem = gotit.item;
		self.detailViewController.title = gotit.name;//newTitle;
		[self.detailViewController.tableView reloadData];
    }
	NSLog(@"%@*DetailView Ready...",prefix);
}







//=================================================
#pragma mark - Authorization Manager
//=================================================

- (void) showInMyView:(UIActionSheet *)actionView {
//	NSLog(@"%@ActionSheet(%i)=%p (%@)",prefix,actionView.retainCount,actionView,actionView.title);
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		//iPhone OR iPod
		[actionView showInView:self.parentViewController.view];	//prevent clipping of top item in Landscape mode...
	}
	else {
		//iPad SPLITVIEW
		UINavigationController * nav = self.navigationController;
//		if (self.detailViewController.mySplitNavController!=nil)
//			nav = self.detailViewController.mySplitNavController;
		[actionView showInView:nav.view.window];
	}
}

static NSString * Button_Cancel   = @"Done";
static NSString * Button_CancelX  = @"{Cancel}";
static NSString * Button_Reset    = @"🚨 Reset 				.";
static NSString * Button_Expire   = @"⌚ Expire Token		.";
static NSString * Button_Invalid  = @"🔫 Invalidate Token	.";
//static NSString * Button_EnterCode= @"📝 Enter Code	.";
static NSString * Button_Startup  = @"🔓 Authorize Now  	.";
static NSString * Button_Scopes   = @"🔭 Requested Scopes.";
static NSString * Button_Service  = @"🏠 Change Service	.";
static NSString * Button_Gateway  = @"💻 Gateway Address .";
#if 0
static NSString * Button_Portal   = @"💻 API Portal .";
static NSString * Button_Admin    = @"💻 API Admin .";
static NSString * Button_Analytics= @"💻 API Analytics .";
#endif
static NSString * Button_Stocks   = @"📈 Select Stock   	.";
#if USE_AXWAY_PUSH
static NSString * Button_PushOut  = @"🎌 Push Notification .";
#endif
static NSString * Title_Service   = @"🏠 Select Service";
static NSString * Title_Scopes    = @"🔭 Request Scopes";
static NSString * Title_Options   = @"OPTIONS";



- (void)authorizationOptions:(id)sender {
	NSInteger ix = 0;
	NSString * ptx[9] = {nil,nil,nil,nil,nil,nil,nil,nil,nil};
	
	NSInteger cfgFlags = 0;
#if 0
	if (!(cfgFlags&0x0001)) {
		if ([ApiMachine shared].oauthJson!=nil) {
			ptx[ix++] = Button_Expire;
			ptx[ix++] = Button_Invalid;
		}
	}
#endif
//	ptx[ix++] = Button_EnterCode;
	if (self.objectH.count==0)
		ptx[ix++] = Button_Startup;
#if USE_PUSH
	if (!(cfgFlags&0x0008)) {
		ptx[ix++] = Button_PushOut;
	}
#endif
#if 1
	if (!(cfgFlags&0x0002)) {
		ptx[ix++] = Button_Scopes;
	}
	if (!(cfgFlags&0x0004)) {
		ptx[ix++] = Button_Service;
	}
#endif
#if USE_AXWAY_PUSH
	ptx[ix++] = Button_PushOut;
#endif
	ptx[ix++] = Button_Stocks;
	ptx[ix++] = Button_Gateway;
#if 0
	if (self.portsJson!=nil) {
		ptx[ix++] = Button_Admin;
		ptx[ix++] = Button_Portal;
		ptx[ix++] = Button_Analytics;
	}
#endif
	self.myActionSheet = [[[UIActionSheet alloc] initWithTitle:Title_Options
														  delegate:self
												 cancelButtonTitle:Button_Cancel
											destructiveButtonTitle:Button_Reset		//RED BUTTON
												 otherButtonTitles:ptx[0],ptx[1],ptx[2],ptx[3],ptx[4],ptx[5],ptx[6],ptx[7],nil] autorelease];	//WHITE BUTTON
	[self showInMyView:self.myActionSheet];
}

//BE SURE NOT TO CONFUSE "REQUESTED SCOPES" with "AUTHORIZED SCOPES"
-(void)initRequestedScopes {
	self.scope_sms	= NO;
	self.scope_mms	= NO;
	self.scope_speech = NO;
	self.scope_device = NO;
	self.scope_location = NO;
	self.scope_mim = NO;
	self.scope_immn = NO;
	[[ApiMachine shared] pushTheScopes:[self getScopeList]];
}
-(NSString *)getScopeList {
	NSString * scopes = ScopeX_default;
	if (self.scope_sms) {
		scopes = [scopes stringByAppendingString:ScopeX_sms];
	}
	if (self.scope_mms) {
		if (scopes.length>0)
			scopes = [scopes stringByAppendingString:ScopeX_separator];
		scopes = [scopes stringByAppendingString:ScopeX_mms];
	}

	if (self.scope_speech) {
		if (scopes.length>0)
			scopes = [scopes stringByAppendingString:ScopeX_separator];
		scopes = [scopes stringByAppendingString:ScopeX_speech];
	}
	if (self.scope_device) {
		if (scopes.length>0)
			scopes = [scopes stringByAppendingString:ScopeX_separator];
		scopes = [scopes stringByAppendingString:ScopeX_device];
	}
	if (self.scope_location) {
		if (scopes.length>0)
			scopes = [scopes stringByAppendingString:ScopeX_separator];
		scopes = [scopes stringByAppendingString:ScopeX_location];
	}
	if (self.scope_mim) {
		if (scopes.length>0)
			scopes = [scopes stringByAppendingString:ScopeX_separator];
		scopes = [scopes stringByAppendingString:ScopeX_mim];
	}
	if (self.scope_immn) {
		if (scopes.length>0)
			scopes = [scopes stringByAppendingString:ScopeX_separator];
		scopes = [scopes stringByAppendingString:ScopeX_immn];
	}
	return scopes;
}
//Scope must be valid, non-blank
static NSString * ScopeX_separator  = @",";
static NSString * ScopeX_default	= @"";
static NSString * ScopeX_sms		= @"SMS";
static NSString * ScopeX_mms		= @"MMS";
static NSString * ScopeX_speech		= @"SPEECH";
static NSString * ScopeX_device		= @"DC";
static NSString * ScopeX_location	= @"TL";
static NSString * ScopeX_mim     	= @"MIM";
static NSString * ScopeX_immn     	= @"IMMN";

//static NSString * Scope_Default		= @"*Default* 					.";
static NSString * Scope_sms		    = @"SMS Send 					2";
static NSString * Scope_mms		    = @"MMS Send					2";
static NSString * Scope_speech		= @"Speech to Text 			2";
static NSString * Scope_device		= @"Device Capabilities 		2";
static NSString * Scope_location	= @"Terminal Location 		3";
static NSString * Scope_mim      	= @"InApp Mesg Read		3";
static NSString * Scope_immn      	= @"InApp Mesg Send 		3";

static NSString * Scope_Done        = @"⬅ Done";
static NSString * Scope_CheckON     = @"✅";
static NSString * Scope_CheckOFF    = @"⛔";

- (void)scopeOptions {
	NSString * ptx[8] = {nil,nil,nil,nil,nil,nil,nil,nil};
	NSInteger ix=0;
	ptx[ix++] = [NSString stringWithFormat:@"%@ %@",(self.scope_sms)		?Scope_CheckON:Scope_CheckOFF,Scope_sms];
	ptx[ix++] = [NSString stringWithFormat:@"%@ %@",(self.scope_mms)		?Scope_CheckON:Scope_CheckOFF,Scope_mms];
//	ptx[ix++] = [NSString stringWithFormat:@"%@ %@",(self.scope_speech)	?Scope_CheckON:Scope_CheckOFF,Scope_speech];
//	ptx[ix++] = [NSString stringWithFormat:@"%@ %@",(self.scope_device)	?Scope_CheckON:Scope_CheckOFF,Scope_device];
//	ptx[ix++] = [NSString stringWithFormat:@"%@ %@",(self.scope_location)	?Scope_CheckON:Scope_CheckOFF,Scope_location];
//	ptx[ix++] = [NSString stringWithFormat:@"%@ %@",(self.scope_mim)	    ?Scope_CheckON:Scope_CheckOFF,Scope_mim];
//	ptx[ix++] = [NSString stringWithFormat:@"%@ %@",(self.scope_immn)	    ?Scope_CheckON:Scope_CheckOFF,Scope_immn];

	self.myActionSheet = [[[UIActionSheet alloc] initWithTitle:Title_Scopes
													  delegate:self
											 cancelButtonTitle:nil
										destructiveButtonTitle:Scope_Done		//RED BUTTON
											 otherButtonTitles:ptx[0],ptx[1],ptx[2],ptx[3],ptx[4],ptx[5],ptx[6],nil] autorelease];	//WHITE BUTTON
	[self showInMyView:self.myActionSheet];
}

static NSString * Button_Call_ATTAPI;
static NSString * Button_Call_FOUNDRY;
static NSString * Button_Env_QA;
static NSString * Button_Env_PR;
static NSString * Button_Use_URL;
static NSString * Button_Use_HDR;
static NSString * Button_Client_ktsb;
static NSString * Button_Client_ktpr;
static NSString * Button_Client_fdev;

- (void)serviceOptions {
	NSInteger ix = 0;
	NSString * ptx[10] = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil};
	NSInteger mobile = [[ApiMachine shared] readServiceSetting];
	Button_Call_ATTAPI= [NSString stringWithFormat:@"%@ 	%@",@"Axway API	GW",((mobile&XDN_SERVICE_MASK) ==XDN_SERVICE_ATTAPI) ?Scope_CheckON:Scope_CheckOFF];
	Button_Call_FOUNDRY=[NSString stringWithFormat:@"%@ 	%@",@"FOUNDRY GW",((mobile&XDN_SERVICE_MASK) ==XDN_SERVICE_FOUNDRY)?Scope_CheckON:Scope_CheckOFF];
	Button_Env_QA     = [NSString stringWithFormat:@"%@ 	%@",@"OAUTH  HTTP ",((mobile&XDN_OAUTHSRVR_MASK)==XDN_OAUTHSRVR_QA)  ?Scope_CheckON:Scope_CheckOFF];
	Button_Env_PR     = [NSString stringWithFormat:@"%@ 	%@",@"OAUTH  HTTPS",((mobile&XDN_OAUTHSRVR_MASK)==XDN_OAUTHSRVR_PR)  ?Scope_CheckON:Scope_CheckOFF];
	ptx[ix++] = Button_Call_ATTAPI;
	ptx[ix++] = Button_Call_FOUNDRY;
	ptx[ix++] = Button_Env_QA;
	ptx[ix++] = Button_Env_PR;
#if 0
	Button_Use_HDR    = [NSString stringWithFormat:@"%@ 	%@",@"Auth via HDR",((mobile&XDN_AUTHMODE_MASK)==XDN_AUTHMODE_HEADER)?Scope_CheckON:Scope_CheckOFF];
	Button_Use_URL    = [NSString stringWithFormat:@"%@ 	%@",@"Auth via URL",((mobile&XDN_AUTHMODE_MASK)==XDN_AUTHMODE_INURL) ?Scope_CheckON:Scope_CheckOFF];
	Button_Client_ktsb= [NSString stringWithFormat:@"%@ 	%@",@"ClientID KTsb",((mobile&XDN_CLIENTID_MASK)==XDN_CLIENTID_KTSB) ?Scope_CheckON:Scope_CheckOFF];
	Button_Client_ktpr= [NSString stringWithFormat:@"%@ 	%@",@"ClientID KTpr",((mobile&XDN_CLIENTID_MASK)==XDN_CLIENTID_KTPR) ?Scope_CheckON:Scope_CheckOFF];
	Button_Client_fdev= [NSString stringWithFormat:@"%@ 	%@",@"ClientID FDev",((mobile&XDN_CLIENTID_MASK)==XDN_CLIENTID_FOUNDRY)?Scope_CheckON:Scope_CheckOFF];
	ptx[ix++] = Button_Use_HDR;
	ptx[ix++] = Button_Use_URL;
	ptx[ix++] = Button_Client_ktsb;
	ptx[ix++] = Button_Client_ktpr;
	ptx[ix++] = Button_Client_fdev;
#endif

	self.myActionSheet = [[[UIActionSheet alloc] initWithTitle:Title_Service
													  delegate:self
											 cancelButtonTitle:Button_Cancel
										destructiveButtonTitle:nil		//RED BUTTON
											 otherButtonTitles:ptx[0],ptx[1],ptx[2],ptx[3],ptx[4],ptx[5],ptx[6],ptx[7],ptx[8],ptx[9],nil] autorelease];	//WHITE BUTTON
	[self showInMyView:self.myActionSheet];
}



- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSString * buttonTitle;
	NSInteger mobile;
//	NSString * port;
	if (buttonIndex>=0) {
		buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
	}
	else {
		buttonTitle = Button_CancelX;	// -1 "cancelbutton" and title was nil => Aka no CANCEL BUTTON, and iPAD clicked outside of actionsheet
	}
//	NSLog(@"%@ <=dismiss button:%i \"%@\"",prefix,buttonIndex,buttonTitle);
	if ([buttonTitle isEqualToString:Button_Cancel]||[buttonTitle isEqualToString:Button_CancelX]) {
		return;
	}
	if ([buttonTitle isEqualToString:Scope_Done]) {
		[[ApiMachine shared] pushTheScopes:[self getScopeList]];
		[self performSelector:@selector(authorizationOptions:) withObject:nil afterDelay:0.1];
		return;
	}
	
	if ([buttonTitle isEqualToString:Button_Scopes]) {
		[self performSelector:@selector(scopeOptions) withObject:nil afterDelay:0.1];
	}
	else if ([buttonTitle isEqualToString:Button_Service]) {
		[self performSelector:@selector(serviceOptions) withObject:nil afterDelay:0.1];
	}
	
	else if ([actionSheet.title isEqualToString:Title_Options]) {
		if ([buttonTitle isEqualToString:Button_Reset]) {
			self.cleanupOnRefresh = YES;
			[[ApiMachine shared] gotActionButtonReset];
		}
		else if ([buttonTitle isEqualToString:Button_Startup]) {
			[self performSelector:@selector(refreshObjects:) withObject:nil afterDelay:1.0];
		}
		else if ([buttonTitle isEqualToString:Button_Expire]) {
			[[ApiMachine shared] gotActionButtonExpire];
		}
		else if ([buttonTitle isEqualToString:Button_Invalid]) {
			[[ApiMachine shared] gotActionButtonInvalid];
		}
		else if ([buttonTitle isEqualToString:Button_Gateway]) {
			[self getGatewayAddress];
		}
		else if ([buttonTitle isEqualToString:Button_Stocks]) {
			[self enterStockSymbol];
		}
#if 0
		else if ([buttonTitle isEqualToString:Button_Portal]) {
			NSString * host = nil;
			port = [self.portsJson valueForKey:@"portal_https"];
			if (port!=nil) {
				host = [NSString stringWithFormat:@"https://%@:%@",self.bonjourAddress,port];
			}
			else {
				port = [self.portsJson valueForKey:@"portal_http"];
				if (port!=nil)
					host = [NSString stringWithFormat:@"http://%@:%@",self.bonjourAddress,port];
			}
			if (host!=nil)
				[self launchSafari:host];
		}
		else if ([buttonTitle isEqualToString:Button_Admin]) {
			NSString * host = nil;
			port = [self.portsJson valueForKey:@"admin_https"];
			if (port!=nil) {
				host = [NSString stringWithFormat:@"https://%@:%@",self.bonjourAddress,port];
			}
			else {
				port = [self.portsJson valueForKey:@"admin_http"];
				if (port!=nil)
					host = [NSString stringWithFormat:@"http://%@:%@",self.bonjourAddress,port];
			}
			if (host!=nil)
				[self launchSafari:host];
		}
		else if ([buttonTitle isEqualToString:Button_Analytics]) {
			NSString * host = nil;
			port = [self.portsJson valueForKey:@"reporter_https"];
			if (port!=nil) {
				host = [NSString stringWithFormat:@"https://%@:%@",self.bonjourAddress,port];
			}
			else {
				port = [self.portsJson valueForKey:@"reporter_http"];
				if (port!=nil)
					host = [NSString stringWithFormat:@"http://%@:%@",self.bonjourAddress,port];
			}
			if (host!=nil)
				[self launchSafari:host];
		}
#endif
#if USE_AXWAY_PUSH
		else if ([buttonTitle isEqualToString:Button_PushOut]) {
			[self sendPushToDevice:@"7a31ce8c4e43ac7c690cd7fdf35dd5eab84e606886a3afa54b3a9bb3b46fbd04" alert:@"Foo Bar!"];
		}
#endif
#if USE_PUSH
		else if ([buttonTitle isEqualToString:Button_PushOut]) {
			[self startupPush];
		}
#endif
	}
	else if ([actionSheet.title isEqualToString:Title_Service]) {
	
		mobile = [[ApiMachine shared] readServiceSetting];
		if ([buttonTitle isEqualToString:Button_Call_ATTAPI]) {
			self.cleanupOnRefresh = YES;
			[[ApiMachine shared] gotActionButtonReset];
			mobile&=~XDN_SERVICE_MASK;
			mobile|= XDN_SERVICE_ATTAPI;
		}
		else if ([buttonTitle isEqualToString:Button_Call_FOUNDRY]) {
			self.cleanupOnRefresh = YES;
			[[ApiMachine shared] gotActionButtonReset];
			mobile&=~XDN_SERVICE_MASK;
			mobile|= XDN_SERVICE_FOUNDRY;
		}
		else if ([buttonTitle isEqualToString:Button_Env_QA]) {
			self.cleanupOnRefresh = YES;
			[[ApiMachine shared] gotActionButtonReset];
			mobile&=~XDN_OAUTHSRVR_MASK;
			mobile|= XDN_OAUTHSRVR_QA;
		}
		else if ([buttonTitle isEqualToString:Button_Env_PR]) {
			self.cleanupOnRefresh = YES;
			[[ApiMachine shared] gotActionButtonReset];
			mobile&=~XDN_OAUTHSRVR_MASK;
			mobile|= XDN_OAUTHSRVR_PR;
		}
		else if ([buttonTitle isEqualToString:Button_Client_ktsb]) {
			self.cleanupOnRefresh = YES;
			[[ApiMachine shared] gotActionButtonReset];
			mobile&=~XDN_CLIENTID_MASK;
			mobile|= XDN_CLIENTID_KTSB;
		}
		else if ([buttonTitle isEqualToString:Button_Client_ktpr]) {
			self.cleanupOnRefresh = YES;
			[[ApiMachine shared] gotActionButtonReset];
			mobile&=~XDN_CLIENTID_MASK;
			mobile|= XDN_CLIENTID_KTPR;
		}
		else if ([buttonTitle isEqualToString:Button_Client_fdev]) {
			self.cleanupOnRefresh = YES;
			[[ApiMachine shared] gotActionButtonReset];
			mobile&=~XDN_CLIENTID_MASK;
			mobile|= XDN_CLIENTID_FOUNDRY;
		}
	
		else if ([buttonTitle isEqualToString:Button_Use_HDR]) {
			mobile&=~XDN_AUTHMODE_MASK;
			mobile|= XDN_AUTHMODE_HEADER;
		}
		else if ([buttonTitle isEqualToString:Button_Use_URL]) {
			mobile&=~XDN_AUTHMODE_MASK;
			mobile|= XDN_AUTHMODE_INURL;
		}
		[[ApiMachine shared] writeServiceSetting:mobile];
		[self performSelector:@selector(serviceOptions) withObject:nil afterDelay:0.1];
		return;
	}
	
	else if ([actionSheet.title isEqualToString:Title_Scopes]) {
		if ([buttonTitle hasSuffix:Scope_sms]) {
			self.scope_sms = !self.scope_sms;
			if (![[ApiMachine shared] pushTheScopes:[self getScopeList]])
				self.scope_sms = !self.scope_sms;
		}
		else if ([buttonTitle hasSuffix:Scope_mms]) {
			self.scope_mms = !self.scope_mms;
			if (![[ApiMachine shared] pushTheScopes:[self getScopeList]])
				self.scope_mms = !self.scope_mms;
		}
		else if ([buttonTitle hasSuffix:Scope_speech]) {
			self.scope_speech = !self.scope_speech;
			if (![[ApiMachine shared] pushTheScopes:[self getScopeList]])
				self.scope_speech = !self.scope_speech;
		}
		else if ([buttonTitle hasSuffix:Scope_device]) {
			self.scope_device = !self.scope_device;
			if (![[ApiMachine shared] pushTheScopes:[self getScopeList]])
				self.scope_device = !self.scope_device;
		}
		else if ([buttonTitle hasSuffix:Scope_location]) {
			self.scope_location = !self.scope_location;
			if (![[ApiMachine shared] pushTheScopes:[self getScopeList]])
				self.scope_location = !self.scope_location;
		}
		else if ([buttonTitle hasSuffix:Scope_mim]) {
			self.scope_mim = !self.scope_mim;
			if (![[ApiMachine shared] pushTheScopes:[self getScopeList]])
				self.scope_mim = !self.scope_mim;
		}
		else if ([buttonTitle hasSuffix:Scope_immn]) {
			self.scope_immn = !self.scope_immn;
			if (![[ApiMachine shared] pushTheScopes:[self getScopeList]])
				self.scope_immn = !self.scope_immn;
		}
		else {
			[[ApiMachine shared] pushTheScopes:[self getScopeList]];
		}
		[self performSelector:@selector(scopeOptions) withObject:nil afterDelay:0.1];
	}
}




//===
#pragma mark AlertView Inputs
#if 0
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];

	//------------
	// RESPONSE TO LOGIN
	//------------
    if([title isEqualToString:button_login]) {
        UITextField *username = [alertView textFieldAtIndex:field_username];
        UITextField *password = [alertView textFieldAtIndex:field_password];
		if (self.axisBonService==nil) {
			self.axisExtUsername = username.text;
			self.axisExtPassword = password.text;
		}
		else {
			self.axisBonUsername = username.text;
			self.axisBonPassword = password.text;
		}
		self.axisHOST_User = username.text;
#if TRACE_VAPIX
        NSLOG(@"%@[VAPIX] <= Retry Authenticate (%@ %@)",prefix, username.text, password.text);
#endif
		[self connectWithCredentials];
    }
    else if([title isEqualToString:button_cancel]) {
		[self connectCancel];
	}

	//------------
	// RESPONSE TO EXTERNAL ADDRESS
	//------------
    else if([title isEqualToString:button_address]) {
        UITextField *address = [alertView textFieldAtIndex:field_address];
		//		NSString * data = [[NSString alloc] initWithData:address.text encoding:NSASCIIStringEncoding];
		NSArray * fields = [address.text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
		if (fields.count==0) {
		}
		else if (fields.count==1) {
			self.axisExtAddress = [fields objectAtIndex:0];
			self.axisExtHttpPort = [NSString stringWithFormat:@"%i",80];
		}
		else if (fields.count==2) {
			self.axisExtAddress = [fields objectAtIndex:0];
			NSInteger port = [[fields objectAtIndex:1] intValue];
			if ((port<=0)||(port>65535))
				port  = 80;
			self.axisExtHttpPort = [NSString stringWithFormat:@"%i",port];
		}

        UITextField *rtspPort = [alertView textFieldAtIndex:field_rtspPort];
		NSInteger port = [rtspPort.text intValue];
		if ((port<=0)||(port>65535))
			port  = 554;
		self.axisExtRtspPort = [NSString stringWithFormat:@"%i",port];
		NSLOG(@"%@ field=%i Address=\"%@\", http:%@ rtsp:%@",prefix,fields.count,self.axisExtAddress,self.axisExtHttpPort,self.axisExtRtspPort);
		self.axisCamFlags = AxisFlagNone;		//Assume NEW CAMERA
		[self axisExternalDone:YES];
	}
    else if([title isEqualToString:button_addcan]) {
		[self axisExternalDone:NO];
	}
	self.alert_field0 = nil;
	self.alert_field1 = nil;
}
#endif

static NSString * Button_CANCEL = @"Cancel";
static NSString * Button_ADDRCAN= @"Cancel";
static NSString * Button_ACCEPT = @"Accept";
static NSString * Button_ADDRNEW= @"Change";
static NSString * Title_GATEWAY = @"Gateway Address";
static NSString * Title_STOCKS  = @"Stock Symbol";

-(void)getGatewayAddress {
	if (self.myAlertView!=nil)
		return;
	NSString * message = nil;
#if USE_BONJOUR
	if (self.bonjourAddress!=nil) {
		message = [NSString stringWithFormat:@"<%@>\n%@:%li",self.bonjourName,self.bonjourAddress,(long)self.bonjourPort];
	}
#endif
	self.myAlertView = [[UIAlertView alloc] initWithTitle:Title_GATEWAY message:message
													   delegate:self cancelButtonTitle:Button_ADDRCAN otherButtonTitles:Button_ADDRNEW,nil];
	self.myAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField *address = [self.myAlertView textFieldAtIndex:0];
	NSString * hostname = [[NSUserDefaults standardUserDefaults] stringForKey:SETTING_hostname];
	if ((hostname==nil)||(hostname.length==0))
		address.text = @"";
	else
		address.text = hostname;
	self.myAlertView.tag = 0;
	address.adjustsFontSizeToFitWidth = YES;
	address.placeholder = @"IP_ADDRESS:PORT";
	[self.myAlertView show];
}

- (void)enterStockSymbol {
	if (self.myAlertView!=nil)
		return;
	self.myAlertView = [[UIAlertView alloc] initWithTitle:Title_STOCKS message:nil
													 delegate:self cancelButtonTitle:Button_CANCEL otherButtonTitles:Button_ACCEPT,nil];
	self.myAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	self.myAlertView.tag = 0;
	UITextField *address = [self.myAlertView textFieldAtIndex:0];
	if ((self.stockSymbol==nil)||(self.stockSymbol.length==0))
		address.text = @"";
	else
		address.text = [NSString stringWithString:self.stockSymbol];
	address.adjustsFontSizeToFitWidth = YES;
	address.placeholder = @"Enter or Paste Symbol";
	[self.myAlertView show];
}

//*************************************
//DELEGATE - Clicked Button
//*************************************
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
	if ([buttonTitle isEqualToString:Button_ACCEPT]) {
		UITextField *address = [alertView textFieldAtIndex:0];
		NSLog(@"%@ BUTTON stock=> %@",prefix,address.text);
		self.stockSymbol = [NSString stringWithString:address.text];
	}
	if ([buttonTitle isEqualToString:Button_ADDRNEW]) {
		UITextField *address = [alertView textFieldAtIndex:0];
		NSLog(@"%@ BUTTON Gateway=> %@",prefix,address.text);
#if USE_BONJOUR
		if (self.bonjourAddress!=nil) {
			self.bonjourAddress = nil;
			self.bonjourPort = -1;
			[self reselectService];
		}
		else {
			[[ApiMachine shared] checkHostGateway:address.text save:YES];
		}
#else
		[[ApiMachine shared] checkHostGateway:address.text save:YES];
#endif
	}
	[self.myAlertView release];
	self.myAlertView = nil;
}
//*************************************
//DELEGATE - Called everytime a Character is added/deleted from either field
//*************************************
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
#if 0
	if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
	    if (alertView.tag++==0)
			return NO;
#if 0
		NSString *inputText = [[alertView textFieldAtIndex:0] text];
		if(inputText.length < 1 )		//if length==0, And no input then inputText=nil, else @""
			return NO;
#endif
		return YES;
	}
#endif
	return YES;
}


-(BOOL)launchSafari:(NSString *)callURL {
	NSLog(@"%@SAFARI>%@",prefix,callURL);
	NSURL * myURL =[NSURL URLWithString:callURL];
	//NOTE: THIS IS PRETTY CRUDE.  CALLING THIS WILL MOVE THIS APP TO BACKGROUND, and START UP SAFARI
	if (![[UIApplication sharedApplication] canOpenURL:myURL]) {
		//No app available to open URL.  aka not HTTP: or HTTPS:
		NSLog(@"%@SAFARI> ?Can not Open",prefix);
		return NO;
	}
	//OK. scheme is valid and URL Syntax valid
	else if (![[UIApplication sharedApplication] openURL:myURL]) {
		//?? Should not happen....
		return NO;
	}
	[[TheDropdown shared] queNavPrompt:@"* Launch Safari *"];
	//APP will now go INACTIVE and then BACKGROUND
	// from browser use "apiworkshop://" to return
	return YES;
}

#if USE_AXWAY_PUSH
#define PUSH_PEM   "AxwayAPI.pem"
#define PUSH_PASS  "axway"
#define PUSH_IPAD4 "7a31ce8c4e43ac7c690cd7fdf35dd5eab84e606886a3afa54b3a9bb3b46fbd04"
#define PUSH_ALERT "My first push notification!"
#define PUSH_DEVICE PUSH_IPAD4

-(BOOL)sendPushToDevice:(NSString *)deviceToken alert:(NSString *)message {
#if 0
	NSURL * appleURL = [NSURL URLWithString:@"ssl://gateway.sandbox.push.apple.com:2195"];
	NSOutputStream * stream = [NSOutputStream outputStreamWithURL:appleURL append:NO];

	char * $deviceToken = PUSH_DEVICE;
	char * $passphrase = PUSH_PASS;
	char * $message = PUSH_ALERT;
	char * $payload = '{aps:{"alert":"foo bars","sound":"defaut"}}';
#endif
	return NO;
}

#if 0
//Send Payload to OPENED TLS/SSL stream
static bool sendPayload(SSL *sslPtr, char *deviceTokenBinary, char *payloadBuff, size_t payloadLength)
{
	bool rtn = false;
	if (sslPtr && deviceTokenBinary && payloadBuff && payloadLength)
	{
		uint8_t command = 1; /* command number */
		char binaryMessageBuff[sizeof(uint8_t) + sizeof(uint32_t) + sizeof(uint32_t) + sizeof(uint16_t) +
							   DEVICE_BINARY_SIZE + sizeof(uint16_t) + MAXPAYLOAD_SIZE];
		/* message format is, |COMMAND|ID|EXPIRY|TOKENLEN|TOKEN|PAYLOADLEN|PAYLOAD| */
		char *binaryMessagePt = binaryMessageBuff;
		uint32_t whicheverOrderIWantToGetBackInAErrorResponse_ID = 1234;
		uint32_t networkOrderExpiryEpochUTC = htonl(time(NULL)+86400); // expire message if not delivered in 1 day
		uint16_t networkOrderTokenLength = htons(DEVICE_BINARY_SIZE);
		uint16_t networkOrderPayloadLength = htons(payloadLength);

		/* command */
		*binaryMessagePt++ = command;

		/* provider preference ordered ID */
		memcpy(binaryMessagePt, &whicheverOrderIWantToGetBackInAErrorResponse_ID, sizeof(uint32_t));
		binaryMessagePt += sizeof(uint32_t);

		/* expiry date network order */
		memcpy(binaryMessagePt, &networkOrderExpiryEpochUTC, sizeof(uint32_t));
		binaryMessagePt += sizeof(uint32_t);

		/* token length network order */
		memcpy(binaryMessagePt, &networkOrderTokenLength, sizeof(uint16_t));
		binaryMessagePt += sizeof(uint16_t);

		/* device token */
		memcpy(binaryMessagePt, deviceTokenBinary, DEVICE_BINARY_SIZE);
		binaryMessagePt += DEVICE_BINARY_SIZE;

		/* payload length network order */
		memcpy(binaryMessagePt, &networkOrderPayloadLength, sizeof(uint16_t));
		binaryMessagePt += sizeof(uint16_t);

		/* payload */
		memcpy(binaryMessagePt, payloadBuff, payloadLength);
		binaryMessagePt += payloadLength;
		if (SSL_write(sslPtr, binaryMessageBuff, (binaryMessagePt - binaryMessageBuff)) > 0)
			rtn = true;
	}
	return rtn;
}
#endif
#endif






-(void)startupPush {
#if 0
	if (![[ApigeeServices shared] signinUserWithDelegate:self])
		[self pushNotification];	//already signed in
#endif
}
#if 0
-(void)apigeeServices:(ApigeeServices *)services signin:(NSInteger)fail {
	if (fail==0) {
		//successfully signed in
		[self pushNotification];
	}
	else if (fail!=1) {
		//Did not CANCEL, so try to authenticate again
		[self startupPush];
	}
}
#endif

#if USE_PUSH
- (void)pushNotification {
	UIAlertView * myAlertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:nil
														  delegate:self cancelButtonTitle:Button_CANCEL otherButtonTitles:Button_ALERT,nil];
	myAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	UITextField *address = [myAlertView textFieldAtIndex:0];
	address.text = @"";
	address.adjustsFontSizeToFitWidth = YES;
	address.placeholder = @"Alert Message or Badge NUmber";
	
	[myAlertView show];
	[myAlertView release];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
	if ([buttonTitle isEqualToString:Button_ACCEPT]) {
		UITextField *address = [alertView textFieldAtIndex:0];
		NSLog(@"%@ BUTTON Code=> %@",prefix,address.text);
		[[ApigeeGateway shared] gotActionCode:address.text];
	}
	else if ([buttonTitle isEqualToString:Button_ALERT]) {
		UITextField *address = [alertView textFieldAtIndex:0];
		NSLog(@"%@ BUTTON Push=> %@",prefix,address.text);
#if 0
		if (![[ApigeeServices shared] sendPushAlert:address.text delegate:self])
			return;	//Invalid Request
#endif
	}
}
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    NSString *inputText0 = [[alertView textFieldAtIndex:0] text];
    if(inputText0.length < 1 )
		return NO;
	return YES;		//PUSH NOW ok
}

#if 0
-(void)apigeeServices:(ApigeeServices *)services status:(NSInteger)failed {
	if (failed) {
		//Invalid PUSH request???
		[self startupPush];
	}
}
#endif
#endif

@end
