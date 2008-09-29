//
//  ESSImageCategory.m
//
//  Created by Matthias Gansrigler on 1/24/07.
//

#import "ESSImageCategory.h"

@implementation NSImage (ESSImageCategory)

- (NSData* )representationForFileType: (NSBitmapImageFileType) fileType 
{
	NSData *temp = [self TIFFRepresentation];
	NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:temp];
	NSData *imgData = [bitmap representationUsingType:fileType properties:nil];
	return imgData;
}

- (NSData *)JPEGRepresentation
{
	return [self representationForFileType: NSJPEGFileType];
}

- (NSData *)PNGRepresentation
{
	return [self representationForFileType: NSPNGFileType];
}

- (NSData *)JPEG2000Representation
{
	return [self representationForFileType: NSJPEG2000FileType];	
}

- (NSData *)GIFRepresentation
{
	return [self representationForFileType: NSGIFFileType];	
}

- (NSData *)BMPRepresentation
{
	return [self representationForFileType: NSBMPFileType];		
}

@end
