//
//  ContactViewController.m
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/20.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "ContactViewController.h"
#import <AddressBook/AddressBook.h>
#import "FastAddressBook.h"
#import "ContactModel.h"
#import "ContactDetailTableViewController.h"

@interface ContactViewController ()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong)NSArray *contactModelList;
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;

@end

@implementation ContactViewController

@synthesize contactModelList;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.0 green:0.502 blue:1.0 alpha:1.0]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:20.0f],
                                                                      }];
    [self loadContactData];
}

#pragma mark - 
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    BOOL contactChanged = [[NSUserDefaults standardUserDefaults] boolForKey:ADDRESSBOOK_CHANGED_KEY];
    if (contactChanged) {
        [self loadContactData];
        [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:ADDRESSBOOK_CHANGED_KEY];
    }
}

- (void)loadContactData {
    contactModelList = [[FastAddressBook sharedInstance] allContactFromSystem];
    [self.contactTableView reloadData];
}

#pragma mark - UITableViewDatasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return contactModelList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableID = @"contactResuableID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableID];
    ContactModel *model = contactModelList[indexPath.row];
    cell.textLabel.text = model.contactName;
    return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ContactDetailSegueID"]) {
        ContactDetailTableViewController *contactDetailVC = (ContactDetailTableViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.contactTableView indexPathForCell:(UITableViewCell *)sender];
        contactDetailVC.contactModel = self.contactModelList[indexPath.row];
    }
}

@end
