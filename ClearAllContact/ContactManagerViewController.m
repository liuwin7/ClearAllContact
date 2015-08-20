//
//  ViewController.m
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/19.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "ContactManagerViewController.h"
#import <AddressBook/AddressBook.h>
#import <AFNetworking/AFNetworking.h>
#import "FastAddressBook.h"
#import "ContactModel.h"

NSString *CONTACT_NAME = @"ContactName";
NSString *CONTACT_PHONE = @"ContactPhone";
NSString *CONTACT_PHONE_LABEL = @"ConctactPhoneLabel";

@interface ContactManagerViewController ()<UIAlertViewDelegate>

@property(nonatomic, assign)ABAddressBookRef addressBook;

@end

@implementation ContactManagerViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.0 green:0.502 blue:1.0 alpha:1.0]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:20.0f],
                                                                      }];
}

#pragma mark - getter and setter
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


#pragma mark - Target Action
- (IBAction)clearAction:(UIButton *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"删除所有联系人"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
    [alertView show];
}

- (IBAction)importAction:(UIButton *)sender {
    [self importDefaultContact];
}

- (IBAction)backupAction:(UIButton *)sender {
    [self backupContact];
}

- (IBAction)recoverAction:(UIButton *)sender {
    [self recoverContact];
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self clearAllContact];
    }
}

#pragma mark - 

- (void)clearAllContact {
    CFArrayRef recordArray = ABAddressBookCopyArrayOfAllPeople(self.addressBook);
    long recordCount = CFArrayGetCount(recordArray);
    CFErrorRef error = nil;
    for (long i = 0; i < recordCount; i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(recordArray, i);
        bool removeRecordSuccess = ABAddressBookRemoveRecord(self.addressBook, record, &error);
        if (!removeRecordSuccess && error) {
            break;
        }
    }
    if (error) {
        NSLog(@"error %@", [(__bridge NSError *)error localizedDescription]);
    } else {
        if (ABAddressBookHasUnsavedChanges(self.addressBook)) {
            bool saveSuccess = ABAddressBookSave(self.addressBook, &error);
            if (saveSuccess && !error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                    message:@"成功"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"取消"
                                                          otherButtonTitles:@"确定", nil];
                [alertView show];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"失败"
                                                                    message:[(__bridge NSError *)error localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"取消"
                                                          otherButtonTitles:@"确定", nil];
                [alertView show];
            }
        } else {
            NSLog(@"has no change");
        }
    }

    if (recordArray) {
        CFRelease(recordArray);
    }
}

- (void)importDefaultContact {
    NSString *defaultContactPlistPath = [[NSBundle mainBundle] pathForResource:@"DefaultContact" ofType:@"plist"];
    NSArray *defaultContacts = [[NSArray alloc] initWithContentsOfFile:defaultContactPlistPath];
    __block CFErrorRef error = NULL;
    [defaultContacts enumerateObjectsUsingBlock:^(NSDictionary *personDic, NSUInteger idx, BOOL *stop) {
        ABRecordRef record = ABPersonCreate();
        NSString *name = personDic[CONTACT_NAME];
        
        // 姓氏
        NSString *lastName = [name substringToIndex:1];
        ABRecordSetValue(record, kABPersonLastNameProperty, (__bridge CFStringRef)lastName, &error);
        if (error) {
            *stop = YES;
        } else {
            // 名字
            NSString *firstName = [name substringFromIndex:1];
            ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFStringRef)firstName, &error);
            if (error) {
                *stop = YES;
            } else {
                // 电话号码
                NSString *phoneNumber = personDic[CONTACT_PHONE];
                ABMultiValueRef phoneNumberRef = ABMultiValueCreateMutable(kABPersonPhoneProperty);
                ABMultiValueAddValueAndLabel(phoneNumberRef, (__bridge CFStringRef)phoneNumber, kABPersonPhoneMobileLabel, NULL);
                ABRecordSetValue(record, kABPersonPhoneProperty, phoneNumberRef, &error);
                if (error) {
                    *stop = YES;
                } else {
                    ABAddressBookAddRecord(self.addressBook, record, &error);
                }
                // 释放Core Foundation 变量
                if (phoneNumberRef) {
                    CFRelease(phoneNumberRef);
                }
            }
        }

        if (error) {
            NSLog(@"error %@", (__bridge NSError *)error);
        } else {
            NSLog(@"success import %@", name);
        }
        
        // 释放Core Foundation 变量
        if (record) {
            CFRelease(record);
        }
    }];
    
    if (ABAddressBookHasUnsavedChanges(self.addressBook)) {
        bool saveSuccess = ABAddressBookSave(self.addressBook, &error);
        if (saveSuccess && !error) {
            NSLog(@"synchronize database success");
        } else {
            NSLog(@"error %@", (__bridge NSError *)error);
        }
    }
}

- (void)backupContact {
    NSArray *allContactModel = [[FastAddressBook sharedInstance] allContactFromSystem];
    NSMutableArray *contactDicArray = [NSMutableArray arrayWithCapacity:allContactModel.count];
    [allContactModel enumerateObjectsUsingBlock:^(ContactModel *contact, NSUInteger idx, BOOL *stop) {
        [contactDicArray addObject:[contact toDictionary]];
    }];
    [self postContacts:contactDicArray forUsername:@"topsci"];
}

- (void)postContacts:(NSArray *)contacts forUsername:(NSString *)username {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingMutableContainers];
    manager.responseSerializer.acceptableContentTypes =[NSSet setWithObjects:@"text/html", nil];
    NSDictionary *params = @{
                             @"userName": username,
                             @"contacts": contacts,
                             };
    [manager POST:@"http://168.192.2.5/post_file.php" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response object %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error %@", error);
    }];
}

- (void)recoverContact {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingMutableContainers];
    manager.responseSerializer.acceptableContentTypes =[NSSet setWithObjects:@"text/html", nil];
    NSDictionary *paramDic = @{
                               @"userName": @"topsci",
                               };
    [manager POST:@"http://168.192.2.5/recover_file.php" parameters:paramDic success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response object %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error %@", error);
    }];
}

@end
