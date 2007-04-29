CFLAGS+=-std=c99 -I.. -g
LDFLAGS+=-framework Cocoa -framework Carbon

pxm-to-tiff: pxm-to-tiff.o ../NSImage+FrompxmArray.o ../pxmLib.o
pxm-to-tiff2: pxm-to-tiff2.o ../NSImage+FrompxmArray.o ../pxmLib.o

.PHONY: clean
clean:
	-rm *.o
	-rm pxm-to-tiff
