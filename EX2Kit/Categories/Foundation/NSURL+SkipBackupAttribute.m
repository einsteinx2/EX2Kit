//
//  NSURL+SkipBackupAttribute.m
//  EX2Kit
//
//  Created by Benjamin Baron on 11/21/12.
//
//

#import "NSURL+SkipBackupAttribute.h"
#import <sys/xattr.h>
#import "EX2ANGLogger.h"

@implementation NSURL (SkipBackupAttribute)

- (BOOL)addOrRemoveSkipAttribute:(BOOL)isAdd
{
    // Do the new method
    NSError *error = nil;
    BOOL success = NO;
    
    @try
    {
        success = [self setResourceValue:@(isAdd) forKey:NSURLIsExcludedFromBackupKey error:&error];
        if(!success)
            [EX2ANGLogger logError:@"Error excluding %@ from backup: %@", self.lastPathComponent, error];
    }
    @catch (NSException *exception)
    {
        [EX2ANGLogger logError:@"Exception excluding %@ from backup: %@", self.lastPathComponent, exception];
    }
    
    return success;
}

- (BOOL)addSkipBackupAttribute
{
    return [self addOrRemoveSkipAttribute:YES];
}

- (BOOL)removeSkipBackupAttribute
{
    return [self addOrRemoveSkipAttribute:NO];
}

@end
