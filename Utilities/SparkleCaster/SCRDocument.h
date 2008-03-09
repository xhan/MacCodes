//
//  MyDocument.h
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


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "ServerConfigController.h"
#import "URLFormatter.h"
#import "FileDropImageView.h"
#import "CommunicationController.h"

#define SCProductNameKey @"productName"
#define SCProductURLKey @"productURL"

@interface SCRDocument : NSDocument
{
	IBOutlet NSWindow				*mainWindow;
	IBOutlet NSTableView			*versionListTableView;
	IBOutlet NSWindow				*projectInfoSheet;
	IBOutlet NSWindow				*versionInfoSheet;
	IBOutlet NSProgressIndicator	*xmlProgressIndicator;
	IBOutlet NSArrayController		*versionArrayController;
	IBOutlet NSObjectController		*versionInfoController;
	IBOutlet NSTextField			*statusTextField;
	IBOutlet NSSegmentedControl		*htmlEditButton;
	IBOutlet NSMenu					*htmlEditMenu;
	
	IBOutlet ServerConfigController	*serverConfigController;
	
	NSMutableArray				*versionListArray;
	NSMutableDictionary			*productInfoDictionary;
	NSMutableDictionary			*versionInfoDictionary;
	
	NSXMLDocument				*xmlDocument;
}

- (NSWindow *)mainWindow;
- (NSMutableArray *) versionListArray;
- (void) setVersionListArray:(NSMutableArray *)newVersionListArray;

- (unsigned) countOfVersionListArray;
- (NSObject *) objectInVersionListArrayAtIndex:(unsigned)idx;
- (void) insertObject:(NSObject *)obj inVersionListArrayAtIndex:(unsigned)idx;
- (void) removeObjectFromVersionListArrayAtIndex:(unsigned)idx;
- (void) replaceObjectInVersionListArrayAtIndex:(unsigned)idx withObject:(NSObject *)obj;

- (NSMutableDictionary *) productInfoDictionary;
- (void) setProductInfoDictionary:(NSMutableDictionary *)newProductInfoDictionary;

- (NSMutableDictionary *) versionInfoDictionary;
- (void) setVersionInfoDictionary:(NSMutableDictionary *)newVersionInfoDictionary;

- (void) setProductName:(NSString *)newName;
- (void) setProductURL:(NSString *)newProductURL;

- (void) removeSelectedObjectFromVersionListArray;

#pragma mark IBAction Methods
- (IBAction)showProjectInfoSheet:(id)sender;
- (IBAction)closeProjectInfoSheet:(id)sender;
- (IBAction)closeServerConfigSheet:(id)sender;
- (IBAction)saveXML:(id)sender;
- (IBAction)showConfigSheet:(id)sender;
- (IBAction)testFTPConnection:(id)sender;

- (void)didEndProjectInfoSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)xmlExportSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (void)displayAlertWithMessage:(NSString *)message informativeText:(NSString *)informativeText buttons:(NSArray *)buttons alertStyle:(NSAlertStyle)alertStyle forWindow:(NSWindow *)window;

- (NSNumber *) sizeOfFileAtPath:(NSString *)filePath;
- (NSString *) mimeTypeForFileAtPath:(NSString *)filePath;

- (BOOL)writeAppCastToURL:(NSURL *)url;
@end
