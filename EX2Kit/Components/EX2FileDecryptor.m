//
//  EX2FileDecryptor.m
//  EX2Kit
//
//  Created by Ben Baron on 6/29/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "EX2FileDecryptor.h"
#import "RNCryptor.h"
//#import "RNDecryptor.h"
#import "EX2RingBuffer.h"
#import "DDLog.h"

// Keyed on file path, value is number of references
static __strong NSMutableDictionary *_activeFilePaths;

@interface EX2FileDecryptor()
{
	NSString *_key;
}
@property (nonatomic, strong) EX2RingBuffer *tempDecryptBuffer;
@property (nonatomic, strong) EX2RingBuffer *decryptedBuffer;
@property (nonatomic) NSUInteger seekOffset;
@property (nonatomic, strong, readonly) NSFileHandle *fileHandle;
@end

@implementation EX2FileDecryptor

#define DEFAULT_DECR_CHUNK_SIZE 4096

static const int ddLogLevel = LOG_LEVEL_ERROR;

+ (void)registerOpenFilePath:(NSString *)path
{
    if (!path)
        return;
    
    @synchronized(self)
    {
        // Make sure the dictionary exists
        if (!_activeFilePaths)
        {
            _activeFilePaths = [NSMutableDictionary dictionaryWithCapacity:10];
        }
        
        // Note that if the entry doesn't exist, this still works because [_activeFilePaths[path] unsignedIntegerValue] evaluates to 0
        NSInteger adjustedValue = [_activeFilePaths[path] integerValue] + 1;
        _activeFilePaths[path] = @(adjustedValue);
        
        DLog(@"_activeFilePaths: %@", _activeFilePaths);
    }
}

+ (void)unregisterOpenFilePath:(NSString *)path
{
    if (!path)
        return;
    
    @synchronized(self)
    {        
        NSInteger adjustedValue = [_activeFilePaths[path] integerValue] - 1;
        if (adjustedValue <= 0)
        {
            // If decrementing the value will bring it to 0, remove the entry
            [_activeFilePaths removeObjectForKey:path];
        }
        else
        {
            _activeFilePaths[path] = @(adjustedValue);
        }
        
        DLog(@"_activeFilePaths: %@", _activeFilePaths);
    }
}

+ (BOOL)isFilePathInUse:(NSString *)path
{
    if (!path)
        return NO;
    
    @synchronized(self)
    {
        // If the dictionary contains this path, then the ref count must be greater than 0
        return [_activeFilePaths.allKeys containsObject:path];
    }
}

- (id)init
{
	return [self initWithChunkSize:DEFAULT_DECR_CHUNK_SIZE];
}

- (id)initWithChunkSize:(NSUInteger)theChunkSize
{
	if ((self = [super init]))
	{
		_chunkSize = theChunkSize;
        
		_tempDecryptBuffer = [[EX2RingBuffer alloc] initWithBufferLength:BytesFromKiB(75)];
        _tempDecryptBuffer.maximumLength = BytesFromKiB(500);
        
		_decryptedBuffer = [[EX2RingBuffer alloc] initWithBufferLength:BytesFromKiB(75)];
        _decryptedBuffer.maximumLength = BytesFromKiB(500);
	}
	return self;
}

- (id)initWithPath:(NSString *)aPath chunkSize:(NSUInteger)theChunkSize key:(NSString *)theKey
{
	if ((self = [self initWithChunkSize:theChunkSize]))
	{
		_key = [theKey copy];
		_path = [aPath copy];
		_fileHandle = [NSFileHandle fileHandleForReadingAtPath:aPath];
        
        [EX2FileDecryptor registerOpenFilePath:_path];
	}
	return self;
}

- (BOOL)seekToOffset:(NSUInteger)offset
{
	BOOL success = YES;
	
	NSUInteger padding = ((int)(offset / self.chunkSize) * self.encryptedChunkPadding); // Calculate the encryption padding
	NSUInteger mod = (offset + padding) % self.encryptedChunkSize;
	NSUInteger realOffset = (offset + padding) - mod; // only seek in increments of the encryption blocks
	
	self.seekOffset = mod;
	
	DDLogVerbose(@"[EX2FileDecryptor] offset: %u  padding: %u  realOffset: %u  mod: %u:", offset, padding, realOffset, mod);
	
	@try {
		[self.fileHandle seekToFileOffset:realOffset];
	} @catch (NSException *exception) {
		success = NO;
	}
	
	if (success)
	{
		[self.tempDecryptBuffer reset];
		[self.decryptedBuffer reset];
	}
	
	return success;
}

- (NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length
{
	if (self.decryptedBuffer.filledSpaceLength < length)
	{
		NSUInteger encryptedChunkSize = self.encryptedChunkSize;
		
		DDLogVerbose(@"[EX2FileDecryptor]   ");
		DDLogVerbose(@"[EX2FileDecryptor] asked to read length: %u", length);
		// Round up the read to the next block
		//length = self.decryptedBuffer.filledSpaceLength - length;
		NSUInteger realLength = self.seekOffset + length;
		
		if (((self.chunkSize - self.seekOffset) + (length / self.chunkSize)) < length)
		{
			// We need to read an extra chunk
			realLength += self.encryptedChunkSize;
		}
		
		DDLogVerbose(@"[EX2FileDecryptor] seek offset %u   realLength %u", self.seekOffset, realLength);
		NSUInteger mod = realLength % encryptedChunkSize;
		if (mod > self.chunkSize)
		{
			realLength += encryptedChunkSize;
			mod -= self.chunkSize;
		}
		
		DDLogVerbose(@"[EX2FileDecryptor] mod %u", mod);
		//if (mod != 0)
		if (realLength % encryptedChunkSize != 0)
		{
			// pad to the next block
			//realLength += ENCR_CHUNK_SIZE - mod; 
			realLength = ((int)(realLength / encryptedChunkSize) * encryptedChunkSize) + encryptedChunkSize;
		}
		DDLogVerbose(@"[EX2FileDecryptor] reading length: %u", realLength);
		
		DDLogInfo(@"[EX2FileDecryptor] file offset: %llu", self.fileHandle.offsetInFile);
		
		// We need to decrypt some more data
		[self.tempDecryptBuffer reset];
		NSData *readData;
		@try {
			readData = [self.fileHandle readDataOfLength:realLength];
		} @catch (NSException *exception) {
			readData = nil;
		}
		DDLogVerbose(@"[EX2FileDecryptor] read data length %u", readData.length);
		
		if (readData)
		{
			DDLogVerbose(@"[EX2FileDecryptor] filling temp buffer with data");
			[self.tempDecryptBuffer fillWithData:readData];
			DDLogVerbose(@"[EX2FileDecryptor] temp buffer filled size %u", self.tempDecryptBuffer.filledSpaceLength);
		}
		
		while (self.tempDecryptBuffer.filledSpaceLength >= encryptedChunkSize)
		{
			DDLogVerbose(@"[EX2FileDecryptor] draining data");
			NSData *data = [self.tempDecryptBuffer drainData:encryptedChunkSize];
			DDLogVerbose(@"[EX2FileDecryptor] data drained, filled size %u", self.tempDecryptBuffer.filledSpaceLength);
			NSError *decryptionError;
			DDLogVerbose(@"[EX2FileDecryptor] decrypting data");
			NSData *decrypted = [[RNCryptor AES256Cryptor] decryptData:data password:_key error:&decryptionError];
            //NSData *decrypted = [RNDecryptor decryptData:data withPassword:_key error:&decryptionError];
			DDLogVerbose(@"[EX2FileDecryptor] data size: %u  decrypted size: %u", data.length, decrypted.length);
			if (decryptionError)
			{
				_error = decryptionError;
				DDLogError(@"[EX2FileDecryptor] ERROR THERE WAS AN ERROR DECRYPTING THIS CHUNK");
			}
			else
			{
				// Add the data to the decryption buffer
				if (self.seekOffset > 0)
				{
					DDLogVerbose(@"[EX2FileDecryptor] seek offset greater than 0");
					const void *tempBuff = decrypted.bytes;
					DDLogVerbose(@"[EX2FileDecryptor] filling decrypted buffer length %u", self.chunkSize - self.seekOffset);
					[self.decryptedBuffer fillWithBytes:tempBuff+self.seekOffset length:self.chunkSize-self.seekOffset];
					self.seekOffset = 0;
					DDLogVerbose(@"[EX2FileDecryptor] setting seekOffset to 0");
				}
				else
				{
					DDLogVerbose(@"[EX2FileDecryptor] filling decrypted buffer with data length %u", decrypted.length);
					[self.decryptedBuffer fillWithData:decrypted];
					DDLogVerbose(@"[EX2FileDecryptor] filled decrypted buffer");
				}
			}
		}
	}
	
	// See if there's enough data in the decrypted buffer
	NSUInteger bytesRead = self.decryptedBuffer.filledSpaceLength >= length ? length : self.decryptedBuffer.filledSpaceLength;
	if (bytesRead > 0)
	{
		DDLogVerbose(@"[EX2FileDecryptor] draining bytes into buffer length %u", bytesRead);
		[self.decryptedBuffer drainBytes:buffer length:bytesRead];
		DDLogVerbose(@"[EX2FileDecryptor] bytes drained");
	}

	return bytesRead;
}

- (NSData *)readData:(NSUInteger)length
{
	void *buffer = malloc(sizeof(char) * length);
	NSUInteger realLength = [self readBytes:buffer length:length];
	NSData *returnData = nil;
	if (realLength > 0)
	{
		returnData = [NSData dataWithBytesNoCopy:buffer length:realLength freeWhenDone:YES];
	}
	DDLogVerbose(@"[EX2FileDecryptor] read bytes length %u", realLength);
	return returnData;
}

- (void)closeFile
{
	[self.tempDecryptBuffer reset];
	[self.decryptedBuffer reset];
	[self.fileHandle closeFile];
	_fileHandle = nil;
    
    [EX2FileDecryptor unregisterOpenFilePath:self.path];
}

- (NSUInteger)encryptedChunkPadding
{
	return self.encryptedChunkSize - self.chunkSize;
}

- (NSUInteger)encryptedChunkSize
{
	NSUInteger aesPaddedSize = ((self.chunkSize / 16) + 1) * 16;
	NSUInteger totalPaddedSize = aesPaddedSize + 66; // Add the RNCryptor padding
	return totalPaddedSize;
}

- (unsigned long long)encryptedFileSizeOnDisk
{
	// Just get the size from disk
	return [[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil] fileSize];
}

- (unsigned long long)decryptedFileSizeOnDisk
{
	// Find the encrypted size
	unsigned long long encryptedSize = self.encryptedFileSizeOnDisk;
	
	// Find padding size
	unsigned long long chunkPadding = self.encryptedChunkSize - self.chunkSize;
	unsigned long long numberOfEncryptedChunks = (encryptedSize / self.encryptedChunkSize);
	unsigned long long filePadding = numberOfEncryptedChunks * chunkPadding;
	
	// Calculate the decrypted size
	unsigned long long decryptedSize = encryptedSize - filePadding;
	
	return decryptedSize;
}

@end
