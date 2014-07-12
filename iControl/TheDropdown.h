/**************************************************************/
/* ktopits -                                                  */
/* TheDropdown.h                                           */
/* KT 09-MAY-2014                                             */
/**************************************************************/

@class TheDropdown;

@interface TheDropdown : NSObject
{
#if 0
	BOOL             usingIOS7;
	UILabel        * myNoteLabel;
	UIImageView    * myNoteView;
	NSMutableArray * promptArray;
	UIViewController    * masterViewController;
#endif
}


#pragma mark - Properties

@property (nonatomic)         BOOL             usingIOS7;
@property (nonatomic, retain) UIViewController * masterViewController;
@property (nonatomic, retain) UILabel        * myNoteLabel;
@property (nonatomic, retain) UIImageView    * myNoteView;
@property (nonatomic, retain) NSMutableArray * promptArray;

//-----------
// Only referenced from ViewControllers and APP Delegate...
//-----------
+ (TheDropdown *) shared;

-(NSInteger)pendingPrompts;
- (void) queNavPrompt:(NSString *)prompt;
- (void)useMasterViewController:(UIViewController *)view;

@end

