//
//  PhoneModel.h
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/20.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "JSONModel.h"

@protocol PhoneModel <NSObject>
@end

@interface PhoneModel : JSONModel

@property(nonatomic, copy)NSString *phoneNumber;
@property(nonatomic, copy)NSString *phoneType;

@end
