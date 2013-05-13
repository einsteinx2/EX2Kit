//
//  NSObject+UserInfo.m
//  EX2Kit
//
//  Created by Benjamin Baron on 5/13/13.
//
//

#import "NSObject+UserInfo.h"
#import <objc/runtime.h>

@implementation NSObject (UserInfo)

static void *key;

- (NSMutableDictionary *)ex2UserInfo
{
    return objc_getAssociatedObject(self, &key);
}

- (void)setEx2UserInfo:(NSMutableDictionary *)ex2UserInfo
{
     objc_setAssociatedObject(self, &key, ex2UserInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
