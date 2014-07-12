/**************************************************************/
/* ktopits -                                                  */
/* ApiMachine.h                                               */
/* KT 08-JUL-2014                                             */
/**************************************************************/

#define USE_DELTAS  0
#define USE_APR_SCOPE 0

#import "HttpProxy.h"
@class HttpProxy;
#import "ApiWeb.h"
@class ApiWeb;

@class ApiMachine;
@protocol ApiMachineDelegate;

@interface ApiMachine : NSObject<
    HttpProxyDelegate,
	ApiWebDelegate
>
{
}


#pragma mark - Properties

@property (nonatomic,assign) id <ApiMachineDelegate> delegate;
@property (nonatomic,assign) id <ApiMachineDelegate> delegate2;

@property (nonatomic)         NSInteger        icnLoginState;
@property (nonatomic)         NSInteger        icnAppState;

@property (nonatomic)         NSInteger        oauthState;
@property (nonatomic)         BOOL             oauth3Leg;
@property (nonatomic, retain) NSString       * oauthCode;
@property (nonatomic, retain) NSString       * oauthScopesRequested;
#if USE_APR_SCOPE
@property (nonatomic, retain) NSString       * oauthScopesApproved;
#endif
@property (nonatomic, retain) NSString       * oauthBody;
@property (nonatomic, retain) NSDate         * oauthDate;
@property (nonatomic, retain) NSMutableDictionary * oauthJson;
@property (nonatomic, retain) NSMutableDictionary * oauthJson2;
@property (nonatomic, retain) NSMutableDictionary * oauthJson3;
@property (nonatomic, retain) NSString       * oauthHTTPport;
@property (nonatomic, retain) NSString       * oauthHTTPSport;
@property (nonatomic, retain) NSString       * oauthHost;
@property (nonatomic, retain) NSString       * oauthWebTitle;

@property (nonatomic)         NSInteger        authState;
@property (nonatomic, retain) NSURL          * authURL;

@property (nonatomic)         BOOL             fakeCode;
@property (nonatomic)         NSInteger        machineRunning;

@property (nonatomic, retain) NSString       * heading;
@property (nonatomic, retain) NSString       * publicKey;
@property (nonatomic, retain) NSString       * secretKey;
@property (nonatomic, retain) NSString       * redirectURI;
@property (nonatomic, retain) NSString       * callbackHost;
@property (nonatomic, retain) NSString       * activeGateway;
@property (nonatomic, retain) NSString       * hostName;

@property (nonatomic, retain) NSString       * restForce;
@property (nonatomic)         BOOL             restForcePost;

@property (nonatomic)         NSInteger        URLloginStatus;
@property (nonatomic, retain) NSString       * URLloginError;
@property (nonatomic, retain) NSString       * URLloginResponse;
@property (nonatomic)         float            URLloginTime;

@property (nonatomic)         BOOL             webViewRunning;
@property (nonatomic, retain) UIViewController * webViewController;



//Define WHICH GATEWAY server to Use (only one at AT&T)
#define XDN_SERVICE_MASK 	0x00FF
#define XDN_SERVICE_ATTAPI 		0x0000	//Normal
#define XDN_SERVICE_FOUNDRY		0x0001	//TESTING APP

#define XDN_CLIENTID_MASK	0x0300
#define XDN_CLIENTID_DEFAULT	0x0000
#define XDN_CLIENTID_FOUNDRY	0x0100
#define XDN_CLIENTID_KTSB		0x0200
#define XDN_CLIENTID_KTPR		0x0400

#define XDN_AUTHMODE_MASK	0x0C00
#define XDN_AUTHMODE_DEFAULT	0x0000
#define XDN_AUTHMODE_INURL		0x0400
#define XDN_AUTHMODE_HEADER		0x0800

#define XDN_OAUTHSRVR_MASK	0x3000
#define XDN_OAUTHSRVR_DEFAULT	0x0000
#define XDN_OAUTHSRVR_QA		0x1000
#define XDN_OAUTHSRVR_PR		0x2000

//For Delegate
typedef enum {
	AuthStateStart = 0,             //*** Startup
    AuthStateWaitBrowser = 1,       //~~Browser Launched - waiting
    AuthStateWaitPost = 2,          //~~Token Requested - waiting
	AuthStateTokenOK = 9,            //***Completed

    AuthStateBrowserError = -1,		//?Invalid URL
    AuthStateBrowserTimeout = -2,	//?No Response
    AuthStateCodeSizeError = -3,	//?code must be 1-16 characters
    AuthStateCodeDenied = -4,		//?code must be 1-16 characters
    AuthStateCodePostError = -5,	//?Post rejected by iOS
    AuthStateCodePostFail = -6,		//?Post not deliverable to URI
	AuthStateTokenFail = -7,		//?Token not provided
	AuthStateScopeError = -8		//?Invalid selection of SCOPES
} _AuthState;

//-----------
// Only referenced from ViewControllers and APP Delegate...
//-----------
+ (ApiMachine *) shared;

-(void) startTheMachine:(BOOL)test;
-(BOOL)icnMachineRunning;
-(BOOL)pushTheScopes:(NSString *)scopes;
-(NSString *)pullTheScopes;
-(BOOL)checkTokenExpired;
-(void)checkHostGateway:(NSString *)hostname save:(BOOL)saveit;

- (void)useWebViewController:(UIViewController *)view;
- (void)didRefreshWebView;
- (void)willRefreshWebView;

-(NSString *)getHostName;
-(void)forceHTTPget:(NSString *)force;
-(void)forceHTTPpost:(NSString *)force;
- (BOOL) browserReturnURL:(NSURL *)url;
-(NSInteger) readServiceSetting;
-(NSInteger) writeServiceSetting:(NSInteger)setting;
- (void)gotActionButtonReset;
- (void)gotActionButtonExpire;
- (void)gotActionButtonInvalid;
- (void)gotActionCode:(NSString *)code;
@end

//==================================================================
// These delegate methods can be called on any arbitrary thread.
// If the delegate does something with the UI when called, make sure to send it to the main thread.
//==================================================================
@protocol ApiMachineDelegate <NSObject>
@optional
- (void) apiMachine:(ApiMachine *)apiMachine authState:(NSInteger)state;
- (void) apiMachine:(ApiMachine *)apiMachine running:(NSInteger)flag;
- (void) apiMachine:(ApiMachine *)apiMachine service:(NSInteger)type heading:(NSString *)heading;

- (void) apiMachine:(ApiMachine *)apiMachine health:(NSString *)health     time:(float)timex status:(NSInteger)status;
- (void) apiMachine:(ApiMachine *)apiMachine ports:(id)ports               time:(float)timex status:(NSInteger)status;
- (void) apiMachine:(ApiMachine *)apiMachine token:(id)token               time:(float)timex status:(NSInteger)status;
- (void) apiMachine:(ApiMachine *)apiMachine throttle:(NSString *)throttle time:(float)timex status:(NSInteger)status;
- (void) apiMachine:(ApiMachine *)apiMachine basic:(id)basic               time:(float)timex status:(NSInteger)status;
- (void) apiMachine:(ApiMachine *)apiMachine stock:(id)stockinfo           time:(float)timex status:(NSInteger)status;

- (void) apiMachine:(ApiMachine *)apiMachine gwNet:(NSString *)health      time:(float)timex status:(NSInteger)status;
- (void) apiMachine:(ApiMachine *)apiMachine appNet:(NSString *)health     time:(float)timex status:(NSInteger)status;
- (void) apiMachine:(ApiMachine *)apiMachine google:(id)prefdata           time:(float)timex status:(NSInteger)status;

//- (void) apiMachine:(ApiMachine *)apiMachine mapID:(id)site time:(float)timex;

- (void) apiMachine:(ApiMachine *)apiMachine forceID:(id)force time:(float)timex;
- (void) apiMachine:(ApiMachine *)apiMachine forcePostID:(NSString *)result;

- (NSString *) apiMachine:(ApiMachine *)apiMachine getString:(NSString *)string;

@end

