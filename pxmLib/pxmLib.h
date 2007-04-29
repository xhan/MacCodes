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

#pragma once

enum
{
	pxmVersionOS8			= 1,
	pxmVersionOSX			= 2,
	pxmVersionOSX2			= 3 //Not sure when this was bumped. Shows up in Panther, in Tiger PPC, and in Tiger Intel.
};

enum
{
	pxmTypeDefault			= 0,
	pxmTypeIndexed			= 8,
	pxmTypeDirect16			= 16,
	pxmTypeDirect32			= 32
};

enum
{
	pxmErrNone				= 0,
	pxmErrMemFull			= 1,
	pxmErrBadParams			= 2,
	pxmErrBadIndex			= 3,
	pxmErrBadDepth			= 4
};

enum
{
	pxmSingleMask			= 1,
	pxmMultiMask			= 0
};


#pragma options align=mac68k

typedef struct pxmData
{
	SInt16			version;
	//We use a union for easy byte-swapping of the entire structure.
	union {
		//This structure must always be in the big-endian layout, since that's what's on disk.
		struct {
			UInt16	__empty:11,
					chaos:1,
					mystery:1,
					hasAlpha:1,
					__unknown1:1,
					maskCount:1;
		} bits;
		UInt16 number;
	} bitfield;
	Rect			bounds;
	UInt16			pixelSize; //In bits
	UInt16			pixelType;
//	UInt16			__unknown2;
//	UInt16			__unknown3;
	CTabPtr			clutAddr;
	SInt16			clutID;
	UInt16			imageCount;
	UInt8			data[0];
} pxmData;

#define	pxmDataSize		24

#pragma options align=reset

typedef pxmData*	pxmRef;
typedef	OSErr		pxmErr;


pxmRef	pxmCreate( void* inData, UInt32 inSize );
pxmErr	pxmDispose( pxmRef inRef );
pxmErr	pxmRead( pxmRef inRef, void* ioBuffer, UInt32* ioSize );

UInt32	pxmSize( pxmRef inRef );
pxmErr	pxmBounds( pxmRef inRef, Rect* outRect );
bool	pxmHasAlpha( pxmRef inRef );
UInt16	pxmPixelSize( pxmRef inRef );
UInt16	pxmPixelType( pxmRef inRef );
UInt16	pxmImageCount( pxmRef inRef );
bool	pxmIsMultiMask( pxmRef inRef );

pxmErr	pxmMakeGWorld( pxmRef inRef, GWorldPtr* outGWorld );

pxmErr	pxmRenderImage( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOffscreen );
pxmErr	pxmRenderMask( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOffscreen );
pxmErr	pxmRenderAlpha( pxmRef inRef, UInt16 imageIndex, GWorldPtr inOffscreen );

pxmErr	pxmWriteImage( pxmRef, UInt16 imageIndex, GWorldPtr inOffscreen );
pxmErr	pxmWriteMask( pxmRef, UInt16 imageIndex, GWorldPtr inOffscreen );
pxmErr	pxmWriteAlpha( pxmRef, UInt16 imageIndex, GWorldPtr inOffscreen );
