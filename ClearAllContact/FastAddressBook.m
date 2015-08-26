//
//  FastAddressBook.m
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/20.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "FastAddressBook.h"
#import "ContactModel.h"

NSString *CONTACT_NAME = @"contactName";
NSString *CONTACT_PHONES = @"contactTelephones";
NSString *CONTACT_PHONE_NUMBER = @"phoneNumber";
NSString *CONTACT_PHONE_TYPE = @"phoneType";
NSString *CONTACT_CHANGED = @"contactChanged";
NSString *ADDRESSBOOK_CHANGED_KEY = @"AddressBookChangedKey";


@implementation FastAddressBook
@synthesize addressBook;

+ (instancetype)sharedInstance {
    static FastAddressBook *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FastAddressBook alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reloadAddressBook];
    }
    return self;
}

- (void)reloadAddressBook {
    if (addressBook) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ABAddressBookUnregisterExternalChangeCallback(addressBook, ContactExternalChangeCallback, nil);
        });
    }
    CFErrorRef error = nil;
    addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (addressBook && !error) {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            if (granted) {
                NSLog(@"App has been granted");
                dispatch_async(dispatch_get_main_queue(), ^{
                    ABAddressBookRegisterExternalChangeCallback(addressBook, ContactExternalChangeCallback, (__bridge void *)(self));
                });
            } else {
                NSLog(@"error %@", [(__bridge NSError *)error localizedDescription]);
            }
        });
    } else {
        NSLog(@"error %@", [(__bridge NSError *)error localizedDescription]);
    }
}


- (NSArray *)allContactFromSystem {
    CFArrayRef recordArray = ABAddressBookCopyArrayOfAllPeople(self.addressBook);
    long recordCount = CFArrayGetCount(recordArray);
    NSMutableArray *contactArray = [NSMutableArray arrayWithCapacity:recordCount];
    NSError *error = nil; // JSONModel 使用
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
                phoneDic[CONTACT_PHONE_TYPE] = (__bridge NSString *)lLocalizedLabel;
                CFRelease(lLocalizedLabel);
            } else {
                phoneDic[CONTACT_PHONE_TYPE] = @"";
            }
            if (phoneLabelRef) {
                CFRelease(phoneLabelRef);
            }
            if (phoneNumberRef) {
                phoneDic[CONTACT_PHONE_NUMBER] = (__bridge NSString *)phoneNumberRef;
                CFRelease(phoneNumberRef);
            } else {
                phoneDic[CONTACT_PHONE_NUMBER] = @"";
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
        
        NSDictionary *contactDic = @{
                              CONTACT_NAME: contactName,
                              CONTACT_PHONES: allPhone,
                              };
        // 转换成JSONModel
        ContactModel *model = [[ContactModel alloc] initWithDictionary:contactDic error:&error];
        if (!model && error) {
            NSLog(@"JSONModel Error %@", error);
            break;
        } else {
            [contactArray addObject:model];
        }
    }
    return [contactArray copy];
}

#pragma mark - 
void ContactExternalChangeCallback(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    FastAddressBook *fastAddressBook = (__bridge FastAddressBook *)context;
    [fastAddressBook reloadAddressBook];
    [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:ADDRESSBOOK_CHANGED_KEY];
}

@end
