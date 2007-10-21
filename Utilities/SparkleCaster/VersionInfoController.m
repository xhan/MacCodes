#import "VersionInfoController.h"

@implementation VersionInfoController

- (IBAction)editReleaseNotes:(id)sender;
{
	[releaseNotesWebView setEditable:YES];
	[doneEditReleaseNotesButton setHidden:NO];
	[addReleaseNotesItemButton setHidden:NO];
	[removeReleaseNotesItemButton setHidden:NO];
}

- (IBAction)finishEditingReleaseNotes:(id)sender;
{
	[releaseNotesWebView setEditable:NO];
	[doneEditReleaseNotesButton setHidden:YES];
	[addReleaseNotesItemButton setHidden:YES];
	[removeReleaseNotesItemButton setHidden:YES];
}

- (IBAction)chooseEnclosure:(id)sender;
{
	int result;
    NSArray *fileTypes = [NSArray arrayWithObjects:@"zip", @"tar", @"tgz", @"tbz", @"dmg", nil];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:NSHomeDirectory()
									 file:nil types:fileTypes];
    if (result == NSOKButton) {
        [self setValue:[[oPanel filenames] objectAtIndex:0] forKeyPath:@"selection.enclosureLocalPath"];
    }
	[fileDropImageView setImage:[[NSWorkspace sharedWorkspace] iconForFile:[[oPanel filenames] objectAtIndex:0]]];
}

- (IBAction)previewReleaseNotes:(id)sender;
{
	if ([[urlTextField stringValue] length] != 0)
	{
		NSURL *url = [NSURL URLWithString:[urlTextField stringValue]];
		if (url != nil)
		{
			[self previewURL:url];
		}
		else
		{
			// Handle Error
		}
	}
}

- (void)previewURL:(NSURL *)url;
{
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	
	if (urlRequest != nil)
	{
		[[releaseNotesWebView mainFrame] loadRequest:urlRequest];
	}
}

#pragma mark FileDropImageView Delegate Methods

- (void)filesWereDropped:(NSArray *)fileArray;
{
	[self setValue:[fileArray objectAtIndex:0] forKeyPath:@"selection.enclosureLocalPath"];
	[self setValue:[[fileArray objectAtIndex:0] lastPathComponent] forKeyPath:@"selection.enclosureName"];
	[self setValue:[myDocument mimeTypeForFileAtPath:[fileArray objectAtIndex:0]] forKeyPath:@"selection.enclosureMimeType"];
	[self setValue:[myDocument sizeOfFileAtPath:[fileArray objectAtIndex:0]] forKeyPath:@"selection.enclosureSize"];
}

@end
