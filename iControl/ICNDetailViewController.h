//
//  ICNDetailViewController.h
//  iControl
//
//  Created by Kirk Topits on 8/22/13.
//  Copyright (c) 2013 Apigee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICNDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
