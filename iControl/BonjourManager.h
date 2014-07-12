/**************************************************************/
/* ktopits  -                                                 */
/* BonjourManager.h                                           */
/* KT 09-JUN-2014                                             */
/**************************************************************/

@class BonjourManager;
@protocol BonjourManagerDelegate;

@interface BonjourManager : NSObject<
	NSNetServiceDelegate,
	NSNetServiceBrowserDelegate
>
{
//no Externally accessable data
}


@property (nonatomic,assign) id <BonjourManagerDelegate> delegate;

@property (nonatomic, retain) NSNetServiceBrowser * myServiceBrowser;
@property (nonatomic)         NSInteger        axisBrowserLock;
@property (nonatomic)         NSInteger        bonjourCounter;
@property (nonatomic, retain) NSMutableArray * reportedServiceNames;
@property (nonatomic, retain) NSMutableArray * availableNetServices;	//LIVE COPY of BONJOUR services

@property (nonatomic, retain) NSString       * serviceType;			//searching for:  _axway._tcp



typedef enum {
	AxisBrowserLockNone = 0x00,		//0 = Not Locked
	AxisBrowserLockWait = 0x01,		//1 = Locked Waiting for Delegate Start
	AxisBrowserLockResp = 0x02,		//2 = Locked Waiting for OK/FAIL
	AxisBrowserLockBusy = AxisBrowserLockWait|AxisBrowserLockResp,
	AxisBrowserLockSelect = 0x04,	//4 = Locked During API Machine active
	AxisBrowserLockBackground = 0x08 //8 = Locked During Background
} _AxisBrowserLock;

//-----------
// External Entry
//-----------
+ (BonjourManager *)shared;

-(void)bonjourSearch:(NSString *)serviceType;
-(void)bonjourBrowserIdleUnlock;
-(void)bonjourBrowserIdleLock;
-(BOOL)resolveBonjourService:(NSString *)serviceName;


@end


// These delegate methods can be called on any arbitrary thread. If the delegate does something with the UI when called, make sure to send it to the main thread.
@protocol BonjourManagerDelegate <NSObject>
@optional
- (void) bonjourManager:(BonjourManager *)manager serviceAdded:(NSString *)serviceName;
- (void) bonjourManager:(BonjourManager *)manager serviceDropped:(NSString *)serviceName;
- (void) bonjourManager:(BonjourManager *)manager serviceReady:(NSInteger) count;
- (void) bonjourManager:(BonjourManager *)manager serviceName:(NSString *)serviceName address:(NSString *)ipaddress port:(NSInteger)port txtrec:(NSDictionary *)txtrec;
@end
