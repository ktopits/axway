/**************************************************************/
/* ktopits -                                                  */
/* AppDelegate.m                                              */
/* KT 09-JUN-2014                                             */
/**************************************************************/


#import "FeatureSettings.h"
#import "AppDelegate.h"
#import "ApiMasterViewController.h"
#import "ApiDetailViewController.h"

#import "ApiMachine.h"
#import "TheDropdown.h"


@implementation AppDelegate

static NSString * prefix = @"[*APP*]  ";

//========================================================================================
#pragma mark - Launch / Dealloc
//========================================================================================

- (void)dealloc
{
    [_window release];
    [_navigationController release];
    [_splitViewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //----------------------------------------------------
	// Get Configuration from "INFO".PLIST Bundle
	// MUST ADD THIS TO INFO.PLIST
	//    <key>CFBundleConfiguration</key>
	//    <string>${CONFIGURATION}</string>
	//----------------------------------------------------
	NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString*  myname = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
	NSString*  myident= [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
	NSString*  myconfig=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleConfiguration"];
	NSLog(@"%@Version  = %@ (%@) %@ {%@}",prefix,myname,version,myident,myconfig);


	//----------------------------------------------------
	// Get Configuration from SETTINGS Bundle - ALL ACCESS is HERE!!!
	// Only KEYS defined in THIS install included
	//   NEW KEYS are ADDED,  Old undefined KEYS are DELETED
	//   KEYS already defined are unchanged
	// Value = nil means either (1) key not defined, or (2) user/app did not explicitly set a value
	//     NOTE: "Default" value might be displayed, but is not available here(?)
	// If you want a "secret" setting, archive or encode it as NSData object.
	// These defaults are specific to a device and can not be exported/imported
	// So restart/checkpoint, usage, owner, keys, application management (warnings,reminders)
	// SQL should be "Stuff" that is NOT device specific - aka songs, lists, chords, sheets
	//----------------------------------------------------
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString * oldVersion = [defaults stringForKey:SETTING_version];
	if (![oldVersion isEqualToString:version]) {
//		NSLog(@"[SETTINGS] Old Version = \"%@\"",oldVersion);
		[defaults setObject:version forKey:SETTING_version];	//PUSH Version to settings
	}
	oldVersion = [defaults stringForKey:SETTING_release];
	if (![oldVersion isEqualToString:myconfig]) {
//		NSLog(@"[SETTINGS] Old Release = \"%@\"",oldVersion);
		[defaults setObject:myconfig forKey:SETTING_release];	//PUSH Release to settings
	}
	
	[[TheDropdown alloc] init];
	[[ApiMachine alloc] init];

	/******************************************************************************/
	// Create WINDOW and VIEWS
	/******************************************************************************/

	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
	
	
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        ApiMasterViewController *masterViewController = [[[ApiMasterViewController alloc] initWithNibName:@"ApiMasterViewController_iPhone" bundle:nil] autorelease];
		[[TheDropdown shared] useMasterViewController:masterViewController];
        self.navigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
        self.window.rootViewController = self.navigationController;
    } else {
        ApiMasterViewController *masterViewController = [[[ApiMasterViewController alloc] initWithNibName:@"ApiMasterViewController_iPad" bundle:nil] autorelease];
		[[TheDropdown shared] useMasterViewController:masterViewController];
        UINavigationController *masterNavigationController = [[[UINavigationController alloc] initWithRootViewController:masterViewController] autorelease];
        
        ApiDetailViewController *detailViewController = [[[ApiDetailViewController alloc] initWithNibName:@"ApiDetailViewController_iPad" bundle:nil] autorelease];
        UINavigationController *detailNavigationController = [[[UINavigationController alloc] initWithRootViewController:detailViewController] autorelease];
		detailViewController.view.backgroundColor = [UIColor grayColor];
    	
    	masterViewController.detailViewController = detailViewController;
    	
        self.splitViewController = [[[UISplitViewController alloc] init] autorelease];
        self.splitViewController.delegate = detailViewController;
        self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
//		masterViewController.detailViewController.mySplitNavController = detailNavigationController;
        
        self.window.rootViewController = self.splitViewController;
    }
    [self.window makeKeyAndVisible];

	/******************************************************************************/
	// Final stuff before EXITING Delegate Initialization
	/******************************************************************************/

#if USE_AXWAY_PUSH
	// Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
	 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#endif
    return YES;
}

#if USE_AXWAY_PUSH
- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
	NSLog(@"%@ Failed to get token, error: %@",prefix,error);
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
	NSLog(@"%@ My token is: %@",prefix,newDeviceToken);
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	for (id key in userInfo) {
        NSLog(@"%@ key: %@, value: %@",prefix, key, [userInfo objectForKey:key]);
    }
}
#endif


-(NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
	return UIInterfaceOrientationMaskAll;
}





//========================================================================================
#pragma mark - Called by Another Applications
//========================================================================================

// Called either from MAIL or SAFARI (or some future app)
// In which case APP was either NOT-RUNNING or BACKGROUND
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    //See if LINKUP request CALL-BACK/RETURN from DropBox APP or Sarfari URL or POP-UP
    NSString * scheme = [[url scheme] lowercaseString];
	if ([scheme isEqualToString:uApiScheme]) {
		NSLog(@"[URL] open URL=%@",url);
        if ([[ApiMachine shared] browserReturnURL:url])
            return YES;
	}
    
    //Must be MAIL or SAFARI or DROPBOX file OPEN
	NSLog(@"[URL] Called to handleOpenURL scheme:\"%@\"",[url scheme]);
	return [self processURLrequest:url];
}
/******************************************************************************/
/* Here from SAFARI or other APP trying to call me "bodywair://"              */
/* Uses info.plist NSURL SCHEMES  [url scheme] is always lowercase            */
/* Also here form MAIL or other APP trying to open a .txt file "file://"      */
/******************************************************************************/

-(NSString *)checkCallURL:(NSURL *)url {
	NSString * info = [url resourceSpecifier];
	if (([url host]==nil)&&(info!=nil)&&([info length]>0)) {
		char cx = [info characterAtIndex:0];
		if (cx=='?') {
			return [info substringWithRange:NSMakeRange(1, [info length]-1)];
		}
	}
	return nil;
}

//This is called - at launch or while in Background
//
//foo://example.com:8042/over/there?name=ferret#nose
//\_/   \______________/\_________/ \_________/ \__/
// |           |            |            |        |
//scheme  host/authority   path        query   fragment
//
//URL - launch - Launch Option & Handle Open
//URL - Backgr - Handle Open
//FILE- Launch - Launch Option & Handle Open
//FILE- Backgr - Handle Open
NSString * uApiScheme = API_SCHEME;

NSString * uFile = @"file";
NSString * uHTTP = @"http";
NSString * uHTTPS = @"https";
//NSString * uDropbox = APP_SCHEME;
//NSString * uwwwDropbox = @"www.dropbox.com";
//NSString * udlDropbox = @"dl.dropbox.com";

- (BOOL) processURLrequest:(NSURL *)url {
//	NSURL * queueURL = nil;
    NSString * scheme = [[url scheme] lowercaseString];
	//------------
	//See if application (MAIL) asking to open a file
	//------------
	if ([scheme isEqualToString:uFile]) {
		if (![[url host] isEqualToString:@"localhost"]) {
			NSLog(@"[URL] file Host: %@", [url host]);		//"localhost"
        }
		NSLog(@"[URL] file Path: %@",[url path]);			//"filespec"
//		queueURL = [url copy];			//Queue it up for ListView
	}
	    
	//------------
	//
	//------------
	else if (![scheme isEqualToString:uApiScheme]) {
		return NO;
	}
    
    
	//------------
	// Here with request to ApiScheme::   UN-SOLICITED!
	// See if URL with a filename (already checked it to be myapp://www.xyz.com/filespec")
	//------------
	else if ([url path]!=nil) {
		NSLog(@"[URL] file Host: %@",[url host]);		// "www.ktopits.com" or "www.dropbox.com"
		NSLog(@"URL] file Path: %@",[url path]);		// "/foo/ktopits_list.txt:8080"
		
		NSString * fScheme = uHTTP; //[url scheme];
		NSString * fHost   = [[url host] lowercaseString];
//		if ([fHost isEqualToString:uwwwDropbox]) {
//			fHost = udlDropbox;
//		}
//		if ([fHost isEqualToString:udlDropbox]) {
//			fScheme = uHTTPS;	//optional...
//		}
		NSString * httpURL = [NSString stringWithFormat:@"%@://%@%@",fScheme,fHost,[url path]];
		httpURL = [httpURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSLog(@"[URL] xxx={%@}",httpURL);
		
//		queueURL = [NSURL URLWithString:httpURL];
        //		NSLog(@"%@[URL] que={%@}",prefix,[queueURL absoluteString]);
	}
	
	//------------
	// URL without a filename or host
	//------------
	else {
    }
	return YES;	//got it and opened it
}

//========================================================================================
#pragma mark - Standard DELEGATE CALLS
//========================================================================================


- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"%@ *** INACTIVE ***",prefix);
	[ApiMachine shared].icnAppState|=1;	//Foreground + Inactive
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"%@ *** BACKGROUND ***",prefix);
	[ApiMachine shared].icnAppState|=2;	//Background + Inactive
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"%@ *** FOREGROUND ***",prefix);
	[ApiMachine shared].icnAppState&=~2;	//Foreground + Inactive
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"%@ *** ACTIVE ***",prefix);
	[ApiMachine shared].icnAppState&=~1;	//Foreground + active
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"%@ *** TERMINATE ***",prefix);
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
