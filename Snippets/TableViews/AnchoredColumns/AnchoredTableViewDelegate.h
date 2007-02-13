//
//  AnchoredTableViewDelegate.h
//  
//  This delegate is adapted from Apple Developer Connection's 
//  Technical Q&A QA1503
//  URL: http://developer.apple.com/qa/qa2006/qa1503.html
//  
//  Purpose: provide a simple tableview delegate that disables dragging
//			 for specified columns, and reverts moves as needed for this.

#import <Cocoa/Cocoa.h>

@interface AnchoredTableViewDelegate : NSObject {
	IBOutlet	NSTableView		*tableView;
	NSArray *anchoredColumns;
	NSDictionary *anchoredPositions;
}
-(void)setAnchoredColumns:(NSArray *)newColumns;
-(void)setAnchoredPositions:(NSDictionary *)newPositions;

@end
