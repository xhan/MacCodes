//
//  PSMTabBarController.m
//  PSMTabBarControl
//
//  Created by Kent Sutherland on 11/24/06.
//  Copyright 2006 Kent Sutherland. All rights reserved.
//

#import "PSMTabBarController.h"
#import "PSMTabBarControl.h"
#import "PSMTabBarCell.h"
#import "PSMTabStyle.h"

@interface PSMTabBarController (Private)
- (NSArray *)_generateWidthsFromCells:(NSArray *)cells;
- (void)_setupCells:(NSArray *)cells withWidths:(NSArray *)widths;
@end

@implementation PSMTabBarController

/*!
    @method     initWithTabBarControl:
    @abstract   Creates a new PSMTabBarController instance.
    @discussion Creates a new PSMTabBarController for controlling a PSMTabBarControl. Should only be called by
                PSMTabBarControl.
    @param      A PSMTabBarControl.
    @returns    A newly created PSMTabBarController instance.
*/

- (id)initWithTabBarControl:(PSMTabBarControl *)control
{
    if ( (self = [super init]) ) {
        _control = [control retain];
        _cellTrackingRects = [[NSMutableArray alloc] init];
        _closeButtonTrackingRects = [[NSMutableArray alloc] init];
        _cellFrames = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_control release];
    [_cellTrackingRects release];
    [_closeButtonTrackingRects release];
    [_cellFrames release];
    [super dealloc];
}

/*!
    @method     addButtonRect
    @abstract   Returns the position for the add tab button.
    @discussion Returns the position for the add tab button.
    @returns    The rect  for the add button rect.
*/

- (NSRect)addButtonRect
{
    return _addButtonRect;
}

/*!
    @method     overflowMenu
    @abstract   Returns current overflow menu or nil if there is none.
    @discussion Returns current overflow menu or nil if there is none.
    @returns    The current overflow menu.
*/

- (NSMenu *)overflowMenu
{
    return _overflowMenu;
}

/*!
    @method     cellTrackingRectAtIndex:
    @abstract   Returns the rect for the tracking rect at the requested index.
    @discussion Returns the rect for the tracking rect at the requested index.
    @param      Index of a cell.
    @returns    The tracking rect of the cell at the requested index.
*/

- (NSRect)cellTrackingRectAtIndex:(int)index
{
    NSRect rect;
    if (index > -1 && index < [_cellTrackingRects count]) {
        rect = [[_cellTrackingRects objectAtIndex:index] rectValue];
    } else {
        NSLog(@"cellTrackingRectAtIndex: Invalid index (%i)", index);
        rect = NSZeroRect;
    }
    return rect;
}

/*!
    @method     closeButtonTrackingRectAtIndex:
    @abstract   Returns the tracking rect for the close button at the requested index.
    @discussion Returns the tracking rect for the close button at the requested index.
    @param      Index of a cell.
    @returns    The close button tracking rect of the cell at the requested index.
*/

- (NSRect)closeButtonTrackingRectAtIndex:(int)index
{
    NSRect rect;
    if (index > -1 && index < [_closeButtonTrackingRects count]) {
        rect = [[_closeButtonTrackingRects objectAtIndex:index] rectValue];
    } else {
        NSLog(@"closeButtonTrackingRectAtIndex: Invalid index (%i)", index);
        rect = NSZeroRect;
    }
    return rect;
}

/*!
    @method     cellFrameAtIndex:
    @abstract   Returns the frame for the cell at the requested index.
    @discussion Returns the frame for the cell at the requested index.
    @param      Index of a cell.
    @returns    The frame of the cell at the requested index.
*/

- (NSRect)cellFrameAtIndex:(int)index
{
    NSRect rect;
    
    if (index > -1 && index < [_cellFrames count]) {
        rect = [[_cellFrames objectAtIndex:index] rectValue];
    } else {
        NSLog(@"cellFrameAtIndex: Invalid index (%i)", index);
        rect = NSZeroRect;
    }
    return rect;
}

/*!
    @method     setSelectedCell:
    @abstract   Changes the cell states so the given cell is the currently selected cell.
    @discussion Makes the given cell the active cell and properly recalculates the tab states for surrounding cells.
    @param      An instance of PSMTabBarCell to make active.
*/

- (void)setSelectedCell:(PSMTabBarCell *)cell
{
    NSArray *cells = [_control cells];
    NSEnumerator *enumerator = [cells objectEnumerator];
    PSMTabBarCell *lastCell = nil, *nextCell;
    
    //deselect the previously selected tab
    while ( (nextCell = [enumerator nextObject]) && ([nextCell state] == NSOffState) ) {
        lastCell = nextCell;
    }
    
    [nextCell setState:NSOffState];
    [nextCell setTabState:PSMTab_PositionMiddleMask];
    
    if (lastCell && lastCell != [_control lastVisibleTab]) {
        [lastCell setTabState:~[lastCell tabState] & PSMTab_RightIsSelectedMask];
    }
    
    if ( (nextCell = [enumerator nextObject]) ) {
        [nextCell setTabState:~[lastCell tabState] & PSMTab_LeftIsSelectedMask];
    }
    
    [cell setState:NSOnState];
    [cell setTabState:PSMTab_SelectedMask];
    
    if (![cell isInOverflowMenu]) {
        int cellIndex = [cells indexOfObject:cell];
        
        if (cellIndex > 0) {
            nextCell = [cells objectAtIndex:cellIndex - 1];
            [nextCell setTabState:[nextCell tabState] | PSMTab_RightIsSelectedMask];
        }
        
        if (cellIndex < [cells count] - 1) {
            nextCell = [cells objectAtIndex:cellIndex + 1];
            [nextCell setTabState:[nextCell tabState] | PSMTab_LeftIsSelectedMask];
        }
    }
}

/*!
    @method     layoutCells
    @abstract   Recalculates cell positions and states.
    @discussion This method calculates the proper frame, tabState and overflow menu status for all cells in the
                tab bar control.
*/

- (void)layoutCells
{
    NSArray *cells = [_control cells];
    int cellCount = [cells count];
    
    // make sure all of our tabs are accounted for before updating
    if ([[_control tabView] numberOfTabViewItems] != cellCount) {
        return;
    }
    
    [_cellTrackingRects removeAllObjects];
    [_closeButtonTrackingRects removeAllObjects];
    [_cellFrames removeAllObjects];
    
    NSArray *cellWidths = [self _generateWidthsFromCells:cells];
    [self _setupCells:cells withWidths:cellWidths];
    
    //set up the rect from the add tab button
    _addButtonRect = [_control genericCellRect];
    _addButtonRect.size = [[_control addTabButton] frame].size;
    if ([_control orientation] == PSMTabBarHorizontalOrientation) {
        _addButtonRect.origin.y = MARGIN_Y;
        _addButtonRect.origin.x += [[cellWidths valueForKeyPath:@"@sum.floatValue"] floatValue] + 2;
    } else {
        _addButtonRect.origin.x = 0;
        _addButtonRect.origin.y = [[cellWidths lastObject] floatValue];
    }
}

/*!
    @method     _generateWidthsFromCells:
    @abstract   Calculates the width of cells that would be visible.
    @discussion Calculates the width of cells in the tab bar and returns an array of widths for the cells that would be
                visible. Uses large blocks of code that were previously in PSMTabBarControl's update method.
    @param      An array of PSMTabBarCells.
    @returns    An array of numbers representing the widths of cells that would be visible.
*/

- (NSArray *)_generateWidthsFromCells:(NSArray *)cells
{
    int cellCount = [cells count], i, numberOfVisibleCells = ([_control orientation] == PSMTabBarHorizontalOrientation) ? 1 : 0;
    NSMutableArray *newWidths = [NSMutableArray arrayWithCapacity:cellCount];
    id <PSMTabStyle> style = [_control style];
    float availableWidth = [_control availableCellWidth], currentOrigin = 0, totalOccupiedWidth = 0.0, width;
    NSRect cellRect = [_control genericCellRect], controlRect = [_control frame];
    PSMTabBarCell *currentCell;
    
    if ([_control orientation] == PSMTabBarVerticalOrientation) {
        currentOrigin = [style topMarginForTabBarControl];
    }
    
    for (i = 0; i < cellCount; i++) {
        currentCell = [cells objectAtIndex:i];
        
        if ([_control orientation] == PSMTabBarHorizontalOrientation) {
            // Determine cell width
			if ([_control sizeCellsToFit]) {
				width = [currentCell desiredWidthOfCell];
				if (width > [_control cellMaxWidth]) {
					width = [_control cellMaxWidth];
				}
			} else {
				width = [_control cellOptimumWidth];
			}
			
			//check to see if there is not enough space to place all tabs as preferred
			totalOccupiedWidth += width;
			if (totalOccupiedWidth >= availableWidth) {
				//if we're not going to use the overflow menu, cram all the tab cells into the bar
				if (![_control useOverflowMenu]) {
					int j, averageWidth = (availableWidth / cellCount);
					
					numberOfVisibleCells = cellCount;
					[newWidths removeAllObjects];
					
					for (j = 0; j < cellCount; j++) {
						float desiredWidth = [[cells objectAtIndex:j] desiredWidthOfCell];
						[newWidths addObject:[NSNumber numberWithFloat:(desiredWidth < averageWidth && [_control sizeCellsToFit]) ? desiredWidth : averageWidth]];
					}
					break;
				}
				
				numberOfVisibleCells = i;
				if ([_control sizeCellsToFit]) {
					int neededWidth = width - (totalOccupiedWidth - availableWidth); //the amount of space needed to fit the next cell in
					// can I squeeze it in without violating min cell width?
					int widthIfAllMin = (numberOfVisibleCells + 1) * [_control cellMinWidth];
					
					if ((width + widthIfAllMin) <= availableWidth) {
						// squeeze - distribute needed sacrifice among all cells
						int q;
						for (q = (i - 1); q >= 0; q--) {
							int desiredReduction = (int)neededWidth / (q + 1);
							if (([[newWidths objectAtIndex:q] floatValue] - desiredReduction) < [_control cellMinWidth]) {
								int actualReduction = (int)[[newWidths objectAtIndex:q] floatValue] - [_control cellMinWidth];
								[newWidths replaceObjectAtIndex:q withObject:[NSNumber numberWithFloat:[_control cellMinWidth]]];
								neededWidth -= actualReduction;
							} else {
								int newCellWidth = (int)[[newWidths objectAtIndex:q] floatValue] - desiredReduction;
								[newWidths replaceObjectAtIndex:q withObject:[NSNumber numberWithFloat:newCellWidth]];
								neededWidth -= desiredReduction;
							}
						}
						
						int totalWidth = [[newWidths valueForKeyPath:@"@sum.intValue"] intValue];
						int thisWidth = width - neededWidth; //width the last cell would want
						
						//append a final cell if there is enough room, otherwise stretch all the cells out to fully fit the bar
						if (availableWidth - totalWidth > thisWidth) {
							[newWidths addObject:[NSNumber numberWithFloat:thisWidth]];
							numberOfVisibleCells++;
							totalWidth += thisWidth;
						}
						
						if (totalWidth < availableWidth) {
							int leftoverWidth = availableWidth - totalWidth;
							int q;
							for (q = i - 1; q >= 0; q--) {
								int desiredAddition = (int)leftoverWidth / (q + 1);
								int newCellWidth = (int)[[newWidths objectAtIndex:q] floatValue] + desiredAddition;
								[newWidths replaceObjectAtIndex:q withObject:[NSNumber numberWithFloat:newCellWidth]];
								leftoverWidth -= desiredAddition;
							}
						}
					} else {
						// stretch - distribute leftover room among cells
						int leftoverWidth = availableWidth - totalOccupiedWidth + width;
						int q;
						
						for (q = i - 1; q >= 0; q--) {
							int desiredAddition = (int)leftoverWidth / (q + 1);
							int newCellWidth = (int)[[newWidths objectAtIndex:q] floatValue] + desiredAddition;
							[newWidths replaceObjectAtIndex:q withObject:[NSNumber numberWithFloat:newCellWidth]];
							leftoverWidth -= desiredAddition;
						}
					}
					
					//make sure there are at least two items in the tab bar
					if (numberOfVisibleCells < 2 && [cells count] > 1) {
						PSMTabBarCell *cell1 = [cells objectAtIndex:0], *cell2 = [cells objectAtIndex:1];
						NSNumber *cellWidth;
						
						[newWidths removeAllObjects];
						totalOccupiedWidth = 0;
						
						cellWidth = [NSNumber numberWithFloat:[cell1 desiredWidthOfCell] < availableWidth * 0.5f ? [cell1 desiredWidthOfCell] : availableWidth * 0.5f];
						[newWidths addObject:cellWidth];
						totalOccupiedWidth += [cellWidth floatValue];
						
						cellWidth = [NSNumber numberWithFloat:[cell2 desiredWidthOfCell] < (availableWidth - totalOccupiedWidth) ? [cell2 desiredWidthOfCell] : (availableWidth - totalOccupiedWidth)];
						[newWidths addObject:cellWidth];
						totalOccupiedWidth += [cellWidth floatValue];
						
						if (totalOccupiedWidth < availableWidth) {
							[newWidths replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:availableWidth - [cellWidth floatValue]]];
						}
						
						numberOfVisibleCells = 2;
					}
					
					break; // done assigning widths; remaining cells go in overflow menu
				} else {
					int revisedWidth = availableWidth / (i + 1);
					if (revisedWidth >= [_control cellMinWidth]) {
						unsigned q;
						totalOccupiedWidth = 0;
						for (q = 0; q < [newWidths count]; q++) {
							[newWidths replaceObjectAtIndex:q withObject:[NSNumber numberWithFloat:revisedWidth]];
							totalOccupiedWidth += revisedWidth;
						}
						// just squeezed this one in...
						[newWidths addObject:[NSNumber numberWithFloat:revisedWidth]];
						totalOccupiedWidth += revisedWidth;
						numberOfVisibleCells++;
					} else {
						// couldn't fit that last one...
						break;
					}
				}
			} else {
				numberOfVisibleCells = cellCount;
				[newWidths addObject:[NSNumber numberWithFloat:width]];
			}
        } else {
            //lay out vertical tabs
			if (currentOrigin + cellRect.size.height <= controlRect.size.height) {
				[newWidths addObject:[NSNumber numberWithFloat:currentOrigin]];
				numberOfVisibleCells++;
				currentOrigin += cellRect.size.height;
			} else {
				//out of room, the remaining tabs go into overflow
				if ([newWidths count] > 0 && controlRect.size.height - currentOrigin < 17) {
					[newWidths removeLastObject];
					numberOfVisibleCells--;
				}
				break;
			}
        }
    }
    
    return newWidths;
}

/*!
    @method     _setupCells:withWidths
    @abstract   Creates tracking rect arrays and sets the frames of the visible cells.
    @discussion Creates tracking rect arrays and sets the cells given in the widths array.
*/

- (void)_setupCells:(NSArray *)cells withWidths:(NSArray *)widths
{
    int i, tabState, cellCount = [cells count];
    NSRect cellRect = [_control genericCellRect];
    PSMTabBarCell *cell;
    NSTabViewItem *selectedTabViewItem = [[_control tabView] selectedTabViewItem];
    NSMenuItem *menuItem;
    
    [_overflowMenu release], _overflowMenu = nil;
    
    for (i = 0; i < cellCount; i++) {
        cell = [cells objectAtIndex:i];
        
        // supress close button?
        [cell setCloseButtonSuppressed:((cellCount == 1 && [_control canCloseOnlyTab] == NO) ||
										[_control disableTabClose] ||
										([[_control delegate] respondsToSelector:@selector(tabView:disableTabCloseForTabViewItem:)] && 
										 [[_control delegate] tabView:[_control tabView] disableTabCloseForTabViewItem:[cell representedObject]]))];
        if (i < [widths count]) {
            tabState = 0;
            
            // set cell frame
            if ([_control orientation] == PSMTabBarHorizontalOrientation) {
                cellRect.size.width = [[widths objectAtIndex:i] floatValue];
            } else {
                cellRect.size.width = [_control frame].size.width;
                cellRect.origin.y = [[widths objectAtIndex:i] floatValue];
                cellRect.origin.x = 0;
            }
            
            [_cellFrames addObject:[NSValue valueWithRect:cellRect]];
            
            //add tracking rects to arrays
            [_closeButtonTrackingRects addObject:[NSValue valueWithRect:[cell closeButtonRectForFrame:cellRect]]];
            [_cellTrackingRects addObject:[NSValue valueWithRect:cellRect]];
            
            if ([[cell representedObject] isEqualTo:selectedTabViewItem]) {
                [cell setState:NSOnState];
                tabState |= PSMTab_SelectedMask;
                // previous cell
                if (i > 0) {
                    [[cells objectAtIndex:i - 1] setTabState:([(PSMTabBarCell *)[cells objectAtIndex:i - 1] tabState] | PSMTab_RightIsSelectedMask)];
                }
                // next cell - see below
            } else {
                [cell setState:NSOffState];
                // see if prev cell was selected
                if ( (i > 0) && ([[cells objectAtIndex:i - 1] state] == NSOnState) ) {
                    tabState |= PSMTab_LeftIsSelectedMask;
                }
            }
            
            // more tab states
            if ([widths count] == 1) {
                tabState |= PSMTab_PositionLeftMask | PSMTab_PositionRightMask | PSMTab_PositionSingleMask;
            } else if (i == 0) {
                tabState |= PSMTab_PositionLeftMask;
            } else if (i == [widths count] - 1) {
                tabState |= PSMTab_PositionRightMask;
            }
            
            [cell setTabState:tabState];
            [cell setIsInOverflowMenu:NO];
            
            // indicator
            if (![[cell indicator] isHidden] && ![_control isTabBarHidden]) {
				if (![[_control subviews] containsObject:[cell indicator]]) {
                    [_control addSubview:[cell indicator]];
                    [[cell indicator] startAnimation:self];
                }
            }
            
            // next...
            cellRect.origin.x += [[widths objectAtIndex:i] floatValue];
        } else {
            [cell setState:NSOffState];
            [cell setIsInOverflowMenu:YES];
            [[cell indicator] removeFromSuperview];
            
			//position the cell well offscreen
			if ([_control orientation] == PSMTabBarHorizontalOrientation) {
				cellRect.origin.x += [[_control style] rightMarginForTabBarControl] + 20;
			} else {
				cellRect.origin.y = [_control frame].size.height + 2;
			}
			
            [_cellFrames addObject:[NSValue valueWithRect:cellRect]];
            
            if (_overflowMenu == nil) {
                _overflowMenu = [[NSMenu alloc] init];
                [_overflowMenu insertItemWithTitle:@"" action:nil keyEquivalent:@"" atIndex:0]; // Because the overflowPupUpButton is a pull down menu
            }
            
            menuItem = [_overflowMenu addItemWithTitle:[[cell attributedStringValue] string] action:@selector(overflowMenuAction:) keyEquivalent:@""];
            [menuItem setTarget:_control];
            [menuItem setRepresentedObject:[cell representedObject]];
            
            if ([cell count] > 0) {
                [menuItem setTitle:[[menuItem title] stringByAppendingFormat:@" (%d)", [cell count]]];
			}
        }
    }
}

@end

/*
PSMTabBarController will store what the current tab frame state should be like based off the last layout. PSMTabBarControl
has to handle fetching the new frame and then changing the tab cell frame.
    Tab states will probably be changed immediately.

Tabs that aren't going to be visible need to have their frame set offscreen. Treat them as if they were visible.

The overflow menu is rebuilt and stored by the controller.

Arrays of tracking rects will be created here, but not applied.
    Tracking rects are removed and added by PSMTabBarControl at the end of an animate/display cycle.

The add tab button frame is handled by this controller. Visibility and location are set by the control.

isInOverflowMenu should probably be removed in favor of a call that returns yes/no to if a cell is in overflow. (Not yet implemented)

Still need to rewrite most of the code in PSMTabDragAssistant.
*/
