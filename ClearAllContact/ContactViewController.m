//
//  ContactViewController.m
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/20.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "ContactViewController.h"
#import <AddressBook/AddressBook.h>

@interface ContactViewController ()<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, assign)ABAddressBookRef addressBook;

@end

@implementation ContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

#pragma mark - Getter and Setter
- (ABAddressBookRef)addressBook {
    if (!_addressBook) {
        CFErrorRef error = nil;
        _addressBook = ABAddressBookCreateWithOptions(NULL, &error);
        if (_addressBook && !error) {
            ABAddressBookRequestAccessWithCompletion(_addressBook, ^(bool granted, CFErrorRef error) {
                if (granted) {
                    NSLog(@"App has been granted");
                } else {
                    NSLog(@"error %@", [(__bridge NSError *)error localizedDescription]);
                }
            });
        } else {
            NSLog(@"error %@", [(__bridge NSError *)error localizedDescription]);
        }
    }
    return _addressBook;
}

#pragma mark - UITableViewDatasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableID = @"contactResuableID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableID];
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
