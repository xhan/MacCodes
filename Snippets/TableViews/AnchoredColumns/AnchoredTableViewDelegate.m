//
//  AnchoredTableViewDelegate.h
//  
//  This delegate is adapted from Apple Developer Connection's 
//  Technical Q&A QA1503
//  URL: http://developer.apple.com/qa/qa2006/qa1503.html
//  
//  Purpose: provide a simple tableview delegate that disables dragging
//			 for specified columns, and reverts moves as needed for this.

#import "AnchoredTableViewDelegate.h"

@interface AnchoredTableViewDelegate (PRIVATE)
-(void)resetColumns;
@end

@implementation AnchoredTableViewDelegate (PRIVATE)

-(void)resetColumns
{
	// temporarily stop listening to column moves to prevent recursion
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSTableViewColumnDidMoveNotification object:nil];
	
	int columnLoop, columnCount = [anchoredColumns count];
	
	// loop through the anchored columns so we can restore them
	for(columnLoop = 0; columnLoop < columnCount; columnLoop++)
	{
		NSString *currentColumn = [anchoredColumns objectAtIndex:columnLoop];
		// move the column to its specified position
		[tableView moveColumn:[tableView columnWithIdentifier:currentColumn] 
					 toColumn:[[anchoredPositions objectForKey:currentColumn] intValue]];		
	}
	
	// listen again for column moves
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewColumnDidMove:)
												 name:NSTableViewColumnDidMoveNotification object:nil];
}

@end

@implementation AnchoredTableViewDelegate

-(void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewColumnDidMove:)
												 name:NSTableViewColumnDidMoveNotification object:nil];
	[self setAnchoredColumns:[NSArray arrayWithObjects:@"usageColumn", @"nameColumn", nil]];
	[self setAnchoredPositions:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:1], nil] forKeys:[NSArray arrayWithObjects:@"usageColumn", @"nameColumn", nil]]];
}

// sets the list of 'locked' columns for checking
-(void)setAnchoredColumns:(NSArray *)newColumns
{
	[anchoredColumns autorelease];
	anchoredColumns = [newColumns retain]; // keep 'em around just in case
}

// sets the list of 'locked' column positions for moves
// this dictionary is keyed by column identifiers
-(void)setAnchoredPositions:(NSDictionary *)newPositions
{
	[anchoredPositions autorelease];
	anchoredPositions = [newPositions retain]; // keep 'em around just in case
}

-(void)tableView: (NSTableView*)inTableView mouseDownInHeaderOfTableColumn:(NSTableColumn*)tableColumn
{
    if ([anchoredColumns containsObject:[tableColumn identifier]])
    {
        [inTableView setAllowsColumnReordering:NO];
    }
    else
    {
        [inTableView setAllowsColumnReordering:YES];
    }
}

- (void)tableViewColumnDidMove:(NSNotification*)aNotification
{
    NSDictionary* userInfo = [aNotification userInfo];
		
    // if the user tries to move the first column out, move it back 
	// if the user tries to move a column in front of the first column, move it back
    if ([[anchoredPositions allValues] containsObject:[userInfo objectForKey:@"NSOldColumn"]] ||
		[[anchoredPositions allValues] containsObject:[userInfo objectForKey:@"NSNewColumn"]])
    {
		[self resetColumns];
    }
}

-(void)dealloc {
	[anchoredColumns autorelease];
	[super dealloc];
}

@end
