//
//  NSString+TransformToChinesePhoneticize.m
//  ClearAllContact
//
//  Created by topsci_ybma on 15/8/26.
//  Copyright (c) 2015年 topsci. All rights reserved.
//

#import "NSString+TransformToChinesePhoneticize.h"

@implementation NSString (TransformToChinesePhoneticize)

- (NSString *)transformToChinesePhoneticize {
    if ([self length]) {
        NSMutableString *mutableString = [[NSMutableString alloc] initWithString:self];
        if (CFStringTransform((__bridge CFMutableStringRef)mutableString, 0, kCFStringTransformToLatin, NO)) {
            if (CFStringTransform((__bridge CFMutableStringRef)mutableString, 0, kCFStringTransformStripDiacritics, NO)) {
                NSString *string = [NSString stringWithString:mutableString];
                return string;
            }
        }
    }
    return nil;
}

@end
