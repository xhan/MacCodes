#import "VersionInfoController.h"

@implementation VersionInfoController

- (void)awakeFromNib;
{
	[fileDropImageView setDelegate:self];
	[self addObserver:self forKeyPath:@"releaseNotesEmbeded" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
}

- (IBAction)addNewVersion:(id)sender;
{
	// Perform any setup before showing the sheet
	NSMutableDictionary *newVersionDict = [NSMutableDictionary dictionaryWithCapacity:4];
	NSDate *date = [NSDate date]; // Today
	
	[newVersionDict setObject:date forKey:@"date"];
	[self setContent:newVersionDict];
	[fileDropImageView setImage:[NSImage imageNamed:@"drop-target"]];
	
	// Show the sheet
	[NSApp beginSheet:versionInfoSheet modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(didEndVersionInfoSheet:returnCode:contextInfo:) contextInfo:nil];
}

- (void)didEndVersionInfoSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
	[versionInfoSheet orderOut:self];
	if (returnCode == SCOKButton)
	{
		[myDocument insertObject:[self content] inVersionListArrayAtIndex:0];
	}
}

- (IBAction)okVersionInfoSheet:(id)sender;
{
	[NSApp endSheet:versionInfoSheet returnCode:SCOKButton];
}

- (IBAction)cancelVersionInfoSheet:(id)sender;
{
	[NSApp endSheet:versionInfoSheet returnCode:SCCancelButton];
}

- (IBAction)editSegmentClicked:(id)sender;
{
	int clickedSegment = [sender selectedSegment];
	
	if (clickedSegment == 0) // Edit segment clicked
	{
		if ([releaseNotesWebView isEditable])
		{
			[releaseNotesWebView setEditable:NO];
			[sender setEnabled:NO forSegment:1];
			[sender setEnabled:NO forSegment:2];
		}
		else
		{
			[releaseNotesWebView setEditable:YES];
			[sender setEnabled:YES forSegment:1];
			[sender setEnabled:YES forSegment:2];
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"releaseNotesEmbeded"])
	{
		BOOL enabled = ([change objectForKey:NSKeyValueChangeNewKey] == YES) ? NO : YES;
		[editSegmentedControl setEnabled:enabled forSegment:0];
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
