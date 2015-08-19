//
//  ViewController.m
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/19.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "MainViewController.h"
#import <AddressBook/AddressBook.h>

NSString *CONTACT_NAME = @"ContactName";
NSString *CONTACT_PHONE = @"ContactPhone";

@interface MainViewController ()<UIAlertViewDelegate>

@property(nonatomic, assign)ABAddressBookRef addressBook;

@end

@implementation MainViewController
@synthesize addressBook;

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    CFErrorRef error = nil;
    addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (addressBook && !error) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
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

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self clearAllContact];
    }
}

#pragma mark - 

- (void)clearAllContact {
    CFArrayRef recordArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    long recordCount = CFArrayGetCount(recordArray);
    CFErrorRef error = nil;
    for (long i = 0; i < recordCount; i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(recordArray, i);
        bool removeRecordSuccess = ABAddressBookRemoveRecord(addressBook, record, &error);
        if (!removeRecordSuccess && error) {
            break;
        }
    }
    if (error) {
        NSLog(@"error %@", [(__bridge NSError *)error localizedDescription]);
    } else {
        if (ABAddressBookHasUnsavedChanges(addressBook)) {
            bool saveSuccess = ABAddressBookSave(addressBook, &error);
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
                    ABAddressBookAddRecord(addressBook, record, &error);
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
    
    if (ABAddressBookHasUnsavedChanges(addressBook)) {
        bool saveSuccess = ABAddressBookSave(addressBook, &error);
        if (saveSuccess && !error) {
            NSLog(@"synchronize database success");
        } else {
            NSLog(@"error %@", (__bridge NSError *)error);
        }
    }
}

@end
