// AppDelegate.m
// ZDSMigration Framework
//
// Copyright (c) 2007, Zarra Studios LLC
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of Zarra Studios LLC nor the names of its contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "AppDelegate.h"

#import "ZDSMigrationHandler.h"
#import "ExampleMigrationHelper.h"

@implementation AppDelegate

- (id)init;
{
    if (![super init]) return nil;
    
    persistentStoreCoordinator = nil;
    managedObjectModel = nil;
    managedObjectContext = nil;
    
    currentEntityName = @"Preparing Migration...";
    
    totalEntities = 3;
    currentEntityIndex = 0;
    totalInstances = 100;
    currentInstanceIndex = 0;
    
    return self;
}

- (void) dealloc;
{
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
    [entityIndicator setUsesThreadedAnimation:YES];
    [instanceIndicator setUsesThreadedAnimation:YES];
    
    NSManagedObjectContext *moc = [self managedObjectContext];
    NSAssert(moc != nil, @"MOC is nil");
    //Check to see if there is any data in this database
    NSManagedObjectModel *mom = [self managedObjectModel];
    NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];
    [fetch setEntity:[[mom entities] objectAtIndex:0]];
    NSError *error;
    NSArray *results = [moc executeFetchRequest:fetch error:&error];
    NSAssert(results != nil, ([NSString stringWithFormat:@"Error on fetch: %@", error]));
    if ([results count] > 0) return; //There is already data in place
    [self performSelector:@selector(populateDatabase) withObject:nil afterDelay:0.01];
}

#pragma mark -
#pragma mark Migration Delegate calls

- (void)migrationCompletedSuccessfully:(id)migrationHandler;
{
    [progressWindow orderOut:nil];
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Migration successful"];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    [NSApp terminate:self];
}

- (void)migrationFailed:(id)migrationHandler;
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Migration failed"];
    [alert setInformativeText:[[migrationHandler error] localizedDescription]];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    [NSApp terminate:self];
}

- (void)migrationUpdate:(id)migrationHandler;
{
    [entityIndicator setMaxValue:[migrationHandler totalEntities]];
    [entityIndicator setDoubleValue:[migrationHandler currentEntityIndex]];
    [instanceIndicator setMaxValue:[migrationHandler totalInstances]];
    [instanceIndicator setDoubleValue:[migrationHandler currentInstanceIndex]];
    [self setCurrentEntityName:[migrationHandler currentEntityName]];
}

#pragma mark -
#pragma mark accessors

- (NSString *)currentEntityName
{
    return [[currentEntityName retain] autorelease]; 
}

- (void)setCurrentEntityName:(NSString *)aCurrentEntityName
{
    [currentEntityName release];
    currentEntityName = [aCurrentEntityName copy];
}

#pragma mark -
#pragma mark GUI Handlers

- (IBAction)startMigration:(id)sender;
{
    //Find the new model path
    NSString *newModelFilePath = [[NSBundle mainBundle] pathForResource:@"UpgradeModel" ofType:@"mom"];
    NSString *oldModelFilePath = [[NSBundle mainBundle] pathForResource:@"TestModel" ofType:@"mom"];
    
    ZDSMigrationHandler *handler = [[ZDSMigrationHandler alloc] initWithDelegate:self];
    [handler setPathToModelToMigrateFrom:oldModelFilePath];
    [handler setPathToModelToMigrateTo:newModelFilePath];
    [handler setPathForFileToMigrate:[[self applicationSupportFolder] stringByAppendingPathComponent:@"Test.zds"]];
    [handler setWarnings:YES];
    [handler setThreaded:YES];
    [handler setMigrationHelper:[[[ExampleMigrationHelper alloc] init] autorelease]];
    [handler startMigration];
}

- (NSString*)applicationSupportFolder;
{
    NSString *temp = NSTemporaryDirectory();
    NSLog(@"%@", temp);
    return temp;
}

- (NSManagedObjectModel*)managedObjectModel;
{
    if (managedObjectModel) return managedObjectModel;

    NSString *modelFilePath = [[NSBundle mainBundle] pathForResource:@"TestModel" ofType:@"mom"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelFilePath];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator;
{
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
    
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    databaseURL = [[NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:@"Test.zds"]] retain];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    id store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                        configuration:nil
                                                                  URL:databaseURL
                                                              options:nil
                                                                error:&error];
    if (!store) {
        [[NSApplication sharedApplication] presentError:error];
    }    
    
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext*)managedObjectContext;
{
    if (managedObjectContext) return managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) return nil;

    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return managedObjectContext;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;
{
    return [[self managedObjectContext] undoManager];
}

- (IBAction) saveAction:(id)sender;
{
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
{
    /*
    if (!managedObjectContext) return NSTerminateNow;
    if (![managedObjectContext commitEditing]) return NSTerminateCancel;
    if (![managedObjectContext hasChanges]) return NSTerminateNow;
    
    NSError *error;
    if ([managedObjectContext save:&error]) return NSTerminateNow;
    NSLog(@"Save failed: %@", error);
    BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
        
    if (errorResult == YES) return NSTerminateCancel;
        
    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
    if (alertReturn == NSAlertAlternateReturn) return NSTerminateCancel;
    */
    [[NSFileManager defaultManager] removeFileAtPath:[databaseURL path] handler:nil];
    NSLog(@"%@:%s database removed", [self class], _cmd);
    return NSTerminateNow;
}

- (id)createEntity:(NSString*)entityName inContext:(NSManagedObjectContext*)moc;
{
    id entityA = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:moc];
    
    [entityA setValue:[[NSProcessInfo processInfo] globallyUniqueString] forKey:@"data1"];
    [entityA setValue:[[NSProcessInfo processInfo] globallyUniqueString] forKey:@"data2"];
    [entityA setValue:[[NSProcessInfo processInfo] globallyUniqueString] forKey:@"data3"];
    [entityA setValue:[[NSProcessInfo processInfo] globallyUniqueString] forKey:@"data4"];
    [entityA setValue:[[NSProcessInfo processInfo] globallyUniqueString] forKey:@"data5"];
    
    [entityA setValue:[NSNumber numberWithDouble:(random())] forKey:@"number1"];
    
    return entityA;
}

- (void)populateDatabase;
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    //Populate the database.
    [NSApp beginSheet:waitSheet modalForWindow:progressWindow modalDelegate:nil didEndSelector:NULL contextInfo:nil];
    srandom([NSDate timeIntervalSinceReferenceDate]);
    int count;
    for (count = 0; count < 100; ++count) {
        id entityA = [self createEntity:@"EntityA" inContext:moc];
        
        int countB;
        int totalB = (random() % 4) + 1;
        for (countB = 0; countB < totalB; ++countB) {
            id entityB = [self createEntity:@"EntityB" inContext:moc];
            [entityB setValue:entityA forKey:@"entityA"];
            
            int countC;
            int totalC = (random() % 10) + 1;
            for (countC = 0; countC < totalC; ++countC) {
                id entityC = [self createEntity:@"EntityC" inContext:moc];
                [entityC setValue:entityB forKey:@"entityB"];
            }
        }
    }
    
    NSError *error;
    NSAssert([moc save:&error], ([NSString stringWithFormat:@"Error saving context: %@", error]));
    
    [waitSheet orderOut:nil];
    [NSApp endSheet:waitSheet];
    
    //Drop the Core Data Stack
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
}    

@end
