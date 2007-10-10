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

typedef enum
{
	SCCancelButton,
	SCOKButton,
} SCDialogButtons;

#define SCProductNameKey @"productName"
#define SCProductURLKey @"productURL"

@interface MyDocument : NSDocument
{
	IBOutlet NSWindow				*mainWindow;
	IBOutlet NSPanel				*urlPreviewPanel;
	IBOutlet NSTextField			*urlTextField;
	IBOutlet WebView				*webView;
	IBOutlet NSMatrix				*previewMatrix;
	IBOutlet NSTableView			*versionListTableView;
	IBOutlet FileDropImageView		*fileDropImageView;
	IBOutlet NSWindow				*projectInfoSheet;
	IBOutlet NSWindow				*versionInfoSheet;
	IBOutlet NSProgressIndicator	*xmlProgressIndicator;
	IBOutlet NSArrayController		*versionArrayController;
	IBOutlet NSObjectController		*versionInfoController;
	IBOutlet NSWindow				*serverConfigSheet;
	IBOutlet NSTextField			*statusTextField;
	
	IBOutlet ServerConfigController	*serverConfigController;
	
	NSMutableArray				*versionListArray;
	NSMutableDictionary			*productInfoDictionary;
	NSMutableDictionary			*versionInfoDictionary;
	
	NSXMLDocument				*xmlDocument;
}

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

- (NSNumber *) sizeOfFileAtPath:(NSString *)filePath;
- (NSString *) mimeTypeForFileAtPath:(NSString *)filePath;

#pragma mark IBAction Methods
- (IBAction)addNewVersion:(id)sender;
- (IBAction)okVersionInfoSheet:(id)sender;
- (IBAction)cancelVersionInfoSheet:(id)sender;
- (IBAction)previewReleaseNotes:(id)sender;
- (IBAction)showProjectInfoSheet:(id)sender;
- (IBAction)closeProjectInfoSheet:(id)sender;
- (IBAction)closeServerConfigSheet:(id)sender;
- (IBAction)saveXML:(id)sender;
- (IBAction)showConfigSheet:(id)sender;

#pragma mark Private Functions
- (void)didEndProjectInfoSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)didEndVersionInfoSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)didEndServerConfigSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)xmlExportSavePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (void)displayAlertWithMessage:(NSString *)message informativeText:(NSString *)informativeText buttons:(NSArray *)buttons alertStyle:(NSAlertStyle)alertStyle forWindow:(NSWindow *)window;

- (void)addVersion;
- (void)previewURL:(NSURL *)url;

- (BOOL)writeAppCastToURL:(NSURL *)url;

#pragma mark FileDropImageView Delegate Methods
- (void)filesWereDropped:(NSArray *)fileArray;
@end
