//
//  FastAddressBook.h
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/20.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

extern NSString *CONTACT_NAME;
extern NSString *CONTACT_PHONES;
extern NSString *CONTACT_PHONE_NUMBER;
extern NSString *CONTACT_PHONE_TYPE;
extern NSString *CONTACT_CHANGED;
extern NSString *ADDRESSBOOK_CHANGED_KEY;

@interface FastAddressBook : NSObject

@property(nonatomic, assign)ABAddressBookRef addressBook;

+ (instancetype)sharedInstance;

/**
 *  所有的联系人信息
 *
 *  @return 由ContactModel组成的数组
 *  @sa ContactModel
 */
- (NSArray *)allContactFromSystem;

@end
