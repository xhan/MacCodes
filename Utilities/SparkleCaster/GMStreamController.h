//
//  CCStreamInfo.h
//  SparkleCaster
//
//  Created by Adam Radestock on 31/10/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/* When using file streams, the 32KB buffer is probably not enough.
 A good way to establish a buffer size is to increase it over time.
 If every read consumes the entire buffer, start increasing the buffer
 size, and at some point you would then cap it. 32KB is fine for network
 sockets, although using the technique described above is still a good idea.
 This sample avoids the technique because of the added complexity it
 would introduce. */
#define kMyBufferSize  32768

static const CFOptionFlags kNetworkEvents = 
kCFStreamEventOpenCompleted
| kCFStreamEventHasBytesAvailable
| kCFStreamEventEndEncountered
| kCFStreamEventCanAcceptBytes
| kCFStreamEventErrorOccurred;

typedef enum
{
	GMReadStream,
	GMWriteStream,
} GMStreamType;

@interface GMStreamController : NSObject {
	
	// Instance Variables
	CFWriteStreamRef		writeStream;		// download (destination file stream) and upload (FTP stream) only
	CFReadStreamRef			readStream;			// download (FTP stream), upload (source file stream), directory list (FTP stream)
	NSDictionary			proxyDict;
	SInt64					fileSize;
    UInt32					totalBytesWritten;
    UInt32					leftOverByteCount;
    UInt8					buffer[kMyBufferSize];    // buffer to hold left over bytes
	NSString				*readStreamUsername;
	NSString				*readStreamPassword;
	NSString				*writeStreamPassword;
	NSString				*writeStreamUsername;
	
}

+ (GMStreamController *)newCCStreamInfo;
+ (GMStreamController *)newCCStreamInfoWithReadStream:(CFReadStreamRef)readStreamRef andWriteStream:(CFWriteStreamRef)writeStreamRef;

- (CFWriteStreamRef) writeStream;
- (void) setWriteStream:(CFWriteStreamRef)newWriteStream;

- (CFReadStreamRef) readStream;
- (void) setReadStream:(CFReadStreamRef)newReadStream;

- (NSDictionary) proxyDict;
- (void) setProxyDict:(NSDictionary)newProxyDict;
- (void) applyProxyDictToStream:(GMStreamType)streamType;

- (NSString	*) usernameForStream:(GMStreamType)streamType;
- (void) setUsername:(NSString *)newUsername forStream:(GMStreamType)streamType;

- (NSString	*) passwordForStream:(GMStreamType)streamType;
- (void) setPassword:(NSString *)newPassword forStream:(GMStreamType)streamType;

- (SInt64) fileSize;
- (void) setFileSize:(SInt64)newFileSize;

- (UInt32) totalBytesWritten;
- (void) setTotalBytesWritten:(UInt32)newTotalBytesWritten;

- (UInt32) leftOverByteCount;
- (void) setLeftOverByteCount:(UInt32)newLeftOverByteCount;

- (UInt8) buffer;
- (void) setBuffer:(UInt8)newBuffer;

@end
