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
    return self;
}


- (NSArray *)allContactFromSystem {
    CFArrayRef recordArray = ABAddressBookCopyArrayOfAllPeople(self.addressBook);
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
        
        NSDictionary *dic = @{
                              CONTACT_NAME: contactName,
                              CONTACT_PHONES: allPhone,
                              };
        
        [contactArray addObject:dic];
    }
    // 转换成JSONModel
    NSMutableArray *contacts = [NSMutableArray array];
    __block NSError *error = nil;
    [contactArray enumerateObjectsUsingBlock:^(NSDictionary *contactDic, NSUInteger idx, BOOL *stop) {
        ContactModel *model = [[ContactModel alloc] initWithDictionary:contactDic error:&error];
        if (!model && error) {
            *stop = YES;
        }
    }];
    
    return [contacts copy];
}


@end
