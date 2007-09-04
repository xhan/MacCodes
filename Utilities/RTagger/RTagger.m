//
//  RTagger.m
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

#import "RTagger.h"

NSMutableArray *taggers = nil;

@implementation RTagger
+ (void)initialize
{
	if(taggers)
		return;
	
	taggers = [[NSMutableArray alloc] init];
	[self registerTaggerClass:@"RTaggerID3"];
	[self registerTaggerClass:@"RTaggerMP4"];
}
+ (id<RTaggerProtocol>)taggerWithPath:(NSString *)inPath
{
	NSObject<RTaggerProtocol> *ret = nil;
	
	NSString *ext = [inPath pathExtension];
	// Find a tagger class that supports the extension
	NSEnumerator *subEnum = [taggers objectEnumerator];
	NSString *className;
	while(className = [subEnum nextObject])
	{
		Class Sub = NSClassFromString(className);
		if([[Sub supportedTypes] containsObject:ext])
		{
			ret = [[Sub alloc] initWithPath:inPath];
			break;
		}
	}
	return [ret autorelease];
}

+ (void)registerTaggerClass:(NSString *)className
{
	if(![taggers containsObject:className] 
	   && [NSClassFromString(className) conformsToProtocol:@protocol(RTaggerProtocol)])
		[taggers addObject:className];
}
+ (NSArray *)taggerClasses
{
	return taggers;
}

//_____________________________________________________________________________________________dICTwRAPPER
+ (NSDictionary *)infoForTagger:(id<RTaggerProtocol>)tagger
{
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];
	[ret setObject:[tagger title] forKey:@"title"];
	[ret setObject:[tagger artist] forKey:@"artist"];
	[ret setObject:[tagger album] forKey:@"album"];
	[ret setObject:[tagger genre] forKey:@"genre"];
	[ret setObject:[tagger comment] forKey:@"comment"];
	[ret setObject:[NSNumber numberWithUnsignedInt:[tagger year]] forKey:@"year"];
	[ret setObject:[NSNumber numberWithUnsignedInt:[tagger trackNumber]] forKey:@"track number"];
	[ret setObject:[NSNumber numberWithUnsignedInt:[tagger totalNumberOfTracks]] forKey:@"total number of tracks"];
	
	return ret;
}
+ (void)setInfoForTagger:(id<RTaggerProtocol>)tagger info:(NSDictionary *)info
{
	NSEnumerator *keyEnum = [[info allKeys] objectEnumerator];
	NSString *key;
	while(key = [keyEnum nextObject])
	{
		if([key isEqualToString:@"title"])
			[tagger setTitle:[info objectForKey:key]];
		else if([key isEqualToString:@"artist"])
			[tagger setArtist:[info objectForKey:key]];
		else if([key isEqualToString:@"album"])
			[tagger setAlbum:[info objectForKey:key]];
		else if([key isEqualToString:@"Comment"])
			[tagger setComment:[info objectForKey:key]];
		else if([key isEqualToString:@"genre"])
			[tagger setGenre:[info objectForKey:key]];
		else if([key isEqualToString:@"year"])
			[tagger setYear:[[info objectForKey:key] unsignedIntValue]];
		else if([key isEqualToString:@"track number"])
			[tagger setTrackNumber:[[info objectForKey:key] unsignedIntValue]];
		else if([key isEqualToString:@"total number of tracks"])
			[tagger setTotalNumberOfTracks:[[info objectForKey:key] unsignedIntValue]];
	}
}

@end
