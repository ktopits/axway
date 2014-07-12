/**************************************************************/
/* ktopits  -                                                 */
/* BonjourManager.m                                           */
/* KT 09-JUN-2014                                             */
/**************************************************************/

//---------------------------
//This is a BONJOUR CLIENT
// Bonjour is a distributed DNS, so everything resolves to a NAME, that bonjour will resolve (local dns) to an ip address
//
// Bonjour only works in local subnet (actually local multicast zone since it sends to 224.0.0.251)
//---------------------------
//
//to publish a BONJOUR SERVICE from IOS, check netservices.h (foundation framework)
//- (id)initWithDomain:(NSString *)domain type:(NSString *)type name:(NSString *)name port:(int)port;
//
//---------------------------
//
//to publish a BONJOUR SERVICE from OSX or WINDOWS, ON CONSOLE enter...
//    dns-sd -R axway1 _axway-api._tcp local 8080
//OR
//    dns-sd -R axway1 _axway-api._tcp local 8080 API=AXWAY NAME=FOO
//OR
//    dns-sd -R "API Gateway" _axway-api._tcp . 8080 API=AXWAY NAME=KTOPITS1
//OR
//  WINDOWS> dns-sd -R "API Gateway" _axway-api._tcp . 8080 API=AXWAY NAME=KTOPITS1
//  OSX>     dns-sd -P "API Proxy"   _axway-api._tcp . 8080 local 192.168.176.144  API=AXWAY NAME=KTOPITS1
//    "API Gateway" => 192.168.176.144:8080  (IP of VM - only useful for APP running on the MAC OSX or WINDOWS VM)
//    "API Proxy"   => 192.168.176.144:8080  (IP of MAC - available to anyone on same SUBNET, or on MAC OSX or on WINDOWS VM)
// Essentially PROXY works like a HTTP re-direct.  So returned IP Must be accessable by caller
// so difference in -R and -P is -R uses "local IP" and -P allows selection on ANY IP
// Port FORWARDING is still in VMWare Fusion setup 10.0.1.29:8080 forwards (not redirects) to 192.168.176.144:8080
//OR
// with TXT REC = JSON
//  WINDOWS> dns-sd -R "API WindowVM"  _axway-api._tcp . 8080 VM=1 GATEWAY=8080 PORTAL=8075 ADMIN=8090
//  OSX>     dns-sd -R "API Gateway"   _axway-api._tcp . 8080 VM=0 GATEWAY=8080 PORTAL=8075 ADMIN=8090
//    "API WindowsVM => 192.168.176.144:8080  (IP of VM - only useful to see if Windows VM is RUNNING)
//    "API Gateway"  =>       10.0.1.29:8080  (IP of MAC - available to anyone on same SUBNET, or on MAC OSX or on WINDOWS VM)
//
// TO BROWSE: dns-sd -B _axway-api._tcp .
//
// AND LEAVE IT RUNNING!  use ^C to stop and unregister
//You can have multiple windows, but each must use different name (aka axway1, axway2)
// [Interfaces: 4=EN, 5=WIFI, 8=VMWARE, 9=VMWARE, 10=VMWARE, 11=BT, 12=USB]
//
// Bonjour For Windows is part of SAFARI for windows.
//
// name = specific service from specific provider (axway1, axway2, foobar,...) available as ".hostname"
// type = generic service (axway) or specified as _SERVICE._tcp (or _udp)
// domain is always local. For DNS-SD command, "local" and "local." and "." all equate to "loal."  (".local" will give an error)
// port = advertised ip port.  available as ".port"
// you can specifify 0 or more TXT records (key=value)
//
//
// NOTE: BONJOUR is IP, so ONLY works on WIFI/ETHERNET (aka NOT LTE)
// Also BONJOUR may be blocked (as weel as peer-to-peer)for paid or Public WIFI.  Gogo allows search/resolve, but must be authenticated to publish
// for TETHERED to IOS, this only works between clients on SAME tethered SUBNET, and NOT a tether HOST
// for MAC + IPAD bother on WIFI to iphone TETHER (host does NOT see Bonjour services)
// Also for Cellular-Enabled tether, CELLULAR MUST be ENABLED (Not AIRPLANE MODE), and MUST NOT be in "NO SERIVCE"
//
// Note that since SIMULATOR is running on MAC, it can detected all services PUBLISHED by MAC
// the "host address" id hostname:ip  aka ktopits-mb.local.:8080  (so "ktopits-mb.local." == "localhost")
// On a REAl IOS device, the published host name is....
// If same subnet and NO Bonjour, enable HOTSPOT on device, and connect device to MAC with USB (reverse tether?)
//
// to SEARCH ALL services   use type:  _services._dns-sd._udp
//
// use  "_http._tcp . 8080" to register current host/ip as serving "http://host:8080" (aka html web-site) (will display in Safari!)
// use "_https._tcp . 8090" to register current host/ip as serving "https://host:8090" (aka html web-site)
//
//---------------------------



#import "BonjourManager.h"

@implementation BonjourManager

@synthesize delegate;

@synthesize myServiceBrowser;
@synthesize axisBrowserLock;
@synthesize reportedServiceNames;
@synthesize availableNetServices;
@synthesize bonjourCounter;
@synthesize serviceType;

#define DEFAULT_SERVICE_NAME @"axway-api"
#define DEFAULT_SERVICE_TYPE @"tcp"
#define DEFAULT_DOMAIN_NAME  @"local."

static NSString * prefix = @"      ->bjm ";

#pragma mark -
#pragma mark SESSION Init, Dealloc

BonjourManager * bonjourManagerSelf = nil;				//Context Definition is here!

//*******************************************
// Here to get INSTANCE
//*******************************************
+ (BonjourManager *)shared {
	return bonjourManagerSelf;
}

//*******************************************
// Here when CREATED (in ViewController)
//*******************************************
- (id) init {
	self = [super init];
	bonjourManagerSelf = [self retain];
	[self initBrowser];
	return self;
}

//*******************************************
// Here if deallocated (Never Called)
//*******************************************
- (void) dealloc
{
 	NSLog(@"%@--- dealloc",prefix);
#if 0
	if (self.myServiceBrowser!=nil) {
		[self.myServiceBrowser stop];
		[self.myServiceBrowser release];
		self.myServiceBrowser = nil;
	}
	[self.reportedServiceNames release];
	self.reportedServiceNames = nil;
	[self.availableNetServices release];
	self.availableNetServices = nil;
	[self release];
	bonjourManagerSelf = nil;
#endif
    [super dealloc];
}



//========================================================================================
#pragma mark -
#pragma mark Bonjour Browser stuff
//========================================================================================

//-----------------------------
//THis starts a recurring Bonjour SEARCH (scheduled)
//Available (matched) service providers and kept in local Array
//And ADD or REMOVE is sent to DELEGATE
//Normally only one (macbook) publishing on Bonjour
//This is just "advertising" that something is publishing the searched SERVICE
//-----------------------------

//#define BONJOUR_AXIS_TIMEOUT1 60.0
//#define BONJOUR_AXIS_TIMEOUT2 20.0

//-------
//Here at BonjourManager Initialization
//-------
-(void)initBrowser {
	self.reportedServiceNames = [[NSMutableArray alloc] init];
	self.availableNetServices = [[NSMutableArray alloc] init];
	self.myServiceBrowser = nil;
	self.axisBrowserLock = AxisBrowserLockNone;
	self.bonjourCounter = 0;
#if 0
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willBackground:)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willForeground:)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
#endif
}
#if 0
- (void)willBackground:(NSNotification *)notification {
	[self bonjourBrowserBkgdLock];
}
- (void)willForeground:(NSNotification *)notification {
	[self bonjourBrowserBkgdUnlock];
}
#endif

//-------
//Here from ViewCOntroller to LOCK-OUT Bonjour Browsing during configuration
//-------
-(void)bonjourBrowserIdleUnlock {
#if 0
	if (self.axisBrowserLock&AxisBrowserLockSelect) {
		self.axisBrowserLock &=~ AxisBrowserLockSelect;
		NSLog(@"%@ --->search SEL UNLOCKED",prefix);
		if (self.axisBrowserLock==AxisBrowserLockNone) {
			self.bonjourCounter = 0;
			[self bonjourSearchNow];
		}
	}
#endif
}
-(void)bonjourBrowserIdleLock {
#if 0
	self.axisBrowserLock |= AxisBrowserLockSelect;
	if (self.axisBrowserLock&AxisBrowserLockBusy) {
		[self axisBrowserTimeout];
	}
	NSLog(@"%@ --->search SEL LOCKED",prefix);
#endif
}

#if 0
//-------
//Here from AVCamView to LOCK-OUT Bonjour Browsing during BACKGROUND operation
//-------
-(void)bonjourBrowserBkgdUnlock {
	if (self.axisBrowserLock&AxisBrowserLockBackground) {
		self.axisBrowserLock &=~ AxisBrowserLockBackground;
		NSLog(@"%@ --->search BKG UNLOCKED",prefix);
		if (self.axisBrowserLock==AxisBrowserLockNone) {
			self.bonjourCounter = 0;
			[self bonjourSearchNow];
		}
	}
}
-(void)bonjourBrowserBkgdLock {
	self.axisBrowserLock |= AxisBrowserLockBackground;
	if (self.axisBrowserLock&AxisBrowserLockBusy) {
		[self axisBrowserTimeout];
	}
	NSLog(@"%@ --->search BKG LOCKED",prefix);
}
#endif


//-------
//Called to start up recurring AXIS camera search
//-------
-(void)bonjourSearch:(NSString *)useServiceName {
	if (useServiceName==nil)
		useServiceName = DEFAULT_SERVICE_NAME;
	self.serviceType = [NSString stringWithFormat:@"_%@._%@",useServiceName,DEFAULT_SERVICE_TYPE];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(bonjourSearch) object:nil];
	[self bonjourSearchNow];
}
-(void)bonjourSearchNow {
	if ((self.axisBrowserLock&AxisBrowserLockBusy)||(self.myServiceBrowser!=nil)) {
		[self performSelector:@selector(axisCameraSearch) withObject:nil afterDelay:2.0];
		NSLog(@"%@ --->search BUSY(%lx) - retry",prefix,(long)self.axisBrowserLock);
		return;
	}
	[self performSelector:@selector(bonjourBrowserStart) withObject:nil afterDelay:0.0];
}
-(void)bonjourBrowserStart {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(bonjourBrowserStart) object:nil];
	if (self.axisBrowserLock!=AxisBrowserLockNone) {
		NSLog(@"%@ --->search LOCKED(%lx) - retry",prefix,(long)self.axisBrowserLock);
		[self performSelector:@selector(bonjourBrowserStart) withObject:nil afterDelay:60.0];
		return;
	}
	if (self.myServiceBrowser == nil) {
		self.myServiceBrowser = [[NSNetServiceBrowser alloc] init];
		self.myServiceBrowser.delegate = self;
	}
	self.axisBrowserLock|=AxisBrowserLockWait;
	NSLog(@"%@ --->search#%li for ServiceType (%@)",prefix,(long)self.bonjourCounter,self.serviceType);
	[self.availableNetServices removeAllObjects];
	[self.myServiceBrowser searchForServicesOfType:self.serviceType inDomain:DEFAULT_DOMAIN_NAME];
	return;
}

//*************************************
//DELEGATE - SEARCH FAILED&STOPPED DUE TO ERROR (maybe before or after start)
//*************************************
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo {
	NSLog(@"%@  <=!Failed search. Error %p=\"%@\"",prefix,errorInfo,errorInfo.description);
	[self.myServiceBrowser stop];		//??
	[self bonjourBrowserDone];
	return;
}

//*************************************
//DELEGATE - SEARCH STARTED
//*************************************
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser {
	NSLog(@"%@  <==Searching for ServiceType....",prefix);
	self.axisBrowserLock |= AxisBrowserLockResp;
	self.axisBrowserLock &=~ AxisBrowserLockWait;
#if 0
	//search will run until at least one SERVICE Found...
	//To detect DELETED services, there MUST be a TIMEOUT
	NSTimeInterval secs;
	if (self.availableNetServices.count==0)
		secs = BONJOUR_AXIS_TIMEOUT1;	//60 seconds
	else
		secs = BONJOUR_AXIS_TIMEOUT2;	//10 seconds
	[self performSelector:@selector(axisBrowserTimeout) withObject:nil afterDelay:secs];
#endif
	return;
}

//*************************************
//DELEGATE - SEARCH STOPPED BY ME
//*************************************
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser {
	NSLog(@"%@  <==Searching STOPPED....",prefix);
	return;
}

#if 0
//*************************************
//NOT DELEGATE - SEARCH TIMEOUT - requested serviceType not found
//*************************************
-(void)axisBrowserTimeout {
	if (self.myServiceBrowser==nil)
		return;
	NSLog(@"%@ <---Search for ServiceType TIMEOUT! (%lx)",prefix,(long)self.axisBrowserLock);
	[self.myServiceBrowser stop];
	[self bonjourBrowserDone];
	return;
}
#endif

//*************************************
//DELEGATE - SEARCH SERVICE ADDED/DROPPED
//*************************************
//DNS-SD command is stupid.  If Windows VM stopped, without unpublishing, the SERVCE will remain until timoeout (1-5 minutes)
//If Windows VM resumed after timeout, it does not know and re-register
//Once a SERVICE is resolved and PORT assigned, there is no point in RECHECKING, since it is just re-checking the same cache
//Obviously, Publishing an IP is not the same as IP accessibility.  AKA laptop can publish internal (VMWARE IP address) that is internal only.

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	[self.availableNetServices addObject:netService];
	NSLog(@"%@ +++ Added New SERVICE = \"%@\"",prefix,netService.name);
	if (!moreServicesComing) {
		[self availableServicesDone];
	}
	return;
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
	[self.availableNetServices removeObject:netService];
	NSLog(@"%@ --- Removed SERVICE = \"%@\"",prefix,netService.name);
	if (!moreServicesComing) {
		[self availableServicesDone];
	}
	return;
}

-(void)availableServicesDone {
	NSLog(@"%@ <---Available Services = %lu",prefix,(unsigned long)self.availableNetServices.count);
	//See if a SERVICE was DETECTED
	NSInteger ix = 0;
	for (NSNetService * serviceNS in self.availableNetServices) {
		for (ix=0; ix<self.reportedServiceNames.count; ix++) {
			NSString * camera = [self.reportedServiceNames objectAtIndex:ix];
			if ([camera isEqualToString:serviceNS.name])
				break;
		}
		if (ix==self.reportedServiceNames.count) {
			NSLog(@"%@ +++ Reporting New SERVICE = \"%@\"",prefix,serviceNS.name);
			if ([[self delegate] respondsToSelector:@selector(bonjourManager:serviceAdded:)]) {
				[[self delegate] bonjourManager:bonjourManagerSelf serviceAdded:[NSString stringWithString:serviceNS.name]];
			}
		}
	}
	//See if an EXISTING SERVICE was DISCONNECTED
	for (NSInteger iz=self.reportedServiceNames.count-1; iz>=0; iz--) {
		NSString * cameraName = [self.reportedServiceNames objectAtIndex:iz];
		for (ix=0; ix<self.availableNetServices.count; ix++) {
			NSNetService * serviceNS = [self.availableNetServices objectAtIndex:ix];
			if ([serviceNS.name isEqualToString:cameraName])
				break;
		}
		if (ix==self.availableNetServices.count) {
			NSLog(@"%@ --- Reporting REM SERVICE = \"%@\"",prefix,cameraName);
			if ([[self delegate] respondsToSelector:@selector(bonjourManager:serviceDropped:)]) {
				[[self delegate] bonjourManager:bonjourManagerSelf serviceDropped:[NSString stringWithString:cameraName]];
			}
		}
	}
	//Rebuild the array of REPORTED SERVICES
	[self.reportedServiceNames removeAllObjects];
	for (NSNetService * serviceNS in self.availableNetServices) {
		[self.reportedServiceNames addObject:[NSString stringWithString:serviceNS.name]];
	}
	if ([[self delegate] respondsToSelector:@selector(bonjourManager:serviceReady:)]) {
		[[self delegate] bonjourManager:bonjourManagerSelf serviceReady:self.reportedServiceNames.count];
	}
	return;
}

//-------
//Called (DELEGATE or TIMEOUT) when Bonjour Search process Completed (aka STOPPED and NOT RUNNING)
//-------
-(void)bonjourBrowserDone {
//	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(axisBrowserTimeout) object:nil];
	[self.myServiceBrowser release];
	self.myServiceBrowser = nil;
	self.axisBrowserLock &=~ AxisBrowserLockResp;
	self.bonjourCounter++;
	if ((self.axisBrowserLock&(AxisBrowserLockBackground|AxisBrowserLockSelect)))
		return;

	//Not Locked OUT, so schedule another Browse...
	NSTimeInterval secs = 0;
#if 0
	secs = (NSTimeInterval)(self.bonjourCounter	* 2);
	if (secs>60.0)
		secs = 30.0;
//	if (self.availableNetServices.count==0)
//		secs = 30.0;
//	else
//		secs = 60.0;
#endif
	[self performSelector:@selector(bonjourBrowserStart) withObject:nil afterDelay:secs];
}






//========================================================================================
#pragma mark -
#pragma mark Bonjour Resolve stuff
//========================================================================================

-(BOOL)resolveBonjourService:(NSString *)useServiceName {

	NSNetService * resolveNS = nil;
	if ((useServiceName!=nil)&&(self.availableNetServices.count>0)) {
		for (NSNetService * serviceNS in self.availableNetServices) {
			if ([useServiceName isEqualToString:serviceNS.name]) {
				resolveNS = serviceNS;
				break;
			}
		}
	}
	if (resolveNS==nil) {
		return NO;
	}

	//If port is >=0 resolve will just pull from cache - there is not "checking", just posting to cache
	if (resolveNS.port>=-1) {		//Can only resolve if unresolved...
		NSLog(@"%@[RESOLVE] -->request \"%@\"...",prefix,resolveNS.name);
		resolveNS.delegate = self;
		[resolveNS resolveWithTimeout:10.0];		//Only takes 150ms for Photosmart!
	}
	else {
		[self performSelector:@selector(axisResolveDone:) withObject:resolveNS afterDelay:0];
	}
	return YES;
}


//*************************************
//DELEGATE - RESOLVE WILL START
//*************************************
- (void)netServiceWillResolve:(NSNetService *)sender {
	NSLog(@"%@[resolve]  <=Started \"%@\"...",prefix,sender.name);
}
//*************************************
//DELEGATE - RESOLVE FAILED
//*************************************
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorInfo {
#if 0
	NSNetServicesUnknownError      = -72000,
	NSNetServicesCollisionError    = -72001,
	NSNetServicesNotFoundError     = -72002,
	NSNetServicesActivityInProgress= -72003,
	NSNetServicesBadArgumentError  = -72004,
	NSNetServicesCancelledError    = -72005,
	NSNetServicesInvalidError      = -72006,
	NSNetServicesTimeoutError      = -72007,
#endif
	NSLog(@"%@[resolve]  <=!Failed \"%@\" Error %p=\"%@\"",prefix,sender.name,errorInfo,errorInfo.description);
	[self axisResolveFail:sender];
}
//#include <sys/socket.h>
//#include <netinet/in.h>
#include <arpa/inet.h>
//*************************************
//DELEGATE - RESOLVE COMPLETED (port and addresses and TXTrecordData valid)
//TXTrecord is <len><string><len><string>.... for EACH record
// for DICTIONARY, text KEY = NSdata string
//*************************************
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
	NSDictionary * txtrec = [NSNetService dictionaryFromTXTRecordData:sender.TXTRecordData];
//	NSLog(@"%@[resolve]  <=Success. HOST=%@ Port:%li \n\"%@\"",prefix,sender.hostName,(long)sender.port,txtrec);
	NSLog(@"%@[resolve]  <=Success. HOST=%@ Port:%li",prefix,sender.hostName,(long)sender.port);

	NSEnumerator *enumerator = [txtrec keyEnumerator];
	id key;
//	key = @"TOPITS";
//	NSLog(@"%@[resolve]  <=  TXTREC KEY %@=%li",prefix,key,[self valueForTxtKey:key dictionary:txtrec]);
	while (key = [enumerator nextObject]) {
		NSLog(@"%@[resolve]  <=  TXTREC KEY %@=%li",prefix,key,(long)[self valueForTxtKey:key dictionary:txtrec]);
	}

	for (NSData * socketAddress in sender.addresses) {
		//LEN=16  12345678 (IP)12.34.56.78 <00000000 00000000>
		//LEN:28  12345678 00000000 (MAC)12: <00 0000> 12:34:56:78 <00000000>
	    if ((socketAddress.length!=16)&&(socketAddress.length!=28)) {
			NSLog(@"%@[resolve]  <=  Socket %3lu Address= %@",prefix,(unsigned long)socketAddress.length,socketAddress);
		}
		else {
#if 0
			char * temp = (char *)malloc(28+1);
			if (temp != NULL)
				{
				struct sockaddr_in * sin = (struct sockaddr_in *)socketAddress;
				strcpy(temp, inet_ntoa(sin->sin_addr));
				NSLog(@"%@[SOCK] IP=%16s",prefix,temp);
				}
#endif
			NSUInteger len = [socketAddress length];
			Byte *byteData = (Byte*)malloc(len);
			memcpy(byteData, [socketAddress bytes], len);
			if (socketAddress.length==16) {
				NSLog(@"%@[resolve]  <=  Socket IP  Address=%02x%02x%02x%02x {%u.%u.%u.%u}",prefix,
					  byteData[0],byteData[1],byteData[2],byteData[3],
					  byteData[4],byteData[5],byteData[6],byteData[7]);
			}
			else if (socketAddress.length==28) {
				NSLog(@"%@[resolve]  <=  Socket MAC Address=%02x%02x%02x%02x {%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x}",prefix,
					  byteData[0],byteData[1],byteData[2],byteData[3],
					  byteData[8],byteData[9],byteData[16],byteData[17],byteData[18],byteData[19],byteData[20],byteData[21],byteData[22],byteData[23]);
			}
			free(byteData);
		}
	}
	[self axisResolveDone:sender];
}

-(NSInteger)valueForTxtKey:(NSString *)key dictionary:(NSDictionary *)txtrec {
	NSData * data = [txtrec objectForKey:key];
	if (data==nil)
		return -1;		//KEY Undefined
	if (data == (NSData *)[NSNull null])
		return -2;		//KEY with no assignment
	if ([data bytes] == nil)
		return -3;		//KEY with empty assignment

	NSString * value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSInteger x = [value integerValue];
	if ((x==0)&&((value.length>1)||(![value isEqualToString:@"0"])))
		x = -4;		//KEY is not numeric
	[value release];
	return x;
}

-(void)axisResolveFail:(NSNetService *)resolveNS {
	NSLog(@"%@[RESOLVE] <--?Failed? \"%@\"",prefix,resolveNS.name);
	resolveNS.delegate = nil;
	if ([[self delegate] respondsToSelector:@selector(bonjourManager:serviceName:address:port:txtrec:)]) {
		[[self delegate] bonjourManager:bonjourManagerSelf serviceName:resolveNS.name address:nil port:-1 txtrec:nil];
	}
}
-(void)axisResolveDone:(NSNetService *)resolveNS {
	NSLog(@"%@[RESOLVE] <--completed \"%@\"",prefix,resolveNS.name);
	resolveNS.delegate = nil;
	if ([[self delegate] respondsToSelector:@selector(bonjourManager:serviceName:address:port:txtrec:)]) {
		NSDictionary * txtrec = [NSNetService dictionaryFromTXTRecordData:resolveNS.TXTRecordData];
		[[self delegate] bonjourManager:bonjourManagerSelf serviceName:resolveNS.name address:resolveNS.hostName port:(NSInteger)resolveNS.port txtrec:txtrec];
	}
}

@end
