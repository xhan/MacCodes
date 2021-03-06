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
	if(argc != 3) {
		fprintf(stderr, "Usage: %s pathname res-ID > foo.tiff\n", argc > 0 ? argv[0] : "pxm-to-TIFF");
		return EXIT_FAILURE;
	}

	//The pool is *NOT* closed! -CB
	//No lifeguard on duty —PRH
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSImage *image = [NSImage imageFrompxmArrayWithResourceID:strtol(argv[2], NULL, 10) inResourceFileAtPath:[NSString stringWithUTF8String:argv[1]]];
	if (!image) {
		fprintf(stderr, "%s: Unable to create image from data\n", argc > 0 ? argv[0] : "pxm-to-TIFF");
		return EXIT_FAILURE;
	}

	//Write it out to disk
	[(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:[image TIFFRepresentation]];

	//Clean up
	[pool release];
	return EXIT_SUCCESS;
}
