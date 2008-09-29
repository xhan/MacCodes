//
//  ESSImageCategory.h
//
//  Created by Matthias Gansrigler on 1/24/07.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (ESSImageCategory)
- (NSData *)JPEGRepresentation;
- (NSData *)JPEG2000Representation;
- (NSData *)PNGRepresentation;
- (NSData *)GIFRepresentation;
- (NSData *)BMPRepresentation;
@end
