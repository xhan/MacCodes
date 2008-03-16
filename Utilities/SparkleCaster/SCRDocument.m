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

#import "SCRDocument.h"

static NSString* 	MyDocToolbarIdentifier				= @"My Document Toolbar Identifier";
static NSString*	ProductInfoToolbarItemIdentifier	= @"Product Info Item Identifier";
static NSString*	AddVersonToolbarItemIdentifier		= @"Add Version Item Identifier";
static NSString*	DeleteVersonToolbarItemIdentifier 	= @"Delete Version Item Identifier";
static NSString*	PublishToolbarItemIdentifier		= @"Publish Item Identifier";
static NSString*	ExportRSSToolbarItemIdentifier		= @"Export RSS Item Identifier";

// This class knows how to validate "most" custom views.  Useful for view items we need to validate.
@interface ValidatedViewToolbarItem : NSToolbarItem
@end

@interface SCRDocument (Private)
- (void)setupToolbar;
@end

@implementation SCRDocument

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
	[NSBundle loadNibNamed:@"ServerConfig" owner:self];
	[versionListTableView setDoubleAction:nil];
	[htmlEditButton setMenu:htmlEditMenu forSegment:0];
}

- (NSNumber *) sizeOfFileAtPath:(NSString *)filePath;
{
	NSFileManager * fm = [NSFileManager defaultManager];
	NSNumber *size;
	BOOL isDirectory;
	
	if ([fm fileExistsAtPath:filePath isDirectory:&isDirectory] && isDirectory) {
		size = [NSNumber numberWithInt:0];
	} else {
		size = [NSNumber numberWithUnsignedLongLong:[[fm fileAttributesAtPath:filePath traverseLink:NO] fileSize]];
	}
	
	// Return Total Size in KBytes
	return size;
}

- (NSString *) mimeTypeForFileAtPath:(NSString *)filePath;
{
	NSFileManager * fm = [NSFileManager defaultManager];
	BOOL isDirectory;
	NSString *mimeType = @"application/unknown";
	
	if ([fm fileExistsAtPath:filePath isDirectory:&isDirectory]) {
		if (!isDirectory){
			NSString *extension = [filePath pathExtension];
			
			if ([extension isEqualToString:@"zip"])
				mimeType = @"application/zip";
			else if ([extension isEqualToString:@"tar"])
				mimeType = @"application/x-tar";
			else if ([extension isEqualToString:@"tgz"])
				mimeType = @"application/x-gzip";
			else if ([extension isEqualToString:@"tbz"])
				mimeType = @"application/x-bzip";
			else if ([extension isEqualToString:@"dmg"])
				mimeType = @"application/x-apple-diskimage";
		}
	}
	// Return the mimeType
	return mimeType;
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
		[toolbarItem setLabel: @"Add"];
		[toolbarItem setPaletteLabel: @"Add Version"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Add a new version"];
		[toolbarItem setImage: [NSImage imageNamed: @"Add"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: versionInfoController];
		[toolbarItem setAction: @selector(addNewVersion:)];
		
	} else if([itemIdent isEqual: DeleteVersonToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
		
        // Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Remove"];
		[toolbarItem setPaletteLabel: @"Remove Version"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Remove selected version"];
		[toolbarItem setImage: [NSImage imageNamed: @"Remove"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(removeSelectedObjectFromVersionListArray)];
		
	} else if([itemIdent isEqual: PublishToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
		
        // Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Publish"];
		[toolbarItem setPaletteLabel: @"Publish RSS"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Publish this RSS feed"];
		[toolbarItem setImage: [NSImage imageNamed: @"Publish"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showConfigSheet:)];
		
	} else if([itemIdent isEqual: ExportRSSToolbarItemIdentifier]) {
        toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
		
        // Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Export"];
		[toolbarItem setPaletteLabel: @"Export RSS"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip: @"Export RSS XML Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"exportRSS"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(saveXML:)];
		
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
    return [NSArray arrayWithObjects: ProductInfoToolbarItemIdentifier, NSToolbarSeparatorItemIdentifier, ExportRSSToolbarItemIdentifier, PublishToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, AddVersonToolbarItemIdentifier, DeleteVersonToolbarItemIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects: 	PublishToolbarItemIdentifier, ProductInfoToolbarItemIdentifier, AddVersonToolbarItemIdentifier, DeleteVersonToolbarItemIdentifier,  NSToolbarCustomizeToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, ExportRSSToolbarItemIdentifier, nil];
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
	} else if ([[toolbarItem itemIdentifier] isEqual: PublishToolbarItemIdentifier]) {
		enable = YES;
	} else if ([[toolbarItem itemIdentifier] isEqual: ExportRSSToolbarItemIdentifier]) {
		enable = YES;
    }
    return enable;
}

#pragma mark Accessor Methods

- (NSWindow *)mainWindow;
{
	return mainWindow;
}

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
	[self updateChangeCount:NSChangeDone];
}
- (void) removeObjectFromVersionListArrayAtIndex:(unsigned)idx {
	[versionListArray removeObjectAtIndex:idx];
	[self updateChangeCount:NSChangeDone];
}
- (void) replaceObjectInVersionListArrayAtIndex:(unsigned)idx withObject:(NSObject *)obj {
	[versionListArray replaceObjectAtIndex:idx withObject:obj];
	[self updateChangeCount:NSChangeDone];
}

- (NSMutableDictionary *) productInfoDictionary {
	return productInfoDictionary;
}
- (void) setProductInfoDictionary:(NSMutableDictionary *)newProductInfoDictionary {
	if(productInfoDictionary != newProductInfoDictionary) {
		[productInfoDictionary setDictionary:newProductInfoDictionary];
		[self updateChangeCount:NSChangeDone];
	}
}

- (NSMutableDictionary *) versionInfoDictionary {
	return versionInfoDictionary;
}

- (void) setProductName:(NSString *)newName;
{
	[productInfoDictionary setObject:newName forKey:SCProductNameKey];
}

- (void) setProductURL:(NSString *)newProductURL;
{
	[productInfoDictionary setObject:newProductURL forKey:SCProductURLKey];
}

- (void) setVersionInfoDictionary:(NSMutableDictionary *)newVersionInfoDictionary {
	if(versionInfoDictionary != newVersionInfoDictionary) {
		[versionInfoDictionary setDictionary:newVersionInfoDictionary];
	}
}

- (void) removeSelectedObjectFromVersionListArray;
{
	[versionArrayController remove:self];
	[self updateChangeCount:NSChangeDone];
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

#pragma mark Sheet Callback Methods

- (void)didEndProjectInfoSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [projectInfoSheet orderOut:self];
}

- (void)xmlExportSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
{
	[sheet orderOut:self];
	
	if ((returnCode == NSOKButton) && ([[sheet URL] isFileURL]))
	{
		if (![self writeAppCastToURL:[sheet URL]])
			[self displayAlertWithMessage:@"Could not save XML" informativeText:@"An unknown error prevented the XML file from being written" buttons:[NSArray arrayWithObject:@"OK"] alertStyle:NSInformationalAlertStyle forWindow:mainWindow];
	}
}

#pragma mark XML Stuff

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

- (BOOL)writeAppCastToURL:(NSURL *)url;
{
	// This currently only works for file:// URLs
	BOOL success = NO;
	
	// Format date string
	NSDateFormatter *dFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
	
	if ((!url) | (![url isFileURL]))
	{
		[self displayAlertWithMessage:@"Invalid URL" informativeText:@"Please check the URL" buttons:[NSArray arrayWithObject:@"OK"] alertStyle:nil forWindow:mainWindow];
	}
	else
	{
		[xmlProgressIndicator startAnimation:self];
		[statusTextField setStringValue:@"Saving XML..."];
		[statusTextField setHidden:NO];
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
		[channelElement addChild:[NSXMLNode elementWithName:@"title" stringValue:[productInfoDictionary objectForKey:SCProductNameKey]]];
		[channelElement addChild:[NSXMLNode elementWithName:@"link" stringValue:[productInfoDictionary objectForKey:SCProductURLKey]]];
		[channelElement addChild:[NSXMLNode elementWithName:@"description" stringValue:[productInfoDictionary objectForKey:@"productDescription"]]];
		NSString *generatorString = [NSString stringWithFormat:@"SparkleCaster %@ - http://www.glassmonkey.co.uk/sparklecaster.html", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
		[channelElement addChild:[NSXMLNode elementWithName:@"generator" stringValue:generatorString]];
		[channelElement addChild:[NSXMLNode elementWithName:@"docs" stringValue:@"http://blogs.law.harvard.edu/tech/rss"]];
		[channelElement addChild:[NSXMLNode elementWithName:@"language" stringValue:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]]];
		
		[channelElement addChild:[NSXMLNode elementWithName:@"lastBuildDate" stringValue:[dFormatter stringFromDate:[NSDate date]]]];
		
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
			NSString *titleString = [NSString stringWithFormat:@"%@ %@", [productInfoDictionary objectForKey:SCProductNameKey], [itemDictionary objectForKey:@"version"]];
			[item addChild:[NSXMLNode elementWithName:@"title" stringValue:titleString]];
			NSXMLNode *releaseNotesTextNode = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeIsCDATA];
			[releaseNotesTextNode setStringValue:[[itemDictionary objectForKey:@"releaseNotes"] absoluteString]];
			NSXMLElement *releaseNotesElement = [NSXMLNode elementWithName:@"description"];
			[releaseNotesElement addChild:releaseNotesTextNode];
			[item addChild:releaseNotesElement];
			[item addChild:[NSXMLNode elementWithName:@"pubDate" stringValue:[dFormatter stringFromDate:[itemDictionary objectForKey:@"date"]]]];
			NSXMLElement *enclosureElement = [NSXMLNode elementWithName:@"enclosure"];

			// If the user has supplied a URL for a remote file, include that
			if ([itemDictionary objectForKey:@"enclosureURL"]) {
				[enclosureElement addAttribute:[NSXMLNode attributeWithName:@"url" stringValue:[itemDictionary objectForKey:@"enclosureURL"]]];
			} else {
				// otherwise, munge the local file url and the enclosure prefix url to produce a valid link tot he file once it's been uploaded
				NSString *mungedURLString = [[productInfoDictionary objectForKey:@"enclosureURLPrefix"] stringByAppendingString:[itemDictionary objectForKey:@"enclosureName"]];
				[enclosureElement addAttribute:[NSXMLNode attributeWithName:@"url" stringValue:mungedURLString]];
			}
			
			[enclosureElement addAttribute:[NSXMLNode attributeWithName:@"length" stringValue:[[self sizeOfFileAtPath:[itemDictionary objectForKey:@"enclosureLocalPath"]] stringValue]]];
			[enclosureElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:[itemDictionary objectForKey:@"enclosureMimeType"]]];
			[enclosureElement addAttribute:[NSXMLNode attributeWithName:@"sparkle:version" stringValue:[itemDictionary objectForKey:@"version"]]];
			[item addChild:enclosureElement];
			// Set the GUID to the product name and version
			NSXMLElement *guidElement = [NSXMLNode elementWithName:@"guid" stringValue:titleString];
			[guidElement addAttribute:[NSXMLNode attributeWithName:@"isPermaLink" stringValue:@"false"]];
			[item addChild:guidElement];
			
			// Add the item to the channel and release the item and itemDictionary ready for the next item in the array.
			[channelElement addChild:item];
		}
		
		// Now write the XML data to the URL
		NSData *xmlData = [xmlDocument XMLDataWithOptions:NSXMLNodePrettyPrint];
		NSError *err;
		if (![xmlData writeToURL:url options:NSAtomicWrite error:&err]){
			[NSApp willPresentError:err];
		}
		
		[xmlProgressIndicator stopAnimation:self];
		[statusTextField setHidden:YES];
		success = YES;
	}
	
	return success;
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

- (IBAction)testFTPConnection:(id)sender; {
	
}

- (IBAction)showProjectInfoSheet:(id)sender;
{
	[NSApp beginSheet:projectInfoSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(didEndProjectInfoSheet:returnCode:contextInfo:) contextInfo: nil];
}

- (IBAction)closeProjectInfoSheet:(id)sender;
{
	// Make any text box lose first responder status so that whatever it is bound
	// to will be updated. Then tell NSApp to end the sheet.
	[projectInfoSheet makeFirstResponder:projectInfoSheet];
	[NSApp endSheet:projectInfoSheet];
}

- (IBAction)saveXML:(id)sender;
{
#ifdef kDebugBuild
	// saves the feed as an xml document to the current user's home directory in a file called "test.xml"
	[self writeAppCastToURL:[NSURL fileURLWithPath:[[NSHomeDirectory() stringByExpandingTildeInPath] stringByAppendingPathComponent:@"test.xml"]]];
#else
	NSSavePanel *sp;
	
	/* create or get the shared instance of NSSavePanel */
	sp = [NSSavePanel savePanel];
	
	[sp setAllowedFileTypes:[NSArray arrayWithObjects:@"xml", @"rss", nil]];
	[sp setCanSelectHiddenExtension:YES];
	
	/* display the NSSavePanel */
	[sp beginSheetForDirectory:NSHomeDirectory() file:[NSString stringWithFormat:@"%@_appcast.xml", [productInfoDictionary objectForKey:@"productName"]] modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(xmlExportSavePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
#endif
}

- (IBAction)showConfigSheet:(id)sender;
{
	[serverConfigController showConfigSheet];
}

- (IBAction)closeServerConfigSheet:(id)sender;
{
	[serverConfigController closeConfigSheet];
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