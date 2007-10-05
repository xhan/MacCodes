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

static NSString* 	MyDocToolbarIdentifier 		= @"My Document Toolbar Identifier";
static NSString*	ProductInfoToolbarItemIdentifier 	= @"Product Info Item Identifier";
static NSString*	AddVersonToolbarItemIdentifier 	= @"Add Version Item Identifier";
static NSString*	DeleteVersonToolbarItemIdentifier 	= @"Delete Version Item Identifier";
static NSString*	PublishToolbarItemIdentifier 	= @"Publish Item Identifier";
static NSString*	ConfigureToolbarItemIdentifier 	= @"Configure Item Identifier";

// This class knows how to validate "most" custom views.  Useful for view items we need to validate.
@interface ValidatedViewToolbarItem : NSToolbarItem
@end

@interface MyDocument (Private)
- (void)setupToolbar;
@end

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
	[self setupToolbar];
}

#pragma mark NSToolbar Related Methods

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: MyDocToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [mainWindow setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = nil;
    
    if ([itemIdent isEqual: ProductInfoToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
		
        // Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Product Info"];
		[toolbarItem setPaletteLabel: @"Product Info"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Edit Product Info"];
		[toolbarItem setImage: [NSImage imageNamed: @"Info"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showProjectInfoSheet:)];
		
    } else if([itemIdent isEqual: AddVersonToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
		
        // Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Add Version"];
		[toolbarItem setPaletteLabel: @"Add Version"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Add New Version"];
		[toolbarItem setImage: [NSImage imageNamed: @"Add"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(addNewVersion:)];
		
	} else if([itemIdent isEqual: DeleteVersonToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
		
        // Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Delete Version"];
		[toolbarItem setPaletteLabel: @"Delete Version"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Delete Version"];
		[toolbarItem setImage: [NSImage imageNamed: @"Remove"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: versionArrayController];
		[toolbarItem setAction: @selector(remove:)];
		
	} else if([itemIdent isEqual: PublishToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
		
        // Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Publish"];
		[toolbarItem setPaletteLabel: @"Publish RSS"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Publish this RSS feed"];
		[toolbarItem setImage: [NSImage imageNamed: @"Publish"]];
		
		// Tell the item what message to send when it is clicked 
		// [toolbarItem setTarget: versionArrayController];
		// [toolbarItem setAction: @selector(remove:)];		
		
	} else if([itemIdent isEqual: ConfigureToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
		
        // Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Configure"];
		[toolbarItem setPaletteLabel: @"Configure Server"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Configure feed server settings"];
		[toolbarItem setImage: [NSImage imageNamed: @"Configure"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showConfigSheet:)];
		
		
    } else {
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar this kind of item is not supported 
		toolbarItem = nil;
    }
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects: ProductInfoToolbarItemIdentifier, ConfigureToolbarItemIdentifier, NSToolbarSeparatorItemIdentifier, PublishToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, AddVersonToolbarItemIdentifier, DeleteVersonToolbarItemIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects: 	PublishToolbarItemIdentifier, ConfigureToolbarItemIdentifier, ProductInfoToolbarItemIdentifier, AddVersonToolbarItemIdentifier, DeleteVersonToolbarItemIdentifier,  NSToolbarCustomizeToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}  

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = NO;
    if ([[toolbarItem itemIdentifier] isEqual: ProductInfoToolbarItemIdentifier]) {
		// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving 
		enable = YES;
    } else if ([[toolbarItem itemIdentifier] isEqual: AddVersonToolbarItemIdentifier]) {
		enable = [versionArrayController canAdd];
    } else if ([[toolbarItem itemIdentifier] isEqual: DeleteVersonToolbarItemIdentifier]) {
		enable = [versionArrayController canRemove];
	} else if ([[toolbarItem itemIdentifier] isEqual: ConfigureToolbarItemIdentifier]) {
		enable = YES;
    }	
    return enable;
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
	NSMutableDictionary *newVersionDict = [NSMutableDictionary dictionaryWithCapacity:4];
	NSDate *date = [NSDate date]; // Today
	
	[newVersionDict setObject:date forKey:@"date"];
	[versionInfoController setContent:newVersionDict];
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
		[self insertObject:[versionInfoController content] inVersionListArrayAtIndex:0];
	}
}

- (void)didEndServerConfigSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [serverConfigSheet orderOut:self];
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

- (IBAction)showConfigSheet:(id)sender;
{
	[NSBundle loadNibNamed:@"ServerConfig" owner:self];
	[NSApp beginSheet:serverConfigSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(didEndServerConfigSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)closeServerConfigSheet:(id)sender;
{
	[NSApp endSheet:serverConfigSheet];
}

#pragma mark FileDropImageView Delegate Methods

- (void)filesWereDropped:(NSArray *)fileArray;
{
	NSLog([fileArray description]);
	[self setValue:[fileArray objectAtIndex:0] forKeyPath:@"versionListArray.selection.enclosure"];
}

@end

@implementation ValidatedViewToolbarItem

- (void)validate {
    [super validate]; // Let super take care of validating the menuFormRep, etc.
	
    if ([[self view] isKindOfClass:[NSControl class]]) {
        NSControl *control = (NSControl *)[self view];
        id target = [control target];
        SEL action = [control action];
        
        if ([target respondsToSelector:action]) {
            BOOL enable = YES;
            if ([target respondsToSelector:@selector(validateToolbarItem:)]) {
                enable = [target validateToolbarItem:self];
            }
            [self setEnabled:enable];
            [control setEnabled:enable];
        }
    }
}

@end