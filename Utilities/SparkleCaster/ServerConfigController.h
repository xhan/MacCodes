/* ServerConfigController */

#import <Cocoa/Cocoa.h>
#import <DotMacKit/DotMacKit.h>

@interface ServerConfigController : NSObject
{
    IBOutlet NSTextField *dotMacPasswordTextField;
    IBOutlet NSTextField *dotMacUserNameTextField;
	IBOutlet NSTextField *dotMacAccountStatus;
	
	DMMemberAccount *_dotMacMemberAccount;
}

- (void)getDotMacUserDetails;

- (void)updateUI;
@end
