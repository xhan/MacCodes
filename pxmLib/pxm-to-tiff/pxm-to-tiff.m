#import <Cocoa/Cocoa.h>
#import "NSImage+FrompxmArray.h"

int main(int argc, char **argv) {
	if(argc != 3) {
		fprintf(stderr, "Usage: %s pathname res-ID > foo.tiff\n", argc > 0 ? argv[0] : "pxm-to-TIFF");
		return EXIT_FAILURE;
	}

	//The pool is *NOT* closed! -CB
	//No lifeguard on duty —PRH
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	//Open our resource file
	FSRef inputFileRef;
	Boolean isDirectory_unused;
	FSPathMakeRef(argv[1], &inputFileRef, &isDirectory_unused);
	short resFileHandle = FSOpenResFile(&inputFileRef, fsRdPerm);
	OSStatus err = FSOpenResourceFile(
		&inputFileRef,
		//A fork name of "" means the data fork.
		/*forkNameLength*/ 0U,
		/*forkName*/ NULL,
		fsRdPerm,
		&resFileHandle);
	if(resFileHandle < 0) {
		fprintf(stderr, "%s: FSOpenResFile failed: %s\n", argc > 0 ? argv[0] : "pxm-to-TIFF", GetMacOSStatusCommentString(err));
		return EXIT_FAILURE;
	}

	//Get the requested pxm# resource
	Handle pxmH = Get1Resource(FOUR_CHAR_CODE('pxm#'), strtol(argv[2], NULL, 10));
	if(!pxmH) {
		err = ResError();
		fprintf(stderr, "%s: Get1Resource failed: %s\n", argc > 0 ? argv[0] : "pxm-to-TIFF", GetMacOSStatusCommentString(err));
		return EXIT_FAILURE;
	}

	//From one container into another
	NSData *pxmData = [NSData dataWithBytes:*pxmH length:GetHandleSize(pxmH)];
	[pxmData writeToFile:[NSString stringWithFormat:@"pxm#-%li.pxma", strtol(argv[2], NULL, 10)] atomically:NO];

	//Take the pxm# bytes and create an NSImage
	NSImage *image = [NSImage imageFrompxmArrayData:pxmData];
	if (!image) {
		fprintf(stderr, "%s: Unable to create image from data\n", argc > 0 ? argv[0] : "pxm-to-TIFF");
		return EXIT_FAILURE;
	}
	NSLog(@"image has %u representations", [[image representations] count]);

	//Write it out to disk
	[(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:[image TIFFRepresentation]];

	//Clean up
	ReleaseResource(pxmH);
	CloseResFile(resFileHandle);
	[pool release];
	return EXIT_SUCCESS;
}
