//
//  DudeMenu.h
//  Take me to the tracking
//
//  Created by chris on 1/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DudeMenu : NSObject {
	NSStatusItem				*statusItem;

	NSImage						*dudeImage;
	NSImage						*dudeHighlightImage;
	
	
	NSURL	*dhlURL;
	NSURL	*fedexURL;
	NSURL	*upsURL;
	NSURL	*uspsURL;
	
}

- (NSMenu *) createMenu;
- (void) setImage;

@end
