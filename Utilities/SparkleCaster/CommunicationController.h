//
//  communicationController.h
//  SparkleCaster
//
//  Created by Adam Radestock on 29/10/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Connection/Connection.h>

static NSString *GMUsernameKey = @"UsernameKey";
static NSString *GMPasswordKey = @"PasswordKey";
static NSString *GMInitialDirectoryKey = @"InitialDirectoryKey";

@interface CommunicationController : NSObject {

	IBOutlet NSTextField			*statusTextField;
	IBOutlet NSProgressIndicator	*progressIndicator;
	
}

@end
