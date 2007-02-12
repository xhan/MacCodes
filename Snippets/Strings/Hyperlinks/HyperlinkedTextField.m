//
//  HyperlinkedTextField.m
//  
//  This subclass is a supplement for Apple Developer Connection's 
//  Technical Q&A QA1487
//  URL: http://developer.apple.com/qa/qa2006/qa1487.html
//  
//  Purpose: provide a method for setting a URL for a text field
//			 added via subclass

#import "HyperlinkedTextField.h"
#import "NSAttributedString+Hyperlink.h"

@implementation HyperlinkedTextField

-(void)setURL:(NSURL *)targetURL
{
	// both are needed, otherwise hyperlink won't accept mousedown
    [self setAllowsEditingTextAttributes:YES];
	[self setEditable:NO];
    [self setSelectable:YES];
	
    NSMutableAttributedString* createdString = [[NSMutableAttributedString alloc] init];
    [createdString appendAttributedString:[NSAttributedString hyperlinkFromString:[self stringValue] withURL:targetURL]];
		
    // set the attributed string to the NSTextField
    [self setAttributedStringValue:[createdString autorelease]];
#pragma warning This is a cheap hack to get the textfield to redraw appropriately. Please fix me.
	[self mouseDown:nil];
}

@end
