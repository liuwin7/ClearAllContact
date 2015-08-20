//
//  FastAddressBook.h
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/20.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

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
