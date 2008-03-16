#import "ServerConfigController.h"

@implementation ServerConfigController

- (id) init {
	self = [super init];
	if (self != nil) {
		serverConfigSettings = [NSMutableDictionary dictionaryWithCapacity:0];
		if ([[NSUserDefaults standardUserDefaults] valueForKey:@"useAccountFromdotMacPreferences"] == NULL)
			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"useAccountFromdotMacPreferences"];
		
		myHost		= [[NSUserDefaults standardUserDefaults] valueForKey:@"host"];
		myUsername	= [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
		myPort		= [[NSUserDefaults standardUserDefaults] valueForKey:@"port"];
		
		_connectionError = NO;
		_testConnection = NO;
	}
	
	return self;
}

- (void)awakeFromNib {
	
		EMInternetKeychainItem *keychainItem = [[EMKeychainProxy sharedProxy] internetKeychainItemForServer:myHost withUsername:myUsername path:nil port:[myPort intValue] protocol:kSecProtocolTypeFTP];
		if (keychainItem != nil) {
			[serverPasswordTextField setStringValue:[keychainItem password]];
		}
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

- (IBAction)testConnection:(id)sender; {
	_testConnection = YES;
	[connectionStatusTextField setHidden:NO];
	[connectionStatusTextField setStringValue:[NSString stringWithFormat:@"Connecting to: %@", [serverURLTextField stringValue]]];
	[connectionStatusIcon setHidden:YES];
	[connectionProgressIndicator setHidden:NO];
	[connectionProgressIndicator animate:self];
	
	[NSThread detachNewThreadSelector:@selector(connectionWithCK) toTarget:self withObject:nil];
}

- (void)connectionWithCK; {
	NSAutoreleasePool *releasePool = [[NSAutoreleasePool alloc] init];
	NSError *err = nil;
	
	switch ([serverConnectionTypePopupButton selectedTag]) {
			
		case 1:
			con = [[AbstractConnection connectionWithName:@"FTP" host:[serverURLTextField stringValue] port:[serverPortTextField stringValue] username:[serverUsernameTextField stringValue] password:[serverPasswordTextField stringValue] error:&err] retain];
			break;
			
		case 2:
			con = [[AbstractConnection connectionWithName:@"SFTP" host:[serverURLTextField stringValue] port:[serverPortTextField stringValue] username:[serverUsernameTextField stringValue] password:[serverPasswordTextField stringValue] error:&err] retain];
			break;
			
		case 3:
			con = [[AbstractConnection connectionWithName:@"WebDAV" host:[serverURLTextField stringValue] port:[serverPortTextField stringValue] username:[serverUsernameTextField stringValue] password:[serverPasswordTextField stringValue] error:&err] retain];
			break;
			
		case 4:
			con = [[AbstractConnection connectionWithName:@"Amazon S3" host:[serverURLTextField stringValue] port:[serverPortTextField stringValue] username:[serverUsernameTextField stringValue] password:[serverPasswordTextField stringValue] error:&err] retain];
			
		default:
			if ([[serverURLTextField stringValue] length] > 0) {
				con = [[AbstractConnection connectionWithURL:[NSURL URLWithString:[serverURLTextField stringValue]] error:&err] retain];
			}
			break;
	}
	
	if (!con)
	{
		if (err)
		{
			[NSApp presentError:err];
		}
		return;
	}
	
	[con setDelegate:self];
	
	[con connect];
	[releasePool release];
}

- (IBAction)publishAppcast:(id)sender; {
	
	_testConnection = NO;
	if ([connectionTypeTabView selectedTabViewItem] == 0) {
		// .Mac connection
	} else {
		// Connection Kit connection
		
		// If the user has chosen the save the password, then save the host info to the keychain
		if ([savePasswordCheckbox state] == NSOnState)
			[self saveCurrentHostToKeychain];
		
		[NSThread detachNewThreadSelector:@selector(connectionWithCK) toTarget:self withObject:nil];
	}
}

#pragma mark Keychain Support

- (void)saveCurrentHostToKeychain; {
	
	myHost		= [serverURLTextField stringValue];
	myPort		= [serverPortTextField stringValue];
	myUsername	= [serverUsernameTextField stringValue];
	myPassword	= [serverPasswordTextField stringValue];
	
	EMInternetKeychainItem *keychainItem = [[EMKeychainProxy sharedProxy] internetKeychainItemForServer:myHost withUsername:myUsername path:nil port:[myPort intValue] protocol:kSecProtocolTypeFTP];
	if (!keychainItem && myPassword && [myPassword length] > 0 && myUsername && [myUsername length] > 0)
	{
		//We don't have any keychain item created for us, but we have all the info we need to make one. Let's do it.
		[[EMKeychainProxy sharedProxy] addInternetKeychainItemForServer:myHost withUsername:myUsername password:myPassword path:nil port:[myPort intValue] protocol:kSecProtocolTypeFTP];
	}
}

#pragma mark Connection Delegate Messages

- (BOOL)connection:(id <AbstractConnectionProtocol>)con authorizeConnectionToHost:(NSString *)host message:(NSString *)message;
{
	if (NSRunAlertPanel(@"Authorize Connection?", @"%@\nHost: %@", @"Yes", @"No", nil, message, host) == NSOKButton)
		return YES;
	return NO;
}

- (void)connectionDidSendBadPassword:(AbstractConnection *)aConn
{
		[connectionStatusTextField setStringValue:[NSString stringWithFormat:@"Incorrect password. Please try again..."]];
		[connectionProgressIndicator stopAnimation:self];
		[connectionProgressIndicator setHidden:YES];
		[connectionStatusIcon setImage:[NSImage imageNamed:@"small_red_cross"]];
		[connectionStatusIcon setHidden:NO];
}

- (void)connection:(AbstractConnection *)aConn didConnectToHost:(NSString *)host
{
	if (!_connectionError) {
		[connectionStatusTextField setStringValue:[NSString stringWithFormat:@"Connected successfully to: %@", host]];
		[connectionProgressIndicator stopAnimation:self];
		[connectionProgressIndicator setHidden:YES];
		[connectionStatusIcon setImage:[NSImage imageNamed:@"small_green_check"]];
		[connectionStatusIcon setHidden:NO];
		if (!_testConnection) {
			// Connect to the host and publish the feed
			
			// export the appcast to the user's Temporary Dirctory
			NSURL *saveURL = [NSURL fileURLWithPath:[[NSTemporaryDirectory() stringByExpandingTildeInPath] stringByAppendingPathComponent:@"SCTempAppcast.xml"]];
			BOOL saved = [documentController writeAppCastToURL:saveURL];
			
#warning Don't forget to wrap this in a thread!
			[aConn uploadFile:[saveURL path] toFile:[self appcastURL] checkRemoteExistence:YES];
			
			// Don't forget to delete the temp appcast
			NSFileManager *fm = [NSFileManager defaultManager];
			BOOL deleted = [fm removeItemAtPath:[saveURL path] error:NULL];
		}
	}
}

- (void)connection:(AbstractConnection *)aConn didReceiveError:(NSError *)error
{
	_connectionError = YES;
	if ([[error domain] isEqualTo:@"ConnectionErrorDomain"]) {
		NSString *host = [[error userInfo] objectForKey:@"host"];
		[connectionStatusTextField setStringValue:[NSString stringWithFormat:@"Could not find host: %@. Please check URL and try again...", host]];
		[connectionProgressIndicator stopAnimation:self];
		[connectionProgressIndicator setHidden:YES];
		[connectionStatusIcon setImage:[NSImage imageNamed:@"small_red_cross"]];
		[connectionStatusIcon setHidden:NO];
	} else {
		[NSApp presentError:error];
	}
}

#pragma mark .Mac Connection Methods

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

#pragma mark Misc

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
