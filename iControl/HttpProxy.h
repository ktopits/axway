/**************************************************************/
/* ktopits -                                                  */
/* HttpProxy.h                                                */
/* KT 08-JUL-2014                                             */
/**************************************************************/

#define HTTP_NONE     0

#define HTTP_200	200	//All OK - with Data
#define HTTP_201	201	//All OK - completion in progress
#define HTTP_202	202	//All OK - completion in progress
#define HTTP_203	203	//All OK - completion in progress
#define HTTP_204	204	//All OK - with NO DATA
#define HTTP_299	299	//MAX OK.

#define HTTP_300    300	//Re-direct MIN VALUE
#define HTTP_301    301	//Re-direct site permanently moved
#define HTTP_302    302	//Re-direct GATEWAY
#define HTTP_399    399	//Re-direct MAX VALUE

#define HTTP_400	400	//Valid  PATH, accessable, authorized,     Invalid PARAMETER
#define HTTP_401	401	//Valid, PATH, accessable, NOT authorized, Invalid Username/Password
#define HTTP_403	403	//Valid  PATH, but forbidden - non public or no default page
#define HTTP_404	404	//Invaild PATH (/xxx/xxx/)

#define HTTP_500    500 //Internal Server Error (misc/generic/fault)
#define HTTP_501    501 //requested item  not-found or unimplemented
#define HTTP_502    502 //Gateway lost power/no network
#define HTTP_503    503 //Service temporarily unavailable (busy or App exceeded quota)
#define HTTP_504    504 //Gateway Timeout to Service
#define HTTP_505    505 //HTTP Version Not Supported
#define HTTP_506    506 //(Axway) Application dependent error
#define HTTP_507    507 //(Axway) Application dependent error

#define HTTP_9999  9999 //FAKE - ERROR- failed to connect to server (check error code)

@class HttpProxy;
@protocol HttpProxyDelegate;


@interface HttpProxy : NSObject<UITextFieldDelegate>
{
	NSInteger        URLcounter;		//Manage REQUESTS => RESPONSES
	NSMutableArray * URLarray;
	NSString       * URLerror;			//Descriptive Error
	NSString       * deviceName;
	NSString       * authTitle;
	NSString       * authModePrefix;
	NSMutableArray * trustedHosts;

	UIAlertView    * myAlertView;
	NSString       * alert_field0;
	NSString       * alert_field1;
	NSString       * save_username;
	NSString       * save_password;
	NSURLAuthenticationChallenge * URLchallenge;	//temp for username/password challenge
}

#pragma mark - Properties

@property (nonatomic,assign) id <HttpProxyDelegate> delegate;
@property (nonatomic)         NSInteger        URLcounter;
@property (nonatomic, retain) NSMutableArray * URLarray;
@property (nonatomic, retain) NSString       * URLerror;
@property (nonatomic, retain) NSString       * deviceName;
@property (nonatomic, retain) NSString       * authTitle;
@property (nonatomic, retain) NSString       * authModePrefix;

@property (nonatomic, retain) NSMutableArray * trustedHosts;
@property (nonatomic, retain) UIAlertView    * myAlertView;
@property (nonatomic, retain) NSString       * alert_field0;
@property (nonatomic, retain) NSString       * alert_field1;
@property (nonatomic, retain) NSString       * save_username;
@property (nonatomic, retain) NSString       * save_password;
@property (nonatomic, retain) NSURLAuthenticationChallenge * URLchallenge;

//-----------
// External Access
//-----------
+ (HttpProxy *) shared;
-(void)authWithURL:(NSString *)prefix;
-(void)authWithTitle:(NSString *)title;

-(NSInteger)get:(NSString *)server request:(NSString *)urx;
-(NSInteger)get:(NSString *)server request:(NSString *)urx delegate:(id)delegate;

-(NSInteger)getAuthorized:(NSString *)server request:(NSString *)urx bearer:(NSString *)token;
-(NSInteger)getAuthorized:(NSString *)server request:(NSString *)urx bearer:(NSString *)token delegate:(id)delegate;
-(NSInteger)getAuthorizedPoll:(NSString *)server request:(NSString *)urx bearer:(NSString *)token delegate:(id)xdelegate;

-(NSInteger)post:(NSString *)server request:(NSString *)urx body:(NSString *)postBody;
-(NSInteger)postBody:(NSString *)server request:(NSString *)urx body:(NSString *)postBody bearer:(NSString *)token;
//-(NSInteger)post:(NSString *)server request:(NSString *)urx body:(NSString *)postBody delegate:(id)delegate;
-(NSInteger)postAuthorized:(NSString *)server request:(NSString *)urx bearer:(NSString *)bearer;
-(NSInteger)postAuthorized:(NSString *)server request:(NSString *)urx bearer:(NSString *)bearer delegate:(id)delegate;

@end

//==================================================================
// These delegate methods can be called on any arbitrary thread.
// If the delegate does something with the UI when called, make sure to send it to the main thread.
//==================================================================
@protocol HttpProxyDelegate <NSObject>
@optional
- (void) httpProxy:(HttpProxy *)httpProxy seq:(NSInteger)seq code:(NSInteger)code response:(NSString *)response time:(float)diff;
@end
