/*
 Copyright (c) 2001, Blackhole Media
 Copyright (c) 2007, Peter Hosey and Colin Barrett
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list
 of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 * Neither the name of Blackhole Media nor the names of its contributors may be
 used to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANYWAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE. 
 
 ---
 
 English non-authoritative interpretation of the license:
 
 This is pretty much the BSD license. This means you can take the source and do
 whatever you please with it. While it is not a requirement of the license, we
 would appreciate a mention in the credits of your application if you use our
 source.
*/
/*
 Intel compatibility by Peter Hosey <http://boredzo.org/> and Colin Barrett <timber@lava.net>. These changes are provided with the following license (also a BSD-style license):

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Peter Hosey, nor the name of Colin Barrett, nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <Carbon/Carbon.h>
#include "pxmLib.h"

#include <string.h>

#if defined(__BIG_ENDIAN__)
#	define BCOPY_OR_SWAB bcopy
#elif  defined(__LITTLE_ENDIAN__)
#	define BCOPY_OR_SWAB swab
#else
#	error You don't have a CPU in your computer!
#endif

static UInt32	_HardMaskSize( pxmRef inRef );
static UInt32	_PixelDataSize( pxmRef inRef );

static bool		_IsBlack( UInt32 inColor );
static UInt8	_MakeGray( UInt32 inColor );
static UInt16	_SetBit16( UInt16 data, UInt16 index, bool newState );
static bool		_GetBit16( UInt16 data, UInt16 index );
static CTabPtr	_DefaultCLUT();

pxmRef
pxmCreate( void* data, UInt32 inSize )
{
	pxmRef	newPxmRef;
	
	if( data == NULL || inSize == 0 )
		return NULL;
	
	newPxmRef = malloc(inSize);
	if( newPxmRef == NULL )
		return NULL;

	//If the low byte of the version is clear, then we expect that the version number is in the high byte—that is, that we must byte-swap the header.
	Boolean byteSwappingNeeded = !(((struct pxmData *)data)->version & 0xFF);
	if(byteSwappingNeeded) {
		//Copy the header with byte-swapping.
		swab(data, newPxmRef, sizeof(struct pxmData));
		//Copy the pixels without byte-swapping.
		bcopy(data + sizeof(struct pxmData), ((void *)newPxmRef) + sizeof(struct pxmData), inSize - sizeof(struct pxmData));
	} else {
		//No swap needed. Do a plain old copy.
		bcopy(data, newPxmRef, inSize);
	}
	
	if( newPxmRef->pixelType == pxmTypeIndexed || ( newPxmRef->pixelType == pxmTypeDefault && newPxmRef->pixelSize == 8 ) )
		newPxmRef->clutAddr = _DefaultCLUT();
	
	return newPxmRef;
}

pxmErr
pxmDispose( pxmRef inRef )
{
	if( inRef == NULL )
		return pxmErrBadParams;
	
	if( inRef->clutAddr != _DefaultCLUT() )
		DisposePtr( (Ptr)inRef->clutAddr );
	
	free(inRef);
	return pxmErrNone;
}

pxmErr
pxmRead( pxmRef inRef, void* ioBuffer, UInt32* ioSize )
{
	if( inRef == NULL || ioBuffer == NULL || ioSize == 0 )
		return pxmErrBadParams;
	
	if( *ioSize > pxmSize(inRef) )
		*ioSize = pxmSize(inRef);
	
	//Copy the header (with byte-swapping, if appropriate).
	BCOPY_OR_SWAB(inRef, ioBuffer, sizeof(struct pxmData));
	//Copy the pixels (without byte-swapping).
	bcopy(inRef, ioBuffer + sizeof(struct pxmData), *ioSize - sizeof(struct pxmData));

	return pxmErrNone;
}

#pragma mark -

UInt32
pxmSize( pxmRef inRef )
{
	return pxmDataSize + _HardMaskSize(inRef) + _PixelDataSize(inRef);
}

pxmErr
pxmBounds( pxmRef inRef, Rect* outRect )
{
	if( inRef == NULL || outRect == NULL )
		return pxmErrBadParams;
	
	*outRect = inRef->bounds;
	return pxmErrNone;
}

bool
pxmHasAlpha( pxmRef inRef )
{
	if( inRef )
		return inRef->bitfield.bits.hasAlpha;
	return NULL;
}

UInt16
pxmPixelSize( pxmRef inRef )
{
	if( inRef )
		return inRef->pixelSize;
	return 0;
}

UInt16
pxmPixelType( pxmRef inRef )
{
	if( inRef )
		return inRef->pixelType;
	return 0;
}

UInt16
pxmImageCount( pxmRef inRef )
{
	if( inRef )
		return inRef->imageCount;
	return 0;
}

bool
pxmIsMultiMask( pxmRef inRef )
{
	if( inRef )
		return !(inRef->bitfield.bits.singleMask);
	return false;
}

void*
pxmBaseAddressForFrame( pxmRef inRef, UInt32 imageIndex )
{
	char*	out = (char*)inRef;
	
	out += pxmDataSize;
	out += _HardMaskSize(inRef);
	out += inRef->bounds.right * inRef->bounds.bottom * ( inRef->pixelSize / 8 ) * imageIndex;
	
	return out;
}

#pragma mark -

UInt32
_HardMaskSize( pxmRef inRef )
{
	UInt32		out;
	UInt32		a;
	UInt32		b;

	//Divide width by 8, rounded up. This converts from bits-per-row (for the mask is a 1-bit-per-pixel image) to bytes-per-row.
	a = inRef->bounds.right / 16;
	b = ((inRef->bounds.right % 16) != 0);

	size_t bytesPerRow = (a + b) * 2;
	
	//Add (height) rows' worth of bytes to our skip distance. For example, if the image's height is four pixels, set our output to 4 * bytesPerRow.
	out = bytesPerRow * (inRef->bounds.bottom - inRef->bounds.top);

	//Now, do we have only one mask up front? If so, then multiply by 1. If not, multiply by the number of images.
	a = inRef->bitfield.bits.singleMask ? 1 : inRef->imageCount;
	out = out * a;
	
	return out;
}

UInt32
_PixelDataSize( pxmRef inRef )
{
	return inRef->bounds.right * inRef->bounds.bottom * (inRef->pixelSize/8) * inRef->imageCount;
}


#pragma mark -

bool
_IsBlack( UInt32 inColor )
{
//	return average(red,green,blue) < 50% gray
	return ( (inColor & 0x000000FF) + ((inColor & 0x0000FF00) >> 8) + ((inColor & 0x00FF0000) >> 16) < (128*3) );
}

UInt8
_MakeGray( UInt32 inColor )
{
	return	((inColor & 0x000000FF) +
			((inColor & 0x0000FF00) >> 8) +
			((inColor & 0x00FF0000) >> 16) ) / 3;
}

static	UInt16	mask[16] = {	0x8000, 0x4000, 0x2000, 0x1000,
								0x0800, 0x0400, 0x0200, 0x0100,
								0x0080, 0x0040, 0x0020, 0x0010,
								0x0008, 0x0004, 0x0002, 0x0001 };

UInt16
_SetBit16( UInt16 data, UInt16 index, bool newState )
{
	if( newState == true )
		return data | mask[index];
	else
		return (data | mask[index]) ^ mask[index];
}

bool
_GetBit16( UInt16 data, UInt16 index )
{
	return data & mask[index];
}

CTabPtr
_DefaultCLUT()
{
	return NULL;
}
