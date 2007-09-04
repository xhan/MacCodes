//
//  RTaggerMP4.m
//  RTagger
//
// Copyright (c) 2007, Fjölnir Ásgeirsson <fjolnir@gmail.com>
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//	¥Redistributions of source code must retain the above copyright notice,
//	 this list of conditions and the following disclaimer.
//	¥Redistributions in binary form must reproduce the above copyright notice,
//	 this list of conditions and the following disclaimer in the documentation and/or
//	 other materials provided with the distribution.
//	¥Neither the name of Fjölnir Ásgeirsson, ninja kitten nor the names of its contributors may be used to 
//	 endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
// FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
// IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RTaggerMP4.h"

@interface RTaggerMP4 (Private)
- (void)setMetaDataValueWithFunction:(void *)ptr value:(const char *)val;
- (NSString *)metaDataValueWithFunction:(void *)ptr;
@end

@implementation RTaggerMP4
- (id)initWithPath:(NSString *)inPath
{
	self = [super init];
	if(!self || ![[NSFileManager defaultManager] fileExistsAtPath:inPath])
		return nil;
	path = [inPath retain];
	
	return self;
}

- (BOOL)save
{
	return YES; // We save after each action (due to how mp4v2 is)
}

+ (NSArray *)supportedTypes
{
	return [NSArray arrayWithObjects:@"aac", @"mp4", @"m4a", nil];
}
+ (BOOL)supportsFile:(NSString *)path
{
	MP4FileHandle *handle = NULL;
	handle = MP4Read([path UTF8String], 0);
	if(handle != NULL)
	{
		MP4Close(handle);
		return YES;
	}
	return NO;
}
//_____________________________________________________________________________________________aCCESSORS
- (NSDictionary *)info
{
	return [RTagger infoForTagger:self];
}
- (void)setInfo:(NSDictionary *)info
{
	[RTagger setInfoForTagger:self info:info];
}

- (void)setMetaDataValueWithFunction:(void *)ptr value:(const char *)val
{
	MP4FileHandle *handle = MP4Read([path UTF8String], 0);
	void (*metadataFuncPtr)(MP4FileHandle *handle, const char *val, int foo, int bar) = ptr;
	metadataFuncPtr(handle, val, 0, 0);
	MP4Close(handle);
}

- (void)setTitle:(NSString *)val
{
	[self setMetaDataValueWithFunction:&MP4SetMetadataName value:[val UTF8String]];
}
- (void)setArtist:(NSString *)val
{
	[self setMetaDataValueWithFunction:&MP4SetMetadataArtist value:[val UTF8String]];
}
- (void)setAlbum:(NSString *)val
{
	[self setMetaDataValueWithFunction:&MP4SetMetadataAlbum value:[val UTF8String]];
}
- (void)setComment:(NSString *)val
{
	[self setMetaDataValueWithFunction:&MP4SetMetadataComment value:[val UTF8String]];
}
- (void)setGenre:(NSString *)val
{
	[self setMetaDataValueWithFunction:&MP4SetMetadataGenre value:[val UTF8String]];
}
- (void)setYear:(unsigned int)val
{
	MP4FileHandle *handle = MP4Modify([path UTF8String], 0, 0);
	char *year;
	asprintf(&year, "%d", val);
	MP4SetMetadataYear(handle, year);
	MP4Close(handle);
	free(year);
}
- (void)setTrackNumber:(unsigned int)val
{
	MP4FileHandle *handle = MP4Modify([path UTF8String], 0, 0);
	MP4SetMetadataTrack(handle, val, [self totalNumberOfTracks]);
	MP4Close(handle);
}
- (void)setTotalNumberOfTracks:(unsigned int)total
{
	MP4FileHandle *handle = MP4Modify([path UTF8String], 0, 0);
	MP4SetMetadataTrack(handle, [self trackNumber], total);
	MP4Close(handle);
}
- (NSString *)metaDataValueWithFunction:(void *)ptr
{
	MP4FileHandle *handle = MP4Read([path UTF8String], 0);
	char *val = NULL;
	void (*metadataFuncPtr)(MP4FileHandle *handle, char **val) = ptr;
	metadataFuncPtr(handle, &val);
	MP4Close(handle);
	printf("foo: %s\n", val);
	if(val == NULL)
		return @"";
	return [NSString stringWithUTF8String:val];
}
- (NSString *)title
{
	return [self metaDataValueWithFunction:&MP4GetMetadataName];
}
- (NSString *)artist
{
	return [self metaDataValueWithFunction:&MP4GetMetadataArtist];
}
- (NSString *)album
{
	return [self metaDataValueWithFunction:&MP4GetMetadataAlbum];
}
- (NSString *)comment
{
	return [self metaDataValueWithFunction:&MP4GetMetadataComment];
}
- (NSString *)genre
{
	return [self metaDataValueWithFunction:&MP4GetMetadataGenre];
}
- (unsigned int)year
{
	MP4FileHandle *handle = MP4Read([path UTF8String], 0);
	char *val = NULL;
	MP4GetMetadataYear(handle, &val);
	MP4Close(handle);
	if(!val)
		return 0;
	return atoi(val);
}
- (unsigned int)trackNumber
{
	MP4FileHandle *handle = MP4Read([path UTF8String], 0);
	u_int16_t val, val2;
	MP4GetMetadataTrack(handle, &val, &val2);
	MP4Close(handle);
	if(!val)
		return 0;
	return val;
}
- (unsigned int)totalNumberOfTracks
{
	MP4FileHandle *handle = MP4Read([path UTF8String], 0);
	u_int16_t val, total;
	MP4GetMetadataTrack(handle, &val, &total);
	MP4Close(handle);
	if(!total)
		return 0;
	return total;
}

//_____________________________________________________________________________________________cLEANuP

- (void)dealloc
{
	[path release];
	
	[super dealloc];
}
@end
