#import "AppController.h"

// Specify the script name here. For instance, if it were ghostbusters.scpt, we would put @"ghostbusters" in this define.
#define nextTrackScript @"nexttrack"
#define previousTrackScript @"backtrack"

// This specifies the extension used.
#define runScriptType @"scpt"


@implementation AppController

// This was implemented last minute. Basically if done correctly, the text on the button would have updated to reflect the running state of iTunes, and it would have changed to "Stop iTunes" or some such. Time constraints left this as is.

- (IBAction)launchiTunes:(id)sender
{
//You want to use the bundle identifier here.
		[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.itunes"
															 options:NSWorkspaceLaunchDefault
									  additionalEventParamDescriptor:nil
													launchIdentifier:NULL];
		
	
}

- (IBAction)trackBackward:(id)sender
{
	/* Locate that darn thing. Specifically we want to find the location of the script*/
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource: previousTrackScript ofType: runScriptType];

	//Then we do this here thing with the scriptPath. We're going to use scriptURL later
	NSURL *scriptURL = [NSURL fileURLWithPath: scriptPath];
	

	//Here we tell NSAppleScript what to do
	NSAppleScript *as = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil];
	[as executeAndReturnError:nil];
	//Release as
	[as release];

}

- (IBAction)trackForward:(id)sender
{
	/* Locate that darn thing. Specifically we want to find the location of the script*/
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource: nextTrackScript ofType: runScriptType];
	NSURL *scriptURL = [NSURL fileURLWithPath: scriptPath];
	
	//NSLog(@"%@", scriptURL);
	
	NSAppleScript *as = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:nil];
	[as executeAndReturnError:nil];
	[as release];

}

@end
