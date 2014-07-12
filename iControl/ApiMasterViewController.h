/**************************************************************/
/* ktopitsAxway -                                                 */
/* ApiMasterViewController.h                                  */
/* KT 02-JUL-2014                                             */
/**************************************************************/

#define USE_BONJOUR 1

#import "ApiMachine.h"

@class ApiDetailViewController;
@class ApigeeGateway;
@class ListTableViewCell;

@interface ApiMasterViewController : UITableViewController <
    UIActionSheetDelegate,
    UIAlertViewDelegate,
    ApiMachineDelegate
>

@property (strong, nonatomic) ApiDetailViewController *detailViewController;
@property (nonatomic        ) BOOL masterArrayReady;
@property (nonatomic, retain) NSMutableArray * objectH;
@property (nonatomic, retain) NSMutableArray * objectD;
@property (nonatomic, retain) NSMutableArray * objectU;
@property (strong, nonatomic) UIActionSheet * myActionSheet;
@property (strong, nonatomic) UIAlertView * myAlertView;
@property (nonatomic, retain) NSString * stockSymbol;
@property (nonatomic, retain) NSString * gatewayAddress;
@property (nonatomic        ) BOOL scope_sms;
@property (nonatomic        ) BOOL scope_mms;
@property (nonatomic        ) BOOL scope_speech;
@property (nonatomic        ) BOOL scope_device;
@property (nonatomic        ) BOOL scope_location;
@property (nonatomic        ) BOOL scope_mim;
@property (nonatomic        ) BOOL scope_immn;
@property (nonatomic        ) BOOL cleanupOnRefresh;
@property (nonatomic, retain) NSDictionary * portsJson;
#if USE_BONJOUR
@property (nonatomic, retain) NSMutableArray * bonjourNames;
@property (nonatomic, retain) NSString * bonjourName;
@property (nonatomic, retain) NSString * bonjourAddress;
@property (nonatomic        ) NSInteger bonjourPort;
#endif
@property (strong, nonatomic) NSIndexPath * detailSelection;
@property (strong, nonatomic) UIBarButtonItem *authButton;
@property (strong, nonatomic) UIBarButtonItem *refreshButton;
@property (strong, nonatomic) UIBarButtonItem *stopButton;

@property (nonatomic, assign) IBOutlet ListTableViewCell * listTableViewCell;
@property (nonatomic, retain) IBOutlet UILabel * myfooter;


@end
