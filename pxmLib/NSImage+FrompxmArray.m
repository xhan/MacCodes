/*
 Copyright (c) 2007, Peter Hosey and Colin Barrett
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Peter Hosey, nor the name of Colin Barrett, nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <machine/endian.h>
#import "NSImage+FrompxmArray.h"

union pxmDataBitfield {
	struct {
#if defined(__BIG_ENDIAN__)
		UInt16			__empty:11,
				chaos:1,
				mystery:1,
				hasAlpha:1,
				__unknown1:1,
				maskCount:1;
#elif defined(__LITTLE_ENDIAN__)
#warning Using little-endian layout
		UInt16
				maskCount:1,
				__unknown1:1,
				hasAlpha:1,
				mystery:1,
				chaos:1,
				__empty:11;
#else
#	error You don't have a CPU in your computer!
#endif //def __BIG_ENDIAN__ or __LITTLE_ENDIAN__
	} bits;
	UInt16 number;
};

#if defined(__BIG_ENDIAN__)
#	define BCOPY_OR_SWAB bcopy
#elif defined(__LITTLE_ENDIAN__)
#	define BCOPY_OR_SWAB swab
#endif

static UInt32
_HardMaskSize( pxmRef inRef );
static void*
_GetPixelDataLoc( pxmRef inRef, UInt32 imageIndex );

@implementation NSImage (CBPRHFrompxmArray)

+ (NSImage *)imageFrompxmArrayData:(NSData *)data {
	NSLog(@"Creating NSImage from pxm# data that is %u bytes long (structure type: %u bytes long)", [data length], sizeof(struct pxmData));
	const struct pxmData *pxmBytes = [data bytes];

	//We don't need the right version, which is a good thing because the version is wrong…
	//NSAssert1(ntohs(pxmBytes->version) == pxmVersionOSX, @"Incorrect pxm# version: %hi", ntohs(pxmBytes->version));
	NSLog(@"Version of pxm#: %hu", ntohs(pxmBytes->version));
	NSAssert1(ntohs(pxmBytes->pixelType) == pxmTypeDirect16 || ntohs(pxmBytes->pixelType) == pxmTypeDirect32, @"Incorrect pxm# pixel-type: %hi", ntohs(pxmBytes->pixelType));

	Rect bounds;
	BCOPY_OR_SWAB(&(pxmBytes->bounds), &bounds, sizeof(bounds));
	NSSize size = {
		.width  = bounds.right - bounds.left,
		//QuickDraw Rects are oriented from the top-left, not bottom-left, so bottom is the greater number.
		.height = bounds.bottom - bounds.top
	};

	NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];

	union pxmDataBitfield bitfield = { .number = ntohs(pxmBytes->bitfield.number) };
//	BCOPY_OR_SWAB(((void *)pxmBytes) + sizeof(pxmBytes->version), &bitfield.number, sizeof(UInt16));
	NSLog(@"bitfield number: %hx; maskCount: %hu; imageCount: %hu", bitfield.number, bitfield.bits.maskCount, ntohs(pxmBytes->imageCount));
	
	size_t bitsPerPixel = ntohs(pxmBytes->pixelSize);
	size_t bytesPerPixel = bitsPerPixel / 8U;

	size_t bytesPerRow = size.width * bytesPerPixel;
	size_t bytesPerFrame = bytesPerRow * size.height;
	NSLog(@"Size of structure %u + first frame %u: %u", sizeof(struct pxmData), bytesPerFrame, sizeof(struct pxmData) + bytesPerFrame);

	size_t samplesPerPixel = bitfield.bits.hasAlpha ? 4U : 3U;

	NSLog(@"wah: %f by %f; bps: 8; spp: %u; has alpha: %u; planar: no; bytes per row: %u; bitsPerPixel: %u", size.width, size.height, samplesPerPixel, (unsigned)bitfield.bits.hasAlpha, bytesPerRow, bitsPerPixel);

	void *dataStart = pxmBytes->data + bytesPerRow * 12U;

	unsigned numFrames = ntohs(pxmBytes->imageCount);
	NSMutableArray *reps = [NSMutableArray arrayWithCapacity:numFrames];
	for(unsigned i = 0U; i < numFrames; ++i) {
		unsigned char *planes[1] = { (unsigned char *)_GetPixelDataLoc(pxmBytes, i)/*(dataStart + (bytesPerFrame * i))*/ };
		NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
			initWithBitmapDataPlanes:planes
			pixelsWide:size.width
			pixelsHigh:size.height
			bitsPerSample:8U
			samplesPerPixel:samplesPerPixel
			hasAlpha:bitfield.bits.hasAlpha
			isPlanar:NO
			colorSpaceName:NSDeviceRGBColorSpace
			bytesPerRow:bytesPerRow
			bitsPerPixel:bitsPerPixel];

		/*
		[bitmapRep getBitmapDataPlanes:planes];
		uint32_t *src = (uint32_t *)_GetPixelDataLoc(pxmBytes, i)/*(dataStart + (bytesPerFrame * i))  * /  ;
		uint32_t *dst = (uint32_t *)planes[0];
		for(unsigned i = 0, num = bytesPerFrame / bytesPerPixel; i < num; ++i) {
//				dst[i] = CFSwapInt32BigToHost(src[i]);
			dst[i] = src[i];
		}
		*/

		[reps addObject:bitmapRep];
		[bitmapRep release];
	}

	[image addRepresentations:reps];

	return image;
}

@end

#pragma mark Borrowed *cough* from pxmLib

UInt32
_HardMaskSize( pxmRef inRef )
{
	UInt32		out;
	UInt32		a;
	UInt32		b;

	//Divide by 8, rounded up.
	a = ntohs(inRef->bounds.right) / 16;
	b = ((ntohs(inRef->bounds.right) % 16) != 0);

	size_t bytesPerRow = (a + b) * 2;
	
	//Add (height) rows' worth of bytes to our skip distance. For example, if the image's height is four pixels, set our output to 4 * bytesPerRow.
	out = bytesPerRow * (ntohs(inRef->bounds.bottom) - ntohs(inRef->bounds.top));
	union pxmDataBitfield bitfield = { .number = ntohs(inRef->bitfield.number) };

	//Now, do we have a mask up front? If so, then multiply by 1. If not, multiply by the number of images. (???????)
	a = bitfield.bits.maskCount ? 1 : ntohs(inRef->imageCount);
	out = out * a;
	
	return out;
}

void*
_GetPixelDataLoc( pxmRef inRef, UInt32 imageIndex )
{
	char*	out = (char*)inRef;
	
	out += pxmDataSize;
	out += _HardMaskSize(inRef);
//	out += inRef->bounds.right * inRef->bounds.bottom * ( inRef->pixelSize / 8 ) * imageIndex;
	out += ntohs(inRef->bounds.right) * ntohs(inRef->bounds.bottom) * ( 4 ) * imageIndex;
	
	return out;
}
