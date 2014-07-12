/**************************************************************/
/* ktopitsAxway -                                             */
/* ApiMachine.m                                               */
/* KT 08-JUL-2014                                             */
/**************************************************************/
// FOR ROUTING MAC PORTS DIRECT TO VM FUSION MACHINE
// TEXTWRANGLER to MAC -> /Library /Preferences /VMware Fusion /vmnet8/nat.conf => [incomingtcp]
#if 0
[incomingtcp]

# Use these with care - anyone can enter into your VM through these...
# The format and example are as follows:
#<external port number> = <VM's IP address>:<VM's port number>
#8080 = 172.16.3.128:80
#ktopits--- 12-JUN-2014 for 7.2.2 and 7.3.0
#Axway Windows VM Uses IP assigned in dhcpd.conf
#API Gateway (HTTP)
8080 = 192.168.176.100:8080
8081 = 192.168.176.100:8081
8082 = 192.168.176.100:8082
#IIS
8088 = 192.168.176.100:8088
#Oauth
8086 = 192.168.176.100:8086
8089 = 192.168.176.100:8089
#Analytics
8040 = 192.168.176.100:8040
#admin node manager (HTTPS)
8090 = 192.168.176.100:8090
#local node mgrs (HTTPS)
8085 = 192.168.176.100:8085
#API Portal (HTTPS)
8075 = 192.168.176.100:8075
8065 = 192.168.176.100:8065
#ktopits--- END

[incomingudp]
#endif

#define TRACE_SAFARI 0
#define TRACE_TOKENS 0
#define TRACE_MSGBOX 1
#define TRACE_HEALTH 0
#define TRACE_SUBME  0
#define TRACE_IDMAP  0


#import "FeatureSettings.h"
#import "ApiMachine.h"
#import "TheDropdown.h"
#import "JsonUtils.h"


#define KEY_RESULT		@"result"



@implementation ApiMachine

@synthesize delegate;
@synthesize delegate2;

@synthesize oauthState;
@synthesize oauth3Leg;
@synthesize oauthCode;
@synthesize oauthScopesRequested;
#if USE_APR_SCOPE
@synthesize oauthScopesApproved;
#endif
@synthesize oauthBody;
@synthesize oauthDate;
@synthesize oauthJson;
@synthesize oauthJson2;
@synthesize oauthJson3;

@synthesize oauthHTTPport;
@synthesize oauthHTTPSport;
@synthesize oauthHost;
@synthesize oauthWebTitle;

@synthesize icnLoginState;
@synthesize icnAppState;
@synthesize authState;

@synthesize fakeCode;
@synthesize authURL;
@synthesize machineRunning;

@synthesize heading;
@synthesize publicKey;
@synthesize secretKey;
@synthesize redirectURI;
@synthesize callbackHost;
@synthesize activeGateway;
@synthesize hostName;

@synthesize restForce;
@synthesize restForcePost;

@synthesize URLloginStatus;
@synthesize URLloginError;
@synthesize URLloginResponse;
@synthesize URLloginTime;

@synthesize webViewRunning;
@synthesize webViewController;



static NSString * prefix = @"-[api]   ";
//static NSDateFormatter *dateFormatter = nil;

//========================================================================================
#pragma mark - SESSION Init, Dealloc
//========================================================================================

ApiMachine * apiMachineSelf = nil;				//Context Definition is here!

//*******************************************
// Here when Application is created (FROM MAIN THREAD)
//*******************************************
+ (ApiMachine *)shared {
	return apiMachineSelf;
}

//*******************************************
//*******************************************

//

//NON-SSL, KT "SANDBOX"
static NSString * ASB_clientID = @"f5babf25-baed-4f10-821c-d815550507bf";
static NSString * ASB_qaSecret   = @"48e8c691-2e1c-4e85-a9ea-3f9d8a5af21f";
static NSString * ASB_prSecret   = @"48e8c691-2e1c-4e85-a9ea-3f9d8a5af21f";
static NSString * ASB_redirect = @"http://localhost:8080/";		//what I tell OAUTH
static NSString * ASB_callback = @"localhost:8080"; 			//what OAUTH returns
#define OAUTH_SB_TITLE @"Authorize"

//SSL, KT PRODUCTION
static NSString * APR_clientID = @"f5babf25-baed-4f10-821c-d815550507bf";
static NSString * APR_qaSecret   = @"48e8c691-2e1c-4e85-a9ea-3f9d8a5af21f";
static NSString * APR_prSecret   = @"48e8c691-2e1c-4e85-a9ea-3f9d8a5af21f";
static NSString * APR_redirect = @"http://localhost:8080/";
static NSString * APR_callback = @"localhost:8080"; //@"apigateway";
#define OAUTH_PR_TITLE @"Authorize"

static NSString * expired_token = @"DZVEyw6bi6FIMoISk7WVDBIikhIlfLiJQwXdaB94Ju06gFkbL43P2R";
static NSString * invalid_token = @"ABCD1234567890abcd1234567890";



// 3-leg URL GET to authorization SERVER (returns a CODE)
//https://api.att.com/oauth/authorize?client_id=f65d5435ec61851b2cb18693c641b1f8&scope=&redirect_uri=http://localhost:8080/
static NSString * default_loginPrefix = @"/api/oauth";
static NSString * default_loginFormat = @"%@/authorize?client_id=%@&redirect_uri=%@&scope=%@";
// 2or3 Leg get TOKEN
static NSString * default_oauthCommand = @"/api/oauth/token";		//NO GATEWAY PREFIX

#define DEFAULT_NOSCOPES @""
//#define DEFAULT_SCOPES0 @"SMS,SPEECH"
//#define DEFAULT_SCOPES1 @"SMS"
#define DEFAULT_NOAUTHCODE @""

//returned query keys from authorization SERVER
#define RECALL_CODE @"code"
//#define RECALL_SCOPE @"scope"
#define RECALL_ERROR @"error"

//JSON keys in OAUTH
#define OAUTH_KEY_ACCESS  @"access_token"
#define OAUTH_KEY_REFRESH @"refresh_token"
#define OAUTH_KEY_TYPE    @"token_type"
#define OAUTH_KEY_SCOPE   @"scope"
#define OAUTH_KEY_EXPIRES @"expires_in"

#define OAUTH_KEY__SCOPE  @"__SCOPE"
#define OAUTH_KEY__DATE   @"__DATE"
#define OAUTH_KEY__BODY   @"__BODY"


//*******************************************
// OAUTH and TOKENS
//*******************************************

static NSString * restGW_prefix = @"http";		//No SSL
static NSString * restGW_hostname = @"";
static NSString * restGW_localhost= @"localhost";

//static NSString * default_backsideURI  = nil;	//URI's in BACKSIDE RESPONSE that need Fixup (non on AT&T?)
static NSString * default_gatewayURI   = nil;
static NSString * default_gatewayPrefix= nil;	//Each SCOPE uses a differnt PREFIX, no "common" prefix
static NSString * default_gatewaySuffix= nil;	//JSON or XML URL qualifier
static NSString * default_gatewayToken = @"&access_token=";

-(void)checkHostGateway:(NSString *)hostname save:(BOOL)saveit {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (hostname==nil) {
		self.activeGateway = [[defaults stringForKey:SETTING_hostname] lowercaseString];
	}
	else {
		self.activeGateway = [hostname lowercaseString];
	}
	if (saveit) {
		[defaults setObject:self.activeGateway forKey:SETTING_hostname];
		[defaults synchronize];		//Delay until completed...
	}

	if ((self.activeGateway==nil)||(self.activeGateway.length==0))
		restGW_hostname = restGW_localhost;
	else
		restGW_hostname = [[NSString stringWithFormat:@"%@://%@",restGW_prefix,self.activeGateway] retain];
	default_gatewayURI   = restGW_hostname;

	self.oauthHost = nil;
	NSInteger mobile = [self readServiceSetting];
	if (mobile==0) {
		mobile = XDN_SERVICE_ATTAPI | XDN_CLIENTID_KTSB | XDN_OAUTHSRVR_QA | XDN_AUTHMODE_INURL;
		[self writeServiceSetting:mobile];
	}
	NSInteger oauthsrvr=mobile&XDN_OAUTHSRVR_MASK;
	NSURL * hosturl = [NSURL URLWithString:default_gatewayURI];
	self.hostName = [hosturl host];
	if ([self.hostName characterAtIndex:self.hostName.length-1]=='.') {
		self.hostName = [self.hostName substringToIndex:self.hostName.length-1];
	}
	if ((oauthsrvr==XDN_OAUTHSRVR_QA)&&(self.oauthHTTPport!=nil)) {
		NSLog(@"%@[KEY] OAUTH = HTTP:%@",prefix,self.oauthHTTPport);
		self.oauthWebTitle = OAUTH_SB_TITLE;
		self.oauthHost   = [[NSString stringWithFormat:@"http://%@:%@",self.hostName,self.oauthHTTPport] retain];
	}
	else if ((oauthsrvr==XDN_OAUTHSRVR_PR)&&(self.oauthHTTPSport!=nil)) {
		NSLog(@"%@[KEY] OAUTH = HTTPS:%@",prefix,self.oauthHTTPSport);
		self.oauthWebTitle = OAUTH_PR_TITLE;
		self.oauthHost   = [[NSString stringWithFormat:@"https://%@:%@",self.hostName,self.oauthHTTPSport] retain];
	}

}

-(NSString *)getHostName {
	return self.hostName;
}
-(void)getTheKeys {
	[self checkHostGateway:nil save:NO];

	NSInteger mobile = [self readServiceSetting];
	if (mobile==0) {
		mobile = XDN_SERVICE_ATTAPI | XDN_CLIENTID_KTSB | XDN_OAUTHSRVR_QA | XDN_AUTHMODE_INURL;
		[self writeServiceSetting:mobile];
	}
	NSInteger service = mobile&XDN_SERVICE_MASK;
	NSInteger clientID= mobile&XDN_CLIENTID_MASK;
	NSInteger authmode= mobile&XDN_AUTHMODE_MASK;
	NSInteger oauthsrvr=mobile&XDN_OAUTHSRVR_MASK;
	
	default_gatewaySuffix= @"";//?$format=json";

	if (service==XDN_SERVICE_ATTAPI) {
		NSLog(@"%@[KEY] Setting Axway API mode",prefix);
		self.heading = @"API GW";
//		default_backsideURI  = @"";
//		default_gatewayURI   = restGW_hostname;
		default_gatewayPrefix= @"";
	}
	else {
		NSLog(@"%@[KEY] Setting localhost mode",prefix);
		self.heading = @"LocalHost";
//		default_backsideURI  = @"";
//		default_gatewayURI   = restGW_localhost;
		default_gatewayPrefix= @"";
	}
	
	if ((clientID!=XDN_CLIENTID_KTSB)&&(clientID!=XDN_CLIENTID_KTPR))
		clientID = XDN_CLIENTID_KTSB;
	if (clientID==XDN_CLIENTID_KTSB) {
		NSLog(@"%@[KEY] Client = AXW_sb",prefix);
		self.publicKey = ASB_clientID;
		self.redirectURI = ASB_redirect;
		self.callbackHost = ASB_callback;
	}
	else if (clientID==XDN_CLIENTID_KTPR) {
		NSLog(@"%@[KEY] Client = AXW_pr",prefix);
		self.publicKey = APR_clientID;
		self.redirectURI = APR_redirect;
		self.callbackHost = APR_callback;
	}

	if ((oauthsrvr!=XDN_OAUTHSRVR_QA)&&(oauthsrvr!=XDN_OAUTHSRVR_PR))
		oauthsrvr = XDN_OAUTHSRVR_QA;
	if (oauthsrvr==XDN_OAUTHSRVR_QA) {
		NSLog(@"%@[KEY] Environment = QA",prefix);
		if(clientID==XDN_CLIENTID_KTSB)
			self.secretKey = ASB_qaSecret;
		else if (clientID==XDN_CLIENTID_KTPR)
			self.secretKey = APR_qaSecret;
	}
	else if (oauthsrvr==XDN_OAUTHSRVR_PR) {
		NSLog(@"%@[KEY] Environment = PR",prefix);
		if(clientID==XDN_CLIENTID_KTSB)
			self.secretKey = ASB_prSecret;
		else if (clientID==XDN_CLIENTID_KTPR)
			self.secretKey = APR_prSecret;
	}

	if ((authmode!=XDN_AUTHMODE_INURL)&&(authmode!=XDN_AUTHMODE_HEADER))
		authmode = XDN_AUTHMODE_INURL;
	if (authmode==XDN_AUTHMODE_INURL) {
		NSLog(@"%@[KEY] Auth = URL",prefix);
		[[HttpProxy shared] authWithURL:default_gatewayToken];
	}
	else if (authmode==XDN_AUTHMODE_HEADER) {
		[[HttpProxy shared] authWithURL:nil];
		NSLog(@"%@[KEY] Auth = HEADER",prefix);
	}
	
	if ([self.delegate respondsToSelector:@selector(apiMachine:service:heading:)]) {
		[self.delegate apiMachine:apiMachineSelf service:mobile heading:self.heading];
	}
}

-(NSInteger) readServiceSetting {
	NSString * gc = [[NSUserDefaults standardUserDefaults] stringForKey:SETTING_service];
	NSInteger mobile = [gc integerValue];
	return mobile;
}
-(NSInteger) writeServiceSetting:(NSInteger)setting {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString * gc = [defaults stringForKey:SETTING_service];
	NSInteger mobile = [gc integerValue];
	if (mobile!=setting) {
		[defaults setObject:[NSString stringWithFormat:@"%li",(long)setting] forKey:SETTING_service];
		[defaults synchronize];
		[self getTheKeys];
	}
	return mobile;
}




- (id) init {
	self = [super init];		//create my context (so caller did not have to
//	NSLog(@"%@--- init self=%p",prefix,self);
	apiMachineSelf = [self retain];
    self.icnLoginState = IcnLoginInit;
	self.machineRunning = 0;

    self.delegate = nil;
	self.fakeCode = NO;
	
	[[HttpProxy  alloc] init];
    [[HttpProxy shared] setDelegate:self];
	[[ApiWeb     alloc] init];
    [[ApiWeb    shared] setDelegate:self];
	
	self.oauthScopesRequested = DEFAULT_NOSCOPES;
	[self initializeOauthJson];

	[self getTheKeys];	//SETS UP PROXY!
	return self;
}

//*******************************************
// Here when WirelessBlueController is released
//*******************************************
- (void) dealloc
{
 	NSLog(@"%@--- dealloc",prefix);
	[self release];
	apiMachineSelf = nil;
    [super dealloc];
}









//========================================================================================
#pragma mark - OAUTH Authentication Machine
//========================================================================================


typedef enum {
    IcnLoginFailed = -2,
    IcnLoginComplete = -1,
	IcnLoginInit = 0,             //*** Startup

	IcnLoginStarted = 1,             //*** Startup
    IcnLoginGot401 = 2,
    IcnLoginTokenInvalid = 3,
	
	IcnLoginNewTest = 4,
    IcnLoginWaitTest = 5,
    IcnLoginDoneTest = 6,

    IcnLoginNewCode = 7,
    IcnLoginTokenExpired = 10,

	IcnLoginWaitOauth = 17,
    IcnLoginDoneOauth = 18,

    IcnLoginCheckForce = 19,
	
    IcnLoginUserHealth = 20,
    IcnLoginWaitGetHealth = 21,
    IcnLoginDoneGetHealth = 22,
    IcnLoginGoodGetHealth = 23,
    IcnLoginFailGetHealth = 24,

    IcnLoginUserPorts = 25,
    IcnLoginWaitGetPorts = 26,
    IcnLoginDoneGetPorts = 27,
    IcnLoginGoodGetPorts = 28,
    IcnLoginFailGetPorts = 29,

    IcnLoginUserThrottle = 35,
    IcnLoginWaitGetThrottle = 36,
    IcnLoginDoneGetThrottle = 37,
    IcnLoginGoodGetThrottle = 38,
    IcnLoginFailGetThrottle = 39,

    IcnLoginUserBasic = 40,
    IcnLoginWaitGetBasic = 41,
    IcnLoginDoneGetBasic = 42,
    IcnLoginGoodGetBasic = 43,
    IcnLoginFailGetBasic = 44,

    IcnLoginUserStock = 45,
    IcnLoginWaitGetStock = 46,
    IcnLoginDoneGetStock = 47,
    IcnLoginGoodGetStock = 48,
    IcnLoginFailGetStock = 49,
	
    IcnLoginUserGWnet = 70,
    IcnLoginWaitGetGWnet = 71,
    IcnLoginDoneGetGWnet = 72,
    IcnLoginGoodGetGWnet = 73,
    IcnLoginFailGetGWnet = 74,

    IcnLoginUserAPPnet = 75,
    IcnLoginWaitGetAPPnet = 76,
    IcnLoginDoneGetAPPnet = 77,
    IcnLoginGoodGetAPPnet = 78,
    IcnLoginFailGetAPPnet = 79,

    IcnLoginUserGoogleWeb = 80,
    IcnLoginWaitGetGoogleWeb = 81,
    IcnLoginDoneGetGoogleWeb = 82,
    IcnLoginGoodGetGoogleWeb = 83,
    IcnLoginFailGetGoogleWeb = 84,

    IcnLoginUserGoogleID = 85,
    IcnLoginWaitGetGoogleID = 86,
    IcnLoginDoneGetGoogleID = 87,
    IcnLoginGoodGetGoogleID = 88,
    IcnLoginFailGetGoogleID = 89,

    IcnLoginUserGetForce = 90,
    IcnLoginWaitGetForce = 91,
    IcnLoginDoneGetForce = 92,
    IcnLoginGoodGetForce = 93,

    IcnLoginUserPostForce = 95,
    IcnLoginWaitPostForce = 96,
    IcnLoginDonePostForce = 97,
    IcnLoginGoodPostForce = 98

} _IcnLogin;


-(BOOL)icnMachineRunning {
	if (self.icnLoginState>IcnLoginInit)
		return YES;
	return NO;
}
-(void)forceHTTPget:(NSString *)force {
	self.restForce = force;
	self.restForcePost = NO;
}
-(void)forceHTTPpost:(NSString *)force {
	self.restForce = force;
	self.restForcePost = YES;
}

//Here when OAUTH Engine completes
-(void)returnCheckOauthToken {
	if (self.icnLoginState == IcnLoginWaitOauth) {
		self.icnLoginState = IcnLoginDoneOauth;
	}
}

static NSString * itFailed = @"";

-(void) startTheMachine:(BOOL)test {
	if (self.webViewRunning) {
		//User chose to KILL "WebView" with [X] button.
		self.URLloginResponse = itFailed;
		self.URLloginStatus = -1;
		[[ApiWeb shared] stopWebView];
		//Was I waiting on WebView?
		if (self.icnLoginState == IcnLoginWaitOauth) {
			self.icnLoginState = IcnLoginFailed;
		}
		if (self.icnLoginState == IcnLoginWaitGetGoogleWeb) {
			self.icnLoginState = IcnLoginFailGetGoogleWeb;
		}
		return;
	}
//	[[TheDropdown shared] queNavPrompt:@"Machine"];
	if (test)
    	self.icnLoginState = IcnLoginNewTest;
	else
    	self.icnLoginState = IcnLoginStarted;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(icnLoginMachine) object:nil];
    [self performSelector:@selector(icnLoginMachine) withObject:nil afterDelay:0.0];
}
-(void) icnLoginMachine {
    BOOL looper = YES;
    BOOL recall = NO;
//	NSString * server;
//	NSString * suffix;
    NSString * json;
	NSString * callURL;
#if 0
	NSInteger mLimit;
	NSInteger mOffset;
	NSInteger mTotal;
#endif
    id objects;
	float recalltime = 0.5;
	NSInteger seq;
    
    while (looper) {
//        NSLog(@"%@--------->Login Machine = %li",prefix,(long)self.icnLoginState);
        switch (self.icnLoginState) {

			//---------
			// First, make sure SERVER and NETWORK available and on-line
			// Intersting case since may be Sim(OSX) => VM => GW(WIN7) => VM(OSX) => network
			// With INTERNAL GW, this app may ONLY run on SIMULATOR
			//---------
            case IcnLoginNewTest:
#if 0
				if ([[HttpProxy shared] get:default_gatewayURI request:@""]==0) {
                    NSLog(@"%@?GET Error on GW Server",prefix);
                    self.icnLoginState = IcnLoginFailed;
                    break;
				}
                self.icnLoginState = IcnLoginWaitTest;
                break;
			case IcnLoginWaitTest:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneTest:
				if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
					NSLog(@"%@?Gateway NOT Available.",prefix);
					[[TheDropdown shared] queNavPrompt:@"?Gateway Not Available"];
					self.icnLoginState = IcnLoginFailed;
					break;
				}
				//on Axway, we should get 404 = "not found"
#endif
				self.icnLoginState = IcnLoginStarted;
				break;
			//---------
			// Initial Startup - see if token needed
			//---------
            case IcnLoginStarted:
                looper = NO;
                recall = YES;
#if 0
				//Use 2-Leg OAUTH to authenticate the APPLICATION
                self.icnLoginState = IcnLoginWaitOauth;
				[self checkOauthToken:0];
#else
				//No OAUTH
                self.icnLoginState = IcnLoginUserHealth;
#endif
                break;

				//---------
				// Simple HEALTHCHECK => HTML 200 (on EVERY GATEWAY)
				//---------
            case IcnLoginUserHealth:
				if ([self.delegate respondsToSelector:@selector(apiMachine:health:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf health:itFailed time:0.0 status:0];
				}
				seq = [[HttpProxy shared] get:default_gatewayURI request:[NSString stringWithFormat:@"%@/healthcheck",default_gatewayPrefix]];
				if (seq==0) {
                    NSLog(@"%@?GET HealthCheck Error",prefix);
                    self.icnLoginState = IcnLoginFailGetHealth;
                    break;
				}
                self.icnLoginState = IcnLoginWaitGetHealth;
                break;
            case IcnLoginWaitGetHealth:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetHealth:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetHealth;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
					//-1001 (no response on port/nat)
                    //-1004 (invalid IP)
					//-1005 Gateway SW is not running
					//-1009 Airplane Mode
                    NSLog(@"%@??? GET not deliverable = %li",prefix,(long)self.URLloginStatus);
                    self.icnLoginState = IcnLoginFailGetHealth;
                    break;
                }
                else if (self.URLloginStatus == HTTP_403) {
					//?Authetication?
                }
                else if (self.URLloginStatus == HTTP_404) {
					//INVALID REST COMMAND (CLASSIFICATION_FAILURE)  = "No such resource" at that URL
                }
                NSLog(@"%@??? code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailGetHealth;
                break;
            case IcnLoginFailGetHealth:
				if ([self.delegate respondsToSelector:@selector(apiMachine:health:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf health:itFailed time:self.URLloginTime status:self.URLloginStatus];
				}
                self.icnLoginState = IcnLoginFailed;
                break;
            case IcnLoginGoodGetHealth:
				//Here with HTML
				callURL	 =[self.URLloginResponse stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				callURL = [callURL stringByReplacingOccurrencesOfString:@"\n" withString:@""];
				if ([self.delegate respondsToSelector:@selector(apiMachine:health:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf health:callURL time:self.URLloginTime status:self.URLloginStatus];
				}
                self.icnLoginState = IcnLoginUserPorts;
                NSLog(@"%@~~~ code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                break;

				//---------
				// See if this gateway has the stuff/policies I need
				//---------
            case IcnLoginUserPorts:
				if ([self.delegate respondsToSelector:@selector(apiMachine:ports:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf ports:itFailed time:0.0 status:0];
				}
				self.oauthHTTPSport = nil;
				self.oauthHTTPport = nil;
				seq = [[HttpProxy shared] get:default_gatewayURI request:[NSString stringWithFormat:@"%@/ports",default_gatewayPrefix]];
				if (seq==0) {
                    NSLog(@"%@?GET Ports Error",prefix);
                    self.icnLoginState = IcnLoginFailGetPorts;
                    break;
				}
                self.icnLoginState = IcnLoginWaitGetPorts;
                break;
            case IcnLoginWaitGetPorts:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetPorts:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetPorts;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE -1004 (airplane), -1001 (no response)
                    NSLog(@"%@??? GET not deliverable = %li",prefix,(long)self.URLloginStatus);
                    self.icnLoginState = IcnLoginFailGetPorts;
                    break;
                }
                else if (self.URLloginStatus == HTTP_403) {
					//REST not implemented on GW
                }
                else if (self.URLloginStatus == HTTP_404) {
					//INVALID REST COMMAND (CLASSIFICATION_FAILURE)  = "No such resource" at that URL
                }
                NSLog(@"%@??? code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailGetPorts;
                break;
            case IcnLoginFailGetPorts:
				if ([self.delegate respondsToSelector:@selector(apiMachine:ports:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf ports:itFailed time:self.URLloginTime status:self.URLloginStatus];
				}
                self.icnLoginState = IcnLoginFailed;
                break;
            case IcnLoginGoodGetPorts:
				json = self.URLloginResponse;
				NSDictionary * portsJson = [jsonUtils decode:json];
				self.oauthHTTPport = [portsJson valueForKey:@"oauth_http"];
				self.oauthHTTPSport = [portsJson valueForKey:@"oauth_https"];
				[self checkHostGateway:nil save:NO];
				if ([self.delegate respondsToSelector:@selector(apiMachine:ports:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf ports:portsJson time:self.URLloginTime status:self.URLloginStatus];
				}
                NSLog(@"%@~~~ code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
				//Use 2-Leg OAUTH to authenticate the APPLICATION
                self.icnLoginState = IcnLoginWaitOauth;
				[self checkOauthToken:0];
                break;
				
           //---------
            // Tried to GET/POST with TOKEN and GOT UnAuthorized (probably 401)
            //---------
            case IcnLoginGot401:
				json = self.URLloginResponse;
				[[TheDropdown shared] queNavPrompt:@"?Authorization Failed"];
				if ([json isEqualToString:@"<h1>Expired token</h1>"]) {
					self.icnLoginState = IcnLoginTokenExpired;
					break;
				}
				if ([self getRefreshString].length>0) {
					if ([self checkTokenExpired]) {
						self.icnLoginState = IcnLoginTokenExpired;
						break;
					}
				}
                NSLog(@"%@??? Authorization Fail = \%@\"",prefix,json);
                self.icnLoginState = IcnLoginTokenInvalid;
                break;
                
            //---------
            // Tried to use TOKEN, but got "401-Invalid Token"
            //---------
            case IcnLoginTokenInvalid:
                self.icnLoginState = IcnLoginNewCode;
                break;
                
			//---------
			// Start OVER - clear fields and call OAUTH LOGIN web page
			//---------
            case IcnLoginNewCode:
                looper = NO;
                recall = YES;
				self.icnLoginState = IcnLoginWaitOauth;
				[self checkOauthToken:1];
                break;

			//---------
            // Got EXPIRED/UNAUTHORIZED.  Try to Use REFRESH CODE to request a NEW TOKEN
            //---------
            case IcnLoginTokenExpired:
                looper = NO;
                recall = YES;
				self.icnLoginState = IcnLoginWaitOauth;
				[self checkOauthToken:-1];
                break;
                
			//---------
			//Wait for OAUTH Engine to Complete
			//---------
			case IcnLoginWaitOauth:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneOauth:
				//Here on RETURN from OAUTHMACHINE
				NSLog(@"%@NEW Oauth Token=\"%@\"",prefix,[self getTokenString]);
				if ([self getTokenString].length==0)
					self.icnLoginState = IcnLoginFailed;
				else
					self.icnLoginState = IcnLoginCheckForce;
				break;


            //---------
            // Here with a TOKEN.  See if NORMAL MACHINE or FORCE
            //---------
            case IcnLoginCheckForce:
				if (self.restForce!=nil) {
					NSLog(@"%@* * * Force %@=%@",prefix,(self.restForcePost)?@"POST":@"GET",self.restForce);
					if (self.restForcePost)
						self.icnLoginState = IcnLoginUserPostForce;
					else
						self.icnLoginState = IcnLoginUserGetForce;
					break;
				}
                self.icnLoginState = IcnLoginUserThrottle;
                break;
				
			//---------
			// Test Throttling
			//---------
            case IcnLoginUserThrottle:
				if ([self.delegate respondsToSelector:@selector(apiMachine:throttle:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf throttle:itFailed time:0.0 status:0];
				}
				seq = [[HttpProxy shared] get:default_gatewayURI request:[NSString stringWithFormat:@"%@/throttle",default_gatewayPrefix]];
				if (seq==0) {
                    NSLog(@"%@?GET Throttle Error",prefix);
                    self.icnLoginState = IcnLoginFailGetThrottle;
                    break;
				}
                self.icnLoginState = IcnLoginWaitGetThrottle;
                break;
            case IcnLoginWaitGetThrottle:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetThrottle:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetThrottle;
                    break;
                }
                else if (self.URLloginStatus == HTTP_500) {
                    self.icnLoginState = IcnLoginGoodGetThrottle;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE
                    NSLog(@"%@??? GET not deliverable",prefix);
                    self.icnLoginState = IcnLoginFailGetThrottle;
                    break;
                }
                else if (self.URLloginStatus == HTTP_404) {
					//INVALID REST COMMAND (CLASSIFICATION_FAILURE)  = "No such resource" at that URL
                }
                NSLog(@"%@??? Throttle code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailGetThrottle;
                break;
				
				//---------
				// GOT HTTP response from GW = either OK (200) or WAIT (500)
				//---------
            case IcnLoginGoodGetThrottle:
				json = self.URLloginResponse;
				callURL	 =[self.URLloginResponse stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				callURL = [callURL stringByReplacingOccurrencesOfString:@"\n" withString:@""];
				if ([self.delegate respondsToSelector:@selector(apiMachine:throttle:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf throttle:callURL time:self.URLloginTime status:self.URLloginStatus];
				}
                self.icnLoginState = IcnLoginUserBasic;
                break;
			case IcnLoginFailGetThrottle:
				if ([self.delegate respondsToSelector:@selector(apiMachine:throttle:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf throttle:self.URLloginResponse time:self.URLloginTime status:self.URLloginStatus];
				}
                if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE))
                    self.icnLoginState = IcnLoginFailed;
                else
					self.icnLoginState = IcnLoginUserBasic;
                break;


			//---------
			// Here with for HTTP Basic
			//---------
            case IcnLoginUserBasic:
				if ([[self delegate] respondsToSelector:@selector(apiMachine:basic:time:status:)]) {
					[[self delegate] apiMachine:apiMachineSelf basic:itFailed time:0.0 status:0];
				}
				[[HttpProxy shared] authWithTitle:nil];
				if ([[HttpProxy shared] get:default_gatewayURI request:[NSString stringWithFormat:@"%@/basic",default_gatewayPrefix]]==0)
				{
                    NSLog(@"%@?GET HTTP Basic Error",prefix);
                    self.icnLoginState = IcnLoginFailGetBasic;
                    break;
				}
                self.icnLoginState = IcnLoginWaitGetBasic;
                break;
            case IcnLoginWaitGetBasic:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetBasic:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetBasic;
                    break;
                }
                else if (self.URLloginStatus == -1012) {
                    NSLog(@"%@???GET Authentication Canceled",prefix);
                    self.icnLoginState = IcnLoginFailGetBasic;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE
                    NSLog(@"%@???GET not deliverable",prefix);
                    self.icnLoginState = IcnLoginFailGetBasic;
                    break;
                }
                else if (self.URLloginStatus == HTTP_401) {
					//Failed authentication
                }
                NSLog(@"%@???GET code=%li Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailGetBasic;
                break;
            case IcnLoginGoodGetBasic:
                NSLog(@"%@BASIC <= \n%@", prefix,self.URLloginResponse);
				json = self.URLloginResponse;
                objects = [jsonUtils decode:json];

				if ([[self delegate] respondsToSelector:@selector(apiMachine:basic:time:status:)]) {
					[[self delegate] apiMachine:apiMachineSelf basic:objects time:self.URLloginTime status:self.URLloginStatus];
				}
                self.icnLoginState = IcnLoginUserStock;
                break;
			case IcnLoginFailGetBasic:
				if ([[self delegate] respondsToSelector:@selector(apiMachine:basic:time:status:)]) {
					[[self delegate] apiMachine:apiMachineSelf basic:self.URLloginResponse time:self.URLloginTime status:self.URLloginStatus];
				}
                if ((self.URLloginStatus==HTTP_9999))
                    self.icnLoginState = IcnLoginFailed;
                else
					self.icnLoginState = IcnLoginUserStock;
                break;
				

				//---------
				// Test KPS Stock Lookup with HTTP Basic Auth
				//---------
            case IcnLoginUserStock:
				if ([self.delegate respondsToSelector:@selector(apiMachine:stock:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf stock:itFailed time:0.0 status:0];
				}
				[[HttpProxy shared] authWithTitle:@"Stock Quote Login"];
				json = @"AXW";
				if ([self.delegate respondsToSelector:@selector(apiMachine:getString:)]) {
					json = [self.delegate apiMachine:apiMachineSelf getString:@"STOCK"];
				}
				seq = [[HttpProxy shared] get:default_gatewayURI request:[NSString stringWithFormat:@"%@/stockquote/getprice/%@",default_gatewayPrefix,json]];
				if (seq==0) {
                    NSLog(@"%@?GET StockQuote Error",prefix);
                    self.icnLoginState = IcnLoginFailGetStock;
                    break;
				}
                self.icnLoginState = IcnLoginWaitGetStock;
                break;
            case IcnLoginWaitGetStock:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetStock:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetStock;
                    break;
                }
                else if (self.URLloginStatus == -1012) {
                    NSLog(@"%@???GET Authentication Canceled",prefix);
                    self.icnLoginState = IcnLoginFailGetStock;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE
                    NSLog(@"%@??? GET not deliverable",prefix);
                    self.icnLoginState = IcnLoginFailGetStock;
                    break;
                }
                else if (self.URLloginStatus == HTTP_404) {
					//INVALID REST COMMAND (CLASSIFICATION_FAILURE)  = "No such resource" at that URL
                }
                else if (self.URLloginStatus == HTTP_501) {
                    NSLog(@"%@???GET Symbol not found",prefix);
                    self.icnLoginState = IcnLoginFailGetStock;
                    break;
                }
                NSLog(@"%@??? STOCK code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailGetStock;
                break;
            case IcnLoginGoodGetStock:
				json = self.URLloginResponse;
				if ([self.delegate respondsToSelector:@selector(apiMachine:stock:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf stock:json time:self.URLloginTime status:self.URLloginStatus];
				}
                self.icnLoginState = IcnLoginUserGWnet;
                break;
			case IcnLoginFailGetStock:
				if ([self.delegate respondsToSelector:@selector(apiMachine:stock:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf stock:self.URLloginResponse time:self.URLloginTime status:self.URLloginStatus];
				}
                if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE))
                    self.icnLoginState = IcnLoginFailed;
                else
					self.icnLoginState = IcnLoginUserGWnet;
                break;
				
				

			//---------
			// This requires GW to have internet access, but NOT the app.
			//---------
            case IcnLoginUserGWnet:
				if ([self.delegate respondsToSelector:@selector(apiMachine:gwNet:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf gwNet:itFailed time:0.0 status:0];
				}
				seq = [[HttpProxy shared] get:default_gatewayURI request:[NSString stringWithFormat:@"%@/internet",default_gatewayPrefix]];
				if (seq==0) {
                    NSLog(@"%@?GET Internet Error",prefix);
                    self.icnLoginState = IcnLoginFailGetGWnet;
                    break;
				}
                self.icnLoginState = IcnLoginWaitGetGWnet;
                break;
            case IcnLoginWaitGetGWnet:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetGWnet:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetGWnet;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE
                    NSLog(@"%@??? GET not deliverable = %li",prefix,(long)self.URLloginStatus);
                    self.icnLoginState = IcnLoginFailGetGWnet;
                    break;
                }
                else if (self.URLloginStatus == HTTP_502) {
                    NSLog(@"%@??? Gateway can not access Internet",prefix);
                    self.icnLoginState = IcnLoginFailGetGWnet;
                    break;
                }
                else if (self.URLloginStatus == HTTP_504) {
                    NSLog(@"%@??? Gateway Fault",prefix);
                    self.icnLoginState = IcnLoginFailGetGWnet;
                    break;
                }
                else if (self.URLloginStatus == HTTP_404) {
					//INVALID REST COMMAND (CLASSIFICATION_FAILURE)  = "No such resource" at that URL
                }
                NSLog(@"%@??? code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailGetGWnet;
                break;
			case IcnLoginFailGetGWnet:
					self.icnLoginState = IcnLoginUserAPPnet;
				callURL	 =[self.URLloginResponse stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				callURL = [callURL stringByReplacingOccurrencesOfString:@"\n" withString:@""];
				if ([self.delegate respondsToSelector:@selector(apiMachine:gwNet:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf gwNet:callURL time:self.URLloginTime status:self.URLloginStatus];
				}
                break;
            case IcnLoginGoodGetGWnet:
				//Here with HTML
				callURL	 =[self.URLloginResponse stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				callURL = [callURL stringByReplacingOccurrencesOfString:@"\n" withString:@""];
				if ([self.delegate respondsToSelector:@selector(apiMachine:gwNet:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf gwNet:callURL time:self.URLloginTime status:self.URLloginStatus];
				}
                self.icnLoginState = IcnLoginUserAPPnet;
                NSLog(@"%@~~~ code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                break;

				//---------
				// This requires APP to have internet access, but NOT the gw.
				//---------
            case IcnLoginUserAPPnet:
				if ([self.delegate respondsToSelector:@selector(apiMachine:appNet:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf appNet:itFailed time:0.0 status:0];
				}
				seq = [[HttpProxy shared] get:@"http://google.com:80" request:@""];
				if (seq==0) {
                    NSLog(@"%@?GET Internet Error",prefix);
                    self.icnLoginState = IcnLoginFailGetAPPnet;
                    break;
				}
                self.icnLoginState = IcnLoginWaitGetAPPnet;
                break;
            case IcnLoginWaitGetAPPnet:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetAPPnet:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetAPPnet;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE
                    NSLog(@"%@??? GET not deliverable = %li",prefix,(long)self.URLloginStatus);
                    self.icnLoginState = IcnLoginFailGetAPPnet;
                    break;
                }
                else if (self.URLloginStatus == HTTP_502) {
                    NSLog(@"%@??? Gateway can not access Internet",prefix);
                    self.icnLoginState = IcnLoginFailGetAPPnet;
                    break;
                }
                else if (self.URLloginStatus == HTTP_504) {
                    NSLog(@"%@??? Gateway Fault",prefix);
                    self.icnLoginState = IcnLoginFailGetAPPnet;
                    break;
                }
                else if (self.URLloginStatus == HTTP_404) {
					//INVALID REST COMMAND (CLASSIFICATION_FAILURE)  = "No such resource" at that URL
                }
                NSLog(@"%@??? code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailGetAPPnet;
                break;
			case IcnLoginFailGetAPPnet:
				self.icnLoginState = IcnLoginUserGoogleWeb;
				callURL	 =[self.URLloginResponse stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				callURL = [callURL stringByReplacingOccurrencesOfString:@"\n" withString:@""];
				if ([self.delegate respondsToSelector:@selector(apiMachine:appNet:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf appNet:callURL time:self.URLloginTime status:self.URLloginStatus];
				}
                break;
            case IcnLoginGoodGetAPPnet:
				//Here with HTML
				callURL	 =[self.URLloginResponse stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				callURL = [callURL stringByReplacingOccurrencesOfString:@"\n" withString:@""];
				if ([self.delegate respondsToSelector:@selector(apiMachine:appNet:time:status:)]) {
					[self.delegate apiMachine:apiMachineSelf appNet:callURL time:self.URLloginTime status:self.URLloginStatus];
				}
                self.icnLoginState = IcnLoginUserGoogleWeb;
                NSLog(@"%@~~~ code=%li GET Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                break;
				
			//---------
			// THis REQUIRES APP to have internat access, but NOT the GW
            //---------
            case IcnLoginUserGoogleWeb:
				if ([[self delegate] respondsToSelector:@selector(apiMachine:google:time:status:)]) {
					[[self delegate] apiMachine:apiMachineSelf google:itFailed time:0.0 status:0];
				}
                looper = NO;
                recall = YES;
                self.icnLoginState = IcnLoginWaitGetGoogleWeb;
				callURL = [NSString stringWithFormat:@"%@%@",default_gatewayURI,@"/google"];
				[self startWebView:callURL callbackHost:self.callbackHost title:@"OpenID"];
                break;
            case IcnLoginWaitGetGoogleWeb:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetGoogleWeb:
				//Web View does NOT setup .URLLoginResponse.
				//Error is managed outside SWITCH to set FAIL.
				self.icnLoginState = IcnLoginUserGoogleID;
				break;
			case IcnLoginFailGetGoogleWeb:
                self.icnLoginState = IcnLoginFailGetGoogleID;
                break;

            case IcnLoginUserGoogleID:
				callURL = [self.authURL absoluteString];
                NSLog(@"%@URL <= \n%@", prefix,callURL);
				callURL = [callURL stringByReplacingOccurrencesOfString:@"http://" withString:@""];
				callURL = [callURL stringByReplacingOccurrencesOfString:self.callbackHost withString:default_gatewayURI];

				if ([[HttpProxy shared] get:callURL request:@""]==0) {
                    NSLog(@"%@?GET GoogleID Error",prefix);
                    self.icnLoginState = IcnLoginFailGetGoogleID;
                    break;
                }
                self.icnLoginState = IcnLoginWaitGetGoogleID;
                break;
            case IcnLoginWaitGetGoogleID:
                looper = NO;
                recall = YES;
                break;
            case IcnLoginDoneGetGoogleID:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetGoogleID;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE - host invalid or not reachable
                    NSLog(@"%@???GET not deliverable",prefix);
                    self.icnLoginState = IcnLoginFailGetGoogleID;
                    break;
                }
                NSLog(@"%@???GET code=%li Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailGetGoogleID;
                break;
            case IcnLoginGoodGetGoogleID:
                NSLog(@"%@JSON <= \n%@", prefix,self.URLloginResponse);
				if ([[self delegate] respondsToSelector:@selector(apiMachine:google:time:status:)]) {
					[[self delegate] apiMachine:apiMachineSelf google:self.URLloginResponse time:self.URLloginTime status:self.URLloginStatus];
				}
				self.icnLoginState = IcnLoginComplete;
				break;
			case IcnLoginFailGetGoogleID:
				if ([[self delegate] respondsToSelector:@selector(apiMachine:google:time:status:)]) {
					[[self delegate] apiMachine:apiMachineSelf google:self.URLloginResponse time:self.URLloginTime status:self.URLloginStatus];
				}
                if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE))
                    self.icnLoginState = IcnLoginFailed;
				else
					self.icnLoginState = IcnLoginComplete;
                break;


				
#if 0
            case IcnLoginUserMsgBoxStart:
				mLimit = 10;
				mOffset = 0;
				mTotal = 0;
				self.icnLoginState = IcnLoginUserMsgBox;
            case IcnLoginUserMsgBox:
				[self checkTokenExpired];
				//For INCEMENTAL use "delta?state=1388102635555" (from previous full)  instead of FULL with "?limit=x&offset=y"
				if ([[HttpProxy shared] getAuthorized:default_gatewayURI request:[NSString stringWithFormat:@"%@%@?limit=%li&offset=%li%@",default_gatewayPrefix,rest_MyMsgs,(long)mLimit,(long)mOffset,default_gatewaySuffix] bearer:[self getTokenString]]==0)
				{
                    NSLog(@"%@?GET MsgBox Error",prefix);
                    self.icnLoginState = IcnLoginFailed;
                    break;
                }
                self.icnLoginState = IcnLoginWaitGetMsgBox;
                break;
                
				//---------
				// GET sent to Server - waiting for HTTP Response
				//---------
            case IcnLoginWaitGetMsgBox:
                looper = NO;
                recall = YES;
                break;
                
				//---------
				// GOT HTTP response from GW/iControl
				//---------
            case IcnLoginDoneGetMsgBox:
                if (self.URLloginStatus == HTTP_200) {
					//SIG = valid data request.  Response = JSON
                    self.icnLoginState = IcnLoginGoodGetMsgBox;
                    break;
                }
                else if (self.URLloginStatus == -1002) {
					//APG-GW  sometimes can not access accounts.....
					self.icnLoginState = IcnLoginUserIdmap;
					recall = YES;
					looper = NO;
					break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE - host invalid or not reachable
                    NSLog(@"%@???GET not deliverable",prefix);
                    self.icnLoginState = IcnLoginFailed;
                    break;
                }
                else if (self.URLloginStatus == HTTP_202) {
					//SIG = data Unavailable.  Response = JSON  (no entries found, empty)
                }
                else if (self.URLloginStatus == HTTP_400) {
					//SIG = bad request (MGW 403 DEVELOPER INACTIVE).  Response = HTML<h1>Invalid Request</h1>
                }
                else if (self.URLloginStatus == HTTP_401) {
					//Invalid TOKEN
					self.icnLoginState = IcnLoginGot401;
					break;
                }
                else if (self.URLloginStatus == HTTP_404) {
					//SIG-GW = not found.  Response = TEXT (invalid prefix URI, semantic combination)
                }
                NSLog(@"%@???GET code=%li Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailed;
                break;
				//---------
				// GOT HTTP response from /healthcheck (sig_healthcheck.html)
				//---------
            case IcnLoginGoodGetMsgBox:
#if TRACE_MSGBOX
                NSLog(@"%@MSGBOX <= \n%@", prefix,self.URLloginResponse);
#endif
				json = self.URLloginResponse;
                objects = [jsonUtils decode:json];
				if (objects==nil) {
                    NSLog(@"%@??? Response is TEXT\n%@",prefix,json);
                    self.icnLoginState = IcnLoginFailed;
                    break;
				}
				else if (![objects isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"%@??? Response is NOT JSON\n%@",prefix,json);
                    self.icnLoginState = IcnLoginFailed;
                    break;
				}
				id msglist = [objects objectForKey:sigkey_messageList];
				if ([[self delegate] respondsToSelector:@selector(apiMachine:mapID:time:)]) {
					[[self delegate] apiMachine:apiMachineSelf mapID:msglist time:self.URLloginTime];
				}
				mOffset = [[msglist objectForKey:sigkey_mOffset] integerValue];
				mLimit = [[msglist objectForKey:sigkey_mLimit] integerValue];
				mTotal = [[msglist objectForKey:sigkey_mTotal] integerValue];

				id messages = [msglist objectForKey:sigkey_messages];
				NSEnumerator *enum_msg = [messages objectEnumerator];
				id msgid;
				while ((msgid = [enum_msg nextObject])) {
					if ([[self delegate] respondsToSelector:@selector(apiMachine:deviceID:time:)]) {
						[[self delegate] apiMachine:apiMachineSelf deviceID:msgid time:self.URLloginTime];
					}
				}
				if ((mTotal>0) && ((mOffset + mLimit) < mTotal)) {
					mOffset += mLimit;
					self.icnLoginState = IcnLoginUserMsgBox;
				}
				else
					self.icnLoginState = IcnLoginUserIdmap;
                looper = NO;
                recall = YES;
				break;
#endif
				
			//---------
			// Here with a TOKEN.  Do a FORCED REST COMMAND
			//---------
            case IcnLoginUserGetForce:
				//this uses an HREF with the FULL REST command
				if ([[HttpProxy shared] getAuthorized:@"" request:[NSString stringWithFormat:@"%@%@",self.restForce,default_gatewaySuffix] bearer:[self getTokenString]]==0) {
                    NSLog(@"%@?GET Error",prefix);
                    self.icnLoginState = IcnLoginFailed;
                    break;
				}
                self.icnLoginState = IcnLoginWaitGetForce;
                break;
                
			//---------
			// GET sent to iControl - waiting for HTTP Response
			//---------
            case IcnLoginWaitGetForce:
                looper = NO;
                recall = YES;
                break;
                
			//---------
			// GOT HTTP response from GW/iControl
			//---------
            case IcnLoginDoneGetForce:
                if (self.URLloginStatus == HTTP_200) {
                    self.icnLoginState = IcnLoginGoodGetForce;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE
                    NSLog(@"%@???GET not deliverable",prefix);
                    self.icnLoginState = IcnLoginFailed;
                    break;
                }
                else if (self.URLloginStatus == HTTP_500) {
                    self.icnLoginState = IcnLoginGot401;
                    break;
                }
                else if (self.URLloginStatus == HTTP_401) {
					//SIG    = unauthorized (token).  Response = "unauthorized"
                    self.icnLoginState = IcnLoginGot401;
                    break;
                }
                else if (self.URLloginStatus == HTTP_404) {
					//INVALID REST COMMAND  = "No such resource"
                }
                else if (self.URLloginStatus == HTTP_503) {
                    //APG-GW = service Unavailable. Response = JSON
                    self.icnLoginState = IcnLoginUserGetForce;
					looper = NO;
					recall = YES;
					break;
                }
                NSLog(@"%@???GET code=%li Result=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailed;
                break;
				
			//---------
			// GOT HTTP response from GW/iControl for FORCE reset command
			//---------
            case IcnLoginGoodGetForce:
                NSLog(@"%@*** Obtained Force Response",prefix);
				json = self.URLloginResponse;
                objects = [jsonUtils decode:json];
				[self performSelector:@selector(pushTheForceGet:) withObject:objects afterDelay:0.0];
				
                self.icnLoginState = IcnLoginComplete;
                break;

				
			//---------
			// Here with a TOKEN.  Do a FORCED REST COMMAND
			//---------
            case IcnLoginUserPostForce:
                if ([[HttpProxy shared] postAuthorized:default_gatewayURI request:self.restForce bearer:[self getTokenString]]==0) {
                    NSLog(@"%@POST Error",prefix);
                    self.icnLoginState = IcnLoginFailed;
                    break;
                }
                self.icnLoginState = IcnLoginWaitPostForce;
                break;
                
			//---------
			// POST sent to iControl.  Park until completed
			//---------
            case IcnLoginWaitPostForce:
                looper = NO;
                recall = YES;
                break;
                
				//---------
				// GOT HTTP response from GW/iControl
				//---------
            case IcnLoginDonePostForce:
                if (self.URLloginStatus == HTTP_200) {
					//The request was accepted and completed.
                    self.icnLoginState = IcnLoginGoodPostForce;
                    break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE
                    NSLog(@"%@???POST not deliverable",prefix);
                    self.icnLoginState = IcnLoginFailed;
                    break;
                }
                else if (self.URLloginStatus == HTTP_401) {
					//SIG    = unauthorized (token).  Response = "unauthorized"
                    self.icnLoginState = IcnLoginGot401;
                    break;
                }
                else if (self.URLloginStatus == HTTP_404) {
					//INVALID REST COMMAND  = "No such resource"
                }
                NSLog(@"%@???POST code=%li Response=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
                self.icnLoginState = IcnLoginFailed;
                break;
				
			//---------
			// GOT HTTP response from GW/iControl for FORCE reset command
			//---------
            case IcnLoginGoodPostForce:
                NSLog(@"%@*** Obtained Force Response",prefix);
				json = self.URLloginResponse;
				[self performSelector:@selector(pushTheForcePost:) withObject:json afterDelay:0.0];
                self.icnLoginState = IcnLoginComplete;
                break;
				
				
            case IcnLoginComplete:
//				[[TheDropdown shared] queNavPrompt:@"*Machine Completed*"];
                looper = NO;
                recall = NO;
                break;

            case IcnLoginFailed:
//				[[TheDropdown shared] queNavPrompt:@"?Machine Failed"];
                looper = NO;
                recall = NO;
                break;

            default:
                looper = NO;
                recall = NO;
                break;
        }
    }
    if (recall) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(icnLoginMachine) object:nil];
        [self performSelector:@selector(icnLoginMachine) withObject:nil afterDelay:recalltime];
    }
	
	NSInteger nowrunning = self.machineRunning;
	if (self.icnLoginState>=IcnLoginInit)
		self.machineRunning|=1;
	else
		self.machineRunning&=~1;
	if (nowrunning!=self.machineRunning) {
		if ([self.delegate respondsToSelector:@selector(apiMachine:running:)]) {
			[self.delegate apiMachine:apiMachineSelf running:self.machineRunning];
		}
	}
}

//Non-Blocking send to delegates
-(void)pushTheForceGet:(id)objects {
	if ([self.delegate respondsToSelector:@selector(apiMachine:forceID:time:)]) {
		[self.delegate apiMachine:apiMachineSelf forceID:objects time:self.URLloginTime];
	}
	if ([self.delegate2 respondsToSelector:@selector(apiMachine:forceID:time:)]) {
		[self.delegate2 apiMachine:apiMachineSelf forceID:objects time:self.URLloginTime];
	}
}
-(void)pushTheForcePost:(NSString *)json {
	if ([self.delegate respondsToSelector:@selector(apiMachine:forcePostID:)]) {
		[self.delegate apiMachine:apiMachineSelf forcePostID:json];
	}
	if ([self.delegate2 respondsToSelector:@selector(apiMachine:forcePostID:)]) {
		[self.delegate2 apiMachine:apiMachineSelf forcePostID:json];
	}
}

//Here if APP or WEBView Return a URL
- (BOOL) browserReturnURL:(NSURL *)url {

    if (self.icnLoginState == IcnLoginWaitGetGoogleWeb) {
        self.icnLoginState = IcnLoginDoneGetGoogleWeb;
        self.authURL = url;
		[self apiWeb:nil running:NO];
        return YES;
    }

    if (self.oauthState == OauthWaitCode) {
        self.oauthState = OauthDoneCode;
        self.authURL = url;
		[self apiWeb:nil running:NO];
        return YES;
    }
    return NO;
}

//Here with delayed response from POST/GET - resume machine
- (void) httpProxy:(HttpProxy *)httpProxy seq:(NSInteger)seq code:(NSInteger)code response:(NSString *)response time:(float)diff {
//	NSLog(@"%@ PROXY SEQ:%i CODE=%i RESPONSE=\n%@\n",prefix,seq,code,response);
	
	self.URLloginStatus = code;
	self.URLloginResponse = response;
	self.URLloginTime = diff;
	self.URLloginError = [HttpProxy shared].URLerror;
	[self httpGetResponse];
}


- (void) httpGetResponse {
    if (self.oauthState == OauthWaitToken) {
        self.oauthState = OauthDoneToken;
		self.oauthDate = [NSDate date];
        return;
    }

	//Just waiting for INITIAL TEST RESPONSE?
    if (self.icnLoginState == IcnLoginWaitTest) {
        self.icnLoginState = IcnLoginDoneTest;
		if (self.URLloginStatus<HTTP_NONE)
			[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"?HTTP %li",(long)self.URLloginStatus]];
        return;
    }
	//Waiting for REAL response
	if ((self.URLloginStatus!=HTTP_200)&&(URLloginStatus!=HTTP_202))
		[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"?HTTP %li",(long)self.URLloginStatus]];
	//Just a WEB PAGE?
    if (self.icnLoginState == IcnLoginWaitGetHealth) {
        self.icnLoginState = IcnLoginDoneGetHealth;
        return;
    }
    if (self.icnLoginState == IcnLoginWaitGetGWnet) {
        self.icnLoginState = IcnLoginDoneGetGWnet;
        return;
    }
    if (self.icnLoginState == IcnLoginWaitGetAPPnet) {
        self.icnLoginState = IcnLoginDoneGetAPPnet;
        return;
    }
#if 0
	//JSON, so Fix UP URIs
	if (default_backsideURI.length>0) {
		self.URLloginResponse = [self.URLloginResponse stringByReplacingOccurrencesOfString:default_backsideURI withString:[NSString stringWithFormat:@"%@%@",default_gatewayURI,default_gatewayPrefix]];
	}
#endif
    if (self.icnLoginState == IcnLoginWaitGetPorts) {
        self.icnLoginState = IcnLoginDoneGetPorts;
        return;
    }
    if (self.icnLoginState == IcnLoginWaitGetThrottle) {
        self.icnLoginState = IcnLoginDoneGetThrottle;
        return;
    }
    if (self.icnLoginState == IcnLoginWaitGetStock) {
        self.icnLoginState = IcnLoginDoneGetStock;
        return;
    }
    if (self.icnLoginState == IcnLoginWaitGetGoogleID) {
        self.icnLoginState = IcnLoginDoneGetGoogleID;
        return;
    }
    if (self.icnLoginState == IcnLoginWaitGetBasic) {
        self.icnLoginState = IcnLoginDoneGetBasic;
        return;
    }
    if (self.icnLoginState == IcnLoginWaitGetForce) {
        self.icnLoginState = IcnLoginDoneGetForce;
        return;
    }
    if (self.icnLoginState == IcnLoginWaitPostForce) {
        self.icnLoginState = IcnLoginDonePostForce;
        return;
    }
}


//========================================================================================
#pragma mark - Authorization Machine
//========================================================================================


static NSDateFormatter *dateFormatter = nil;

//Here at startup - Get inernal Dictionary of OauthToken
-(void)initializeOauthJson {
	if (self.oauthJson2 == nil) {
		self.oauthJson2 = [NSMutableDictionary dictionaryWithCapacity:100];
	}
	[self.oauthJson2 removeAllObjects];	//Since likely a SHARED dictionary
	if (self.oauthJson3 == nil) {
		self.oauthJson3 = [NSMutableDictionary dictionaryWithCapacity:100];
	}
	[self.oauthJson3 removeAllObjects];	//Since likely a SHARED dictionary
#if 0
	NSString * json = [self readOauthToken2];
	if ((json==nil)||(json.length==0)) {
		NSLog(@"%@! No TOKEN2 Information.",prefix);
	}
	else {
		id objects = [jsonUtils decode:json];
		if ((objects==nil)||![objects isKindOfClass:[NSDictionary class]]) {
			NSLog(@"%@! Invalid TOKEN2 Information.",prefix);
		}
		else {
			//Got a saved JSON Dictionary!
			[self.oauthJson2 addEntriesFromDictionary:objects];
			NSLog(@"%@* Loaded TOKEN2 Information (%lu).",prefix,(unsigned long)self.oauthJson2.count);
		}
	}

	json = [self readOauthToken3];
	if ((json==nil)||(json.length==0)) {
		NSLog(@"%@! No TOKEN3 Information.",prefix);
	}
	else {
		id objects = [jsonUtils decode:json];
		if ((objects==nil)||![objects isKindOfClass:[NSDictionary class]]) {
			NSLog(@"%@! Invalid TOKEN3 Information.",prefix);
		}
		else {
			//Got a saved JSON Dictionary!
			[self.oauthJson3 addEntriesFromDictionary:objects];
			NSLog(@"%@* Loaded TOKEN3 Information (%lu).",prefix,(unsigned long)self.oauthJson3.count);
		}
	}
#endif
	self.oauthJson = self.oauthJson2;

	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	}
}

-(BOOL)checkTokenExpired {
	NSString * value = [self.oauthJson objectForKey:OAUTH_KEY__DATE];
	if (value==nil)
		return YES;
	NSDate * newDate = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
	NSTimeInterval elapsed = [newDate timeIntervalSinceNow] * -1;
	//	NSLog(@"%@Token Elapsed = %+.0f seconds (%@)",prefix,elapsed,newDate);
	value = [self.oauthJson objectForKey:OAUTH_KEY_EXPIRES];
	if (value==nil)
		return YES;
	NSTimeInterval expires = [value doubleValue];
	if (elapsed>=expires)
		return YES;
	NSLog(@"%@Token Remaining %+.0f seconds",prefix,expires-elapsed);
	return NO;
}

typedef enum {
    OauthFailed = -2,
    OauthComplete = -1,
	OauthStart = 0,             //*** Startup
	
    OauthNewCode = 5,
    OauthWaitCode = 7,
    OauthDoneCode = 9,
	
    OauthNewToken = 10,
    OauthRefreshToken = 11,
    OauthRequestToken = 12,
    OauthWaitToken = 14,
    OauthDoneToken = 16,
    OauthGoodToken = 17

} _OauthLogin;

//Here from GATEWAY to Enter - Delegate to Return
-(void) checkOauthToken:(NSInteger)mode {
	//	[[TheDropdown shared] queNavPrompt:@"*OAUTH*"];
	if ([[self delegate] respondsToSelector:@selector(apiMachine:token:time:status:)]) {
		[[self delegate] apiMachine:apiMachineSelf token:itFailed time:0.0 status:0];
	}
	if (mode==0)
    	self.oauthState = OauthStart;
	else if (mode>0)
    	self.oauthState = OauthNewCode;
	else
    	self.oauthState = OauthRefreshToken;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(oauthMachine) object:nil];
    [self performSelector:@selector(oauthMachine) withObject:nil afterDelay:0.0];
}

//Here to RUN the OAUTH MACHINE
-(void) oauthMachine {
    BOOL looper = YES;
    BOOL recall = NO;
    NSString * token;
	NSString * callURL;
    NSString * json;
    id objects;
    
    while (looper) {
//		NSLog(@"%@--------->OAUTH Machine = %li",prefix,(long)self.oauthState);
        switch (self.oauthState) {
				
				//---------
				//Make a GUESS on Validity/Availability of TOKEN
				//---------
			case OauthStart:
				token = [self getTokenString];
                if ((token!=nil)&&(token.length>0)) {
                    NSString * scopes = [self getScopeString];		//Get AUTHORIZED Scopes
                    NSLog(@"%@Existing Token = %@,  Authorized Scope=\"%@\"",prefix,token,scopes);

					//Send a copy of the TOKEN to ViewController for display
                    [self tellAuthToDelegate:AuthStateTokenOK];
					if ([[self delegate] respondsToSelector:@selector(apiMachine:token:time:status:)]) {
						[[self delegate] apiMachine:apiMachineSelf token:self.oauthJson time:0.0 status:200];
					}

					if ([self checkTokenExpired])
						self.oauthState = OauthRefreshToken;	//Token Looks BAD
					else
						self.oauthState = OauthComplete;		//Token has NOT expired
                }
                else {
#if 0
					if (![self validateScopes:self.oauthScopesRequested]) {
						[self tellAuthToDelegate:AuthStateScopeError];
						[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"?ScopeErr?"]];
						self.oauthState = OauthFailed;
						break;
					}
#endif
#if USE_APR_SCOPE
					self.oauthScopesApproved = self.oauthScopesRequested;
#endif
//					if (self.oauth3Leg)
//						self.oauthState = OauthNewCode;			//Don't have a TOKEN = OAUTH 3-leg
//					else
						self.oauthState = OauthNewToken;		//Don't have a TOKEN = Oauth 2-leg
                }
				break;
				
				//---------
				// 3-LEG: Start OVER - clear fields and call OAUTH LOGIN web page
				//---------
            case OauthNewCode:
				looper = NO;
				recall = YES;
				if ([TheDropdown shared].pendingPrompts>0) {
					break;
				}
				[self eraseOauthInfo];
                self.oauthCode = DEFAULT_NOAUTHCODE;
#if USE_APR_SCOPE
				self.oauthScopesApproved = DEFAULT_NOSCOPES;
#endif
				callURL = self.oauthHost;
				callURL = [callURL stringByAppendingFormat:default_loginFormat,default_loginPrefix,self.publicKey,self.redirectURI,self.oauthScopesRequested];
				self.oauthState = OauthWaitCode;
				[self tellAuthToDelegate:AuthStateWaitBrowser];
				[self startWebView:callURL callbackHost:self.callbackHost title:self.oauthWebTitle];
                break;
			case OauthWaitCode:
                looper = NO;
                recall = YES;
                break;
				//---------
				// <callback>?code=qaJfiJ5TNW2l6JTAI5KT
				// <callback>?error=invalid_scope   {scope is undefined or blank}
				// <callback>?error=access_denied   {all scopes are 2-LEG only (SMS,SPEECH,DC), or 3-Leg canceled/failed (TL,MIM)}
				// SCOPE approval is ALL requested or Nothing...
				//---------
            case OauthDoneCode:
                looper = looper;	//Dummy
                
                NSString * result_code = nil;
                NSString * result_error= nil;
#if USE_APR_SCOPE
                NSString * result_scope= nil;
#endif
                NSString * query = [self.authURL query];
				NSLog(@"%@ CallBack QUERY = %@",prefix,query);
				
                for(NSString *keyValuePairString in [query componentsSeparatedByString:@"&"]) {
                    NSArray *keyValuePairArray = [keyValuePairString componentsSeparatedByString:@"="];
                    if ([keyValuePairArray count] < 2)
                        continue; // Verify that there is at least one key, and at least one value.  Ignore extra = signs
                    NSString *key =  [[keyValuePairArray objectAtIndex:0] lowercaseString];
                    NSString *value= [keyValuePairArray objectAtIndex:1];
                    if ([key isEqualToString:RECALL_CODE]) {
                        result_code = value;
                    }
#if USE_APR_SCOPE
                    else if ([key isEqualToString:RECALL_SCOPE]) {
                        result_scope=value;
                    }
#endif
                    else if ([key isEqualToString:RECALL_ERROR]) {
                        result_error = value;
                    }
                }
                
                if (result_error!=nil) {
                    NSLog(@"%@!!!Authorization = %@",prefix,result_error);
                    [self tellAuthToDelegate:AuthStateCodeDenied];
					[[TheDropdown shared] queNavPrompt:[NSString stringWithFormat:@"?%@?",result_error]];
                    self.oauthState = OauthFailed;
                    break;
                }
#if 0
                if ((result_code==nil)||(result_code.length<1)||(result_code.length>24)) {
                    NSLog(@"%@?Authorization Code Size",prefix);
                    [self tellAuthToDelegate:AuthStateCodeSizeError];
                    self.oauthState = OauthFailed;
                    break;
                }
#endif
				//Have a AUThORIZATION CODE!
                self.oauthCode = result_code;
#if USE_APR_SCOPE
				if (result_scope==nil) {
					self.oauthScopesApproved = self.oauthScopesRequested;
				}
				else {
					self.oauthScopesApproved = result_scope;
				}
#endif
                NSLog(@"%@Authentication CODE =\"%@\"",prefix,self.oauthCode);
                self.oauthState = OauthNewToken;
                break;
				
				//---------
				// Request a NEW Token
				//---------
            case OauthNewToken:
				[self eraseOauthInfo];
				[[TheDropdown shared] queNavPrompt:@"*RequestNew Token *"];
                self.oauthBody = @"";
				if (self.oauth3Leg) {
					self.oauthBody = [self.oauthBody stringByAppendingString:@"grant_type=authorization_code"];
					self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&redirect_uri=%@",[self.redirectURI stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
					self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&code=%@",self.oauthCode];
				}
				else {
					self.oauthBody = [self.oauthBody stringByAppendingString:@"grant_type=client_credentials"];
				}
                self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&scope=%@",self.oauthScopesRequested];				//Use NEW approved SCOPES
                self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&client_id=%@",self.publicKey];
                self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&client_secret=%@",self.secretKey];
				
				self.oauthState	= OauthRequestToken;
				break;
				//---------
				// Tried to use TOKEN, but got "401-Invalid Token"  (EXIPRE IS 1 YEAR1!)
				//---------
            case OauthRefreshToken:
                token = [self getRefreshString];
                NSLog(@"%@RefreshCode Token = \"%@\"",prefix,token);
                if ((token==nil)||(token.length==0)) {
                    self.oauthState = OauthNewToken;
					[self.oauthJson setObject:@"" forKey:OAUTH_KEY_REFRESH];
                    break;
                }
				[[TheDropdown shared] queNavPrompt:@"* Refresh Token *"];
                self.oauthCode = DEFAULT_NOAUTHCODE;

                self.oauthBody = @"";
                self.oauthBody = [self.oauthBody stringByAppendingString: @"grant_type=refresh_token"];
                self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&refresh_token=%@",token];
#if 0
				if (self.oauth3Leg) {
	                self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&redirect_uri=%@",[self.redirectURI stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				}
                self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&scope=%@",[self getScopeString]];		//Use SAME scopes
#endif
                self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&client_id=%@",self.publicKey];
                self.oauthBody = [self.oauthBody stringByAppendingFormat:@"&client_secret=%@",self.secretKey];
				self.oauthState	= OauthRequestToken;
				break;
				
            case OauthRequestToken:
#if TRACE_TOKENS
                NSLog(@"%@Body => \n%@", prefix,self.oauthBody);
#endif
				callURL = default_oauthCommand;
				if ([[HttpProxy shared] post:self.oauthHost request:callURL body:self.oauthBody]==0) {
                    NSLog(@"%@?Post Body Error=\n%@\n",prefix,self.oauthBody);
					self.oauthBody = @"";
                    [self tellAuthToDelegate:AuthStateCodePostError];
                    self.oauthState = OauthFailed;
                    break;
                }
                [self tellAuthToDelegate:AuthStateWaitPost];
                self.oauthState = OauthWaitToken;
//              break;
			case OauthWaitToken:
                looper = NO;
                recall = YES;
                break;

            case OauthDoneToken:
                if (URLloginStatus == HTTP_200) {
                    self.oauthState = OauthGoodToken;
                    break;
                }
				self.oauthBody = @"";
                if ((URLloginStatus == HTTP_500)||(URLloginStatus == HTTP_400)||(URLloginStatus == HTTP_401)) {
					//Probably a BAD reauthentication code (authentication info no longer in Gateway)
					// or 500 = CODE expired (max life 5 minutes.... "fault
					// 400 = Bad Request/Fault.  500 = Invalid Request
					// 400 = "Invalid_client"
					json = self.URLloginResponse;
                    objects = [jsonUtils decode:json];
					NSString * reason = [objects objectForKey:@"Error"];
					if (reason!=nil) {
						NSLog(@"%@???POST Code=%li Error=\"%@\"",prefix,(long)self.URLloginStatus,reason);
#if 0
						if (([self getTokenString].length>0)&&([self getRefreshString].length>0)) {
							//should be "Invalid Request"
							[self eraseOauthInfo];
							self.oauthState = OauthNewCode;
							break;
						}
#endif
						[self tellAuthToDelegate:AuthStateCodePostFail];
						self.oauthState = OauthFailed;
						break;
					}
					reason = [objects objectForKey:@"error"];	//sig response
					if (reason!=nil) {
						NSLog(@"%@???POST Code=%li ErrorReason=\"%@\"",prefix,(long)self.URLloginStatus,reason);
						if ([reason isEqualToString:@"invalid_grant"]) {
							[self eraseOauthInfo];
							self.oauthState = OauthNewCode;
							break;
						}
						if ([reason isEqualToString:@"invalid_client"]) {
							[self eraseOauthInfo];
							[[TheDropdown shared] queNavPrompt:@"?ClientID?"];
						}
						if ([reason isEqualToString:@"invalid_scope"]) {
							//No bad "scopes" in code, so must be "unauthorized for clientID"
							[self eraseOauthInfo];
							[[TheDropdown shared] queNavPrompt:@"?Scope?"];
						}
						[self tellAuthToDelegate:AuthStateCodePostFail];
						self.oauthState = OauthFailed;
						break;
					}
#if 0
					reason = [objects objectForKey:KEY_FAULT];
					if (reason!=nil) {
						NSLog(@"%@???POST Code=%li Fault=\"%@\"",prefix,(long)self.URLloginStatus,reason);
						if (([self getTokenString].length>0)&&([self getRefreshString].length>0)) {
							//should be "Invalid Request"
							//							[self writeRefreshSetting:@""];
							[self eraseOauthInfo];
							self.oauthState = OauthNewCode;
							break;
						}
						[self tellAuthToDelegate:AuthStateCodePostFail];
						self.oauthState = OauthFailed;
						break;
					}
#endif
					NSLog(@"%@???POST Code=%li Resp=\"%@\"",prefix,(long)self.URLloginStatus,self.URLloginResponse);
					self.oauthState = OauthFailed;
					break;
                }
                else if ((self.URLloginStatus==HTTP_9999)||(self.URLloginStatus<HTTP_NONE)) {
                    //UNDELIVERABLE
                    NSLog(@"%@???POST not deliverable",prefix);
                    [self tellAuthToDelegate:AuthStateCodePostFail];
                }
                else {
					json = self.URLloginResponse;
                    objects = [jsonUtils decode:json];
                    NSLog(@"%@?POST Result=%li json=\"%@\"",prefix,(long)self.URLloginStatus,json);
                    [self tellAuthToDelegate:AuthStateTokenFail];
                }
				self.oauthState = OauthFailed;
                break;

			//---------
			// Gateway returned HTTP:200 and JSON data
			//---------
            case OauthGoodToken:
				if ([TheDropdown shared].pendingPrompts>0) {
					looper = NO;
					recall = YES;
					break;
				}
				json = self.URLloginResponse;
                objects = [jsonUtils decode:json];
				if ((json==nil)||(json.length==0)||(objects==nil)||![objects isKindOfClass:[NSDictionary class]]) {
                    [self tellAuthToDelegate:AuthStateTokenFail];
					self.oauthState = OauthFailed;
                    break;
				}
				//Make a UPDATED JSON with DATE
				[self.oauthJson removeAllObjects];	//Since likely a SHARED dictionary
				[self.oauthJson addEntriesFromDictionary:objects];
                NSLog(@"%@Tokens(%lu) <= objects", prefix,(unsigned long)self.oauthJson.count);
				token = [NSString stringWithFormat:@"%0.8f",[self.oauthDate timeIntervalSince1970]];//seconds since 1970 DOT fraction of second
				[self.oauthJson setValue:token forKey:OAUTH_KEY__DATE];
				token = [self.oauthJson valueForKey:OAUTH_KEY__DATE];
				NSDate * newDate = [NSDate dateWithTimeIntervalSince1970:[token doubleValue]];
				NSLog(@"%@ Date = %@",prefix,[dateFormatter stringFromDate:newDate]);
				[self.oauthJson setValue:self.oauthBody forKey:OAUTH_KEY__BODY];
				[self.oauthJson setValue:self.oauthScopesRequested forKey:OAUTH_KEY__SCOPE];
				self.oauthBody = @"";
#if 0
				token = [jsonUtils encode:self.oauthJson];
#else
				NSError * error = nil;
				token = [jsonUtils encode:self.oauthJson error:&error];
#endif
                [self writeOauthSetting:token];
#if TRACE_TOKENS
                NSLog(@"%@Tokens(%lu) <= \n%@", prefix,(unsigned long)self.oauthJson.count,token);
#endif

 				if ([[self delegate] respondsToSelector:@selector(apiMachine:token:time:status:)]) {
					[[self delegate] apiMachine:apiMachineSelf token:self.oauthJson time:self.URLloginTime status:self.URLloginStatus];
				}
               self.oauthCode = DEFAULT_NOAUTHCODE;
                [self tellAuthToDelegate:AuthStateTokenOK];
				self.oauthState = OauthComplete;
                break;


            case OauthComplete:
//				[[TheDropdown shared] queNavPrompt:@"*OAUTH Completed*"];
				[self returnCheckOauthToken];
                looper = NO;
                recall = NO;
                break;
				
            case OauthFailed:
				if ([[self delegate] respondsToSelector:@selector(apiMachine:token:time:status:)]) {
					[[self delegate] apiMachine:apiMachineSelf token:itFailed time:self.URLloginTime status:self.URLloginStatus];
				}
//				[[TheDropdown shared] queNavPrompt:@"?OAUTH Failed"];
				[self eraseOauthInfo];
				[self returnCheckOauthToken];
                looper = NO;
                recall = NO;
                break;
				
            default:
                looper = NO;
                recall = NO;
                break;
        }
    }
    if (recall) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(oauthMachine) object:nil];
        [self performSelector:@selector(oauthMachine) withObject:nil afterDelay:0.5];
    }
}


//========================================================================================
#pragma mark - WebView Authentication Server
//========================================================================================

//---------------------------
//From ApiGateway
//---------------------------
- (void)startWebView:(NSString *)callURL callbackHost:(NSString *)callBack title:(NSString *)title {
	[[ApiWeb shared] startWebView:callURL callbackHost:callBack title:title];
}
- (void)stopWebView {
	[[ApiWeb shared] stopWebView];
}

//---------------------------
//From Delegate
//---------------------------
- (void) apiWeb:(ApiWeb *)ApiWeb running:(BOOL)running {
	if (running) {
		self.webViewRunning = YES;
		self.machineRunning|=2;
		if ([self.delegate respondsToSelector:@selector(apiMachine:running:)]) {
			[self.delegate apiMachine:apiMachineSelf running:self.machineRunning];
		}
	}
	else {
		self.webViewRunning = NO;
		self.machineRunning&=~2;
		if ([self.delegate respondsToSelector:@selector(apiMachine:running:)]) {
			[self.delegate apiMachine:apiMachineSelf running:self.machineRunning];
		}
		if (self.oauthState == OauthFailed) {
			[self tellAuthToDelegate:AuthStateBrowserError];
		}
	}
}
- (void) apiWeb:(ApiWeb *)ApiWeb gotError:(NSError *)error {
	if (self.icnLoginState == IcnLoginWaitGetGoogleWeb) {
		self.icnLoginState = IcnLoginFailGetGoogleWeb;
		[self tellAuthToDelegate:AuthStateBrowserError];
	}
	if (self.oauthState == OauthWaitCode) {
		self.oauthState = OauthFailed;
		[self tellAuthToDelegate:AuthStateBrowserError];
	}
}
- (void) apiWeb:(ApiWeb *)ApiWeb gotHttpStatus:(NSInteger)status; {
	if (status>HTTP_200) {
		[self performSelector:@selector(stopWebView) withObject:nil afterDelay:3.0];
		if (self.oauthState == OauthWaitCode) {
			self.oauthState = OauthFailed;
		}
		if (self.icnLoginState == IcnLoginWaitGetGoogleWeb) {
			self.icnLoginState = IcnLoginFailGetGoogleWeb;
		}
	}
}

//DELEGATE RETURN FOR WEB VIEW
- (void) apiWeb:(ApiWeb *)ApiWeb gotReturnURL:(NSURL *)url {
	[self browserReturnURL:url];
}

- (BOOL) apiWeb:(ApiWeb *)ApiWeb approveClickURL:(NSURL *)url {
	NSString * scheme = [[url scheme] lowercaseString];
	NSString * host = [[url host] lowercaseString];
//	NSInteger  port = [url port];
//	if (port!=0) {
//		host = [NSString stringWithFormat:@"%@:%i",host,port];
//	}
#if 0
	if ([scheme isEqualToString:@"sms"]) {
		//"SMS:" only works on phone WITH IOS "MESSAGES" application (so NOT Simulator)
		NSLog(@"%@ Click SMS => %@\n ",prefix,url);
		//Called "short number" can only be accessed from (real) AT&T SMS Service (not VZ or TMO phone, or any iPad)
		//SMS can be sent to AT&T from ANY AT&T phone with SMS service
		return YES;
	}
	else
#endif
//	NSString * hostAddress = [NSString stringWithFormat:@"%@:%@",[[url host] lowercaseString],[url port]];
	if ([scheme isEqualToString:@"https"]) {
		if ([host isEqualToString:@"accounts.google.com"])		//Gateway
			return YES;
		if ([host isEqualToString:@"www.google.com"])	//Oauth redirect /CONSENT
			return YES;
	}
	else if ([scheme isEqualToString:@"http"]) {
//		if ([hostAddress isEqualToString:self.activeGateway])			//Bonjour
//			return YES;
		if ([[url host] isEqualToString:@"www.google.com"])		//Here to CREATE account....GET Video, Wrong size screen, But WORK
			return YES;
		if ([[url host] isEqualToString:@"developers.google.com"])		//Gateway
			return YES;
	}
	return NO;
}

//---------------------------
//From ViewController
//---------------------------
- (void)useWebViewController:(UIViewController *)view {
	[[ApiWeb shared] useWebViewController:view];
}
-(void)willRefreshWebView {
	if (self.webViewRunning)
		[[ApiWeb shared] willRefreshWebView];
}
- (void)didRefreshWebView {
	if (self.webViewRunning)
		[[ApiWeb shared] didRefreshWebView];
}



//========================================================================================
#pragma mark - Data Store
//========================================================================================

-(NSString *) readOauthToken2 {
	NSString * oauth = [[NSUserDefaults standardUserDefaults] stringForKey:SETTING_oauth2];
    if (oauth==nil)
        oauth = @"";
    return oauth;
}
-(NSString *) readOauthToken3 {
	NSString * oauth = [[NSUserDefaults standardUserDefaults] stringForKey:SETTING_oauth3];
    if (oauth==nil)
        oauth = @"";
    return oauth;
}
-(NSString *)getTokenString {
	id object = [self.oauthJson objectForKey:OAUTH_KEY_ACCESS];
	if (object==nil)
		return @"";
	return [NSString stringWithString:object];
}
-(NSString *)getRefreshString {
	id object = [self.oauthJson objectForKey:OAUTH_KEY_REFRESH];
	if (object==nil)
		return @"";
	return [NSString stringWithString:object];
}
-(NSString *)getScopeString {
	id object = [self.oauthJson objectForKey:OAUTH_KEY__SCOPE];
	if (object==nil)
		return @"";
	return [NSString stringWithString:object];
}


-(void)eraseOauthInfo {
	[self writeOauthSetting:@""];
	[self.oauthJson removeAllObjects];
}
-(NSString *) writeOauthSetting:(NSString *)newOauth {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	NSString * oldOauth = [defaults stringForKey:SETTING_oauth2];
	newOauth = [newOauth stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//	if (![oldOauth isEqualToString:newOauth]) {
		[defaults setObject:newOauth forKey:SETTING_oauth2];	//READ-ONLY in settings
        oldOauth = [defaults stringForKey:SETTING_oauth2];
		[defaults synchronize];
 //   }
    return oldOauth;
}


//*********************************
//Here from ViewControler to set REQUESTED scopes
//*********************************
-(BOOL)pushTheScopes:(NSString *)scopes {
	if (scopes.length==0)
		return YES;
	if ([self validateScopes:scopes]) {
		self.oauthScopesRequested = scopes;
		return YES;
	}
	self.oauthScopesRequested = DEFAULT_NOSCOPES;
	return NO;
}

//*********************************
//Here from ViewControler to READ the AUTHORIZED scopes
//Note that ALL requested SCOPES must be approved or OAUTH will Fail.
//Probably best is to keep ALL separate, and manage 11+ tokens....
//*********************************
-(NSString *)pullTheScopes {
	return [self getScopeString];
}

-(BOOL)validateScopes:(NSString *)scopes {
	NSInteger oauth2 = 0;
	NSInteger oauth3 = 0;
	NSInteger error = 0;
	NSArray * scopex = [scopes componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
	if (scopex.count==0) {
		error++;		//Must Have at least ONE scope!
	}
	else  {
		for (NSString * scope in scopex) {
			if ([scope isEqualToString:@"SMS"])				//"Broadcast" SMS message to phones
				oauth2++;
			else if ([scope isEqualToString:@"MMS"])		//"Broadcast" MMS message to phones
				oauth2++;
			else if ([scope isEqualToString:@"PAYMENT"])	// Payments
				oauth2++;

			else if ([scope isEqualToString:@"TL"])			//Terminal (device) Location
				oauth3++;
			else if ([scope isEqualToString:@"DC"])			//Device Capabilities (Requires AT&T device on AT&T network)
				oauth3++;
			else
				error++;
		}
	}
	if ((error==0) && (((oauth2==0)&&(oauth3==0))||((oauth3>0)&&(oauth2>0)) ))
		error++;	//Unknown or Undefined SCOPE, or mixing 2 and 3 legged Oauth Requests
	else {
		if (oauth2>0)
			self.oauth3Leg = NO;
		else if (oauth3>0)
			self.oauth3Leg = YES;
	}

	NSLog(@"%@ ScopeSet Ox2=%li Ox3=%li Err=%li {%@}",prefix,(long)oauth2,(long)oauth3,(long)error,scopes);
	if (error==0)
		return YES;
	return NO;
}

- (void)tellAuthToDelegate:(NSInteger)newState {
//    NSLog(@"Token Authentication state %i => %i",self.authState,newState);
    self.authState = newState;
    if ([[self delegate] respondsToSelector:@selector(apiMachine:authState:)]) {
        [[self delegate] apiMachine:apiMachineSelf authState:self.authState];
    }
}





//========================================================================================
#pragma mark - ViewController Action Buttons
//========================================================================================

- (void)gotActionButtonReset {
	NSLog(@"%@ BUTTON===> Reset",prefix);
	self.fakeCode = NO;
	self.oauthCode = DEFAULT_NOAUTHCODE;
#if USE_APR_SCOPE
	self.oauthScopesApproved = DEFAULT_NOSCOPES;
#endif
	[self eraseOauthInfo];
	[[ApiWeb shared] resetWebView];
}


- (void)gotActionButtonExpire {
	NSLog(@"%@ BUTTON===> Set Expired Token",prefix);
	[self.oauthJson setValue:expired_token forKey:OAUTH_KEY_ACCESS];
}
- (void)gotActionButtonInvalid {
	NSLog(@"%@ BUTTON===> Set Invalid Token",prefix);
	[self.oauthJson setValue:invalid_token forKey:OAUTH_KEY_ACCESS];
}
- (void)gotActionCode:(NSString *)code {
	NSLog(@"%@ BUTTON===> Code=%@",prefix,code);
	self.oauthCode = code;
	self.fakeCode = YES;
}

@end
