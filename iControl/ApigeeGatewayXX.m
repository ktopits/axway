/**************************************************************/
/* BLUEBAND -                                                 */
/* ApigeeGateway.m                                            */
/* KT 25-AUG-2013                                             */
/**************************************************************/

#import "ApigeeGateway.h"


@implementation ApigeeGateway

@synthesize auth_url;
@synthesize code;
@synthesize token;


static NSString * prefix = @"[AGW] ";

#pragma mark -
#pragma mark SESSION Init, Dealloc

ApigeeGateway * apigeeGateway = nil;				//Context Definition is here!

//*******************************************
// Here when Application is created (FROM MAIN THREAD)
//*******************************************
+ (ApigeeGateway *)shared {
	return apigeeGateway;
}

//*******************************************
// Here when WirelessBlueController is created (FROM MAIN THREAD)
//*******************************************
- (id) init {
	self = [super init];		//create my context (so caller did not have to
	NSLog(@"%@--- init self=%p",prefix,self);
	apigeeGateway = [self retain];
	if (self) {
		NSString * orgName = @"org";
		NSString * appName = @"app";
	}
	return self;
}

//*******************************************
// Here when WirelessBlueController is released
//*******************************************
- (void) dealloc
{
 	NSLog(@"%@--- dealloc",prefix);
	[self release];
	apigeeGateway = nil;
    [super dealloc];
}







#pragma mark -
#pragma mark Implementation
#if 0
//==========================================================
// 1) USERGRID - DEVICE UUID (self) is ONLINE (keep alive + timeout)
// 2) Is Player/Peer UUID defined on USERGRID?
//==========================================================

#define USERGRID_qENTITIES @"entities"
#define USERGRID_eTYPE     @"type"			//COLLECTION NAME
#define USERGRID_eNAME     @"name"			//ENTITY UNIQUE  NAME
#define USERGRID_eTITLE    @"title"			//ENTITY LOGICAL NAME
#define USERGRID_eUUID     @"uuid"			//Managed by USERGRID
#define USERGRID_eCREATE D @"create"		//Managed by USERGRID
#define USERGRID_eMODIFIED @"modified"		//Managed by USERGRID

#define USERGRID_cBLUES    @"blues"			//Custom Field= program Count

-(NSString*)postSelf {
#if 0 // Mobile Analytics does this...
    NSString * myName = [UIDevice currentDevice].name;
	ApigeeQuery *query = [ApigeeQuery new];
	[query addRequiredOperation:USERGRID_eNAME op:kApigeeQueryOperationEquals valueStr:myName];
	ApigeeClientResponse *response = [self.usergridClient getEntities:APIGEE_TYPE_DEVICES query:query];
	if (response.transactionState == kUGClientResponseFailure) {
		//Probably "The Internet connection appears to be offline."
		//If error, then "response" is same as "raw response"
		NSLOG(@"%@Query ?FAILED (%@) Error=%@",prefix,APIGEE_TYPE_DEVICES,response.response);
		return @"?FAILED";
	}

	NSArray * entities = [response.response objectForKey:USERGRID_qENTITIES];
	if (entities.count==0) {
		NSLOG(@"%@Query *NOT FOUND (%@)=%@ result=\n%@",prefix,APIGEE_TYPE_DEVICES,self.blue.paidDevice,response.response);
		NSMutableDictionary *entity = [[NSMutableDictionary alloc] init ];
		[entity setObject:APIGEE_TYPE_DEVICES  forKey:USERGRID_eTYPE];		//STD field = COLLECTION NAME
		[entity setObject:self.blue.paidOwner  forKey:USERGRID_eTITLE];		//STD field = Descriptive Name
		[entity setObject:self.blue.paidDevice forKey:USERGRID_eNAME];		//STD field = NON-CHANGEABLE AND UNIQUE
		[entity setObject:@"1"                 forKey:USERGRID_cBLUES];		//CUST field

		response = [self.usergridClient createEntity:entity];
		[entity release];
		if (response.transactionState == kUGClientResponseFailure) {
			//Probably ALREADY EXISTS?
			NSLog(@"%@Create ?FAILED (%@)=%@ Error=%@",prefix,APIGEE_TYPE_DEVICES,self.blue.paidDevice,response.response);
			return @"?FAIL";
		}
		return @"!CREATED";
	}

//	NSLOG(@"%@ ==RESPONSE=======\n%@",prefix,response.response);
//	NSLOG(@"%@ ==ENTITY=======\n%@",prefix,[axis objectAtIndex:0]);
	NSString * title = [[entities objectAtIndex:0] objectForKey:USERGRID_eTITLE];
	NSString * blues = [[entities objectAtIndex:0] objectForKey:USERGRID_cBLUES];
	NSString * uuid =  [[entities objectAtIndex:0] objectForKey:USERGRID_eUUID];
	NSString * modified = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
	NSLog(@"%@Query Found TITLE=\"%@\"  MODIFIED=%@  Blues=%@ UUID=%@",prefix,title,modified,blues,uuid);

	if (blues==nil)
		blues = @"1";
	else
		blues = [NSString stringWithFormat:@"%i",[blues integerValue]+1];

	NSMutableDictionary *entity = [[NSMutableDictionary alloc] init ];
	[entity setObject:APIGEE_TYPE_DEVICES forKey:USERGRID_eTYPE];
//	[entity setObject:modified forKey:USERGRID_eMODIFIED];
	[entity setObject:blues forKey:USERGRID_cBLUES];
	UGClientResponse * responseX = [self.usergridClient updateEntity:uuid entity:entity];
	[entity release];
	if (responseX.transactionState == kUGClientResponseFailure) {
		NSLog(@"%@Modify ?FAILED (%@)=%@ Error=%@",prefix,APIGEE_TYPE_DEVICES,self.blue.paidDevice,responseX.response);
	}
#endif
	return @"*EXISTING";
 }

//*******************************************
// Make sure new CAMERA NAME is in UserGrid
// ENTITIES:
//    "type" = top level (book, axiscams, players, peers, ...) = @"Axis M1032-1234"
// COLLECTIONS:
//*******************************************
-(NSString*)postCameraName:(NSString *)cameraName title:(NSString *)cameraTitle{
	ApigeeQuery *query = [ApigeeQuery new];
	[query addRequiredOperation:USERGRID_eNAME op:kApigeeQueryOperationEquals valueStr:cameraName];
	ApigeeClientResponse *response = [self.usergridClient getEntities:APIGEE_TYPE_AXISCAMS query:query];
	if (response.transactionState == kApigeeClientResponseFailure) {
		//Probably "The Internet connection appears to be offline."
		//If error, then "response" is same as "raw response"
		NSLog(@"%@Query ?FAILED (%@) Error=%@",prefix,APIGEE_TYPE_AXISCAMS,response.response);
		return @"?FAILED";
	}

	NSArray * entities = [response.response objectForKey:USERGRID_qENTITIES];
	if (entities.count==0) {
		NSLog(@"%@Query *NOT FOUND (%@)=%@ result=\n%@",prefix,APIGEE_TYPE_AXISCAMS,cameraName,response.response);
		NSMutableDictionary *entity = [[NSMutableDictionary alloc] init ];
		[entity setObject:APIGEE_TYPE_AXISCAMS  forKey:USERGRID_eTYPE];		//STD field = COLLECTION NAME
		[entity setObject:cameraTitle           forKey:USERGRID_eTITLE];		//STD field = Descriptive Name
		[entity setObject:cameraName            forKey:USERGRID_eNAME];		//STD field = NON-CHANGEABLE AND UNIQUE
		[entity setObject:@"1"                  forKey:USERGRID_cBLUES];		//CUST field

		response = [self.usergridClient createEntity:entity];
		[entity release];
		if (response.transactionState == kApigeeClientResponseFailure) {
			//Probably ALREADY EXISTS?
			NSLog(@"%@Create ?FAILED (%@)=%@ Error=%@",prefix,APIGEE_TYPE_AXISCAMS,cameraName,response.response);
			return @"?FAIL";
		}
		return @"!CREATED";
	}

	NSString * title = [[entities objectAtIndex:0] objectForKey:USERGRID_eTITLE];
	NSString * blues = [[entities objectAtIndex:0] objectForKey:USERGRID_cBLUES];
	NSString * uuid =  [[entities objectAtIndex:0] objectForKey:USERGRID_eUUID];
	NSString * modified = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
	NSLog(@"%@Query Found TITLE=\"%@\"  MODIFIED=%@  Blues=%@ UUID=%@",prefix,title,modified,blues,uuid);

	if (blues==nil)
		blues = @"1";
	else
		blues = [NSString stringWithFormat:@"%i",[blues integerValue]+1];
	
	NSMutableDictionary *entity = [[NSMutableDictionary alloc] init ];
	[entity setObject:APIGEE_TYPE_AXISCAMS forKey:USERGRID_eTYPE];
//	[entity setObject:modified forKey:USERGRID_eMODIFIED];
	[entity setObject:blues forKey:USERGRID_cBLUES];
	ApigeeClientResponse * responseX = [self.usergridClient updateEntity:uuid entity:entity];
	[entity release];
	if (responseX.transactionState == kApigeeClientResponseFailure) {
		NSLog(@"%@Modify ?FAILED (%@)=%@ Error=%@",prefix,APIGEE_TYPE_AXISCAMS,cameraName,responseX.response);
	}
	return @"*EXISTING";
 }

//*******************************************
// RESPONSE DELGATE
//*******************************************
 -(void)ApigeeClientResponse:(ApigeeClientResponse *)response {
	 //Potential EXCEPTION
	 NSLog(@"%@Response#%i -RESULT (%p)=%@",prefix,response.transactionID,response,response.response);
	 @try {
		 NSArray * axis = [response.response objectForKey:@"entities"];
		 NSLog(@"%@TRY=%@ = %@",prefix,response.response,[axis objectAtIndex:0]);
	 }
	 //Yes, It Caused an Exception
	 @catch (NSException * e) {
	 }
	 return;
 }
#endif
@end
