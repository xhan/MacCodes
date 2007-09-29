//
//  MyDocument.m
//  SparkleCaster
//
//  Created by Adam Radestock on 02/09/2007.
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

#import "MyDocument.h"

@implementation MyDocument

- (id) init {
	self = [super init];
	if (self != nil) {
		versionListArray = [[NSMutableArray alloc] initWithCapacity:0];
		productInfoDictionary = [[NSMutableDictionary alloc] initWithCapacity:3];
	}
	return self;
}


- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
	self = [super initWithType:typeName error:outError];
	[self performSelector:@selector(showProjectInfoSheet:) withObject:mainWindow afterDelay:0.1];
	return self;
}

- (void)dealloc {
    [versionListArray release];
	[productInfoDictionary release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

#pragma mark Accessor Methods

- (NSMutableArray *) versionListArray {
	return versionListArray;
}
- (void) setVersionListArray:(NSMutableArray *)newVersionListArray {
	if(versionListArray != newVersionListArray) {
		[versionListArray setArray:newVersionListArray];
	}
}

- (unsigned) countOfVersionListArray {
	return [versionListArray count];
}
- (NSObject *) objectInVersionListArrayAtIndex:(unsigned)idx {
	return [versionListArray objectAtIndex:idx];
}
- (void) insertObject:(NSObject *)obj inVersionListArrayAtIndex:(unsigned)idx {
	[versionListArray insertObject:obj atIndex:idx];
}
- (void) removeObjectFromVersionListArrayAtIndex:(unsigned)idx {
	[versionListArray removeObjectAtIndex:idx];
}
- (void) replaceObjectInVersionListArrayAtIndex:(unsigned)idx withObject:(NSObject *)obj {
	[versionListArray replaceObjectAtIndex:idx withObject:obj];
}

- (NSMutableDictionary *) productInfoDictionary {
	return productInfoDictionary;
}
- (void) setProductInfoDictionary:(NSMutableDictionary *)newProductInfoDictionary {
	if(productInfoDictionary != newProductInfoDictionary) {
		[productInfoDictionary setDictionary:newProductInfoDictionary];
	}
}

- (NSMutableDictionary *) versionInfoDictionary {
	return versionInfoDictionary;
}

- (void) setVersionInfoDictionary:(NSMutableDictionary *)newVersionInfoDictionary {
	if(versionInfoDictionary != newVersionInfoDictionary) {
		[versionInfoDictionary setDictionary:newVersionInfoDictionary];
	}
}

#pragma mark Document Read/Write

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	
	NSMutableDictionary *masterDictionary = [NSMutableDictionary dictionary];
	
    [masterDictionary setObject:[self productInfoDictionary] forKey:@"productInfoDictionary"];
	[masterDictionary setObject:[self versionListArray] forKey:@"versionArray"];
	
#ifdef kDebugBuild
	NSLog([masterDictionary description]);
#endif
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:masterDictionary];
	
    if (!data && outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
    }
	
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	BOOL readSuccess = NO;
	
	NSMutableDictionary *masterDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	
#ifdef kDebugBuild
	NSLog([masterDictionary description]);
#endif
	
	if (masterDictionary != nil) {
		readSuccess = YES;
		[self setProductInfoDictionary:[masterDictionary valueForKey:@"productInfoDictionary"]];
		[self setVersionListArray:[masterDictionary valueForKey:@"versionArray"]];
	}
	return readSuccess;
}

#pragma mark Misc Methods

- (void)addVersion;
{
	NSMutableDictionary *newVersionDict;
	NSDate *date = [NSDate date]; // Today
	
	newVersionDict = [NSMutableDictionary new];
	[newVersionDict setObject:date forKey:@"date"];
	[self setVersionInfoDictionary:newVersionDict];
#ifdef kDebugBuild
	NSLog([versionInfoDictionary description]);
#endif
}

- (void)previewURL:(NSURL *)url;
{
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	
	if (urlRequest != nil)
	{
		[urlPreviewPanel makeKeyAndOrderFront:self];
		[[webView mainFrame] loadRequest:urlRequest];
	}
}

#pragma mark Sheet Callback Methods

- (void)didEndProjectInfoSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [projectInfoSheet orderOut:self];
}

- (void)didEndVersionInfoSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	[versionInfoSheet orderOut:self];
	if (returnCode == SCOKButton)
	{
		[self insertObject:[self versionInfoDictionary] inVersionListArrayAtIndex:0];
	}
}

#pragma mark XML Stuff

- (NSXMLDocument *)xmlDocument
{
    return [[xmlDocument retain] autorelease];
}

- (void)setXMLDocument:(NSXMLDocument *)newXMLDocument
{
    if (xmlDocument != newXMLDocument)
    {
        [newXMLDocument retain];
        [xmlDocument release];
        xmlDocument = newXMLDocument;
    }
}

/*
 <?xml version="1.0" encoding="utf-8"?>
 <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
	<channel>
		<title>SparkleCast Demo</title>
		<link>http://www.glassmonkey.co.uk/</link>
		<description>Blah</description>
		<generator>Feeder 1.4.6 http://reinventedsoftware.com/feeder/</generator>
		<docs>http://blogs.law.harvard.edu/tech/rss</docs>
		<language>en</language>
		<pubDate>Sat, 08 Sep 2007 17:37:09 +0100</pubDate>
		<lastBuildDate>Sat, 08 Sep 2007 17:37:09 +0100</lastBuildDate>
			<item>
			<title>Test</title>
			<description><![CDATA[blah]]></description>
			<pubDate>Sat, 08 Sep 2007 17:37:09 +0100</pubDate>
			<enclosure url="http://www.glassmonkey.co.uk/test.zip" length="6857972" type="application/zip" sparkle:version="1.0"/>
			<guid isPermaLink="false">test</guid>
			</item>
	</channel>
 </rss>
*/

- (void)writeAppCastToURL:(NSURL *)url;
{
	if (!url)
	{
		[self displayAlertWithMessage:@"Invalid URL" informativeText:@"Please check the URL" buttons:[NSArray arrayWithObject:@"OK"] alertStyle:nil forWindow:mainWindow];
	}
	else
	{
		[xmlProgressIndicator startAnimation:self];
		// Create the root element
		NSXMLElement *rootElement = [NSXMLNode elementWithName:@"rss"];
		xmlDocument = [NSXMLDocument documentWithRootElement:rootElement];
		//set up generic XML doc data (<?xml version="1.0" encoding="UTF-8"?>)
		[xmlDocument setVersion:@"1.0"];
		[xmlDocument setCharacterEncoding:@"UTF-8"];
		// Set the sparkle attributes
		[rootElement addAttribute:[NSXMLNode attributeWithName:@"xmlns:sparkle" stringValue:@"http://www.andymatuschak.org/xml-namespaces/sparkle"]];
		[rootElement addAttribute:[NSXMLNode attributeWithName:@"version" stringValue:@"2.0"]];
		// Setup the Channel Element
		NSXMLElement *channelElement = [NSXMLNode elementWithName:@"channel"];
		[rootElement addChild:channelElement];
		[channelElement addChild:[NSXMLNode elementWithName:@"title" stringValue:[productInfoDictionary objectForKey:@"productName"]]];
		[channelElement addChild:[NSXMLNode elementWithName:@"link" stringValue:[[productInfoDictionary objectForKey:@"productLink"] absoluteString]]];
		[channelElement addChild:[NSXMLNode elementWithName:@"description" stringValue:[productInfoDictionary objectForKey:@"productDescription"]]];
		NSString *generatorString = [NSString stringWithFormat:@"SparkleCaster %@ - http://www.glassmonkey.co.uk/sparklecaster.html", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
		[channelElement addChild:[NSXMLNode elementWithName:@"generator" stringValue:generatorString]];
		[channelElement addChild:[NSXMLNode elementWithName:@"docs" stringValue:@"http://blogs.law.harvard.edu/tech/rss"]];
		[channelElement addChild:[NSXMLNode elementWithName:@"language" stringValue:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]];
		[channelElement addChild:[NSXMLNode elementWithName:@"lastBuildDate" stringValue:[[NSDate date] description]]];
		
		// Start adding items (versions)
		// Sort the version array by date first, so that the latest version is first in the list
		[versionArrayController setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease]]];
		NSArray *itemArray = [versionArrayController arrangedObjects];
		
		NSEnumerator *enumerator = [itemArray objectEnumerator];
		id anObject;
		
		while (anObject = [enumerator nextObject]) {
			/* code to act on each element as it is returned */
			// Get the current version's dictionary
			NSDictionary *itemDictionary = anObject;
			
			NSXMLElement *item = [NSXMLNode elementWithName:@"item"];
			NSString *titleString = [NSString stringWithFormat:@"%@ %@", [productInfoDictionary objectForKey:@"productName"], [itemDictionary objectForKey:@"version"]];
			[item addChild:[NSXMLNode elementWithName:@"title" stringValue:titleString]];
			NSXMLNode *releaseNotesNode = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
			[releaseNotesNode setStringValue:[[itemDictionary objectForKey:@"releaseNotes"] absoluteString]];
			[item addChild:[NSXMLNode elementWithName:@"description" stringValue:[releaseNotesNode XMLStringWithOptions:NSXMLNodePreserveCDATA]]];
			[item addChild:[NSXMLNode elementWithName:@"pubDate" stringValue:[[itemDictionary objectForKey:@"date"] description]]];
			NSXMLElement *enclosureElement = [NSXMLNode elementWithName:@"enclosure"];
			[enclosureElement addAttribute:[NSXMLNode attributeWithName:@"url" stringValue:[itemDictionary objectForKey:@"enclosure"]]];
			// Need to add attributes for enclosure length and MIME type
			[enclosureElement addAttribute:[NSXMLNode attributeWithName:@"sparkle:version" stringValue:[itemDictionary objectForKey:@"version"]]];
			[item addChild:enclosureElement];
			// Set the GUID to the product name and version
			NSXMLElement *guidElement = [NSXMLNode elementWithName:@"guid" stringValue:titleString];
			[guidElement addAttribute:[NSXMLNode attributeWithName:@"isPermaLink" stringValue:@"false"]];
			[item addChild:guidElement];
			
			// Add the item to the channel and release the item and itemDictionary ready for the next item in the array.
			[channelElement addChild:item];
			[releaseNotesNode release];
			[itemDictionary release];
		}
		
		// Now write the XML data to the URL
		NSData *xmlData = [xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint];
		if (![xmlData writeToURL:url atomically:NO])
			NSBeep();
		
		[xmlProgressIndicator stopAnimation:self];
	}
}

#pragma mark Alert Convienience Methods

- (void)displayAlertWithMessage:(NSString *)message informativeText:(NSString *)informativeText buttons:(NSArray *)buttons alertStyle:(NSAlertStyle)alertStyle forWindow:(NSWindow *)window;
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	NSEnumerator *enumerator = [buttons objectEnumerator];
	id buttonTitle;
	
	while (buttonTitle = [enumerator nextObject]) {
		[alert addButtonWithTitle:buttonTitle];
	}
	[alert setMessageText:message];
	[alert setInformativeText:informativeText];
	[alert setAlertStyle:alertStyle];
	
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    
}

#pragma mark IBActions

- (IBAction)addNewVersion:(id)sender;
{
	[self addVersion];
	[NSApp beginSheet:versionInfoSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(didEndVersionInfoSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)okVersionInfoSheet:(id)sender;
{
	[NSApp endSheet:versionInfoSheet returnCode:SCOKButton];
}

- (IBAction)cancelVersionInfoSheet:(id)sender;
{
	[NSApp endSheet:versionInfoSheet returnCode:SCCancelButton];
}

- (IBAction)previewReleaseNotes:(id)sender;
{
	if (([previewMatrix selectedTag] == 0) && ([[urlTextField stringValue] length] != 0))
	{
		NSURL *url = [NSURL URLWithString:[urlTextField stringValue]];
		if (url != nil)
		{
			[self previewURL:url];
		}
		else
		{
			[self displayAlertWithMessage:@"Invalid URL" informativeText:@"Please check the URL" buttons:[NSArray arrayWithObject:@"OK"] alertStyle:nil forWindow:mainWindow];
		}
	}
}

- (IBAction)showProjectInfoSheet:(id)sender;
{
	[NSApp beginSheet:projectInfoSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(didEndProjectInfoSheet:returnCode:contextInfo:) contextInfo: nil];
}

- (IBAction)closeProjectInfoSheet:(id)sender;
{
	[NSApp endSheet:projectInfoSheet];
}

- (IBAction)saveXML:(id)sender;
{
	[self writeAppCastToURL:[NSURL URLWithString:NSHomeDirectory()]];
}

#pragma mark FileDropImageView Delegate Methods

- (void)filesWereDropped:(NSArray *)fileArray;
{
	NSLog([fileArray description]);
	[self setValue:[fileArray objectAtIndex:0] forKeyPath:@"versionListArray.selection.enclosure"];
}

@end
