/**************************************************************/
/* iControl -                                                 */
/* ApigeeGateway.h                                            */
/* KT 25-Aug-2013                                             */
/**************************************************************/



@interface ApigeeGateway : NSObject
{
    NSString        * auth_url;         //url for autorization
    NSString        * code;             //Return From OAUTH signin
    NSString        * token;            //Return From OAUTH autorization
}

#pragma mark -
#pragma mark Properties

@property (nonatomic, strong) NSString * auth_url;
@property (nonatomic, strong) NSString * code;
@property (nonatomic, strong) NSString * token;


//-----------
// External Access
//-----------
+ (ApigeeGateway *) shared;

@end
