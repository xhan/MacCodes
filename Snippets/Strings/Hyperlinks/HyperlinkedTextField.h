//
//  HyperlinkedTextField.h
//  
//  This subclass is a supplement for Apple Developer Connection's 
//  Technical Q&A QA1487
//  URL: http://developer.apple.com/qa/qa2006/qa1487.html
//  
//  Purpose: provide a method for setting a URL for a text field
//			 added via subclass

#import <Cocoa/Cocoa.h>

@interface HyperlinkedTextField : NSTextField
{
}

-(void)setURL:(NSURL *)targetURL;

@end
