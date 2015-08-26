//
//  ContactDetailTableViewController.h
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/26.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ContactModel;
@interface ContactDetailTableViewController : UITableViewController

@property(nonatomic, strong)ContactModel *contactModel;

@end
