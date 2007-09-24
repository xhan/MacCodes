/*

BSD License

Copyright (c) 2007, Adam Radestock, Glass Monkey Software
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of Glass Monkey Software or Adam Radestock nor the names
	of its contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

#import "FileDropImageView.h"

@implementation FileDropImageView

- (id)initWithFrame:(NSRect)frameRect;
{
	self = [super initWithFrame:frameRect];
	if (self != nil) {
		[self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
		_acceptsMultipleFiles = YES;
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ([self isEditable]) {
		NSPasteboard *pboard = [sender draggingPasteboard];
		if ([[pboard types] containsObject:NSFilenamesPboardType])
		{
			if (([[pboard propertyListForType:NSFilenamesPboardType] count] > 1) && (!_acceptsMultipleFiles))
				return NSDragOperationNone;
			else
				return NSDragOperationLink;
		}
	}
	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
	
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		if ([delegate respondsToSelector:@selector(filesWereDropped:)]) {
			[delegate filesWereDropped:files];
			if ((_acceptsMultipleFiles) && ([files count] > 1))
				[self setImage:[NSImage imageNamed:@"documents"]];
			else
				[self setImage:[[NSWorkspace sharedWorkspace] iconForFile:[files objectAtIndex:0]]];
		}
		else
			NSLog(@"The delegate does not respond to selector filesWereDropped");
    }
    return YES;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
	return YES;
}

#pragma mark Delegate Methods

- (void)shouldAcceptMultipleFiles:(BOOL)acceptMultipleFiles;
{
	_acceptsMultipleFiles = acceptMultipleFiles;
}
- (BOOL)acceptsMultipleFiles;
{
	return _acceptsMultipleFiles;
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)newDelegate {
    delegate = newDelegate;
}

@end
