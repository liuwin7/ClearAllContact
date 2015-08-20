//
//  ViewController.m
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/19.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "MainViewController.h"
#import <AddressBook/AddressBook.h>
#import <AFNetworking/AFNetworking.h>

NSString *CONTACT_NAME = @"ContactName";
NSString *CONTACT_PHONE = @"ContactPhone";
NSString *CONTACT_PHONE_LABEL = @"ConctactPhoneLabel";

@interface MainViewController ()<UIAlertViewDelegate>

@property(nonatomic, assign)ABAddressBookRef addressBook;

@end

@implementation MainViewController
@synthesize addressBook;

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:0.0 green:0.502 blue:1.0 alpha:1.0]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:20.0f],
                                                                      }];
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
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

/**
 *  备份通讯录中的内容，主要是姓名,电话,电话的标签(Label)
 *  生成一个plist文件
    name:张三
    phone:{
            [
                {
                     1352572727,
                     住宅
                },
                {
                     1352572727,
                     办公
                }
 
            ]
        }
 */

- (void)backupContact {
    CFArrayRef recordArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    long recordCount = CFArrayGetCount(recordArray);
    NSMutableArray *contactArray = [NSMutableArray arrayWithCapacity:recordCount];
    for (long i = 0; i < recordCount; i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(recordArray, i);
        // 电话号码
        ABMultiValueRef phoneRef = ABRecordCopyValue(record, kABPersonPhoneProperty);
        long phoneCount = ABMultiValueGetCount(phoneRef);
        NSMutableArray *allPhone = [NSMutableArray arrayWithCapacity:phoneCount]; // 存放所有的电话号码
        for (long j = 0; j < phoneCount; j++) {
            NSMutableDictionary *phoneDic = [NSMutableDictionary dictionaryWithCapacity:3];
            CFStringRef phoneLabelRef = ABMultiValueCopyLabelAtIndex(phoneRef, j);
            CFStringRef lLocalizedLabel = ABAddressBookCopyLocalizedLabel(phoneLabelRef);
            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phoneRef, j);
            if (lLocalizedLabel) {
                phoneDic[CONTACT_PHONE_LABEL] = (__bridge NSString *)lLocalizedLabel;
                CFRelease(lLocalizedLabel);
            } else {
                phoneDic[CONTACT_PHONE_LABEL] = @"";
            }
            if (phoneLabelRef) {
                CFRelease(phoneLabelRef);
            }
            if (phoneNumberRef) {
                phoneDic[CONTACT_PHONE] = (__bridge NSString *)phoneNumberRef;
                CFRelease(phoneNumberRef);
            } else {
                phoneDic[CONTACT_PHONE] = @"";
            }
            
            [allPhone addObject:phoneDic];
        }
        if (phoneRef) {
            CFRelease(phoneRef);
        }
        
        // 姓名
        CFStringRef firstNameRef = ABRecordCopyValue(record, kABPersonFirstNameProperty);
        CFStringRef lastNameRef = ABRecordCopyValue(record, kABPersonLastNameProperty);
        NSString *firstName = firstNameRef != NULL ? (__bridge NSString *)firstNameRef : @"";
        NSString *lastName = lastNameRef != NULL ? (__bridge NSString *)lastNameRef : @"";
        NSString *contactName = [NSString stringWithFormat:@"%@%@", lastName, firstName]; // 姓名

        NSDictionary *dic = @{
                              @"name": contactName,
                              @"phone": allPhone,
                              };
        
        [contactArray addObject:dic];
    }
    
    NSString *backupFilePath = [NSHomeDirectory() stringByAppendingString:@"/Documents/conatct_backup.plist"];
    if (contactArray.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [contactArray writeToFile:backupFilePath atomically:YES];
        });
    }
    [self postContactToServer:contactArray];
}

- (void)postContactToServer:(NSArray *)contacts {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingMutableContainers];
    manager.responseSerializer.acceptableContentTypes =[NSSet setWithObjects:@"text/html", nil];
    NSDictionary *params = @{
                             @"userName": @"topsci",
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
