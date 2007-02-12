//
//  NSAttributedString+Hyperlink.h
//  
//  This category is pulled from Apple Developer Connection's 
//  Technical Q&A QA1487
//  URL: http://developer.apple.com/qa/qa2006/qa1487.html
//  
//  Purpose: provide a method for creating a hyperlinked string
//			 added via the Hyperlink category

#import <Cocoa/Cocoa.h>

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end
