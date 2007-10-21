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
	[self performSelector:@selector(getDotMacUserDetails) withObject:nil afterDelay:0.5];
}

- (void)closeConfigSheet;
{
	[NSApp endSheet:serverConfigSheet];
}
	
- (void)didEndServerConfigSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [serverConfigSheet orderOut:self];
}

- (void) getDotMacUserDetails;
{
	[dotMacAccountProgressIndicator animate:self];
	[dotMacAccountStatus setStringValue:@"Getting account details..."];
	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"useAccountFromdotMacPreferences"] boolValue] == YES)
	{
		_dotMacMemberAccount = [DMMemberAccount accountFromPreferencesWithApplicationID:@"SCst"];
		
		[_dotMacMemberAccount setApplicationName:@"SparkleCaster"];
		[_dotMacMemberAccount setIsSynchronous:YES];
		[_dotMacMemberAccount setDelegate:self];
		
		if ([_dotMacMemberAccount validateCredentials] != kDMSuccess) { 
			// invalid credentials - sign them up?
		}
		
		DMTransaction *serviceTransaction = [_dotMacMemberAccount servicesAvailableForAccount]; 
		
		if ([serviceTransaction isSuccessful]) { 
			NSArray *services = [serviceTransaction result]; 
			if ([services containsObject:kDMWebHostingService] == NO) {
				[dotMacAccountStatus setStringValue:@"Web hosting is not available on this account"];
			} else {
				[dotMacAccountStatus setStringValue:@"OK to upload to this account"];
			}
		} else { 
			// handle error
		}
		[dotMacUserNameTextField setStringValue:[_dotMacMemberAccount name]];
		[dotMacAccountProgressIndicator stopAnimation:self];
	}
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
