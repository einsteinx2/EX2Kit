//
//  NSMutableDictionary+Safe.m
//  EX2Kit
//
//  Created by Ben Baron on 9/15/12.
//  Copyright (c) 2012 Anghami. All rights reserved.
//

#import "NSMutableDictionary+Safe.h"

@implementation NSMutableDictionary (Safe)

- (void)setObjectSafe:(id)object forKey:(id)key
{
    if (object)
    {
        [self setObject:object forKey:key];
    }
}

@end
