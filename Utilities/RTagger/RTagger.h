//
//  RTagger.h
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
// ==============================
//
// Audio file tag reader/writer
// Supports the following formats:
// * MP3 (id3v1 & id3v2)
// * AAC (Metadata)
// * FLAC
// * OGG
// Almost all functionality is in the two subclasses

#import <Cocoa/Cocoa.h>

@protocol RTaggerProtocol <NSObject>
- (id)initWithPath:(NSString *)inPath;
- (BOOL)save;
+ (NSArray *)supportedTypes;
+ (BOOL)supportsFile:(NSString *)path;

// Bunched up accessors
- (NSDictionary *)info;
- (void)setInfo:(NSDictionary *)info;

// Individual accessors
- (void)setTitle:(NSString *)val;
- (void)setArtist:(NSString *)val;
- (void)setAlbum:(NSString *)val;
- (void)setComment:(NSString *)val;
- (void)setGenre:(NSString *)val;
- (void)setYear:(unsigned int)val;
- (void)setTrackNumber:(unsigned int)val;
- (void)setTotalNumberOfTracks:(unsigned int)total;
- (NSString *)title;
- (NSString *)artist;
- (NSString *)album;
- (NSString *)comment;
- (NSString *)genre;
- (unsigned int)year;
- (unsigned int)trackNumber;
- (unsigned int)totalNumberOfTracks;
@end

@interface RTagger : NSObject {
}
+ (id<RTaggerProtocol>)taggerWithPath:(NSString *)inPath;
+ (void)registerTaggerClass:(NSString *)className;
+ (NSArray *)taggerClasses;

// Pass an instance of a tagger that conforms to RTaggerProtocol
// and these method will handle wrapping properties in a dictionary
// (I didn't want to implement this in every tagger)
+ (NSDictionary *)infoForTagger:(id<RTaggerProtocol>)tagger;
+ (void)setInfoForTagger:(id<RTaggerProtocol>)tagger info:(NSDictionary *)info;
@end
