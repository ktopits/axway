/**************************************************************/
/* iControl -                                                 */
/* ApigeeManager.h                                            */
/* KT 23-Aug-2013                                             */
/**************************************************************/

#import <InstaOpsSDK/InstaOps.h>

#import <ApigeeIOSSDK/Apigee.h>
#import <ApigeeIOSSDK/ApigeeClient.h>
#import <ApigeeIOSSDK/ApigeeUser.h>
#import <ApigeeIOSSDK/ApigeeQuery.h>
#import <ApigeeIOSSDK/ApigeeClientResponse.h>


//GET THESE FROM APIGEE DEVELOPER ADMIN PORTAL
#define APIGEE_ORG_NAME @"ktopits1"
#define APIGEE_ORG_UUID @"0c30eb4a-e00f-11e2-ad27-5d48d6bf3865"
#define APIGEE_APP_NAME @"iControl"
#define APIGEE_APP_UUID @"13ac3e80-0c27-11e3-b017-b54d2a452f7e"

//#define APIGEE_CLIENTID @"b3U6DDDrSuAPEeKtJ11I1r84ZQ"
//#define APIGEE_CLSECRET @"b3U6LoFFkHtzCthlDlDeevkSeSu0mhE"


#define APIGEE_TYPE_AXISCAMS    @"axiscams"
#define APIGEE_TYPE_DEVICES     @"iosdevices"
#define APIGEE_TYPE_SWITCHS     @"switches"
#define APIGEE_TYPE_THEROMSTATS @"thermostats"



@interface ApigeeManager : NSObject
{
	ApigeeClient    * usergridClient;
	ApigeeUser      * user;
}

#pragma mark -
#pragma mark Properties

@property (nonatomic, strong) ApigeeClient *usergridClient;
@property (nonatomic, strong) ApigeeUser *user;


//-----------
// External Access
//-----------
+ (ApigeeManager *) manager;
-(NSString*)postSelf;

-(NSString*)postCameraName:(NSString *)cameraName title:(NSString *)cameraTitle;

@end
