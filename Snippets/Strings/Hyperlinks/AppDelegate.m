#import "AppDelegate.h"
#import "NSAttributedString+Hyperlink.h"

@implementation AppDelegate

-(void)awakeFromNib
{
	[testField setURL:[NSURL URLWithString:@"http://www.growl.info"]];
	
	// for the text view we'll set up some regular text, a link, and some regular text
	NSAttributedString *introString = [[NSAttributedString alloc] initWithString:@"Use multiple IM services? Try "];
	NSAttributedString *linkString = [NSAttributedString hyperlinkFromString:@"Adium" 
										withURL:[NSURL URLWithString:@"http://www.adiumx.com"]];
	NSAttributedString *endingString = [[NSAttributedString alloc] initWithString:@" today!"];
	
	// build the sentence
	NSMutableAttributedString *completeSentence = [[NSMutableAttributedString alloc] init];
	[completeSentence appendAttributedString:introString];
	[completeSentence appendAttributedString:linkString];
	[completeSentence appendAttributedString:endingString];
		
	[[testView textStorage] setAttributedString:completeSentence];
}

@end
