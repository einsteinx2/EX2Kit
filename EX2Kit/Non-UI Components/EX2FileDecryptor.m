//
//  EX2FileDecryptor.m
//  TestCode
//
//  Created by Ben Baron on 6/29/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "EX2FileDecryptor.h"
#import "RNCryptor.h"
#import "EX2RingBuffer.h"
//#import "DDLog.h"

@interface EX2FileDecryptor()
{
	NSString *key;
}
@property (nonatomic, strong) EX2RingBuffer *tempDecryptBuffer;
@property (nonatomic, strong) EX2RingBuffer *decryptedBuffer;
@property (nonatomic) NSUInteger seekOffset;
@property (nonatomic, strong, readonly) NSFileHandle *fileHandle;
@end

@implementation EX2FileDecryptor
@synthesize fileHandle, path, decryptedBuffer, tempDecryptBuffer, seekOffset, chunkSize;

#define DEFAULT_DECR_CHUNK_SIZE 4096

//static const int ddLogLevel = LOG_LEVEL_ERROR;

- (id)init
{
	return [self initWithChunkSize:DEFAULT_DECR_CHUNK_SIZE];
}

- (id)initWithChunkSize:(NSUInteger)theChunkSize
{
	if ((self = [super init]))
	{
		chunkSize = theChunkSize;
		tempDecryptBuffer = [[EX2RingBuffer alloc] initWithBufferLength:500*1024];
		decryptedBuffer = [[EX2RingBuffer alloc] initWithBufferLength:500*1024];
	}
	return self;
}

- (id)initWithPath:(NSString *)aPath chunkSize:(NSUInteger)theChunkSize key:(NSString *)theKey
{
	if ((self = [self initWithChunkSize:theChunkSize]))
	{
		key = [theKey copy];
		path = [aPath copy];
		fileHandle = [NSFileHandle fileHandleForReadingAtPath:aPath];
	}
	return self;
}

- (BOOL)seekToOffset:(NSUInteger)offset
{
	BOOL success = YES;
	
	NSUInteger padding = ((int)(offset / chunkSize) * self.encryptedChunkPadding); // Calculate the encryption padding
	NSUInteger mod = (offset + padding) % self.encryptedChunkSize;
	NSUInteger realOffset = (offset + padding) - mod; // only seek in increments of the encryption blocks
	
	seekOffset = mod;
	
	//DDLogVerbose(@"offset: %u  padding: %u  realOffset: %u  mod: %u:", offset, padding, realOffset, mod);
	
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
		
		//DDLogVerbose(@"  ");
		//DDLogVerbose(@"asked to read length: %u", length);
		// Round up the read to the next block
		//length = self.decryptedBuffer.filledSpaceLength - length;
		NSUInteger realLength = seekOffset + length;
		
		if (((chunkSize - seekOffset) + (length / chunkSize)) < length)
		{
			// We need to read an extra chunk
			realLength += self.encryptedChunkSize;
		}
		
		//DDLogVerbose(@"seek offset %u   realLength %u", seekOffset, realLength);
		NSUInteger mod = realLength % encryptedChunkSize;
		if (mod > chunkSize)
		{
			realLength += encryptedChunkSize;
			mod -= chunkSize;
		}
		
		//DDLogVerbose(@"mod %u", mod);
		//if (mod != 0)
		if (realLength % encryptedChunkSize != 0)
		{
			// pad to the next block
			//realLength += ENCR_CHUNK_SIZE - mod; 
			realLength = ((int)(realLength / encryptedChunkSize) * encryptedChunkSize) + encryptedChunkSize;
		}
		//DDLogVerbose(@"reading length: %u", realLength);
		
		//DDLogInfo(@"file offset: %llu", self.fileHandle.offsetInFile);
		
		// We need to decrypt some more data
		[self.tempDecryptBuffer reset];
		NSData *readData;
		@try {
			readData = [self.fileHandle readDataOfLength:realLength];
		} @catch (NSException *exception) {
			readData = nil;
		}
		//DDLogVerbose(@"read data length %u", readData.length);
		
		if (readData)
		{
			//DDLogVerbose(@"filling temp buffer with data");
			[self.tempDecryptBuffer fillWithData:readData];
			//DDLogVerbose(@"temp buffer filled size %u", self.tempDecryptBuffer.filledSpaceLength);
		}
		
		while (self.tempDecryptBuffer.filledSpaceLength >= encryptedChunkSize)
		{
			//DDLogVerbose(@"draining data");
			NSData *data = [self.tempDecryptBuffer drainData:encryptedChunkSize];
			//DDLogVerbose(@"data drained, filled size %u", self.tempDecryptBuffer.filledSpaceLength);
			NSError *decryptionError;
			//DDLogVerbose(@"decrypting data");
			NSData *decrypted = [[RNCryptor AES256Cryptor] decryptData:data password:key error:&decryptionError];
			//DDLogVerbose(@"data size: %u  decrypted size: %u", data.length, decrypted.length);
			if (decryptionError)
			{
				//DDLogError(@"ERROR THERE WAS AN ERROR DECRYPTING THIS CHUNK");
			}
			else
			{
				// Add the data to the decryption buffer
				if (seekOffset > 0)
				{
					//DDLogVerbose(@"seek offset greater than 0");
					const void *tempBuff = decrypted.bytes;
					//DDLogVerbose(@"filling decrypted buffer length %u", chunkSize-seekOffset);
					[self.decryptedBuffer fillWithBytes:tempBuff+seekOffset length:chunkSize-seekOffset];
					seekOffset = 0;
					//DDLogVerbose(@"setting seekOffset to 0");
				}
				else
				{
					//DDLogVerbose(@"filling decrypted buffer with data length %u", decrypted.length);
					[self.decryptedBuffer fillWithData:decrypted];
					//DDLogVerbose(@"filled decrypted buffer");
				}
			}
		}
	}
	
	// See if there's enough data in the decrypted buffer
	NSUInteger bytesRead = self.decryptedBuffer.filledSpaceLength >= length ? length : self.decryptedBuffer.filledSpaceLength;
	if (bytesRead > 0)
	{
		//DDLogVerbose(@"draining bytes into buffer length %u", bytesRead);
		[self.decryptedBuffer drainBytes:buffer length:bytesRead];
		//DDLogVerbose(@"bytes drained");
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
	//DDLogVerbose(@"read bytes length %u", realLength);
	return returnData;
}

- (void)closeFile
{
	[self.tempDecryptBuffer reset];
	[self.decryptedBuffer reset];
	[self.fileHandle closeFile];
	fileHandle = nil;
}

- (NSUInteger)encryptedChunkPadding
{
	return self.encryptedChunkSize - chunkSize;
}

- (NSUInteger)encryptedChunkSize
{
	NSUInteger aesPaddedSize = ((chunkSize / 16) + 1) * 16;
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
	unsigned long long chunkPadding = self.encryptedChunkSize - chunkSize;
	unsigned long long numberOfEncryptedChunks = (encryptedSize / self.encryptedChunkSize);
	unsigned long long filePadding = numberOfEncryptedChunks * chunkPadding;
	
	// Calculate the decrypted size
	unsigned long long decryptedSize = encryptedSize - filePadding;
	
	return decryptedSize;
}

@end
