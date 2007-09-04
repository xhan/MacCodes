//
//  RTaggerID3.m
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

#import "RTaggerID3.h"

@implementation RTaggerID3
- (id)initWithPath:(NSString *)inPath
{
	self = [super init];
	
	if(!self || ![[NSFileManager defaultManager] fileExistsAtPath:inPath])
		return nil;
	file = taglib_file_new([inPath UTF8String]);
	tag  = taglib_file_tag(file);
	if(!file || !tag)
		return nil;
	
	return self;
}

- (BOOL)save
{
	return taglib_file_save(file);
}

+ (NSArray *)supportedTypes
{
	return [NSArray arrayWithObjects:@"mp3", @"ogg", @"flac", nil];
}
+ (BOOL)supportsFile:(NSString *)path
{
	RTaggerID3 *testObj = [[self alloc] initWithPath:path];
	if(testObj)
	{
		[testObj release];
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

- (void)setTitle:(NSString *)val
{
	taglib_tag_set_title(tag, [val UTF8String]);
}
- (void)setArtist:(NSString *)val
{
	taglib_tag_set_artist(tag, [val UTF8String]);
}
- (void)setAlbum:(NSString *)val
{
	taglib_tag_set_album(tag, [val UTF8String]);
}
- (void)setComment:(NSString *)val
{
	taglib_tag_set_comment(tag, [val UTF8String]);
}
- (void)setGenre:(NSString *)val
{
	taglib_tag_set_genre(tag, [val UTF8String]);
}
- (void)setYear:(unsigned int)val
{
	taglib_tag_set_year(tag, val);
}
- (void)setTrackNumber:(unsigned int)val
{
	taglib_tag_set_track(tag, val);
}
- (void)setTotalNumberOfTracks:(unsigned int)total
{
	return;
}
- (NSString *)title
{
	return [NSString stringWithUTF8String:taglib_tag_title(tag)];
}
- (NSString *)artist
{
	return [NSString stringWithUTF8String:taglib_tag_artist(tag)];
}
- (NSString *)album
{
	return [NSString stringWithUTF8String:taglib_tag_album(tag)];
}
- (NSString *)comment
{
	return [NSString stringWithUTF8String:taglib_tag_comment(tag)];
}
- (NSString *)genre
{
	return [NSString stringWithUTF8String:taglib_tag_genre(tag)];
}
- (unsigned int)year
{
	return taglib_tag_year(tag);
}
- (unsigned int)trackNumber
{
	return taglib_tag_track(tag);
}
- (unsigned int)totalNumberOfTracks
{
	return 0; // There's no such thing as a track count in id3
}


//_____________________________________________________________________________________________cLEANuP
- (void)dealloc
{
	taglib_file_free(file);
	taglib_tag_free_strings();
	
	[super dealloc];
}
@end
