//
//  LinesTextDocument.h
//  Line enumerator test
//
//  Created by Peter Hosey on 2008-09-01.
//  Copyright 2008 Peter Hosey. All rights reserved.
//

@interface LinesTextDocument : NSDocument
{
	NSString *stringFromFile;
	IBOutlet NSTextView *textView;
	IBOutlet NSTableView *linesTable;
	NSMutableArray *lines;
}

- (void) refreshLines;

@end
