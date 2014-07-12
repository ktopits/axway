/**************************************************************/
/* KTOPITS -                                                 */
/* ListTableViewCell.m                                        */
/* KT 09-JUL-2014                                             */
/**************************************************************/

#import "ListTableViewCell.h"

@implementation ListTableViewCell

@synthesize listIcon;
@synthesize redbarIcon;
@synthesize nameField;
@synthesize infoLabel;
@synthesize activity;


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	// The user can only edit the text field when in editing mode.
    [super setEditing:editing animated:animated];
	nameField.enabled = editing;
}

#if 0
//if recycle cell that was last used duringediting, and now viewing, need to undo size adjust
- (void)prepareForReuse {
	[super prepareForReuse]; //<- MAGIC here! Fixes incorrect (-) in LIST, but Breaks name offset in SONG
#if 0
	if ((self.nameFieldWidth>0)&&(!countLabel.hidden)) {
//		NSLog(@"~~~ >ListCell   *FIXUP(%f) was= \"%@\"",self.nameFieldWidth,self.nameField.text);
		CGRect frame = nameField.frame;
		frame.size.width = self.nameFieldWidth;
		
		nameField.frame = frame;	
		nameField.adjustsFontSizeToFitWidth = YES;
		self.nameFieldWidth = 0;
	}
#endif
}
#endif

//Called to kill of CELL VIEW.  If "deque" then this only happens when VIEW disappears, and all 10 views are killed.
// if not "deque" then this is called when cell is no longer visible
//Clean up here, because SUPER is brutal and will de-allocate everything it can find!
//BlueBand uses same image in MULTIPLE cells, so never want it de-allocated.
- (void)dealloc {
//	NSLog(@"~~~ >ListCell   *DEALLOC* %p %@ !@!@!@!@!@  %p/%p",self,self.reuseIdentifier,self.listIcon.image,self.listIcon.highlightedImage);

	
	self.listIcon.image = nil;
	self.listIcon.hidden = YES;
	self.listIcon.highlightedImage = nil;
	self.nameField.placeholder = nil;
//	self.nameFieldWidth = 0;
	[infoLabel release];
	[nameField release];
	[listIcon release];
	[activity release];
	[redbarIcon release];
	[super dealloc];
}

@end
