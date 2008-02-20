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

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	[recentDocsTableView setTarget:self];
	[recentDocsTableView setDoubleAction:@selector(openRecentSCDocument)];
}

- (void) dealloc {
	[super dealloc];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO; // Prevents the app from creating a blank document on startup
}

- (void)openRecentSCDocument;
{
#ifdef kDebugBuild
	NSLog([NSString stringWithFormat:@"%d", [recentDocsTableView clickedRow]]);
	NSLog([[[[NSDocumentController sharedDocumentController] recentDocumentURLs] objectAtIndex:[recentDocsTableView clickedRow]] absoluteString]);
#endif
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[[[NSDocumentController sharedDocumentController] recentDocumentURLs] objectAtIndex:[recentDocsTableView clickedRow]] display:YES];
}

- (IBAction)newSCDocument:(id)sender;
{
	if (startPanel != nil)
		[startPanel close];
	[[NSDocumentController sharedDocumentController] newDocument:self];
}

- (IBAction)openSCDocument:(id)sender;
{
	if (startPanel != nil)
		[startPanel close];
	[[NSDocumentController sharedDocumentController] openDocument:self];
}

#pragma mark Recent Documents Table Data Source Methods
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *outString = [[[[NSDocumentController sharedDocumentController] recentDocumentURLs] objectAtIndex:rowIndex] path];
	return [outString lastPathComponent];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[[NSDocumentController sharedDocumentController] recentDocumentURLs] count];
}
@end
