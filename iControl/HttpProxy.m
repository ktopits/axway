/**************************************************************/
/* ktopits -                                                  */
/* HttpProxy.m                                                */
/* KT 03-JUL-2014                                             */
/**************************************************************/

#define NETACT_ON     [UIApplication sharedApplication].networkActivityIndicatorVisible = YES
#define NETACT_OFF     [UIApplication sharedApplication].networkActivityIndicatorVisible = NO

#import "HttpProxy.h"

#pragma mark - Private Connection Structure
//================
@interface ICNPostreq: NSObject {
#if 0
	NSInteger             seq;			//assigned SEQ number
	NSMutableURLRequest * request;		//URL request
	NSURLConnection     * connection;	//connection
	NSDate              * time;			//Time Connection Started (get Issued)
	BOOL                  authorized;	//This request requires authorization

	NSInteger             code;			//error code or 0
	NSInteger             status;		//HTTP status or 0
	NSInteger             expect;		//data length expected
	NSMutableData       * data;			//response data
#endif
}
@property (nonatomic,assign) id xdelegate;
@property (nonatomic        ) NSInteger seq;
@property (nonatomic, retain) NSMutableURLRequest * request;
@property (nonatomic, retain) NSURLConnection * connection;
@property (nonatomic, retain) NSDate * time;;
@property (nonatomic        ) BOOL authorized;

@property (nonatomic        ) NSInteger code;
@property (nonatomic        ) NSInteger status;
@property (nonatomic        ) NSInteger expect;
@property (nonatomic, retain) NSMutableData * data;
@end

@implementation ICNPostreq
@synthesize xdelegate;
@synthesize seq;
@synthesize request;
@synthesize connection;
@synthesize time;
@synthesize authorized;

@synthesize code;
@synthesize status;
@synthesize expect;
@synthesize data;
@end
//================


//==========================================================================
#pragma mark - SESSION Init, Dealloc
//==========================================================================

@implementation HttpProxy

@synthesize delegate;
@synthesize URLcounter;
@synthesize URLarray;
@synthesize URLerror;
@synthesize deviceName;
@synthesize authTitle;
@synthesize authModePrefix;
@synthesize trustedHosts;
@synthesize myAlertView;
@synthesize alert_field0;
@synthesize alert_field1;
@synthesize save_username;
@synthesize save_password;
@synthesize URLchallenge;

static NSString * prefix = @"--[prx]  ";


HttpProxy * httpProxySelf = nil;				//Context Definition is here!

//*******************************************
// Here when Application is created (FROM MAIN THREAD)
//*******************************************
+ (HttpProxy *)shared {
	return httpProxySelf;
}

//*******************************************
// Here when WirelessBlueController is created (FROM MAIN THREAD)
//*******************************************
- (id) init {
	self = [super init];		//create my context (so caller did not have to
//	NSLog(@"%@--- init self=%p",prefix,self);
	httpProxySelf = [self retain];
	if (self) {
		self.delegate = nil;
		self.URLcounter = 0;
		self.authModePrefix = nil;
		self.URLarray = [[NSMutableArray alloc]init];
		self.deviceName = [NSString stringWithString:[UIDevice currentDevice].name];
		self.trustedHosts = [[NSMutableArray alloc]init];
		[self.trustedHosts addObject:@"localhost"];		//NO scheme, NO port
	}
	return self;
}

//*******************************************
// Here when WirelessBlueController is released
//*******************************************
- (void) dealloc
{
 	NSLog(@"%@--- dealloc",prefix);
	[self.URLarray release];
	[self release];
	httpProxySelf = nil;
    [super dealloc];
}

-(void)authWithURL:(NSString *)prefix {
	self.authModePrefix = prefix;
}
-(void)authWithTitle:(NSString *)title {
	self.authTitle = title;
}



//==========================================================================
#pragma mark - GET and POST Requests
//==========================================================================
#define GPR_GET			@"GET"
#define GPR_POST		@"POST"

//Request headers
#define GPR_NAME		  @"user_id"
#define GPR_CACHE         @"bypass-cache"
#define GPR_AUTHORIZATION @"Authorization"
#define GPR_V_BEARER	  @"Bearer %@"

//Generic request/response headers
#define GPR_ACCEPT   	  @"Accept"
#define GPR_CONTENTTYPE	  @"Content-Type"
#define GPR_V_XML         @"application/xml"
#define GPR_V_JSON        @"application/json"
#define GPR_V_ENCODE      @"application/x-www-form-urlencoded"
#define GPR_CONTENTLENGTH @"Content-Length"

//Generic response headers
#define GPR_DATE          @"Date"
#define GPR_SERVER        @"Server"
//Apigee GW response Headers (Custom)
#define GPR_APG_TOTALMS   @"X-time-total-elapsed"
#define GPR_APG_TARGETMS  @"X-time-target-elapsed"
//Mashery GW response Headers
#define GPR_MASHERY       @"X-Mashery-Responder"
#define GPR_MASHERY_ERR   @"X-Mashery-Error-Code"
//Oauth Server response Headers
#define GPR_WWW_AUTH      @"WWW-Authenticate"


-(NSInteger)get:(NSString *)server request:(NSString *)urx {
	return [self get:server request:urx delegate:self.delegate];
}
-(NSInteger)get:(NSString *)server request:(NSString *)urx delegate:(id)xdelegate {
	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",server,(urx==nil)?@"":urx]];

	NSMutableURLRequest * myRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
	[myRequest setHTTPMethod:GPR_GET];
	
	return [self startupConnectionWithRequest:myRequest authorized:NO delegate:xdelegate];
}


-(NSInteger)getAuthorized:(NSString *)server request:(NSString *)urx bearer:(NSString *)token {
	return [self getAuthorized:server request:urx bearer:token delegate:self.delegate];
}
-(NSInteger)getAuthorized:(NSString *)server request:(NSString *)urx bearer:(NSString *)token delegate:(id)xdelegate {
	NSMutableURLRequest * myRequest;
	NSURL * url;
	NSString * baseURL = [NSString stringWithFormat:@"%@%@",server,(urx==nil)?@"":urx];
	if (self.authModePrefix!=nil) {
		if ((token!=nil)&&(token.length>0)) {
			baseURL = [NSString stringWithFormat:@"%@%@%@",baseURL,self.authModePrefix,token];
		}
		url = [NSURL URLWithString:baseURL];
		myRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
	}
	else {
		url = [NSURL URLWithString:baseURL];
		myRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30.0];
		
		if ((token!=nil)&&(token.length>0)) {
			[myRequest setValue:[NSString stringWithFormat:GPR_V_BEARER, token] forHTTPHeaderField:GPR_AUTHORIZATION];
		}
		[myRequest setValue:GPR_V_JSON forHTTPHeaderField:GPR_CONTENTTYPE];
	}
	[myRequest setHTTPMethod:GPR_GET];
	return [self startupConnectionWithRequest:myRequest authorized:YES delegate:xdelegate];
}

-(NSInteger)getAuthorizedPoll:(NSString *)server request:(NSString *)urx bearer:(NSString *)token delegate:(id)xdelegate {
	NSMutableURLRequest * myRequest;
	NSURL * url;
	NSString * baseURL = [NSString stringWithFormat:@"%@%@",server,(urx==nil)?@"":urx];
	if (self.authModePrefix!=nil) {
		if ((token!=nil)&&(token.length>0)) {
			baseURL = [NSString stringWithFormat:@"%@%@%@",baseURL,self.authModePrefix,token];
		}
		url = [NSURL URLWithString:baseURL];
		myRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:120.0];
	}
	else {
		url = [NSURL URLWithString:baseURL];
		myRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:120.0];
		
		if ((token!=nil)&&(token.length>0)) {
			[myRequest setValue:[NSString stringWithFormat:GPR_V_BEARER, token] forHTTPHeaderField:GPR_AUTHORIZATION];
		}
		[myRequest setValue:GPR_V_JSON forHTTPHeaderField:GPR_CONTENTTYPE];
	}
	[myRequest setHTTPMethod:GPR_GET];
	NSInteger ret = [self startupConnectionWithRequest:myRequest authorized:YES delegate:xdelegate];
	NETACT_OFF;
	return ret;
}


//POST with BODY, UNAUTHORIZED
-(NSInteger)post:(NSString *)server request:(NSString *)urx body:(NSString *)postBody {
	return [self post:server request:urx body:postBody bearer:nil delegate:self.delegate];
}
//POST with BODY, AUTHORIZED
-(NSInteger)postBody:(NSString *)server request:(NSString *)urx body:(NSString *)postBody bearer:(NSString *)token {
	return [self post:server request:urx body:postBody bearer:token delegate:self.delegate];
}
-(NSInteger)post:(NSString *)server request:(NSString *)urx body:(NSString *)postBody bearer:(NSString *)token delegate:(id)xdelegate {

	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",server,(urx==nil)?@"":urx]];

	NSMutableURLRequest * myRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:20.0];
	[myRequest setHTTPMethod:GPR_POST];		//Default method is "GET"
	
    NSString * bodyData = [NSString stringWithString:postBody];
	NSLog(@"%@[POST] (len=%lu)=\n%@\n",prefix,(unsigned long)bodyData.length,bodyData);
	[myRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:[bodyData length]]];

	BOOL authorized = NO;
	if ((token!=nil)&&(token.length>0)) {
		[myRequest setValue:[NSString stringWithFormat:GPR_V_BEARER, token] forHTTPHeaderField:GPR_AUTHORIZATION];
		authorized = YES;
		[myRequest setValue:GPR_V_XML forHTTPHeaderField:GPR_CONTENTTYPE];
	}
	else {
		[myRequest setValue:GPR_V_ENCODE forHTTPHeaderField:GPR_CONTENTTYPE];
	}

	[myRequest setValue:GPR_V_JSON forHTTPHeaderField:GPR_ACCEPT];
	return [self startupConnectionWithRequest:myRequest authorized:authorized delegate:xdelegate];
}

//POST with NO BODY, AUTHORIZED
-(NSInteger)postAuthorized:(NSString *)server request:(NSString *)urx bearer:(NSString *)token {
	return [self postAuthorized:server request:urx bearer:token delegate:self.delegate];
}
-(NSInteger)postAuthorized:(NSString *)server request:(NSString *)urx bearer:(NSString *)token delegate:(id)xdelegate {

	NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",server,(urx==nil)?@"":urx]];

	NSMutableURLRequest * myRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:20.0];
	[myRequest setHTTPMethod:GPR_POST];		//Default method is "GET"

	if ((token!=nil)&&(token.length>0)) {
		[myRequest setValue:[NSString stringWithFormat:GPR_V_BEARER, token] forHTTPHeaderField:GPR_AUTHORIZATION];
	}

	[myRequest setValue:GPR_V_JSON forHTTPHeaderField:GPR_CONTENTTYPE];
	return [self startupConnectionWithRequest:myRequest authorized:YES delegate:xdelegate];
}



//-(NSInteger)startupConnectionWithRequest:(NSMutableURLRequest *)myRequest authorized:(BOOL)auth {
//	return [self startupConnectionWithRequest:myRequest authorized:auth delegate:self.delegate];
//}
-(NSInteger)startupConnectionWithRequest:(NSMutableURLRequest *)myRequest authorized:(BOOL)auth  delegate:(id)xdelegate {
#if 0
	[myRequest setValue:self.deviceName forHTTPHeaderField:GPR_NAME];
#endif
	NETACT_ON;
	NSURLConnection * myConnection = [[NSURLConnection alloc] initWithRequest:myRequest delegate:self];
	if (myConnection==nil)  {
		NETACT_OFF;
		NSLog(@"%@[HTTP] ?could not connect with: %@",prefix,myRequest.URL);
		self.URLerror = @"?Connection Failed";
        return 0;
	}
	ICNPostreq * postreq = [ICNPostreq alloc];
	postreq.xdelegate = xdelegate;
	postreq.seq = ++self.URLcounter;
	postreq.data = [[NSMutableData data] retain];
	postreq.status = HTTP_NONE;
	postreq.code = 0;
	postreq.time = [NSDate date];
	postreq.request = myRequest;
	postreq.expect = 0;
	postreq.authorized = auth;
	postreq.connection = myConnection;
	[self.URLarray addObject:postreq];
	self.URLerror = nil;
	return postreq.seq;
}

-(ICNPostreq *)findReqForConneciton:(NSURLConnection *)connection remove:(BOOL)remove {
	for (NSInteger x=0; x<self.URLarray.count; x++) {
		ICNPostreq * req = [self.URLarray objectAtIndex:x];
		if (req.connection == connection) {
			if (remove)
				[self.URLarray removeObjectAtIndex:x];
			return req;
		}
	}
	return nil;
}

-(void)httpFailed:(NSURL *)url {
	NSLog(@"%@[http#%li] ?could not connect with: %@",prefix,(long)self.URLcounter,url);
	self.URLerror = @"?Connection Failed";
}

//Here is REQUEST was sent, AND and RESPONSE was received
-(void)httpCompleted:(ICNPostreq *)req {
	NSDate * now = [NSDate date];
	NETACT_OFF;
	float diff = [now timeIntervalSinceDate:req.time];
	NSLog(@"%@[http#%li] *Done*  (%4.3f sec)",prefix,(long)req.seq,diff);
	if ([req.xdelegate respondsToSelector:@selector(httpProxy:seq:code:response:time:)]) {
		[req.xdelegate httpProxy:self seq:req.seq code:req.status response:[[NSString alloc] initWithData:req.data encoding:NSASCIIStringEncoding] time:diff];
	}
	[req.data release];
	[req.connection release];
	[req.request release];
}



//==========================================================================
#pragma mark - URL Delegate
//==========================================================================

//--------
//Delegate - POST (there are 2, one is PRIOR to auth, the other is AFTER auth
//--------
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	ICNPostreq * req = [self findReqForConneciton:connection remove:NO];
	if (req==nil)
		return;
	NSString * http = [NSString stringWithFormat: @"%@[http#%li] ",prefix,(long)req.seq];

	NSLog(@"%@<= POST body=%li (Total=%li/%li)",http,(long)bytesWritten,(long)totalBytesWritten,(long)totalBytesExpectedToWrite);
}


//--------
//Delegate - REQUEST Terminated with ERROR - No CONNECTION to URI (bad DNS, no such server, no response, no network)
//--------
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	ICNPostreq * req = [self findReqForConneciton:connection remove:YES];
	if (req==nil)
		return;
	NSString * http = [NSString stringWithFormat: @"%@[http#%li] ",prefix,(long)req.seq];
    
	if ([error code]==-1001) {			//Request Timeout (60 seconds)
		NSLog(@"%@?TMO %ld:\"%@\"",http,(long)[error code], [error localizedDescription]);
	}
	else if ([error code]==-1002) {		//Unsupported URL - aka out-of-scope
		NSLog(@"%@?URL %ld:\"%@\" \n=> %@",http,(long)[error code],[error localizedDescription],req.request.URL);
	}
	else if ([error code]==-1009) {		//Internet OFF-Line
		NSLog(@"%@?NET %ld:\"%@\"",http,(long)[error code],[error localizedDescription]);
	}
	else if ([error code]==-1003) {		//No server with Specified Host Name (DNS offline)
		NSLog(@"%@?DNS %ld:\"%@\"",http,(long)[error code],[error localizedDescription]);
	}
	else if ([error code]==-1012) {		//Authentication Canceled (see below)
		NSLog(@"%@?ATH %ld:\"%@\"",http,(long)[error code],[error localizedDescription]);
	}
	else if ([error code]==-1200) {		//SSL Handshake Failed (Firewall or WEB authentication Intenet)
		NSLog(@"%@?SSL %ld:\"%@\"",http,(long)[error code],[error localizedDescription]);
	}
	else if ([error code]==-1202) {		//SSL Certificate signature is invalid
		NSLog(@"%@?SSL %ld:\"%@\"",http,(long)[error code],[error localizedDescription]);
	}
	else {
		NSLog(@"%@?ERR %ld:\"%@\"",http,(long)[error code], [error localizedDescription]);
	}
	self.URLerror = [NSString stringWithString:[error localizedDescription]];
	if ([error code]<HTTP_NONE)
		req.status = [error code];
	else
		req.status = HTTP_9999;
    [self httpCompleted:req];
}

//--------
//Delegate - Connection to URL
//  "request" is a NEW non-mutable request header for redirect
//--------
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
	ICNPostreq * req = [self findReqForConneciton:connection remove:NO];
	if (req==nil)
		return request;
	NSString * http = [NSString stringWithFormat: @"%@[http#%li] ",prefix,(long)req.seq];

	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	NSInteger statusCode = [httpResponse statusCode];

	//Redirect to SECONDARY URL
	if (response && ((statusCode >= HTTP_300) && (statusCode <= HTTP_399))) {
		[req.data setLength:0];
        //Automatically perform redirection
		NSLog(@"%@%@<= re-directing (%li) to \n=> %@",http,([req.request valueForHTTPHeaderField:GPR_AUTHORIZATION]!=nil)?@"$ ":@"",(long)statusCode,[request URL]);
		req.request.URL = [request URL];
        return req.request;
	}
    //Direct to PRIMARY URL
	NSLog(@"%@%@<= directing (%li) to \n=> %@",http,([request valueForHTTPHeaderField:GPR_AUTHORIZATION]!=nil)?@"$ ":@"",(long)statusCode,[request URL]);
	return request;
}

//--------
//Delegate - POST delivered to URI and HTTP response obtained
//--------
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	ICNPostreq * req = [self findReqForConneciton:connection remove:NO];
	if (req==nil)
		return;
	
	NSDictionary * headers = [(NSHTTPURLResponse *)response allHeaderFields];
	NSString * http = [NSString stringWithFormat: @"%@[http#%li] ",prefix,(long)req.seq];
	NSString * length = [headers objectForKey:GPR_CONTENTLENGTH];
	req.expect = (length==nil)?0:[length intValue];
//	NSLog(@"%@ %@ = %i",http,GPR_CONTENTLENGTH,req.expect);	//Data that will be SENT

	NSString * agw = @"";

#if 0 //Look for CUSTOMER headers
	//Apigee Gateway Specific
	NSString * xtime = [headers objectForKey:GPR_APG_TOTALMS];		//milli-seconds client -> service -> client;
	NSString * dtime = [headers objectForKey:GPR_APG_TARGETMS];		//milli-seconds    agw -> serivce -> agw;
	float xmilli = (xtime==nil)?0.0:[xtime floatValue]/1000.0;
	float dmilli = (dtime==nil)?0.0:[dtime floatValue]/1000.0;
	if ((dtime!=nil)||(xtime!=nil))
		agw = [NSString stringWithFormat:@" (AGW: %2.3F - %2.3f = %2.3f)",xmilli, dmilli, xmilli-dmilli];
//	NSEnumerator *enumerator = [headers keyEnumerator];
//	id key;
//	while ((key = [enumerator nextObject])) {
//		NSLog(@"%@=> Header %@=\"%@\"",prefix,key,[headers valueForKey:key]);
//	}
	
	NSString * xmashgw = [headers objectForKey:GPR_MASHERY];	//not added/replaced in APIGEE GW
	if (xmashgw==nil)
		xmashgw = [headers objectForKey:GPR_SERVER];	//not added/replaced in APIGEE GW
	if (xmashgw!=nil)
		agw = [agw stringByAppendingFormat:@" <%@>",xmashgw];
	xmashgw = [headers objectForKey:GPR_MASHERY_ERR];
	if (xmashgw!=nil)
		agw = [agw stringByAppendingFormat:@" <MGW? %@>",xmashgw];
	NSString * wwwauth = [headers objectForKey:GPR_WWW_AUTH];
	if (wwwauth!=nil)
		agw = [agw stringByAppendingFormat:@" {%@}",wwwauth];
#endif

	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	req.status = [httpResponse statusCode];
	self.URLerror = [NSString stringWithString:[NSHTTPURLResponse localizedStringForStatusCode:req.status]];
	NSString * label = @"???";
	
	if (req.status == HTTP_200) {	//200 is All OK with CONTENT
		label=@"OK";
	}
	else if (req.status == HTTP_201) {	//201 is All OK
		label=@"OK-1";
	}
	else if (req.status == HTTP_202) {	//202 is All OK
		label=@"OK-2";
	}
	else if (req.status == HTTP_203) {	//203 is All OK
		label=@"OK-3";
	}
	else if (req.status == HTTP_204) {	//204 is All OK
		label=@"OK-4";
	}
	else if (req.status == HTTP_404) {	//(#1) Invalid or Unrecognized URL path or API not enabled
		label=@"?PATH";
	}
	else if (req.status == HTTP_401) {	//(#2) Unauthorized (invalid username/password)
		label=@"?UNAUTHORIZED";
	}
	else if (req.status == HTTP_400) {	//(#3) Bad request/parameter
		label=@"?PARAMETER";
	}
	else if (req.status == HTTP_403) {	//Valid Path, but no default page
		label=@"?FORBIDDEN";
	}
	else if (req.status == HTTP_302) {	//redirect to
		label=@"!ReDirect";
	}
	else if (req.status == HTTP_502) {	//no network (GW to internet service)
		label=@"?GW2Network";
	}
	else {
		label=@"?FAIL";
	}
	NSLog(@"%@<= %@ %ld:\"%@\"%@",http,label,(long)req.status,self.URLerror,agw);
}

//--------
//Delegate - HTTP request delivered.  Host is sending back data (one or more)
//--------
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	ICNPostreq * req = [self findReqForConneciton:connection remove:NO];
	if (req==nil)
		return;

	[req.data appendData:data];
#if 0
	NSString * http = [NSString stringWithFormat: @"%@[http#%i] ",prefix,req.seq];
	NSLog(@"%@<= rcv:%i {length=%i/%i}",http,[data length],[req.data length],req.expect);
	if ((req.status!=HTTP_NONE)) {
		NSString * foo = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		NSLog(@"%@\n#~~~~~~~~~~~~~~~~~~~#\n%@\n#~~~~~~~~~~~~~~~~~~~#",http,foo);
	}
#endif
}

//--------
//Delegate - HTTP request is completed and DONE.
//--------
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	ICNPostreq * req = [self findReqForConneciton:connection remove:YES];
	if (req==nil)
		return;
	NSString * http = [NSString stringWithFormat: @"%@[http#%li] ",prefix,(long)req.seq];

//	[connection release];
//	self.myPostConnection = nil;
	NSLog(@"%@<= finished! {length=%lu/%li}",http,(unsigned long)[req.data length],(long)req.expect);
	
    [self httpCompleted:req];
}


//--------
//Delegate - Which authentications are allowed? (a single web site acces may requires MULTIPLE types of authentication)
//--------
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	ICNPostreq * req = [self findReqForConneciton:connection remove:NO];
	if (req==nil)
		return NO;
	if ( [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])	//SSL (TRUSTED SERVER)
		return YES;
	if ( [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic])		//BASIC (USER/PW)
		return YES;
	return NO;
}


//--------
//Delegate - Perform ALLOWED Authentications
//--------
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	ICNPostreq * req = [self findReqForConneciton:connection remove:NO];
	if (req==nil)
		return;

	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		BOOL trusted = YES;//[self.trustedHosts containsObject:challenge.protectionSpace.host];
		NSLog(@"%@[http#%li] Authenticate Server \"%@\" (%@,%li)",prefix,(long)req.seq,challenge.protectionSpace.host,(trusted)?@"Trusted":@"default",(long)[challenge previousFailureCount]);
		if (trusted)
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
		else
			[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
		return;
	}

	if ( [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
		NSLog(@"%@[http#%li] Authenticate Basic \"%@\" (%li)",prefix,(long)req.seq,challenge.protectionSpace.host,(long)[challenge previousFailureCount]);
		self.URLchallenge = challenge;
		if (([challenge previousFailureCount] == 0)&&(self.save_username!=nil)&&(self.save_password!=nil)) {
			[self connectWithCredentials];		//First attempt - use saved and have a saved username/pw
		}
		else {
			if ([challenge previousFailureCount] != 0) {
				NSLog(@"%@[http#%li] !Authenticate Failed",prefix,(long)req.seq);
			}
			if (self.authTitle==nil) {
				self.authTitle = [NSString stringWithFormat:@"Login to \"%@\"",challenge.protectionSpace.realm];
			}
			[self alertViewLogin];
		}
	}
}

-(void)connectWithCredentials {
	NSURLCredential *newCredential;
	NSString * username;
	NSString * password;
	username = self.save_username;
	password = self.save_password;
	NSLog(@"%@[http#%li] <= Authenticate (%@ %@) and RE-Request...",prefix,(long)self.URLcounter,username,password);
	newCredential = [NSURLCredential credentialWithUser:username
											   password:password
											persistence:NSURLCredentialPersistenceForSession];
	[[self.URLchallenge sender] useCredential:newCredential
				   forAuthenticationChallenge:self.URLchallenge];
}
-(void)connectCancel {
	[[self.URLchallenge sender] cancelAuthenticationChallenge:self.URLchallenge];
	self.URLchallenge = nil;
}


#pragma mark AlertView Inputs

static NSString * button_login = @"Login";
static NSString * button_cancel = @"Cancel";
static NSInteger  field_username = 0;
static NSInteger  field_password = 1;


-(void)alertViewLogin {
	NSString * title;
	title = self.authTitle;
	self.myAlertView = [[UIAlertView alloc] initWithTitle:title message:nil
													   delegate:self cancelButtonTitle:button_cancel otherButtonTitles:button_login,nil];
	self.myAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
	UITextField *username = [self.myAlertView textFieldAtIndex:field_username];
	//	UITextField *password = [alertView textFieldAtIndex:field_password];
	username.text = self.save_username;
	self.alert_field0 = [NSString stringWithString:username.text];
	//	password.text = self.save_password;
	self.alert_field1 = @"";
	self.myAlertView.tag = 1234;
	[[self.myAlertView textFieldAtIndex:1] setDelegate:self];
	[self.myAlertView show];
	[self.myAlertView release];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.myAlertView dismissWithClickedButtonIndex:self.myAlertView.firstOtherButtonIndex animated:YES];
	[[self.myAlertView textFieldAtIndex:1] setDelegate:nil];
    return YES;
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[[self.myAlertView textFieldAtIndex:1] setDelegate:nil];
	self.myAlertView = nil;
//}
//*************************************
//DELEGATE - Try Username/pw
//*************************************
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	//------------
	// RESPONSE TO LOGIN
	//------------
    if([title isEqualToString:button_login]) {
        UITextField *username = [alertView textFieldAtIndex:field_username];
        UITextField *password = [alertView textFieldAtIndex:field_password];
		//		if (self.axisBonService==nil) {
		self.save_username = username.text;
		self.save_password = password.text;
//		NSLog(@"%@[http#%li] <= Retry Authenticate (%@ %@)",prefix,(long)self.URLcounter, username.text, password.text);
		[self connectWithCredentials];
    }
    else if([title isEqualToString:button_cancel]) {
		[self connectCancel];
	}

	self.alert_field0 = nil;
	self.alert_field1 = nil;
}
//*************************************
//DELEGATE - Called everytime a Character is added/deleted from either field
//*************************************
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
	if (alertView.alertViewStyle != UIAlertViewStyleLoginAndPasswordInput)
		return YES;
    NSString *inputText0 = [[alertView textFieldAtIndex:0] text];
	NSString *inputText1 = [[alertView textFieldAtIndex:1] text];
    if((inputText0.length < 1 )||(inputText1.length < 1))
		return NO;
	if ([inputText0 isEqualToString:self.alert_field0] && [inputText1 isEqualToString:self.alert_field1])
		return NO;
	return YES;
}


@end
