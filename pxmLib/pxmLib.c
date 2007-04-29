/*
 Copyright (c) 2001, Blackhole Media
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

#include "pxmLib.h"

static UInt32	_HardMaskSize( pxmRef inRef );
static UInt32	_PixelDataSize( pxmRef inRef );
static void*	_GetPixelDataLoc( pxmRef inRef, UInt32 imageIndex );

static pxmErr	_Render32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_Render16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_Render8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_RenderMask32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_RenderMask16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_RenderMask8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_RenderAlpha32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_RenderAlpha16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_RenderAlpha8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );

static pxmErr	_Write32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_Write16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_Write8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_WriteMask32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_WriteMask16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_WriteMask8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_WriteAlpha32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_WriteAlpha16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );
static pxmErr	_WriteAlpha8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS );

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
	
	newPxmRef = (pxmRef)NewPtr(inSize);
	if( newPxmRef == NULL )
		return NULL;
	BlockMoveData( data, newPxmRef, inSize );
	
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
	
	DisposePtr( (Ptr)inRef );
	return pxmErrNone;
}

pxmErr
pxmRead( pxmRef inRef, void* ioBuffer, UInt32* ioSize )
{
	if( inRef == NULL || ioBuffer == NULL || ioSize == 0 )
		return pxmErrBadParams;
	
	if( *ioSize > pxmSize(inRef) )
		*ioSize = pxmSize(inRef);
	
	BlockMoveData( inRef, ioBuffer, *ioSize );
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
		return inRef->hasAlpha;
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
		return inRef->maskCount == pxmMultiMask;
	return false;
}

#pragma mark -

pxmErr
pxmMakeGWorld( pxmRef inRef, GWorldPtr* outGWorld )
{
	OSStatus	status;
	GWorldPtr	newGWorld = NULL;
	
	if( inRef == NULL )
		return pxmErrBadParams;
	
	status = NewGWorld( outGWorld, 32, &inRef->bounds, NULL, NULL, 0 );
	if( status ){ *outGWorld = NULL; return pxmErrMemFull; }
	
	return pxmErrNone;
}

#pragma mark -

pxmErr
pxmRenderImage( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	if( inRef == NULL  || inOS == NULL )
		return pxmErrBadParams;
	
	if( imageIndex >= inRef->imageCount )
		return pxmErrBadIndex;
	
	if( inRef->pixelType == pxmTypeDirect32 )
		return _Render32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeDirect16 )
		return _Render32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeIndexed || ( inRef->pixelType == pxmTypeDefault && inRef->pixelSize == 8 ) )
		return _Render32( inRef, imageIndex, inOS );
	
	return pxmErrBadDepth;
}

pxmErr
pxmRenderMask( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	if( inRef == NULL  || inOS == NULL )
		return pxmErrBadParams;
	
	if( imageIndex >= inRef->imageCount )
		return pxmErrBadIndex;
	
	if( inRef->pixelType == pxmTypeDirect32 )
		return _RenderMask32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeDirect16 )
		return _RenderMask32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeIndexed || ( inRef->pixelType == pxmTypeDefault && inRef->pixelSize == 8 ) )
		return _RenderMask32( inRef, imageIndex, inOS );
	
	return pxmErrBadDepth;
}

pxmErr
pxmRenderAlpha( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	if( inRef == NULL  || inOS == NULL )
		return pxmErrBadParams;
	
	if( imageIndex >= inRef->imageCount )
		return pxmErrBadIndex;
	
	if( inRef->pixelType == pxmTypeDirect32 )
		return _RenderAlpha32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeDirect16 )
		return _RenderAlpha32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeIndexed || ( inRef->pixelType == pxmTypeDefault && inRef->pixelSize == 8 ) )
		return _RenderAlpha32( inRef, imageIndex, inOS );
	
	return pxmErrBadDepth;
}

#pragma mark -

pxmErr
pxmWriteImage( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	if( inRef == NULL  || inOS == NULL )
		return pxmErrBadParams;
	
	if( imageIndex >= inRef->imageCount )
		return pxmErrBadIndex;
	
	// Patch up fucked headers
	inRef->pixelType = pxmTypeDirect32;
	inRef->pixelSize = 32;
	inRef->clutID = 0;
	
	if( inRef->pixelType == pxmTypeDirect32 )
		return _Write32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeDirect16 )
		return _Write16( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeIndexed || ( inRef->pixelType == pxmTypeDefault && inRef->pixelSize == 8 ) )
		return _Write8( inRef, imageIndex, inOS );
	
	return pxmErrBadDepth;
}

pxmErr
pxmWriteMask( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	if( inRef == NULL  || inOS == NULL )
		return pxmErrBadParams;
	
	if( imageIndex >= inRef->imageCount )
		return pxmErrBadIndex;
	
	if( inRef->pixelType == pxmTypeDirect32 )
		return _WriteMask32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeDirect16 )
		return _WriteMask16( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeIndexed || ( inRef->pixelType == pxmTypeDefault && inRef->pixelSize == 8 ) )
		return _WriteMask8( inRef, imageIndex, inOS );
	
	return pxmErrBadDepth;
}

pxmErr
pxmWriteAlpha( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	if( inRef == NULL  || inOS == NULL )
		return pxmErrBadParams;
	
	if( imageIndex >= inRef->imageCount )
		return pxmErrBadIndex;
	
	if( inRef->pixelType == pxmTypeDirect32 )
		return _WriteAlpha32( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeDirect16 )
		return _WriteAlpha16( inRef, imageIndex, inOS );
	
	if( inRef->pixelType == pxmTypeIndexed || ( inRef->pixelType == pxmTypeDefault && inRef->pixelSize == 8 ) )
		return _WriteAlpha8( inRef, imageIndex, inOS );
	
	return pxmErrBadDepth;
}

#pragma mark -

UInt32
_HardMaskSize( pxmRef inRef )
{
	UInt32		out;
	UInt32		a;
	UInt32		b;
	
	a = inRef->bounds.right >> 4;
	b = ((inRef->bounds.right & 0x000F) != 0);
	out = (a + b) * 2;
	
	out = out * inRef->bounds.bottom;
	a = inRef->maskCount ? 1 : (inRef->imageCount);
	out = out * a;
	
	return out;
}

UInt32
_PixelDataSize( pxmRef inRef )
{
	return inRef->bounds.right * inRef->bounds.bottom * (4) * inRef->imageCount;
	return inRef->bounds.right * inRef->bounds.bottom * (inRef->pixelSize/8) * inRef->imageCount;
}

void*
_GetPixelDataLoc( pxmRef inRef, UInt32 imageIndex )
{
	char*	out = (char*)inRef;
	
	out += pxmDataSize;
	out += _HardMaskSize(inRef);
//	out += inRef->bounds.right * inRef->bounds.bottom * ( inRef->pixelSize / 8 ) * imageIndex;
	out += inRef->bounds.right * inRef->bounds.bottom * ( 4 ) * imageIndex;
	
	return out;
}

#pragma mark -

pxmErr
_Render32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt16		dstRB;
	UInt32*		dstBA;
	UInt16		srcRL;
	UInt32*		srcBA;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	dstBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	dstRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	srcBA = (UInt32*)_GetPixelDataLoc( inRef, imageIndex );
	srcRL = inRef->bounds.right;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
			dstBA[j] = srcBA[j] >> 8; // kill alpha
		
		srcBA += srcRL;
		dstBA = (UInt32*)((UInt8*)dstBA + dstRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_Render16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt16		dstRB;
	UInt32*		dstBA;
	UInt16		srcRL;
	UInt32*		srcBA;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	dstBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	dstRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	srcBA = (UInt32*)_GetPixelDataLoc( inRef, imageIndex );
	srcRL = inRef->bounds.right;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
			dstBA[j] =	(srcBA[j] & 0x0000F800) << 8 +
						(srcBA[j] & 0x000007C0) << 5 +
						(srcBA[j] & 0x0000003E) << 2;
		
		srcBA += srcRL;
		dstBA = (UInt32*)((UInt8*)dstBA + dstRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_Render8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	return pxmErrBadDepth;
}

pxmErr
_RenderMask32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt16		dstRB;
	UInt32*		dstBA;
	UInt16		srcRL;
	UInt16*		srcBA;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	dstBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	dstRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	srcBA = (UInt16*)((char*)inRef + pxmDataSize);
	srcRL = (inRef->bounds.right >> 4) + ((inRef->bounds.right & 0x000F) != 0);
	if( inRef->maskCount == pxmMultiMask )
		srcBA += (srcRL*inRef->bounds.bottom)*imageIndex;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
			dstBA[j] = _GetBit16(srcBA[j/16], j%16) ? 0x00000000 : 0x00FFFFFF;
		
		srcBA += srcRL;
		dstBA = (UInt32*)((Ptr)dstBA + dstRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_RenderMask16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt16		dstRB;
	UInt16*		dstBA;
	UInt16		srcRL;
	UInt16*		srcBA;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	dstBA = (UInt16*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	dstRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	srcBA = (UInt16*)((char*)inRef + pxmDataSize);
	srcRL = (inRef->bounds.right >> 4) + ((inRef->bounds.right & 0x000F) != 0);
	if( inRef->maskCount == pxmMultiMask )
		srcBA += (srcRL*inRef->bounds.bottom)*imageIndex;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
			dstBA[j] = _GetBit16(srcBA[j], j%16) ? 0x0000 : 0xFFFE;
		
		srcBA += srcRL;
		dstBA = (UInt16*)((Ptr)dstBA + dstRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_RenderMask8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{return pxmErrBadDepth;}

pxmErr
_RenderAlpha32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt16		dstRB;
	UInt32*		dstBA;
	UInt16		srcRL;
	UInt32*		srcBA;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	dstBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	dstRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	srcBA = (UInt32*)_GetPixelDataLoc( inRef, imageIndex );
	srcRL = inRef->bounds.right;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
			dstBA[j] =  (srcBA[j] & 0x000000FF) +
						((srcBA[j] & 0x000000FF) << 8) +
						((srcBA[j] & 0x000000FF) << 16);
		
		srcBA = srcBA + srcRL;
		dstBA = (UInt32*)((Ptr)dstBA + dstRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_RenderAlpha16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt16		dstRB;
	UInt32*		dstBA;
	UInt16		srcRL;
	UInt32*		srcBA;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	dstBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	dstRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	srcBA = (UInt32*)_GetPixelDataLoc( inRef, imageIndex );
	srcRL = inRef->bounds.right;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
			dstBA[j] = (srcBA[j] & 0x000000FF) +
						((srcBA[j] & 0x000000FF) << 8) + 
						((srcBA[j] & 0x000000FF) << 16);     // (srcBA[j] & 0x0001) ? 0x00FFFFFF : 0x00000000;
		
		srcBA = srcBA + srcRL;
		dstBA = (UInt32*)((Ptr)dstBA + dstRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_RenderAlpha8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{return pxmErrBadDepth;}

#pragma mark -

pxmErr
_Write32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt32*		srcBA;
	UInt16		srcRB;
	UInt32*		dstBA;
	UInt16		dstRL;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	srcBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	srcRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	dstBA = (UInt32*)_GetPixelDataLoc( inRef, imageIndex );
	dstRL = inRef->bounds.right;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
			dstBA[j] = ((srcBA[j] & 0x00FFFFFF) << 8) + (dstBA[j] & 0x000000FF);
		
		dstBA += dstRL;
		srcBA = (UInt32*)((Ptr)srcBA + srcRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_Write16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{return pxmErrBadDepth;}

pxmErr
_Write8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{return pxmErrBadDepth;}

pxmErr
_WriteMask32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt32*		srcBA;
	UInt16		srcRB;
	UInt16*		dstBA;
	UInt16		dstRL;
	UInt16		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	srcBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	srcRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	dstBA = (UInt16*)((Ptr)inRef + pxmDataSize);
	dstRL = (inRef->bounds.right >> 4) + ((inRef->bounds.right & 0x000F) != 0);
	if( inRef->maskCount == pxmMultiMask )
		dstBA += (dstRL * inRef->bounds.bottom) * imageIndex;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
		{
			if( (j%16) == 0 ) dstBA[j/16] = 0; // init destination to 0
			dstBA[j/16] = _SetBit16( dstBA[j/16], j%16, _IsBlack(srcBA[j]) );
		}
		
		dstBA += dstRL;
		srcBA = (UInt32*)((Ptr)srcBA + srcRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_WriteMask16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{return pxmErrBadDepth;}

pxmErr
_WriteMask8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{return pxmErrBadDepth;}

pxmErr
_WriteAlpha32( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{
	UInt32*		srcBA;
	UInt16		srcRB;
	UInt32*		dstBA;
	UInt16		dstRL;
	UInt32		i, j;
	
	LockPixels(GetGWorldPixMap(inOS));
	
	srcBA = (UInt32*)GetPixBaseAddr(GetGWorldPixMap(inOS));
	srcRB = GetPixRowBytes(GetGWorldPixMap(inOS));
	dstBA = (UInt32*)_GetPixelDataLoc( inRef, imageIndex );
	dstRL = inRef->bounds.right;
	
	for( i = 0; i < inRef->bounds.bottom; i++ )
	{
		for( j = 0; j < inRef->bounds.right; j++ )
			dstBA[j] = _MakeGray(srcBA[j]) + (dstBA[j] & 0xFFFFFF00);
		
		dstBA += dstRL;
		srcBA = (UInt32*)((Ptr)srcBA + srcRB);
	}
	
	UnlockPixels(GetGWorldPixMap(inOS));
	return pxmErrNone;
}

pxmErr
_WriteAlpha16( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{return pxmErrBadDepth;}

pxmErr
_WriteAlpha8( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOS )
{return pxmErrBadDepth;}

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
		return (data | mask[index]) xor mask[index];
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
