//
//  DudeMenu.m
//  Take me to the tracking
//
//  Created by chris on 1/15/07.
//

#import "DudeMenu.h"
#import "AppController.h"


#define kDHLMenuEntry				NSLocalizedString(@"DHL", @"")
#define kUPSMenuEntry				NSLocalizedString(@"UPS", @"")
#define kUSPSMenuEntry				NSLocalizedString(@"USPS", @"")
#define kFedexMenuEntry				NSLocalizedString(@"Fedex", @"")
#define kCloseDudeMenu				NSLocalizedString(@"Close the menu", @"")


int main(void) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];
	
	DudeMenu *menu = [[DudeMenu alloc] init];
	[NSApp setDelegate:menu];
	[NSApp run];
	
	// dead code
	[pool release];
	
	return EXIT_SUCCESS;
}

@implementation DudeMenu

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
#pragma unused(aNotification)
	
	NSMenu *m = [self createMenu];
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
	
	NSBundle *bundle = [NSBundle mainBundle];
	
	dudeImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"package" ofType:@"gif"]];
	dudeHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"package-blackedout" ofType:@"gif"]];

	
	[self setImage];
	
	[statusItem setMenu:m]; // retains m
	[statusItem setToolTip:@"Dude!"];
	[statusItem setHighlightMode:YES];
	
	[m release];
	
	dhlURL = [[NSURL alloc] initWithString:@"http://track.dhl-usa.com/trackbynbr.asp"];
	fedexURL = [[NSURL alloc] initWithString:@"http://www.fedex.com/Tracking?cntry_code=us"];
	upsURL = [[NSURL alloc] initWithString:@"http://www.ups.com/tracking/tracking.html"];
	uspsURL = [[NSURL alloc] initWithString:@"http://www.usps.com/shipping/trackandconfirm.htm"];
	[NSApp setDelegate:self];
	
	
}



- (void) shutdown:(id)sender {
	[NSApp terminate:sender];
}


- (void) applicationWillTerminate:(NSNotification *)aNotification {
#pragma unused(aNotification)
	[dhlURL release];
	[fedexURL release];
	[upsURL release];
	[uspsURL release];
	[dudeImage release];
	[dudeHighlightImage release];
	
	[self release];
}

#pragma mark menuitem stuff

- (void) goDHLMenuItem:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:dhlURL];
}


- (void) goUPSMenuItem:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:upsURL];

}

- (void) goUSPSMenuItem:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:uspsURL];
	
}
- (void) goFedexMenuItem:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:fedexURL];
	
}

#pragma mark setimage
- (void) setImage {
		[statusItem setImage:dudeImage];
		[statusItem setAlternateImage:dudeHighlightImage];
}

- (NSMenu *) createMenu {
	NSZone *menuZone = [NSMenu menuZone];
	NSMenu *m = [[NSMenu allocWithZone:menuZone] init];
	
	NSMenuItem *tempMenuItem;
	
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kDHLMenuEntry action:@selector(goDHLMenuItem:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:1];
	
	
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kUPSMenuEntry action:@selector(goUPSMenuItem:) keyEquivalent:@""];
	[tempMenuItem setTag:2];
	[tempMenuItem setTarget:self];

	
//	[m addItem:[NSMenuItem separatorItem]];
	
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kUSPSMenuEntry action:@selector(goUSPSMenuItem:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:3];

	
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kFedexMenuEntry action:@selector(goFedexMenuItem:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:4];

	
	
	[m addItem:[NSMenuItem separatorItem]];

	
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kCloseDudeMenu action:@selector(shutdown:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:5];
	

	return m;
}

- (BOOL) validateMenuItem:(NSMenuItem *)item {
	
	return YES;
}

@end
