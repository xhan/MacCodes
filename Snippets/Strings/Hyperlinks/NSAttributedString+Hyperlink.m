//
//  NSAttributedString+Hyperlink.m
//  
//  This category is pulled from Apple Developer Connection's 
//  Technical Q&A QA1487
//  URL: http://developer.apple.com/qa/qa2006/qa1487.html
//  
//  Purpose: provide a method for creating a hyperlinked string
//			 added via the Hyperlink category

#import "NSAttributedString+Hyperlink.h"

@implementation NSAttributedString (Hyperlink)

+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
	
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
	
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
	
    // next make the text appear with an underline
    [attrString addAttribute:
            NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
	
    [attrString endEditing];
	
    return [attrString autorelease];
}

@end
