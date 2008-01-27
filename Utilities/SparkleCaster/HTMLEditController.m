//
//  HTMLEditController.m
//  SparkleCaster
//
//  Created by Adam Radestock on 09/12/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HTMLEditController.h"


@implementation HTMLEditController

- (void)awakeFromNib {
	NSString *bundleString = [[NSBundle mainBundle] bundlePath];
	NSString *htmlInBundleString = [bundleString stringByAppendingString:@"/Contents/Resources/Release Notes Template/rnotes.html"];
	[[releaseNotesWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlInBundleString]]];
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
	else if (clickedSegment == 1) // Add Section segment clicked
	{
		[self addNewSection];
	}
	else if (clickedSegment == 2) // Remove Section segment clicked
	{
		[self removeCurrentSection];
	}
}

@end
