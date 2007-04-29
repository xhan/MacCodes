/*
 Copyright (c) 2007, Peter Hosey and Colin Barrett
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Peter Hosey, nor the name of Colin Barrett, nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <Carbon/Carbon.h>
#import "NSImage+FrompxmArray.h"

@implementation NSImage (CBPRHFrompxmArray)

+ (NSImage *)imageFrompxmArrayData:(NSData *)data {
	const struct pxmData *pxmBytes = [data bytes];

	//We currently only know how to deal with direct (RGB/RGBA) pixels. We don't know about indexed pixels yet. That will involve adding clut-handling logic.
	NSAssert1(pxmPixelType(pxmBytes) == pxmTypeDirect16 || pxmPixelType(pxmBytes) == pxmTypeDirect32, @"Incorrect pxm# pixel-type: %hi", pxmPixelType(pxmBytes));

	//Get the bounds by reference, and compute the width and height from them.
	Rect bounds;
	pxmBounds(pxmBytes, &bounds);
	NSSize size = {
		.width  = bounds.right - bounds.left,
		//QuickDraw Rects are oriented from the top-left, not bottom-left, so bottom is the greater number.
		.height = bounds.bottom - bounds.top
	};

	NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];

	//Assemble information needed by NSBitmapImageRep.
	size_t bitsPerPixel = pxmPixelSize(pxmBytes);
	size_t bytesPerPixel = bitsPerPixel / 8U;

	size_t bytesPerRow = size.width * bytesPerPixel;
	size_t bytesPerFrame = bytesPerRow * size.height;

	size_t samplesPerPixel = pxmHasAlpha(pxmBytes) ? 4U : 3U;

    //Iterate through our “frames”
	unsigned numFrames = pxmImageCount(pxmBytes);
	NSMutableArray *reps = [NSMutableArray arrayWithCapacity:numFrames];
	for(unsigned i = 0U; i < numFrames; ++i) {
		//Passing NULL here makes NSBitmapImageRep allocate its own storage…
		NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
			initWithBitmapDataPlanes:NULL
			pixelsWide:size.width
			pixelsHigh:size.height
			bitsPerSample:8U
			samplesPerPixel:samplesPerPixel
			hasAlpha:pxmHasAlpha(pxmBytes)
			isPlanar:NO
			colorSpaceName:NSDeviceRGBColorSpace
			bytesPerRow:bytesPerRow
			bitsPerPixel:bitsPerPixel];

        //…which we copy into here, from the pixels' address within the pxmRef.
		memcpy([bitmapRep bitmapData], pxmBaseAddressForFrame(pxmBytes, i), bytesPerRow * size.height);

		//Add our new Bitmap Image Rep to the array of representations that will be put in the image.
		[reps addObject:bitmapRep];
		[bitmapRep release];
	}

	//Outfit our image with its representations.
	[image addRepresentations:reps];

	return image;
}

+ (NSImage *)imageFrompxmArrayWithResourceID:(short)resID inResourceFileAtPath:(NSString *)path forkName:(struct HFSUniStr255 *)forkName
{
	//First try to convert the path to a FSRef.
	NSURL *URL = [NSURL fileURLWithPath:path];
	FSRef inputFileRef;
	if(!CFURLGetFSRef((CFURLRef)URL, &inputFileRef)) {
		NSLog(@"In +[NSImage imageFrompxmArrayWithResourceID:inResourceFileAtPath:forkName:]: Could not convert NSURL %@ to FSRef", URL);
		return nil;
	} else {
		//Now try to open the file.
		short resFileHandle = -1;
		OSStatus err = FSOpenResourceFile(
			&inputFileRef,
			//A fork name of "" means the data fork.
			/*forkNameLength*/ forkName ? forkName->length : 0U,
			/*forkName*/ forkName ? forkName->unicode : NULL,
			fsRdPerm,
			&resFileHandle);

		if(resFileHandle < 0) {
			if(err != eofErr) {
				NSLog(@"In +[NSImage imageFrompxmArrayWithResourceID:inResourceFileAtPath:forkName:]: Could not open resource file %@ with fork name %@: %s", path, forkName ? [NSString stringWithCharacters:forkName->unicode length:forkName->length] : nil, GetMacOSStatusCommentString(err));
			}
			return nil;
		}

		//Now retrieve the resource from the freshly-opened file.
		Handle pxmH = Get1Resource(FOUR_CHAR_CODE('pxm#'), resID);
		if(!pxmH) {
			err = ResError();
			NSLog(@"In +[NSImage imageFrompxmArrayWithResourceID:inResourceFileAtPath:forkName:]: Could not get 'pxm#' resource with ID %hi from resource file %@: %s\n", resID, path, GetMacOSStatusCommentString(err));
			CloseResFile(resFileHandle);
			return nil;
		}

		//Create a pxmRef from the resource data.
		pxmRef myPxmRef = pxmCreate(*pxmH, GetHandleSize(pxmH));

		//Create the image that we'll return.
		NSImage *image = [self imageFrompxmArrayData:[NSData dataWithBytesNoCopy:myPxmRef length:GetHandleSize(pxmH) freeWhenDone:NO]];

		//Clean up.
		pxmDispose(myPxmRef);
		ReleaseResource(pxmH);
		CloseResFile(resFileHandle);

		return image;
	}
}

+ (NSImage *)imageFrompxmArrayWithResourceID:(short)resID inResourceFileAtPath:(NSString *)path
{
	NSImage *outImage = nil;
	struct HFSUniStr255 forkNameStorage;

	//First try the resource fork.
	FSGetResourceForkName(&forkNameStorage);
	outImage = [self imageFrompxmArrayWithResourceID:resID inResourceFileAtPath:path forkName:&forkNameStorage];

	//If we manage to create a valid image, return it.
	if(outImage) return outImage;

	//Next, try the data fork.
	FSGetDataForkName(&forkNameStorage);
	outImage = [self imageFrompxmArrayWithResourceID:resID inResourceFileAtPath:path forkName:&forkNameStorage];

	//Return whatever we have.
	return outImage;
}

+ (NSImage *)imageFrompxmArrayInSearchPathWithResourceID:(short)resID
{
	//Now retrieve the resource from the freshly-opened file.
	Handle pxmH = GetResource(FOUR_CHAR_CODE('pxm#'), resID);
	if(!pxmH) {
		OSStatus err = ResError();
		NSLog(@"In +[NSImage imageFrompxmArrayInSearchPathWithResourceID:]: Could not get 'pxm#' resource with ID %hi: %s\n", resID, GetMacOSStatusCommentString(err));
		return nil;
	}

	//Create the image that we'll return.
	pxmRef myPxmRef = pxmCreate(*pxmH, GetHandleSize(pxmH));
	NSImage *image = [self imageFrompxmArrayData:[NSData dataWithBytesNoCopy:myPxmRef length:GetHandleSize(pxmH) freeWhenDone:NO]];

	//Clean up.
	pxmDispose(myPxmRef);
	ReleaseResource(pxmH);

	return image;
}

@end
