#import "ServerConfigController.h"

@implementation ServerConfigController

- (id) init {
	self = [super init];
	if (self != nil) {
		serverConfigSettings = [NSMutableDictionary dictionaryWithCapacity:0];
	}
	return self;
}

- (void)showConfigSheet;
{
	[NSApp beginSheet:serverConfigSheet modalForWindow:[documentController mainWindow] modalDelegate:self didEndSelector:@selector(didEndServerConfigSheet:returnCode:contextInfo:) contextInfo:nil];
	[self getDotMacUserDetails];
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
	_dotMacMemberAccount = [DMMemberAccount accountFromPreferencesWithApplicationID:@"SCst"];
	[_dotMacMemberAccount setApplicationName:@"SparkleCaster"];
	if ([_dotMacMemberAccount validateCredentials] != kDMSuccess) { 
		// invalid credentials - sign them up?
	}
	
	DMTransaction *serviceTransaction = [_dotMacMemberAccount servicesAvailableForAccount]; 
	
	if ([serviceTransaction isSuccessful]) { 
		NSArray *services = [serviceTransaction result]; 
		if ([services containsObject:kDMWebHostingService] == NO) {
			// Web Hosting service is not available
		} 
	} else { 
		// handle error 
	}
	
	[self updateUI];
}

- (void)updateUI;
{
	[dotMacUserNameTextField setStringValue:[_dotMacMemberAccount name]];
	// [dotMacPasswordTextField setStringValue:[_dotMacMemberAccount password]];
	
	NSString *statusString = [NSString stringWithFormat:@"You have %d days left on your account."];
	[dotMacAccountStatus setStringValue:statusString];
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
