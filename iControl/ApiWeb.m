/**************************************************************/
/* ktopits  -                                                 */
/* ApiWeb.m                                                   */
/* KT 08-JUL-2014                                             */
/**************************************************************/

#import "ApiWeb.h"

#define USE_COOKIES 1

#define HTTP_NONE     0
#define HTTP_200	200	//All OK - with Data

#define NETACT_ON     [UIApplication sharedApplication].networkActivityIndicatorVisible = YES
#define NETACT_OFF     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO


@implementation ApiWeb

@synthesize delegate;
@synthesize usingIOS7;
@synthesize inactive;

@synthesize savedAlpha;
@synthesize usingAlpha;
@synthesize savedTitle;
@synthesize callBackHost;
@synthesize startingURL;
@synthesize countURL;
@synthesize loadedHost;
@synthesize webViewRefreshing;
@synthesize responseStatus;

@synthesize backView;
@synthesize webView;
@synthesize webViewController;
@synthesize webConnection;
@synthesize webTitle;
@synthesize webCookies;
@synthesize webLoads;

#define BACKVIEW_START magentaColor
#define BACKVIEW_LOAD blueColor
#define BACKVIEW_IDLE grayColor
#define BACKVIEW_ERROR redColor

static NSString * prefix = @"--[web]  ";

//========================================================================================
#pragma mark - SESSION Init, Dealloc
//========================================================================================

ApiWeb * apiWebSelf = nil;				//Context Definition is here!

//*******************************************
// Here when Application is created (FROM MAIN THREAD)
//*******************************************
+ (ApiWeb *)shared {
	return apiWebSelf;
}


- (id) init {
	self = [super init];		//create my context (so caller did not have to
	apiWebSelf = [self retain];
    self.delegate = nil;
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	NSString *reqSysVer = @"7.0";
	self.usingIOS7	= ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
	self.webLoads = [[NSMutableArray alloc]init];


	return self;
}

//*******************************************
// Here when WirelessBlueController is released
//*******************************************
- (void) dealloc
{
 	NSLog(@"%@--- dealloc",prefix);
	[self release];
	apiWebSelf = nil;
    [super dealloc];
}

- (void)useWebViewController:(UIViewController *)view {
	self.webViewController = view;
}


//========================================================================================
#pragma mark - WebView Authentication Server
//========================================================================================

#define EDGE 0.0
#define WEDGE 4.0

//Add COLORED BORDER
-(void)fixWebFrames {
	CGRect frame = self.webViewController.navigationController.navigationBar.frame;
//	NSLog(@"%@nav x=%.0f y=%.0f    w=%.0f h=%.0f",prefix,frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
	CGRect navbar = frame;
	
	frame = self.webViewController.view.frame;		//iphone=MASTERVIEW, ipad=DETAILVIEW
//	NSLog(@"%@vew x=%.0f y=%.0f    w=%.0f h=%.0f",prefix,frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (!self.usingIOS7) {
			//ipad 6 (detail).  View = (0,0) 703x748, Navbar = (0,0) 703x44
			frame.origin.y += EDGE;
			frame.size.height -= navbar.size.height+(EDGE*2.0);
		}
		else {
			//ipad 7 (detail).  View = (0,0) 703x768, Navbar = (0,20) 703x44
			frame.origin.y += EDGE;
			frame.size.height -= navbar.size.height+navbar.origin.y+(EDGE*2.0);
		}
	}
	else { // iPhone
		if (!self.usingIOS7) {
			//iphone 6.  View = (0,0) 320x460, Navbar = (0,20) 320x44
			frame.origin.y -= (navbar.size.height-EDGE);
			frame.size.height -= (EDGE*2.0);
		}
		else {
			//iphone 7.  View = (0,0) 320x480, Navbar = (0,20) 320x44
			frame.origin.y -= (navbar.size.height-EDGE);
			frame.size.height -= navbar.origin.y+(EDGE*2.0);
		}
	}
//	NSLog(@"%@wvw x=%.0f y=%.0f    w=%.0f h=%.0f",prefix,frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
	self.backView.frame = frame;
	
	frame = self.backView.frame;
//	NSLog(@"%@web x=%.0f y=%.0f    w=%.0f h=%.0f",prefix,frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
	frame.origin.x = WEDGE;
	frame.origin.y = WEDGE;
	frame.size.width -= (WEDGE*2.0);
	frame.size.height-= (WEDGE*2.0);
	self.webView.frame = frame;
//	NSLog(@"%@web x=%.0f y=%.0f    w=%.0f h=%.0f",prefix,frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		self.webViewController.navigationController.navigationBar.alpha = self.usingAlpha;
	}
}

//Here when user cancels windows [X]
- (void)resetWebView {
	[self stopWebView];
#if USE_COOKIES
	//Delete ALL WebView Cookies - Always launch with a Clean Slate!
	NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
	for (NSInteger x=cookies.count-1; x>=0;x--) {
		NSHTTPCookie * cookie = [cookies objectAtIndex:x];
//		NSLog(@"%@ ==D#%i (%@) %@",prefix,cookies.count-x,cookie.domain,cookie.name);
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}
	self.webCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
#endif
}
- (BOOL)restartWebView {
	if (self.webView==nil)
		return NO;
	NSLog(@"%@ ====== view RE-STARTED =============================================================",prefix);
	NETACT_OFF;
	if (self.webView.loading)
		[self.webView stopLoading];
	if (self.webConnection!=nil) {
		[self.webConnection cancel];
		self.webConnection = nil;
	}
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.startingURL]];
	return YES;
}
//--------------------------
//on IPAD this is SUB VIEW of DETAIL (rotated by DETAIL)
//on iPHONE this is SUB VIEW of MASTER (rotated by MASTER)
//--------------------------
- (void)startWebView:(NSString *)callURL callbackHost:(NSString *)callBack title:(NSString *)title {
	if (self.backView==nil) {
		NSLog(@"%@ ====== view STARTED =============================================================",prefix);
		self.savedAlpha = self.webViewController.navigationController.navigationBar.alpha;
		if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
			self.usingAlpha = 0.60;
		}
		else {
			self.usingAlpha = self.savedAlpha;
		}

		//backView is "border"
		//Webview is browser window on TOP of backView
		self.backView = [[UIView alloc] init];
		self.backView.backgroundColor = [UIColor BACKVIEW_START];

		self.webView = [[UIWebView alloc] init];
		[self.backView addSubview:self.webView];
		self.webView.delegate = self;
		[self fixWebFrames];
		self.savedTitle = self.webViewController.title;
		self.webView.scalesPageToFit = YES;
		self.webView.allowsInlineMediaPlayback = NO;
		self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
#if 0
		CGRect header = self.backView.frame;
		header.origin.y += 40;
		header.size.width -= 40;
		self.backView.frame = header;
#endif
		[self.webViewController.view addSubview:self.backView];		//WebViewController is a TableViewController!
	}
	else {
		NSLog(@"%@ ====== view RE-STARTED =============================================================",prefix);
		NETACT_OFF;
		if (self.webView.loading) {
			[self.webView stopLoading];
			NSLog(@"%@ [req#%li] %@ canceled  --------------",prefix,(long)self.countURL,(self.webViewRefreshing)?@"Refresh":@"Load");
		}
	}
	self.webTitle = title;
	self.webViewController.title = self.webTitle;

	//===============
	if ([self.delegate respondsToSelector:@selector(apiWeb:running:)]) {
		[self.delegate apiWeb:apiWebSelf	running:YES];
	}
	self.callBackHost = callBack;
	self.startingURL = [NSURL URLWithString:callURL];
	self.countURL = -1;
	self.webConnection = nil;
	[self.webLoads removeAllObjects];

#if USE_COOKIES
	NSString * host = self.startingURL.host;
	NSArray * parts = [host componentsSeparatedByString:@"."];
	if (parts.count > 1) {
		host = [NSString stringWithFormat:@"%@.%@",[parts objectAtIndex:parts.count-2],[parts objectAtIndex:parts.count-1]];
	}
	//Delete ALL WebView Cookies - Always launch with a Clean Slate!
	NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
	for (NSInteger x=cookies.count-1; x>=0;x--) {
		NSHTTPCookie * cookie = [cookies objectAtIndex:x];
//		NSRange match = [cookie.domain rangeOfString:host];
//		if ((match.location==NSNotFound)&&(match.length==0)) {
			NSLog(@"%@ ==D#%li (%@) %@",prefix,(long)cookies.count-x,cookie.domain,cookie.name);
			[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
//		}
	}
	self.webCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
#endif

	self.inactive = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResign:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResume:) name:UIApplicationDidBecomeActiveNotification object:nil];
#if USE_COOKIES
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCookie:) name:NSHTTPCookieManagerCookiesChangedNotification object:nil];
#endif
	self.loadedHost = [self.startingURL host];
	
	self.webConnection = nil;
	//Do Clean Lauch outside of Gateway Context
	[self performSelector:@selector(launchWeb) withObject:nil afterDelay:0.0];
	return;
}
-(void)launchWeb {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:self.startingURL];
	[request setHTTPShouldHandleCookies:YES];
//	[request setValue:@"Foobar/1.0" forHTTPHeaderField:@"User-Agent"];
#if USE_COOKIES
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
#endif
	[self.webView loadRequest:request];	//Fire up starting URL
}
//--------------------------
//Here on ERROR or SUCCESSFULL CALLBACK
//--------------------------
- (void)stopWebView {
	if (self.webView==nil)
		return;
	NETACT_OFF;
	if (self.webView.loading) {
		[self.webView stopLoading];
		NSLog(@"%@ [req#%li] %@ CANCELED  --------------",prefix,(long)self.countURL,(self.webViewRefreshing)?@"Refresh":@"Load");
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
#if USE_COOKIES
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSHTTPCookieManagerCookiesChangedNotification object:nil];
#endif
	
	[self.webView removeFromSuperview];
	[self.webView release];
	self.webView = nil;
	[self.backView removeFromSuperview];
	[self.backView release];
	self.backView = nil;
	self.webViewController.title = self.savedTitle;
	self.webViewController.navigationController.navigationBar.alpha = self.savedAlpha;
	if (self.webConnection!=nil) {
		[self.webConnection cancel];
		self.webConnection = nil;
	}

	if ([self.delegate respondsToSelector:@selector(apiWeb:running:)]) {
		[self.delegate apiWeb:apiWebSelf running:NO];
	}
	NSLog(@"%@ ====== view STOPPED =============================================================\n ",prefix);
}

//-------------------------------
//HERE on ROTATION
//-------------------------------
-(void)willRefreshWebView {
	self.backView.hidden = YES;
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		self.webViewController.navigationController.navigationBar.alpha = self.savedAlpha;
	}
}
- (void)didRefreshWebView {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshWebView) object:nil];
	if (self.webView==nil)
		return;
	if (self.webView.loading) {
		[self.webView stopLoading];
		[self performSelector:@selector(didRefreshWebView) withObject:nil afterDelay:0.1];
		return;
	}
	self.webViewRefreshing = YES;

	[self fixWebFrames];
	[self.webView reload];
	return;
}


//-------------------------------
//HERE on NOTIFICATION
//-------------------------------
- (void)willResign:(NSNotification *)notification {
	if (!self.inactive) {
//		NSLog(@"%@<:-- *Inactive*",prefix);
		self.inactive = YES;
	}
	else { //SPLITVIEW SENDS TWICE!
//		NSLog(@"%@<:-- (Inactive)",prefix);
	}
}
- (void)willResume:(NSNotification *)notification {
	if (self.inactive) {
//		NSLog(@"%@<:++ *Active*",prefix);
		self.inactive = NO;			//Set the FLAG
	}
	else { //SPLITVIEW SENDS TWICE!
//		NSLog(@"%@<:++ (Active)",prefix);
	}
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		if (self.webView!=nil) {
			[self performSelector:@selector(didRefreshWebView) withObject:nil afterDelay:0.1];
		}
	}
}


#if USE_COOKIES
- (void)newCookie:(NSNotification *)notification {
	NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
//	NSLog(@"%@ [Cookie] Changed! =================> Total=%i",prefix,cookies.count);
#if 1//USE_COOKIES
	for (NSHTTPCookie * newCookie in cookies) {
//		NSLog(@"%@ ==Q %@=(%@)",prefix,newCookie.name,newCookie.value);
		BOOL match = NO;
		if (self.webCookies!=nil) {
			for (NSHTTPCookie * oldCookie in self.webCookies) {
				if ([newCookie.name isEqualToString:oldCookie.name]) {
					match = YES;
					NSString * oldStuff = [NSString stringWithFormat:@"%@",oldCookie.properties];	//Full NSDICTIONARY of all fields
					NSString * newStuff = [NSString stringWithFormat:@"%@",newCookie.properties];	//Full NSDICTIONARY of all fields
					if (![oldCookie.value isEqualToString:newCookie.value]) {
						NSLog(@"%@ [Cookie] UpdateV <%@> ",prefix,newCookie.name);
					}
					else if (![[oldCookie.properties objectForKey:@"Created"] isEqualToNumber:[newCookie.properties objectForKey:@"Created"]]) {
//						NSLog(@"%@ [Cookie] UpdateC <%@> ",prefix,newCookie.name);
					}
					else if (![oldCookie.expiresDate isEqualToDate:newCookie.expiresDate]) {
//						NSLog(@"%@ [Cookie] UpdateX <%@> ",prefix,newCookie.name);
					}
					else if (![oldStuff isEqualToString:newStuff]) {
						NSLog(@"%@ [Cookie] UpdateP <%@> \nOLD=%@\nNEW=%@\n ",prefix,newCookie.name,oldStuff,newStuff);
					}
					break;
				}
			}
		}
		if (!match) {
			NSLog(@"%@ [Cookie] +Added+ <%@> {%@}",prefix,newCookie.name,newCookie.domain);
		}
	}
	for (NSHTTPCookie * oldCookie in self.webCookies) {
		BOOL match = NO;
		for (NSHTTPCookie * newCookie in cookies) {
			if ([newCookie.name isEqualToString:oldCookie.name]) {
				match = YES;
				break;
			}
		}
		if (!match) {
			NSLog(@"%@ [Cookie] -Deleted <%@> {%@}",prefix,oldCookie.name,oldCookie.domain);
		}
	}
	self.webCookies = cookies;
//	for (NSInteger x=cookies.count-1; x>=0;x--) {
//		NSHTTPCookie * cookie = [cookies objectAtIndex:x];
//		NSLog(@"%@ ==X#%i (%@) %@=(%i)",prefix,cookies.count-x,cookie.domain,cookie.name,cookie.value.length);
//	}
#endif

}
#endif

-(void)makeIdle {
	self.backView.backgroundColor = [UIColor BACKVIEW_IDLE];
	self.webViewController.title = self.webTitle;
}
-(void)makeError:(NSString *)title {
	self.backView.backgroundColor = [UIColor BACKVIEW_ERROR];
	if (title!=nil)
		self.webViewController.title = title;
}
-(void)makeRed:(NSString *)title {
	[self makeError:title];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(unred) object:nil];
	[self performSelector:@selector(unred) withObject:nil afterDelay:1.0];
}
-(void)unred {
	if (self.backView.backgroundColor == [UIColor BACKVIEW_ERROR]) {
		[self makeIdle];
	}
}
-(void)makeLoad {
	self.backView.backgroundColor = [UIColor BACKVIEW_LOAD];
}




//-------------------------------
// DELEGATE: Requesting permission to LOAD a URL
//-------------------------------

- (BOOL)webView:(UIWebView *)webview shouldStartLoadWithRequest:(NSURLRequest *)requestx navigationType:(UIWebViewNavigationType)navigationType {
//	NSURLRequest * request = requestx;
	NSURLRequest * request = [requestx copy];

	NSString * scheme = [[request.URL scheme] lowercaseString];
	NSString * host = [[request.URL host] lowercaseString];
	NSNumber * port = [request.URL port];
	if (port!=nil)
		host = [NSString stringWithFormat:@"%@:%@",host,port];
	if (!self.webView.loading) //not a redirect...
		self.countURL++;
	NSLog(@"%@ [req#%li] <= *NEW* callback=\"%@\" host=\"%@\" type=%li %@",prefix,(long)self.countURL,self.callBackHost,host,(long)navigationType,(self.webView.loading)?@"*REDIRECT*":@"idle");

	if (([self.callBackHost isEqualToString:host])&&(self.countURL>0)) {
		//UIWebViewNavigationTypeOther
		NSLog(@"%@ [req#%li] CallBack! URL=\n=> %@\n ",prefix,(long)self.countURL,request.URL);
		if (self.webConnection!=nil) {
			[self.webConnection cancel];
			self.webConnection = nil;
		}
		[self stopWebView];
		if ([self.delegate respondsToSelector:@selector(apiWeb:gotReturnURL:)]) {
			[self.delegate apiWeb:apiWebSelf gotReturnURL:request.URL];
		}
		return NO;
	}

#if 0//USE_COOKIES
	//Report COOKIES relevant to REQUEST
	NSArray * cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
	for (NSInteger x=cookies.count-1; x>=0;x--) {
		NSHTTPCookie * cookie = [cookies objectAtIndex:x];
//		NSLog(@"%@ ==C#%i (%@) %@=\"%@\"",prefix,cookies.count-x,cookie.domain,cookie.name,cookie.value);
		NSLog(@"%@ ==C#%i (%@) %@=(%i)",prefix,cookies.count-x,cookie.domain,cookie.name,cookie.value.length);
	}
#endif

	//UIWebViewNavigationTypeFormSubmitted = 1
	//UIWebViewNavigationTypeOther = 5 (Launch/redirect)
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		if ([self.delegate respondsToSelector:@selector(apiWeb:approveClickURL:)]) {
			if (![self.delegate apiWeb:apiWebSelf approveClickURL:request.URL]) {
				NSLog(@"%@ [req#%li] Click Reject! URL=(%@ %@)\n=> %@\n ",prefix,(long)self.countURL,[request.URL host],self.loadedHost,request.URL);
				[self makeRed:@"*Click Rejected*"];
				return NO;
			}
		}
	}
	else if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {

		if (![[request.URL host] isEqualToString:self.loadedHost]) {
			NSRange range = [[request.URL host] rangeOfString:self.loadedHost];
			if (range.length == 0) {
				//not xxx.att.com
				if ([self.delegate respondsToSelector:@selector(apiWeb:approveClickURL:)]) {
					if (![self.delegate apiWeb:apiWebSelf approveClickURL:request.URL]) {
						NSLog(@"%@ [req#%li] REJECT-SITE! URL=(%@ %@)\n=> %@\n ",prefix,(long)self.countURL,[request.URL host],self.loadedHost,request.URL);
						[self makeRed:@"*Site Rejected*"];
						return NO;
					}
				}
				else {
					NSLog(@"%@ [req#%li] OFF-SITE! URL=(%@ %@)\n=> %@\n ",prefix,(long)self.countURL,[request.URL host],self.loadedHost,request.URL);
					[self makeRed:@"*Site Blocked*"];
					return NO;
				}
			}
		}
	}
	else if ([scheme isEqualToString:@"about"]) {
		NSLog(@"%@ [req#%li] About! scheme=(%@)=> %@ ",prefix,(long)self.countURL,scheme,request.URL);
		//let it through.  Google finished with redirects.... This starts WEB display for past redirects...
//		request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestx.URL.absoluteString]];
		return NO;	//no reason to do a GET
	}
	else {
		NSLog(@"%@ [req#%li] ?Invalid scheme=(%@)\n=> %@\n ",prefix,(long)self.countURL,scheme,request.URL);
		[self makeRed:@"*LINK Invalid*"];
		return NO;
	}

	//UIWebViewNavigationTypeFormSubmitted = 1
	//UIWebViewNavigationTypeOther = 5 (Launch/redirect)
	if (self.webConnection!=nil)
		[self.webConnection cancel];
	self.webConnection = [NSURLConnection connectionWithRequest:request delegate:self];
	NSLog(@"%@ [req#%li] OK=> %@ URL=\n=> %@\n ",prefix,(long)self.countURL,(navigationType==UIWebViewNavigationTypeFormSubmitted)?@"Submit":@"Request",request.URL);
//	[self.webLoads addObject:[NSString stringWithString:request.URL.absoluteString]];
	return YES;
}




//========================================================================================
#pragma mark - Load HTML Content
//========================================================================================

// request => Loading => (redirect) => (redirect) => status 200 => (redirect) => LoadCompleted

-(NSInteger)findURLrequest:(NSString *)URL {
	for (NSInteger x=0; x<self.webLoads.count; x++) {
		NSString * xURL = [self.webLoads objectAtIndex:x];
		if ([xURL isEqualToString:URL]) {
//			NSLog(@"%@ ** YES! (%li) <%@>",prefix,(long)x,URL);
			return x;
		}
	}
	NSLog(@"%@ ** NOPE (%li) <%@>",prefix,(long)self.webLoads.count,URL);
	return -1;
}


//-------------------------------
// DELEGATE: LOAD HTML Starting (waiting for status)
//-------------------------------
- (void)webViewDidStartLoad:(UIWebView *)webview {
	NETACT_ON;
	[self makeLoad];
//	NOTE this indication of STARTUP, so webview copy has NOT been loaded yet.
//	NSString * url = webView.request.URL.absoluteString;
	NSLog(@"%@ [req#%li] <= %@ Waiting for status ...",prefix,(long)self.countURL,(self.webViewRefreshing)?@"Refresh":@"Load");
	return;
}

//-------------------------------
// DELEGATE: HOST RETURNED STATUS - loading HTML will start
//-------------------------------
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	self.responseStatus = [httpResponse statusCode];
	NSString * url= self.webConnection.currentRequest.URL.absoluteString;
	NSInteger x = self.webLoads.count;//[self findURLrequest:url];
	[self.webLoads addObject:url];
	NSLog(@"%@ [req#%li:%li] <= STATUS %li: %@",prefix,(long)self.countURL,(long)x,(long)self.responseStatus,[NSString stringWithString:[NSHTTPURLResponse localizedStringForStatusCode:self.responseStatus]]);

	if ((self.responseStatus!=HTTP_200)&&(self.responseStatus!=HTTP_NONE)) {
		[self makeError:[NSString stringWithFormat:@"?%li: %@",(long)self.responseStatus,[NSHTTPURLResponse localizedStringForStatusCode:self.responseStatus]]];
	}
//	[connection cancel];
//	self.webConnection = nil;
	if ([self.delegate respondsToSelector:@selector(apiWeb:gotHttpStatus:)]) {
		[self.delegate apiWeb:apiWebSelf gotHttpStatus:self.responseStatus];
	}
}

//-------------------------------
// DELEGATE: LOAD HTML Successful and completed
//-------------------------------
- (void)webViewDidFinishLoad:(UIWebView *)webview {
	NSInteger x = [self findURLrequest:webView.request.URL.absoluteString];
	if (x>=0)
		[self.webLoads replaceObjectAtIndex:x withObject:@"ok:"];
	NSLog(@"%@ [req#%li:%li] <= %@ FINISHED  --------------",prefix,(long)self.countURL,(long)x,(self.webViewRefreshing)?@"Refresh":@"Load");
	[self.webConnection cancel];
	self.webConnection = nil;

	NETACT_OFF;
	if ((self.responseStatus==HTTP_200)||(self.responseStatus==HTTP_NONE)) {
		[self makeIdle];
	}
	if (self.webViewRefreshing) {
		self.webViewRefreshing = NO;
		self.backView.hidden = NO;
	}
	return;
}

//-------------------------------
// DELEGATE: LOAD HTML Failed (after a START)
// Unsupported html?
//-------------------------------
- (void)webView:(UIWebView *)webview didFailLoadWithError:(NSError *)error {
	NSInteger x = [self findURLrequest:webView.request.URL.absoluteString];
	if (x>=0)
	[self.webLoads replaceObjectAtIndex:x withObject:@"err:"];
	NSLog(@"%@ [req#%li:%li] <= ?Load ERROR %li =%@",prefix,(long)self.countURL,(long)x,(long)[error code],[error localizedDescription]);

	//-999 STOP LOADING
	if ([error code]==-999) {
		return;	//ignore
	}
	//101 Not displayable URL
	if ([error code]==101) {
		return;	//ignore
	}
//	NSLog(@"%@ [req#%li:%li] ?Load ERROR %li =%@",prefix,(long)self.countURL,(long)x,(long)[error code],[error localizedDescription]);
	[self makeRed:[error localizedDescription]];
	[self stopWebView];
	if ([self.delegate respondsToSelector:@selector(apiWeb:gotError:)]) {
		[self.delegate apiWeb:apiWebSelf gotError:error];
	}
	return;
}


@end
