//
//  NSMutableArray+Safe.m
//  EX2Kit
//
//  Created by Ben Baron on 6/11/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "NSMutableArray+Safe.h"

@implementation NSMutableArray (Safe)

- (void)addObjectSafe:(id)object
{
    if (object)
    {
        [self addObject:object];
    }
}

- (void)insertObjectSafe:(id)object atIndex:(NSUInteger)index
{
    if (object)
    {
        [self insertObject:object atIndex:index];
    }
}

- (void)removeObjectAtIndexSafe:(NSUInteger)index
{
	if (index < self.count)
	{
		[self removeObjectAtIndex:index];
	}
}

@end
