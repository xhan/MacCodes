/* VersionInfoController */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "FileDropImageView.h"
#import "SCRDocument.h"

typedef enum
{
	SCReleaseNotesEmbeded,
	SCReleaseNotesFromURL
} SCReleaseNotesType;

typedef enum
{
	SCCancelButton,
	SCOKButton,
} SCDialogButtons;

@interface VersionInfoController : NSObjectController
{
	IBOutlet SCRDocument				*myDocument;
	IBOutlet NSWindow				*versionInfoSheet;
	IBOutlet NSWindow				*mainWindow;
	IBOutlet FileDropImageView		*fileDropImageView;
	IBOutlet WebView				*releaseNotesWebView;
	IBOutlet NSTextField			*urlTextField;
	IBOutlet NSSegmentedControl		*editSegmentedControl;
}

- (IBAction)editSegmentClicked:(id)sender;
- (IBAction)chooseEnclosure:(id)sender;
- (IBAction)previewReleaseNotes:(id)sender;
- (IBAction)addNewVersion:(id)sender;
- (IBAction)okVersionInfoSheet:(id)sender;
- (IBAction)cancelVersionInfoSheet:(id)sender;

- (void)didEndVersionInfoSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)filesWereDropped:(NSArray *)fileArray;
- (void)previewURL:(NSURL *)url;
@end
