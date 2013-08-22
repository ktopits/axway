//
//  ICNMasterViewController.h
//  iControl
//
//  Created by Kirk Topits on 8/22/13.
//  Copyright (c) 2013 Apigee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ICNDetailViewController;

@interface ICNMasterViewController : UITableViewController

@property (strong, nonatomic) ICNDetailViewController *detailViewController;

@end
