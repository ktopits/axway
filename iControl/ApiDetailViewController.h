/**************************************************************/
/* ktopits  -                                                 */
/* ApiDetailViewController.h                                  */
/* KT 01-May-2013                                             */
/**************************************************************/

#import <UIKit/UIKit.h>
#import "ApiMachine.h"

@class ApigeeGateway;
//@class ICNEvent;

@interface ApiDetailViewController : UITableViewController <
	UISplitViewControllerDelegate,
    UIActionSheetDelegate,
    UIAlertViewDelegate,
	ApiMachineDelegate
>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) NSString * detailType;
@property (strong, nonatomic) id responseItem;
@property (strong, nonatomic) UIBarButtonItem * barButton;

@property (nonatomic        ) BOOL detailArrayReady;
@property (strong, nonatomic) NSMutableArray * detailArray0;
@property (strong, nonatomic) NSMutableArray * detailArray1;
@property (strong, nonatomic) NSMutableArray * detailArray2;

@property (strong, nonatomic) UIAlertView * detailAlertView;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) UINavigationController * mySplitNavController;

@end
