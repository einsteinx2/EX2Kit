//
//  EX2FileDecryptor.h
//  EX2Kit
//
//  Created by Ben Baron on 6/29/12.
//  Copyright (c) 2012 Anghami. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EX2FileDecryptor : NSObject

@property (nonatomic, readonly) NSError *error;

@property (nonatomic, readonly) NSUInteger chunkSize;
@property (nonatomic, readonly) NSUInteger encryptedChunkSize;
@property (nonatomic, readonly) NSString *path;

@property (nonatomic, readonly) unsigned long long encryptedFileSizeOnDisk;
@property (nonatomic, readonly) unsigned long long decryptedFileSizeOnDisk;

- (id)initWithPath:(NSString *)path chunkSize:(NSUInteger)chunkSize key:(NSString *)key;
- (id)initWithPath:(NSString *)path chunkSize:(NSUInteger)chunkSize key:(NSString *)key alternateKeys:(NSArray *)alternateKeys;

- (BOOL)seekToOffset:(NSUInteger)offset;

- (NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length;
- (NSData *)readData:(NSUInteger)length;
- (NSData *)getEntireData;

- (void)closeFile;

+ (NSDictionary *)openFilePaths;
+ (void)registerOpenFilePath:(NSString *)path;
+ (void)unregisterOpenFilePath:(NSString *)path;
+ (BOOL)isFilePathInUse:(NSString *)path;

+ (unsigned long long)decryptedFileSizeOnDiskForPath:(NSString *)path chunkSize:(NSUInteger)chunkSize;


@end
