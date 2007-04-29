pxmLib is a set of utilities for reading and understanding 'pxm#' resources. These resources are used by Mac OS X, through Tiger, for storage of system-wide images used in constructing the Aqua user interface. If you want to borrow these images without using Appearance Manager or HITheme (especially if neither of those will do what you want), then this set of functions is for you.

The functions were originally authored by Blackhole Media in 2001. Six years later, Peter Hosey and Colin Barrett (that's us!) salvaged it and began upgrading it for modern Macs and modern APIs.

We knew about it from its use in the Adium 1.0 codebase, where it was used to retrieve the close-box image for use by Adium's tabs. That version was trimmed and reformatted from the Blackhole Media original by Adam Iser. The version here is derived from that original, which I (PRH) retrieved from Blackhole's resource editor “Sprocket”, version d5, thanks to the Internet Wayback Machine.

The Cocoa API consists of a category on NSImage that returns one image from the data of a 'pxm#' resource. We have also added compatibility with Intel processors (the original pxmLib assumed big-endian, since all Macs at that time were big-endian).

A test app is included. This is a command-line utility that accepts a filename (to a .rsrc file) and a resource ID. It retrieves the 'pxm#' resource with that ID from that file, creates an NSImage using the category, and writes TIFF data for the image to stdout. The TIFF data includes all of the images from the 'pxm#' resource.

pxmLib was originally authored by Blackhole Media <http://blackholemedia.com/code>.
Intel compatibility and Cocoa functionality have been provided by Peter Hosey and Colin Barrett.
