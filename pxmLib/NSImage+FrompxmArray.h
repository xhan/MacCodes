#include <Carbon/Carbon.h>
#import "pxmLib.h"
#import <Cocoa/Cocoa.h>

@interface NSImage (CBPRHFrompxmArray)

+ (NSImage *)imageFrompxmArrayData:(NSData *)data;

@end
