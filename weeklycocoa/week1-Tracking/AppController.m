#import "AppController.h"


@implementation AppController

#pragma mark Whee

- (void) awakeFromNib {
	
	
	dhlURL = [[NSURL alloc] initWithString:@"http://track.dhl-usa.com/trackbynbr.asp"];
	fedexURL = [[NSURL alloc] initWithString:@"http://www.fedex.com/Tracking?cntry_code=us"];
	upsURL = [[NSURL alloc] initWithString:@"http://www.ups.com/tracking/tracking.html"];
	uspsURL = [[NSURL alloc] initWithString:@"http://www.usps.com/shipping/trackandconfirm.htm"];
	[NSApp setDelegate:self];
}

#pragma mark Destroy when done

- (void) dealloc {
	[dhlURL release];
	[fedexURL release];
	[upsURL release];
	[uspsURL release];
	[super dealloc];
}
#pragma mark NSWorkspace button launching stuff
- (IBAction)goDHL:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:dhlURL];
}

- (IBAction)goFedex:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:fedexURL];
}

- (IBAction)goUPS:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:upsURL];
}

- (IBAction)goUSPS:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:uspsURL];
}


- (void) enableDudeMenu {
	NSBundle *bundle = [NSBundle mainBundle];

	NSString *dudeMenuPath = [bundle pathForResource:@"GrowlMenu" ofType:@"app"];
	NSURL *dudeMenuURL = [NSURL fileURLWithPath:dudeMenuPath];
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:dudeMenuURL]
	                withAppBundleIdentifier:nil
	                                options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync
	         additionalEventParamDescriptor:nil
	                      launchIdentifiers:NULL];
}

#pragma mark Quit on close

-(BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}



@end
