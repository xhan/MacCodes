/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
	NSURL	*dhlURL;
	NSURL	*fedexURL;
	NSURL	*upsURL;
	NSURL	*uspsURL;
//	IBOutlet	NSWindow * window;
}
- (IBAction)goDHL:(id)sender;
- (IBAction)goFedex:(id)sender;
- (IBAction)goUPS:(id)sender;
- (IBAction)goUSPS:(id)sender;


@end
