//
//  EX2RingBuffer.m
//  EX2Kit
//
//  Created by Ben Baron on 6/27/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "EX2RingBuffer.h"

@implementation EX2RingBuffer
@synthesize buffer, readPosition, writePosition, freeSpaceLength, filledSpaceLength;

- (id)initWithBufferLength:(NSUInteger)bytes
{
	if ((self = [super init]))
	{
		bufferBackingStore = malloc(sizeof(char) * bytes);
		buffer = [NSData dataWithBytesNoCopy:bufferBackingStore length:bytes freeWhenDone:YES];
		[self reset];
	}
	return self;
}

+ (id)ringBufferWithLength:(NSUInteger)bytes
{
	return [[EX2RingBuffer alloc] initWithBufferLength:bytes];
}

- (void)reset
{
	memset(bufferBackingStore, 0, self.totalLength);
	self.readPosition = 0;
	self.writePosition = 0;
}

- (NSUInteger)totalLength
{
	return self.buffer.length;
}

- (NSUInteger)freeSpaceLength
{
	@synchronized(self)
	{
		return self.totalLength - self.filledSpaceLength;
	}
}

- (NSUInteger)filledSpaceLength
{
	@synchronized(self)
	{
		if (self.readPosition <= self.writePosition)
		{
			return self.writePosition - self.readPosition;
		}
		else
		{
			// The write position has looped around
			return self.totalLength - self.readPosition + self.writePosition;
		}
	}
}

- (void)advanceWritePosition:(NSUInteger)writeLength
{
	@synchronized(self)
	{
		//NSUInteger oldWritePosition = self.writePosition;
		
		self.writePosition += writeLength;
		if (self.writePosition >= self.totalLength)
		{
			self.writePosition = self.writePosition - self.totalLength;
		}
		
		//DLog(@"writeLength: %i old writePosition: %i  new writePosition: %i", writeLength, oldWritePosition, self.writePosition);
	}
}

- (void)advanceReadPosition:(NSUInteger)readLength
{
	@synchronized(self)
	{
		//NSUInteger oldReadPosition = self.readPosition;
		
		self.readPosition += readLength;
		if (self.readPosition >= self.totalLength)
		{
			self.readPosition = self.readPosition - self.totalLength;
		}
		//DLog(@"readLength: %i old readPosition:%i  new readPosition: %i", readLength, oldReadPosition, self.readPosition);
	}
}

- (BOOL)fillWithBytes:(const void *)byteBuffer length:(NSUInteger)bufferLength
{	
	@synchronized(self)
	{
		// Make sure there is space
		if (self.freeSpaceLength > bufferLength)
		{
			NSUInteger bytesUntilEnd = self.totalLength - self.writePosition;
			if (bufferLength > bytesUntilEnd)
			{
				// Split it between the end and beginning
				memcpy(bufferBackingStore + self.writePosition, byteBuffer, bytesUntilEnd);
				memcpy(bufferBackingStore, byteBuffer + bytesUntilEnd, bufferLength - bytesUntilEnd);
			}
			else
			{
				// Just copy in the bytes
				memcpy(bufferBackingStore + self.writePosition, byteBuffer, bufferLength);
			}
			
			//DLog(@"filled %i bytes, free: %i, filled: %i, writPos: %i, readPos: %i", bufferLength, self.freeSpaceLength, self.filledSpaceLength, self.writePosition, self.readPosition);
			
			[self advanceWritePosition:bufferLength];
			
			return YES;
		}
		return NO;
	}
}

- (BOOL)fillWithData:(NSData *)data
{
	return [self fillWithBytes:data.bytes length:data.length];
}

- (NSUInteger)drainBytes:(void *)byteBuffer length:(NSUInteger)bufferLength
{
	@synchronized(self)
	{
		bufferLength = self.filledSpaceLength >= bufferLength ? bufferLength : self.filledSpaceLength;
		
		if (bufferLength > 0) 
		{
			NSUInteger bytesUntilEnd = self.totalLength - self.readPosition;
			if (bufferLength > bytesUntilEnd)
			{
				// Split it between the end and beginning
				memcpy(byteBuffer, bufferBackingStore + self.readPosition, bytesUntilEnd);
				memcpy(byteBuffer + bytesUntilEnd, bufferBackingStore, bufferLength - bytesUntilEnd);
			}
			else
			{
				// Just copy in the bytes
				memcpy(byteBuffer, bufferBackingStore + self.readPosition, bufferLength);
			}
			
			//DLog(@"read %i bytes, free: %i, filled: %i, writPos: %i, readPos: %i", bufferLength, self.freeSpaceLength, self.filledSpaceLength, self.writePosition, self.readPosition);
			
			[self advanceReadPosition:bufferLength];		
		}
		return bufferLength;
	}
}

- (NSData *)drainData:(NSUInteger)readLength
{
	void *byteBuffer = malloc(sizeof(char) * readLength);
	readLength = [self drainBytes:byteBuffer length:readLength];
	if (readLength > 0)
	{
		return [NSData dataWithBytesNoCopy:byteBuffer length:readLength freeWhenDone:YES];
	}
	else
	{
		free(byteBuffer);
		return nil;
	}
}

- (BOOL)hasSpace:(NSUInteger)length
{
	return self.freeSpaceLength >= length;
}

@end
