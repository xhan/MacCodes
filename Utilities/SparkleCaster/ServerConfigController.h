/* ServerConfigController */

#import <Cocoa/Cocoa.h>
#import <DotMacKit/DotMacKit.h>

@class MyDocument;

@interface ServerConfigController : NSObject
{
    IBOutlet NSTextField			*dotMacPasswordTextField;
    IBOutlet NSTextField			*dotMacUserNameTextField;
	IBOutlet NSTextField			*dotMacAccountStatus;
	IBOutlet NSTextField			*appcastURL;
	IBOutlet NSTextField			*enclosureURL;
	IBOutlet NSWindow				*serverConfigSheet;
	IBOutlet MyDocument				*documentController;
	IBOutlet NSProgressIndicator	*dotMacAccountProgressIndicator;
	
	
	DMMemberAccount *_dotMacMemberAccount;
	
	NSMutableDictionary	*serverConfigSettings;
}

- (void)getDotMacUserDetails;
- (void)showConfigSheet;
- (void)closeConfigSheet;

- (void)didEndServerConfigSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSMutableDictionary	*) serverConfigSettings;
- (void) setServerConfigSettings:(NSMutableDictionary	*)newServerConfigSettings;

- (NSString *) appcastURL;
- (NSString *) enclosureURLPrefix;

@end
