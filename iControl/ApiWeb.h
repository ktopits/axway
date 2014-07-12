/**************************************************************/
/* ktopits  -                                                 */
/* ApiWeb.h                                                   */
/* KT 03-JUL-2014                                             */
/**************************************************************/

@class ApiWeb;
@protocol ApiWebDelegate;

@interface ApiWeb : NSObject<
	UIWebViewDelegate
>
{
}


#pragma mark - Properties

@property (nonatomic)         BOOL             usingIOS7;
@property (nonatomic,assign) id <ApiWebDelegate> delegate;

@property (nonatomic)         BOOL             inactive;
@property (nonatomic)         float            savedAlpha;
@property (nonatomic)         float            usingAlpha;
@property (nonatomic, retain) NSString       * savedTitle;
@property (nonatomic, retain) NSString       * callBackHost;
@property (nonatomic, retain) NSURL          * startingURL;
@property (nonatomic)         NSInteger        countURL;
@property (nonatomic, retain) NSString       * loadedHost;
@property (nonatomic)         BOOL             webViewRefreshing;
@property (nonatomic)         NSInteger        responseStatus;
@property (nonatomic, retain) UIView         * backView;
@property (nonatomic, retain) UIWebView      * webView;
@property (nonatomic, retain) UIViewController * webViewController;
@property (nonatomic, retain) NSURLConnection  * webConnection;
@property (nonatomic, retain) NSString       * webTitle;
@property (nonatomic, retain) NSArray        * webCookies;
@property (nonatomic, retain) NSMutableArray * webLoads;


//-----------
// External Access
//-----------
+ (ApiWeb *) shared;

- (void)startWebView:(NSString *)callURL callbackHost:(NSString *)callBack title:(NSString *)title;
- (void)stopWebView;
- (BOOL)restartWebView;
- (void)resetWebView;

- (void)useWebViewController:(UIViewController *)view;
- (void)didRefreshWebView;
- (void)willRefreshWebView;
@end

//==================================================================
// These delegate methods can be called on any arbitrary thread.
// If the delegate does something with the UI when called, make sure to send it to the main thread.
//==================================================================
@protocol ApiWebDelegate <NSObject>
@optional
- (void) apiWeb:(ApiWeb *)ApiWeb running:(BOOL)status;
- (void) apiWeb:(ApiWeb *)ApiWeb gotError:(NSError *)error;
- (void) apiWeb:(ApiWeb *)ApiWeb gotHttpStatus:(NSInteger)status;
- (void) apiWeb:(ApiWeb *)ApiWeb gotReturnURL:(NSURL *)url;
- (BOOL) apiWeb:(ApiWeb *)ApiWeb approveClickURL:(NSURL *)url;
@end
