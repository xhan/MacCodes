#import "AppDelegate.h"

#import "ZDSMigrationHandler.h"

@implementation AppDelegate

- (id)init;
{
    if (![super init]) return nil;
    
    totalEntities = 3;
    currentEntityIndex = 0;
    totalInstances = 1000;
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

- (IBAction)startMigration:(id)sender;
{
    //Find the new model path
    NSString *modelFilePath = [[NSBundle mainBundle] pathForResource:@"TestModel" ofType:@"mom"];
    
    [ZDSMigrationHandler migrateContext:[self managedObjectContext] toModelAtPath:modelFilePath withDelegate:self];
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
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:databaseURL options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    
    
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *) managedObjectContext;
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
    
    return entityA;
}

- (void)populateDatabase;
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    //Populate the database.
    [NSApp beginSheet:waitSheet modalForWindow:progressWindow modalDelegate:nil didEndSelector:NULL contextInfo:nil];
    srandom([NSDate timeIntervalSinceReferenceDate]);
    int count;
    for (count = 0; count < 1000; ++count) {
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
    [moc save:&error];
    [waitSheet orderOut:nil];
    [NSApp endSheet:waitSheet];
}

@end
