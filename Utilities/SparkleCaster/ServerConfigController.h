/* ServerConfigController */

#import "SCRDocument.h"
#import <DotMacKit/DotMacKit.h>
#import <Connection/Connection.h>

@class SCRDocument;

@interface ServerConfigController : NSObject
{
    IBOutlet NSTextField			*dotMacPasswordTextField;
    IBOutlet NSTextField			*dotMacUserNameTextField;
	IBOutlet NSTextField			*dotMacAccountStatus;
	IBOutlet NSTextField			*appcastURL;
	IBOutlet NSTextField			*enclosureURL;
	IBOutlet NSWindow				*serverConfigSheet;
	IBOutlet SCRDocument			*documentController;
	IBOutlet NSProgressIndicator	*dotMacAccountProgressIndicator;
	IBOutlet NSImageView			*dotMacAccountStatusIcon;
	IBOutlet NSImageView			*connectionStatusIcon;
	IBOutlet NSProgressIndicator	*connectionProgressIndicator;
	IBOutlet NSTextField			*connectionStatusTextField;
	IBOutlet NSTextField			*serverURLTextField;
	IBOutlet NSTextField			*serverPortTextField;
	IBOutlet NSTextField			*serverUsernameTextField;
	IBOutlet NSTextField			*serverPasswordTextField;
	IBOutlet NSPopUpButton			*serverConnectionTypePopupButton;
	IBOutlet NSButton				*savePasswordCheckbox;
	IBOutlet NSTabView				*connectionTypeTabView;
	IBOutlet NSTextView				*log;
	IBOutlet NSButton				*showTranscriptButton;
	
	NSString *myHost;
	NSString *myPort;
	NSString *myUsername;
	NSString *myPassword;
	
	NSFileManager *fileManager;
	NSURL *saveURL;
	
	DMMemberAccount *_dotMacMemberAccount;
	
	NSMutableDictionary	*serverConfigSettings;
	
	id <AbstractConnectionProtocol> con;
	
	BOOL _connectionError;
	BOOL _testConnection;
}

- (IBAction)setupDotMacAccount:(id)sender;
- (IBAction)testConnection:(id)sender;
- (void)getDotMacUserDetails;
- (void)showConfigSheet;
- (void)closeConfigSheet;
- (IBAction)publishAppcast:(id)sender;
- (void)connectionWithCK;
- (void)saveCurrentHostToKeychain;

- (void)didEndServerConfigSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSMutableDictionary *) serverConfigSettings;
- (void) setServerConfigSettings:(NSMutableDictionary *)newServerConfigSettings;

- (NSString *) appcastPath;
- (NSString *) enclosurePath;

@end