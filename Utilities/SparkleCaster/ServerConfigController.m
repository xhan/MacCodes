#import "ServerConfigController.h"

@implementation ServerConfigController

- (id) init {
	self = [super init];
	if (self != nil) {
		serverConfigSettings = [NSMutableDictionary dictionaryWithCapacity:0];
		if ([[NSUserDefaults standardUserDefaults] valueForKey:@"useAccountFromdotMacPreferences"] == NULL)
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"useAccountFromdotMacPreferences"];
		
	}
	return self;
}

- (void)showConfigSheet;
{
	[NSApp beginSheet:serverConfigSheet modalForWindow:[documentController mainWindow] modalDelegate:self didEndSelector:@selector(didEndServerConfigSheet:returnCode:contextInfo:) contextInfo:nil];
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"useAccountFromdotMacPreferences"] boolValue] == YES)
		[self setupDotMacAccount:self];
}

- (void)closeConfigSheet;
{
	[NSApp endSheet:serverConfigSheet];
}
	
- (void)didEndServerConfigSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [serverConfigSheet orderOut:self];
}

- (IBAction)setupDotMacAccount:(id)sender; {
	if (sender != self) {
		if (([sender tag] == 0) && ([sender state] == NSOffState))
		{
			[dotMacUserNameTextField setStringValue:@""];
			[dotMacPasswordTextField setStringValue:@""];
		} else {
			[dotMacAccountStatusIcon setHidden:YES];
			[dotMacAccountProgressIndicator startAnimation:self];
			[dotMacAccountStatus setStringValue:@"Getting .Mac details..."];
			
			[NSThread detachNewThreadSelector:@selector(getDotMacUserDetails) toTarget:self withObject:nil];
		}
	} else {
		[dotMacAccountStatusIcon setHidden:YES];
		[dotMacAccountProgressIndicator startAnimation:self];
		[dotMacAccountStatus setStringValue:@"Getting .Mac details..."];
		
		[NSThread detachNewThreadSelector:@selector(getDotMacUserDetails) toTarget:self withObject:nil];
	}
}

- (void) getDotMacUserDetails;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"useAccountFromdotMacPreferences"] boolValue] == YES)
	{
		_dotMacMemberAccount = [DMMemberAccount accountFromPreferencesWithApplicationID:@"SCst"];
		
		[_dotMacMemberAccount setApplicationName:@"SparkleCaster"];
		[_dotMacMemberAccount setIsSynchronous:YES];
		[_dotMacMemberAccount setDelegate:self];
		
		if ([_dotMacMemberAccount validateCredentials] != kDMSuccess) {
			[dotMacAccountStatus setStringValue:@"Account details incorrect, please check"];
			[dotMacAccountStatusIcon setImage:[NSImage imageNamed:@"small_red_cross"]];
			[dotMacAccountStatusIcon setHidden:NO];
		} else {
			
			NSString *accountName = [_dotMacMemberAccount name];
			[dotMacUserNameTextField setStringValue:accountName];
			
			DMTransaction *serviceTransaction = [_dotMacMemberAccount servicesAvailableForAccount]; 
			
			if ([serviceTransaction isSuccessful]) { 
				NSArray *services = [serviceTransaction result]; 
				if ([services containsObject:kDMWebHostingService] == NO) {
					[dotMacAccountStatus setStringValue:@"Web hosting is not available on this account"];
					[dotMacAccountStatusIcon setImage:[NSImage imageNamed:@"small_red_cross"]];
					[dotMacAccountStatusIcon setHidden:NO];
				} else {
					[dotMacAccountStatus setStringValue:@"OK to upload to this account"];
					[dotMacAccountStatusIcon setImage:[NSImage imageNamed:@"small_green_check"]];
					[dotMacAccountStatusIcon setHidden:NO];
				}
			} else { 
				// handle error
			}
		}
	} else {
		_dotMacMemberAccount = [DMMemberAccount accountWithName:[dotMacUserNameTextField stringValue] password:[dotMacPasswordTextField stringValue] applicationID:@"SCst"];
		
		[_dotMacMemberAccount setApplicationName:@"SparkleCaster"];
		[_dotMacMemberAccount setIsSynchronous:YES];
		[_dotMacMemberAccount setDelegate:self];
		
		if ([_dotMacMemberAccount validateCredentials] != kDMSuccess) {
			[dotMacAccountStatus setStringValue:@"Account details incorrect, please check"];
			[dotMacAccountStatusIcon setImage:[NSImage imageNamed:@"small_red_cross"]];
			[dotMacAccountStatusIcon setHidden:NO];
		} else {
			
			NSString *accountName = [_dotMacMemberAccount name];
			[dotMacUserNameTextField setStringValue:accountName];
			
			DMTransaction *serviceTransaction = [_dotMacMemberAccount servicesAvailableForAccount]; 
			
			if ([serviceTransaction isSuccessful]) { 
				NSArray *services = [serviceTransaction result]; 
				if ([services containsObject:kDMWebHostingService] == NO) {
					[dotMacAccountStatus setStringValue:@"Web hosting is not available on this account"];
					[dotMacAccountStatusIcon setImage:[NSImage imageNamed:@"small_red_cross"]];
					[dotMacAccountStatusIcon setHidden:NO];
				} else {
					[dotMacAccountStatus setStringValue:@"OK to upload to this account"];
					[dotMacAccountStatusIcon setImage:[NSImage imageNamed:@"small_green_check"]];
					[dotMacAccountStatusIcon setHidden:NO];
				}
			} else { 
				// handle error
			}
		}
	}
	[dotMacAccountProgressIndicator stopAnimation:self];
	[pool release];
}

- (void)transactionSuccessful: (DMTransaction *)theTransaction
{
	//Okay this object got notified that its daysLeftUntilExpiration transaction is
	//complete. So get the payload and update the UI
	
}

- (NSMutableDictionary	*) serverConfigSettings {
	return serverConfigSettings;
}
- (void) setServerConfigSettings:(NSMutableDictionary	*)newServerConfigSettings {
	if(serverConfigSettings != newServerConfigSettings) {
		[serverConfigSettings setDictionary:newServerConfigSettings];
	}
}

- (NSString *) appcastURL;
{
	return [serverConfigSettings objectForKey:@"appcastURL"];
}

- (NSString *) enclosureURLPrefix;
{
	return [serverConfigSettings objectForKey:@"enclosureURLPrefix"];
}

- (void) dealloc {
	[serverConfigSettings release];
	[super dealloc];
}


@end
