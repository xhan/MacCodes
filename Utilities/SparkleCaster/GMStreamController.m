//
//  CCStreamInfo.m
//  SparkleCaster
//
//  Created by Adam Radestock on 31/10/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "GMStreamController.h"


@implementation GMStreamController

+ (GMStreamController *)newCCStreamInfo; {
	return [[[self alloc] init] autorelease];
}

+ (GMStreamController *)newCCStreamInfoWithReadStream:(CFReadStreamRef)readStreamRef andWriteStream:(CFWriteStreamRef)writeStreamRef; {
	id newMe = [[self alloc] init];
	
	[newMe setWriteStream:writeStreamRef];
	[newMe setReadStream:readStreamRef];
	[newMe setProxyDict:NULL];
	
	return [newMe autorelease];
}

- (id) init {
	self = [super init];
	if (self != nil) {
		fileSize = 0;
		totalBytesWritten = 0;
		leftOverByteCount = 0;
		proxyDict = SCDynamicStoreCopyProxies(NULL);
	}
	return self;
}

- (void) dealloc {
	if ([self readStream])
	{
		CFReadStreamUnscheduleFromRunLoop([self readStream], CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        (void) CFReadStreamSetClient([self readStream], kCFStreamEventNone, NULL, NULL);
        
        /* CFReadStreamClose terminates the stream. */
        CFReadStreamClose([self readStream]);
        CFRelease([self readStream]);
	}
	if ([self writeStream])
	{
		CFWriteStreamUnscheduleFromRunLoop([self writeStream], CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        (void) CFWriteStreamSetClient([self writeStream], kCFStreamEventNone, NULL, NULL);
        
        /* CFWriteStreamClose terminates the stream. */
        CFWriteStreamClose([self writeStream]);
        CFRelease([self writeStream]);
	}
	if (readStreamUsername)
		[readStreamUsername release];
	if (readStreamPassword)
		[readStreamPassword release];
	if (writeStreamUsername)
		[writeStreamUsername release];
	if (writeStreamPassword)
		[writeStreamPassword release];
	[proxyDict release];
	[super dealloc];
}


#pragma mark Accessor Methods

- (CFWriteStreamRef) writeStream {
	return writeStream;
}
- (void) setWriteStream:(CFWriteStreamRef)newWriteStream {
	writeStream = newWriteStream;
}

- (CFReadStreamRef) readStream {
	return readStream;
}
- (void) setReadStream:(CFReadStreamRef)newReadStream {
	readStream = newReadStream;
}

- (NSDictionary) proxyDict {
	return proxyDict;
}
- (void) setProxyDict:(NSDictionary)newProxyDict {
	proxyDict = newProxyDict;
}

- (void) applyProxyDictToStream:(GMStreamType)streamType; {
	BOOL success = NO;
	NSNumber passiveMode;
	BOOL isPassive;
	
	if (proxyDict) {
		
		passiveMode = CFDictionaryGetValue(proxyDict, kSCPropNetProxiesFTPPassive);
		
		if ( (passiveMode != NULL) && (CFGetTypeID(passiveMode) == CFNumberGetTypeID()) ) {
			int         value;
			
			success = CFNumberGetValue(passiveMode, kCFNumberIntType, &value);
			
			if (value) isPassive = kCFBooleanTrue;
			else isPassive = kCFBooleanFalse;
		} else {
			isPassive = kCFBooleanTrue;         // if prefs malformed, we just assume true
		}
		
		if (streamType == GMReadStream) {
			success = CFReadStreamSetProperty([self readStream], kCFStreamPropertyFTPProxy, proxyDict);
			success = CFReadStreamSetProperty([self readStream], kCFStreamPropertyFTPUsePassiveMode, isPassive);
		} else if (streamType == GMWriteStream) {
			success = CFWriteStreamSetProperty([self writeStream], kCFStreamPropertyFTPProxy, proxyDict);
			success = CFWriteStreamSetProperty([self writeStream], kCFStreamPropertyFTPUsePassiveMode, isPassive);
		}
	}
}

- (NSString	*) usernameForStream:(GMStreamType)streamType;{
	
	NSString *username = [NSString string];
	
	if (streamType == GMReadStream)
		username = readStreamUsername;
	else if (streamType == GMWriteStream)
		username = writeStreamUsername;
	
	return username;
}

- (void) setUsername:(NSString *)newUsername forStream:(GMStreamType)streamType; {
	
	BOOL success = NO;
	
	if (streamType == GMReadStream) {
		if (readStreamUsername != newUsername) {
			[readStreamUsername release];
			readStreamUsername = [newUsername copy];
			success = CFReadStreamSetProperty([self readStream], kCFStreamPropertyFTPUserName, readStreamUsername);
		}
	} else if (streamType == GMWriteStream) {
		if (writeStreamUsername != newUsername) {
			[writeStreamUsername release];
			writeStreamUsername = [newUsername copy];
			success = CFWriteStreamSetProperty([self writeStream], kCFStreamPropertyFTPUserName, writeStreamUsername);
		}
	}
	
	if (!success) {
		// could not set username; present error to user.
	}
}

- (NSString	*) passwordForStream:(GMStreamType)streamType; {
	
	NSString *password = [NSString string];
	
	if (streamType == GMReadStream)
		password = readStreamPassword;
	else if (streamType == GMWriteStream)
		password = writeStreamPassword;
	
	return password;
	
}
- (void) setPassword:(NSString *)newPassword forStream:(GMStreamType)streamType; {
	BOOL success = NO;
	
	if (streamType == GMReadStream) {
		if (readStreamPassword != newPassword) {
			[readStreamPassword release];
			readStreamPassword = [newPassword copy];
			success = CFReadStreamSetProperty([self readStream], kCFStreamPropertyFTPPassword, readStreamPassword);
		}
	} else if (streamType == GMWriteStream) {
		if (writeStreamPassword != newPassword) {
			[writeStreamPassword release];
			writeStreamPassword = [newPassword copy];
			success = CFWriteStreamSetProperty([self writeStream], kCFStreamPropertyFTPPassword, writeStreamPassword);
		}
	}
	
	if (!success) {
		// could not set password; present error to user.
	}
}

- (SInt64) fileSize {
	return fileSize;
}
- (void) setFileSize:(SInt64)newFileSize {
	fileSize = newFileSize;
}

- (UInt32) totalBytesWritten {
	return totalBytesWritten;
}
- (void) setTotalBytesWritten:(UInt32)newTotalBytesWritten {
	totalBytesWritten = newTotalBytesWritten;
}

- (UInt32) leftOverByteCount {
	return leftOverByteCount;
}
- (void) setLeftOverByteCount:(UInt32)newLeftOverByteCount {
	leftOverByteCount = newLeftOverByteCount;
}

- (UInt8) buffer {
	return buffer;
}
- (void) setBuffer:(UInt8)newBuffer {
	buffer = newBuffer;
}

@end
