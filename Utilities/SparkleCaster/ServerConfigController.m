#import "ServerConfigController.h"

@implementation ServerConfigController

- (void) awakeFromNib
{
	[self performSelector:@selector(getDotMacUserDetails) withObject:nil afterDelay:0.5];
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

@end
