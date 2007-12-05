//
//  communicationController.h
//  SparkleCaster
//
//  Created by Adam Radestock on 29/10/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <CoreServices/CoreServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <sys/dirent.h>
#import <sys/stat.h>
#import <unistd.h>         // getopt
#import <string.h>         // strmode
#import <stdlib.h>
#import <inttypes.h>

#import "CCStreamInfo.h"

static NSString *GMUsernameKey = @"UsernameKey";
static NSString *GMPasswordKey = @"PasswordKey";
static NSString *GMInitialDirectoryKey = @"InitialDirectoryKey";

@interface CommunicationController : NSObject {

	IBOutlet NSTextField			*statusTextField;
	IBOutlet NSProgressIndicator	*progressIndicator;
	
}

- (void)downloadFileAtURL:(NSURL *)remoteURL toPath:(NSURL *)localPath withOptions:(NSDictionary *)optionsDict;
- (void) downloadCallbackFromStream:(CFReadStreamRef)readStream withEvent:(CFStreamEventType) type andGMStreamController:(GMStreamController *)streamController;
- (void)testConnectionToServer:(NSString *)serverAddress withOptions:(NSDictionary *)optionsDict;

@end
