/* ServerConfigController */

#import <Cocoa/Cocoa.h>
#import <DotMacKit/DotMacKit.h>

@interface ServerConfigController : NSObject
{
    IBOutlet NSTextField *dotMacPasswordTextField;
    IBOutlet NSTextField *dotMacUserNameTextField;
	IBOutlet NSTextField *dotMacAccountStatus;
	IBOutlet NSTextField *appcastURL;
	IBOutlet NSTextField *enclosureURL;
	
	DMMemberAccount *_dotMacMemberAccount;
	
	NSMutableDictionary	*serverConfigSettings;
}

- (void)getDotMacUserDetails;

- (void)updateUI;

- (NSMutableDictionary	*) serverConfigSettings;
- (void) setServerConfigSettings:(NSMutableDictionary	*)newServerConfigSettings;

- (NSString *) appcastURL;
- (NSString *) enclosureURLPrefix;

@end
