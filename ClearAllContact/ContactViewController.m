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
#import "NSString+TransformToChinesePhoneticize.h"

@interface ContactViewController ()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, strong)NSArray *contactTableViewTitles;
@property(nonatomic, strong)NSDictionary *contactGroupDictionary;
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;

@end

@implementation ContactViewController

@synthesize contactTableViewTitles, contactGroupDictionary;

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
    NSArray *systemContactModels = [[FastAddressBook sharedInstance] allContactFromSystem];
    
    // 分组的title
    NSMutableSet *lastNames = [NSMutableSet set];
    [systemContactModels enumerateObjectsUsingBlock:^(ContactModel *model, NSUInteger idx, BOOL *stop) {
        [lastNames addObject:[[[model.contactName transformToChinesePhoneticize] substringToIndex:1] uppercaseString]];
    }];
    contactTableViewTitles = [[lastNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    // 每个分组的model
    NSMutableDictionary *groupModelDic = [NSMutableDictionary dictionaryWithCapacity:contactTableViewTitles.count];
    [systemContactModels enumerateObjectsUsingBlock:^(ContactModel *model, NSUInteger idx, BOOL *stop) {
        NSString *firstCharInLastName = [[[model.contactName transformToChinesePhoneticize] substringToIndex:1] uppercaseString];
        if (firstCharInLastName) {
            NSMutableArray *groupArray = groupModelDic[firstCharInLastName];
            if (!groupArray) {
                groupArray = [NSMutableArray array];
                [groupModelDic setObject:groupArray forKey:firstCharInLastName];
            }
            [groupArray addObject:model];
        }
    }];
    contactGroupDictionary = [NSDictionary dictionaryWithDictionary:groupModelDic];
    
    [self.contactTableView reloadData];
}

#pragma mark - UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return contactTableViewTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionTitle = contactTableViewTitles[section];
    NSArray *sectionContacts = contactGroupDictionary[sectionTitle];
    return sectionContacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableID = @"contactResuableID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableID];
    
    NSString *sectionTitle = contactTableViewTitles[indexPath.section];
    NSArray *sectionContacts = contactGroupDictionary[sectionTitle];
    ContactModel *model = sectionContacts[indexPath.row];
    
    cell.textLabel.text = model.contactName;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return contactTableViewTitles[section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return contactTableViewTitles;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ContactDetailSegueID"]) {
        ContactDetailTableViewController *contactDetailVC = (ContactDetailTableViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.contactTableView indexPathForCell:(UITableViewCell *)sender];
        
        NSString *sectionTitle = contactTableViewTitles[indexPath.section];
        NSArray *sectionContacts = contactGroupDictionary[sectionTitle];
        ContactModel *model = sectionContacts[indexPath.row];
        
        contactDetailVC.contactModel = model;
    }
}

@end
