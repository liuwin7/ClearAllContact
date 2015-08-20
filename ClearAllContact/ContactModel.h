//
//  ContactModel.h
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/20.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "JSONModel.h"
#import "PhoneModel.h"

@interface ContactModel : JSONModel

@property(nonatomic, copy)NSString *contactName;
@property(nonatomic, strong)NSArray<PhoneModel, ConvertOnDemand> *contactTelephones;

@end
