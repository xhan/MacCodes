//
//  LinesTextDocument.m
//  Line enumerator test
//
//  Created by Peter Hosey on 2008-09-01.
//  Copyright Peter Hosey 2008 . All rights reserved.
//

#import "LinesTextDocument.h"

#import "PRHLineEnumerator.h"

@implementation LinesTextDocument

- (id)init {
	if ((self = [super init])) {
		lines = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void) dealloc {
	[[self class] cancelPreviousPerformRequestsWithTarget:self];
	[lines release];
	[super dealloc];
}

- (NSString *)windowNibName {
	return @"LinesTextDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
	if (stringFromFile) {
		[textView setString:stringFromFile];
		[self refreshLines];
	}
}

- (void) refreshLines {
	[self willChangeValueForKey:@"lines"];
	[lines removeAllObjects];
	NSEnumerator *stringLinesEnumerator = [[textView string] lineEnumerator];
	NSString *line;
	while ((line = [stringLinesEnumerator nextObject])) {
		[lines addObject:line];
	}
	[self didChangeValueForKey:@"lines"];

	[linesTable reloadData];
}

- (void)textDidChange:(NSNotification *)aNotification {
	[[self class] cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(refreshLines) withObject:nil afterDelay:0.1];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	stringFromFile = [[NSString alloc] initWithContentsOfURL:absoluteURL encoding:NSUTF8StringEncoding error:outError];
	return (stringFromFile != nil);
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [lines count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)row {
	return [lines objectAtIndex:row];
}

@end
