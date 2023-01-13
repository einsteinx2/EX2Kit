//
//  EX2FileDecryptor.m
//  EX2Kit
//
//  Created by Ben Baron on 6/29/12.
//  Copyright (c) 2012 Anghami. All rights reserved.
//

#import "EX2FileDecryptor.h"
#import "RNCryptorOld.h"
#import "RNDecryptor.h"
#import "EX2RingBuffer.h"
#import "DDLog.h"
#import "EX2ANGLogger.h"

// Keyed on file path, value is number of references
static __strong NSMutableDictionary *_activeFilePaths;

@interface EX2FileDecryptor()
{
	NSString *_key;
    NSArray *_alternateKeys;
}
@property (nonatomic, strong) EX2RingBuffer *tempDecryptBuffer;
@property (nonatomic, strong) EX2RingBuffer *decryptedBuffer;
@property (nonatomic) NSUInteger seekOffset;
@property (nonatomic, strong, readonly) NSFileHandle *fileHandle;
@property (nonatomic) BOOL useOldDecryptor;
@end

@implementation EX2FileDecryptor

#define DEFAULT_DECR_CHUNK_SIZE 4096

+ (NSDictionary *)openFilePaths
{
    return [NSDictionary dictionaryWithDictionary:_activeFilePaths];
}

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
        
        // Note that if the entry doesn't exist, this still works because [_activeFilePaths[path] integerValue] evaluates to 0
        // when _activeFilePaths[path] is nil
        NSInteger adjustedValue = [_activeFilePaths[path] integerValue] + 1;
        //[EX2ANGLogger log:@"EX2FileDecryptor: incremented \"%@\" (%li)", path, (long)adjustedValue];
        _activeFilePaths[path] = @(adjustedValue);
        
        //[EX2ANGLogger log:@"_activeFilePaths: %@", _activeFilePaths];
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
            //[EX2ANGLogger log:@"EX2FileDecryptor: removing \"%@\" (%li)", path, (long)adjustedValue];
        }
        else
        {
            _activeFilePaths[path] = @(adjustedValue);
            //[EX2ANGLogger log:@"EX2FileDecryptor: decremented \"%@\" (%li)", path, (long)adjustedValue];
        }
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

- (unsigned long long)offsetInFile
{
    return self.fileHandle.offsetInFile;
}

- (id)initWithChunkSize:(NSUInteger)theChunkSize
{
	if ((self = [super init]))
	{
		_chunkSize = theChunkSize;
        
		_tempDecryptBuffer = [[EX2RingBuffer alloc] initWithBufferLength:BytesFromKiB(75)];
        _tempDecryptBuffer.maximumLength = BytesFromKiB(200);
        
		_decryptedBuffer = [[EX2RingBuffer alloc] initWithBufferLength:BytesFromKiB(75)];
        _decryptedBuffer.maximumLength = BytesFromKiB(200);
	}
	return self;
}

- (id)initWithPath:(NSString *)aPath chunkSize:(NSUInteger)theChunkSize key:(NSString *)theKey alternateKeys:(NSArray *)alternateKeys
{
	if ((self = [self initWithChunkSize:theChunkSize]))
	{
		_key = [theKey copy];
		_path = [aPath copy];
		_fileHandle = [NSFileHandle fileHandleForReadingAtPath:aPath];
        _alternateKeys = [alternateKeys copy];
        
        [EX2FileDecryptor registerOpenFilePath:_path];
	}
	return self;
}

- (id)initWithPath:(NSString *)aPath chunkSize:(NSUInteger)theChunkSize key:(NSString *)theKey
{
    return [self initWithPath:aPath chunkSize:theChunkSize key:theKey alternateKeys:nil];
}

- (void)dealloc
{
    // Make sure the file handle is closed and recorded
    [self closeFile];
}

- (BOOL)seekToOffset:(NSUInteger)offset
{
	BOOL success = NO;
	
	NSUInteger padding = ((int)(offset / self.chunkSize) * self.encryptedChunkPadding); // Calculate the encryption padding
	NSUInteger mod = (offset + padding) % self.encryptedChunkSize;
	NSUInteger realOffset = (offset + padding) - mod; // only seek in increments of the encryption blocks
    
    // Check if this much of the file even exists
    if (self.encryptedFileSizeOnDisk >= realOffset + mod)
    {
        self.seekOffset = mod;
        
        //[EX2ANGLogger log:@"[EX2FileDecryptor] offset: %lu  padding: %lu  realOffset: %lu  mod: %lu:  for path: %@", (unsigned long)offset, (unsigned long)padding, (unsigned long)realOffset, (unsigned long)mod, self.path];
        
        @try 
        {
            [self.fileHandle seekToFileOffset:realOffset];
            success = YES;
        } 
        @catch (NSException *exception) 
        {
            //[EX2ANGLogger logError:@"[EX2FileDecryptor] exception seeking to offset %lu, %@ for path: %@", (unsigned long)offset, exception, self.path];
        }
        
        if (success)
        {
            [self.tempDecryptBuffer reset];
            [self.decryptedBuffer reset];
        }
    }
	
	return success;
}

- (NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length
{
    NSUInteger offset = 0;
    while (offset < length) {
        NSUInteger lengthToRead = MIN(length-offset, BytesFromKB(100));
        NSUInteger amountRead = [self _readBytes:buffer+offset length:lengthToRead];
        if (amountRead == 0) {
            break;
        }
        offset += amountRead;
    }
    return offset;
}

- (NSUInteger)_readBytes:(void *)buffer length:(NSUInteger)length
{
	if (self.decryptedBuffer.filledSpaceLength < length)
	{
		NSUInteger encryptedChunkSize = self.encryptedChunkSize;
		
		//[EX2ANGLogger log:@"[EX2FileDecryptor] asked to read length: %lu for path: %@", (unsigned long)length, self.path];
		// Round up the read to the next block
		//length = self.decryptedBuffer.filledSpaceLength - length;
		NSUInteger realLength = self.seekOffset + length;
		
		if (((self.chunkSize - self.seekOffset) + (length / self.chunkSize)) < length)
		{
			// We need to read an extra chunk
			realLength += self.encryptedChunkSize;
		}
		
		//[EX2ANGLogger log:@"[EX2FileDecryptor] seek offset %lu  realLength %lu for path: %@", (unsigned long)self.seekOffset, (unsigned long)realLength, self.path];
		NSUInteger mod = realLength % encryptedChunkSize;
		if (mod > self.chunkSize)
		{
			realLength += encryptedChunkSize;
			mod -= self.chunkSize;
		}
		
		//[EX2ANGLogger log:@"[EX2FileDecryptor] mod %lu for path: %@", (unsigned long)mod, self.path];
		//if (mod != 0)
		if (realLength % encryptedChunkSize != 0)
		{
			// pad to the next block
			//realLength += ENCR_CHUNK_SIZE - mod; 
			realLength = ((int)(realLength / encryptedChunkSize) * encryptedChunkSize) + encryptedChunkSize;
		}
		//[EX2ANGLogger log:@"[EX2FileDecryptor] reading length: %lu for path: %@", (unsigned long)realLength, self.path];
		
		//[EX2ANGLogger log:@"[EX2FileDecryptor] file offset: %llu for path: %@", self.fileHandle.offsetInFile, self.path];
		
		// We need to decrypt some more data
		[self.tempDecryptBuffer reset];
		NSData *readData;
		@try {
			readData = [self.fileHandle readDataOfLength:realLength];
		} @catch (NSException *exception) {
			readData = nil;
		}
		//[EX2ANGLogger log:@"[EX2FileDecryptor] read data length %lu for path: %@", (unsigned long)readData.length, self.path];
		
		if (readData)
		{
			//[EX2ANGLogger log:@"[EX2FileDecryptor] filling temp buffer with data for path: %@", self.path];
			[self.tempDecryptBuffer fillWithData:readData];
			//[EX2ANGLogger log:@"[EX2FileDecryptor] temp buffer filled size %lu for path: %@", (unsigned long)self.tempDecryptBuffer.filledSpaceLength, self.path];
		}
		
		while (self.tempDecryptBuffer.filledSpaceLength > 0)
		{
			//[EX2ANGLogger log:@"[EX2FileDecryptor] draining data for path: %@", self.path];
			NSData *data = [self.tempDecryptBuffer drainData:encryptedChunkSize];
			//[EX2ANGLogger log:@"[EX2FileDecryptor] data drained, filled size %lu for path: %@", (unsigned long)self.tempDecryptBuffer.filledSpaceLength, self.path];
            
            //[EX2ANGLogger log:@"[EX2FileDecryptor] decrypting data for path: %@", self.path];
			NSError *decryptionError;
            NSData *decrypted;
            if (!self.useOldDecryptor)
            {
                decrypted = [RNDecryptor decryptData:data withPassword:_key error:&decryptionError];
                //[EX2ANGLogger log:@"[EX2FileDecryptor] data size: %lu  decrypted size: %lu for path: %@", (unsigned long)data.length, (unsigned long)decrypted.length, self.path];
            }
            
            if (decryptionError && _alternateKeys)
			{
                if (decryptionError)
                {
                    _error = decryptionError;
                    //[EX2ANGLogger logError:@"[EX2FileDecryptor] There was an error decrypting this chunk using new decryptor, trying the alternate keys: %@ for path: %@", decryptionError, self.path];
                }
                
                decryptionError = nil;
                for (NSString *alternate in _alternateKeys)
                {
                    decrypted = [RNDecryptor decryptData:data withPassword:alternate error:&decryptionError];
                    //[EX2ANGLogger log:@"[EX2FileDecryptor] data size: %lu  decrypted size: %lu for path: %@", (unsigned long)data.length, (unsigned long)decrypted.length, self.path];
                    if (decryptionError)
                    {
                        //[EX2ANGLogger logError:@"[EX2FileDecryptor] There was an error decrypting this chunk using an alternate key: %@  for path: %@", decryptionError, self.path];
                    }
                    else
                    {
                        //[EX2ANGLogger logError:@"[EX2FileDecryptor] The alternate key was successful, storing that as the new key for path: %@", self.path];
                        _key = alternate;
                        _error = nil;
                        break;
                    }
                }
			}
            
			if (decryptionError || self.useOldDecryptor)
			{
                if (decryptionError)
                {
                    _error = decryptionError;
                    //[EX2ANGLogger logError:@"[EX2FileDecryptor] There was an error decrypting this chunk using new decryptor, trying old decryptor: %@ for path: %@", decryptionError, self.path];
                }
                
                decryptionError = nil;
                decrypted = [[RNCryptorOld AES256Cryptor] decryptData:data password:_key error:&decryptionError];
                //[EX2ANGLogger log:@"[EX2FileDecryptor] data size: %lu  decrypted size: %lu for path: %@", (unsigned long)data.length, (unsigned long)decrypted.length, self.path];
                if (decryptionError)
                {
                    //[EX2ANGLogger logError:@"[EX2FileDecryptor] There was an error decrypting this chunk using old decryptor, giving up: %@  for path: %@", decryptionError, self.path];
                }
                else
                {
                    self.useOldDecryptor = YES;
                    _error = nil;
                }
			}
            
			if (!decryptionError)
			{
				// Add the data to the decryption buffer
				if (self.seekOffset > 0)
				{
					//[EX2ANGLogger log:@"[EX2FileDecryptor] seek offset greater than 0 for path: %@", self.path];
					const void *tempBuff = decrypted.bytes;
					//[EX2ANGLogger log:@"[EX2FileDecryptor] filling decrypted buffer length %lu for path: %@", (unsigned long)(self.chunkSize - self.seekOffset), self.path];
					[self.decryptedBuffer fillWithBytes:tempBuff+self.seekOffset length:self.chunkSize-self.seekOffset];
					self.seekOffset = 0;
					//[EX2ANGLogger log:@"[EX2FileDecryptor] setting seekOffset to 0 for path: %@", self.path];
				}
				else
				{
					//[EX2ANGLogger log:@"[EX2FileDecryptor] filling decrypted buffer with data length %lu for path: %@", (unsigned long)decrypted.length, self.path];
					[self.decryptedBuffer fillWithData:decrypted];
					//[EX2ANGLogger log:@"[EX2FileDecryptor] filled decrypted buffer for path: %@", self.path];
				}
			}
		}
	}
	
	// See if there's enough data in the decrypted buffer
	NSUInteger bytesRead = self.decryptedBuffer.filledSpaceLength >= length ? length : self.decryptedBuffer.filledSpaceLength;
	if (bytesRead > 0)
	{
		//[EX2ANGLogger log:@"[EX2FileDecryptor] draining bytes into buffer length %lu for path: %@", (unsigned long)bytesRead, self.path];
		[self.decryptedBuffer drainBytes:buffer length:bytesRead];
		//[EX2ANGLogger log:@"[EX2FileDecryptor] bytes drained for path: %@", self.path];
	}
    else
    {
        //[EX2ANGLogger log:@"[EX2FileDecryptor] bytes read was 0 so not draining anything for path: %@", self.path];
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
	//[EX2ANGLogger log:@"[EX2FileDecryptor] read bytes length %lu for path: %@", (unsigned long)realLength, self.path];
	return returnData;
}

- (void)closeFile
{
    //[EX2ANGLogger log:@"[EX2FileDecryptor] closing file for path: %@", self.path];
    
    if (self.fileHandle)
    {
        [self.tempDecryptBuffer reset];
        [self.decryptedBuffer reset];
        [self.fileHandle closeFile];
        _fileHandle = nil;
        
        //[EX2ANGLogger log:@"[EX2FileDecryptor] deallocated handle for path: %@", self.path];
    }
    else
    {
        //[EX2ANGLogger log:@"[EX2FileDecryptor] no handle was found for path: %@", self.path];
    }
    
    //[EX2ANGLogger log:@"[EX2FileDecryptor] unregistering path: %@", self.path];
    [EX2FileDecryptor unregisterOpenFilePath:self.path];
}

- (NSUInteger)encryptedChunkPadding
{
	return self.encryptedChunkSize - self.chunkSize;
}

- (NSUInteger)encryptedChunkSize
{
    return [EX2FileDecryptor encryptedChunkSizeForChunkSize:self.chunkSize];
}

+ (NSUInteger)encryptedChunkSizeForChunkSize:(NSUInteger)chunkSize
{
    NSUInteger aesPaddedSize = ((chunkSize / 16) + 1) * 16;
    NSUInteger totalPaddedSize = aesPaddedSize + 66; // Add the RNCryptor padding
    return totalPaddedSize;
}

- (unsigned long long)encryptedFileSizeOnDisk
{
    return [EX2FileDecryptor encryptedFileSizeOnDiskForPath:self.path withError:nil];
}

+ (unsigned long long)encryptedFileSizeOnDiskForPath:(NSString *)path withError:(NSError **)error {
    // Just get the size from disk
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:error] fileSize];
}

- (unsigned long long)decryptedFileSizeOnDisk
{
	// Find the encrypted size
	unsigned long long encryptedSize = self.encryptedFileSizeOnDisk;
	
	// Find padding size
	unsigned long long chunkPadding = self.encryptedChunkSize - self.chunkSize;
	unsigned long long numberOfEncryptedChunks = (encryptedSize / self.encryptedChunkSize);
	unsigned long long filePadding = numberOfEncryptedChunks * chunkPadding;
	
    // Calculate padding remainder
    int remainder = encryptedSize % self.encryptedChunkSize;
    if (remainder > 0)
    {
        // There is a partial chunk, so just assume full padding size (sometimes it can be a bit under for some reason, don't know why yet)
        filePadding += chunkPadding;
    }
    
	// Calculate the decrypted size
	unsigned long long decryptedSize = encryptedSize - filePadding;
	
	return decryptedSize;
}

+ (unsigned long long)decryptedFileSizeOnDiskForPath:(NSString *)path
                                           chunkSize:(NSUInteger)chunkSize
                                           withError:(NSError **)error {
    // Find the encrypted size
    unsigned long long encryptedSize = [self encryptedFileSizeOnDiskForPath:path withError:error];
    
    NSUInteger encryptedChunkSize = [self encryptedChunkSizeForChunkSize:chunkSize];
    // Find padding size
    unsigned long long chunkPadding = encryptedChunkSize - chunkSize;
    unsigned long long numberOfEncryptedChunks = (encryptedSize / encryptedChunkSize);
    unsigned long long filePadding = numberOfEncryptedChunks * chunkPadding;
    
    // Calculate padding remainder
    int remainder = encryptedSize % encryptedChunkSize;
    if (remainder > 0)
    {
        // There is a partial chunk, so just assume full padding size (sometimes it can be a bit under for some reason, don't know why yet)
        filePadding += chunkPadding;
    }
    
    // Calculate the decrypted size
    unsigned long long decryptedSize = encryptedSize - filePadding;
    
    return decryptedSize;
}

- (NSData *)getEntireData
{
    NSUInteger maxSongSize = 100*1024*1024;
    NSUInteger totalBytesRead = 0;
    NSMutableData *songData = [[NSMutableData alloc]init];
    char * buffer = malloc(sizeof(char) * 4096);
    do {
        NSUInteger readBytes = [self readBytes:buffer length:4096];
        if (readBytes <= 0) {
            break;
        }
        totalBytesRead += readBytes;
        [songData appendBytes:buffer length:readBytes];
    } while (totalBytesRead < maxSongSize);
    free(buffer);
    
    return songData;
}

@end
