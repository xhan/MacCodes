/* VersionInfoController */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "FileDropImageView.h"
#import "MyDocument.h"

typedef enum
{
	SCReleaseNotesEmbeded,
	SCReleaseNotesFromURL
} SCReleaseNotesType;

@interface VersionInfoController : NSObjectController
{
	IBOutlet MyDocument				*myDocument;
	IBOutlet FileDropImageView		*fileDropImageView;
	IBOutlet WebView				*releaseNotesWebView;
	IBOutlet NSTextField			*urlTextField;
	IBOutlet NSButton				*editReleaseNotesButton;
	IBOutlet NSButton				*doneEditReleaseNotesButton;
	IBOutlet NSButton				*addReleaseNotesItemButton;
	IBOutlet NSButton				*removeReleaseNotesItemButton;
}

- (IBAction)editReleaseNotes:(id)sender;
- (IBAction)finishEditingReleaseNotes:(id)sender;
- (IBAction)chooseEnclosure:(id)sender;
- (IBAction)previewReleaseNotes:(id)sender;

- (void)filesWereDropped:(NSArray *)fileArray;
- (void)previewURL:(NSURL *)url;
@end
