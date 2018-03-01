//
//  EX2ANGLogger.m
//  EX2Kit
//
//  Created by Apple on 3/1/18.
//

#import "EX2ANGLogger.h"

@implementation EX2ANGLogger

+ (void)log:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    
    NSString *logMsg = [[NSString alloc] initWithFormat:format arguments:args];
    if (logMsg.length == 0) {
        return;
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationLogRequest object:logMsg];
    va_end(args);
}

+ (void)logError:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    
    NSString *logMsg = [[NSString alloc] initWithFormat:format arguments:args];
    if (logMsg.length == 0) {
        return;
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationLogRequest object:logMsg];
    va_end(args);
}

+ (void)logInfo:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    
    NSString *logMsg = [[NSString alloc] initWithFormat:format arguments:args];
    if (logMsg.length == 0) {
        return;
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:kNotificationLogRequest object:logMsg];
    va_end(args);
}

@end
