/*
 Copyright (c) 2007, Peter Hosey and Colin Barrett
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Peter Hosey, nor the name of Colin Barrett, nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>
#import "NSImage+FrompxmArray.h"

int main(int argc, char **argv) {
	if(argc != 2) {
		fprintf(stderr, "Usage: %s res-ID > foo.tiff\n\nAlways searches Extras.rsrc and Extras2.rsrc.", argc > 0 ? argv[0] : "pxm-to-TIFF");
		return EXIT_FAILURE;
	}

	//The pool is *NOT* closed! -CB
	//No lifeguard on duty —PRH
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	OSStatus err;

	short extrasFileHandle;
	FSRef extrasRef;
	FSPathMakeRef(
#if defined(__BIG_ENDIAN__)
		(UInt8 *)"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Resources/Extras.rsrc",
#elif defined(__LITTLE_ENDIAN__)
		(UInt8 *)"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Resources/Extras2.rsrc",
#endif
		&extrasRef, /*isDirectory*/ NULL);
	err = FSOpenResourceFile(
			&extrasRef,
			//A fork name of "" means the data fork.
			/*forkNameLength*/ 0U,
			/*forkName*/ NULL,
			fsRdPerm,
			&extrasFileHandle);
	if(err != noErr) {
		fprintf(stderr, "%s: Could not open resource file Extras.rsrc: %s", argc > 0 ? argv[0] : "pxm-to-TIFF", GetMacOSStatusCommentString(err));
		return EXIT_FAILURE;
	}

	NSImage *image = [NSImage imageFrompxmArrayInSearchPathWithResourceID:strtol(argv[1], NULL, 10)];
	if (!image) {
		fprintf(stderr, "%s: Unable to create image from data\n", argc > 0 ? argv[0] : "pxm-to-TIFF");
		return EXIT_FAILURE;
	}

	//Write it out to disk
	[(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:[image TIFFRepresentation]];

	//Clean up
	CloseResFile(extrasFileHandle);
	[pool release];
	return EXIT_SUCCESS;
}
