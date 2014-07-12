/**************************************************************/
/* KTOPITS  -                                                 */
/* ListTableViewCell.h                                        */
/* KT 09-JUL-2014                                             */
/**************************************************************/

//NIB file view, links elements to this structure

@interface ListTableViewCell : UITableViewCell {
	UIImageView *listIcon;
	UIImageView *redbarIcon;
	UILabel *infoLabel;
	UITextField *nameField;
	UIActivityIndicatorView *activity;
}

//Items SYNCED with INTERFACE BUILDER
@property (nonatomic, retain) IBOutlet UIImageView *listIcon;
@property (nonatomic, retain) IBOutlet UIImageView *redbarIcon;
@property (nonatomic, retain) IBOutlet UILabel *infoLabel;
@property (nonatomic, retain) IBOutlet UITextField *nameField;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activity;

@end
