#import "ZDSMigrationHandler.h"
#import "ZDSManagedObject.h"

@interface ZDSMigrationHandler (private)

- (void)setOldContext:(NSManagedObjectContext*)context;
- (void)setNewModel:(NSManagedObjectModel*)model;
- (void)performMigration;
- (BOOL)saveAndFlush:(NSError**)error;

@end

static int const kSaveMarker = 1000;
static SEL kSELmigrationCompleted;
static SEL kSELmigrationFailed;
static SEL kSELmigrationUpdate;
static SEL kSELmigrationProgress;

@implementation ZDSMigrationHandler (private)

- (void)setOldContext:(NSManagedObjectContext*)context;
{
    [context retain];
    [oldContext release];
    oldContext = context;
}

- (void)setNewModel:(NSManagedObjectModel*)model;
{
    [model retain];
    [newModel release];
    newModel = model;
    //Release all of the relationship constraints now
    modelWithoutConstraints = [newModel copy];
    NSEnumerator *entityEnum = [[modelWithoutConstraints entities] objectEnumerator];
    NSEntityDescription *entity;
    while (entity = [entityEnum nextObject]) {
        NSEnumerator *relationshipEnum = [[[entity relationshipsByName] allKeys] objectEnumerator];
        NSRelationshipDescription *relationship;
        NSString *relationshipKey;
        while (relationshipKey = [relationshipEnum nextObject]) {
            relationship = [[entity relationshipsByName] valueForKey:relationshipKey];
            [relationship setOptional:YES];
        }
    }
    
    NSPersistentStoreCoordinator *store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:modelWithoutConstraints];
    if (![store addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:tempFileURL options:nil error:&error]) {
        NSLog(@"Error creating new store: %@", error);
        @throw [NSException exceptionWithName:@"Migration Error" reason:[error localizedDescription] userInfo:nil];
    }
    
    newContext = [[NSManagedObjectContext alloc] init];
    [newContext setPersistentStoreCoordinator:store];
    [store release];
}

- (BOOL)saveAndFlush:(NSError**)incomingError;
{
    //Capture what needs to be faulted
    NSMutableArray *toFlushArray = [NSMutableArray array];
    [toFlushArray addObjectsFromArray:[[newContext insertedObjects] allObjects]];
    [toFlushArray addObjectsFromArray:[[newContext updatedObjects] allObjects]];
    //Save the context so we can flush it
    if (![newContext save:incomingError]) return NO;
    //Loop and fault
    NSEnumerator *toFlushEnum = [toFlushArray objectEnumerator];
    ZDSManagedObject *newEntity;
    while (newEntity = [toFlushEnum nextObject]) {
        [newContext refreshObject:newEntity mergeChanges:NO];
    }
    return YES;
}

- (void)performMigration;
{
    NSDictionary *oldEntityDict = [[[oldContext persistentStoreCoordinator] managedObjectModel] entitiesByName];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSEnumerator *entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    unsigned objectCounter = 0;
    
    NSMutableDictionary *newEntitiesReference = [[NSMutableDictionary alloc] init];
    while (currentEntityName = [entityNamesEnum nextObject]) {
        if (![[newModel entitiesByName] valueForKey:currentEntityName]) continue;
        
        NSEntityDescription *entityDescription = [oldEntityDict valueForKey:currentEntityName];
        if ([entityDescription isAbstract]) continue;
        if ([NSClassFromString([entityDescription managedObjectClassName]) isKindOfClass:[ZDSManagedObject class]]) {
            NSLog(@"Skipping: %@", currentEntityName);
            continue;
        }
        
        [request setEntity:entityDescription];
        
        NSArray *oldEntities = [oldContext executeFetchRequest:request error:&error];
        totalObjectsForEntity = [oldEntities count];
        if (!totalObjectsForEntity) {
            [newEntitiesReference release], newEntitiesReference = nil;
            [pool release], pool = nil;
            @throw [NSException exceptionWithName:@"Migration Failed" 
                                           reason:[error localizedDescription] 
                                         userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
        }
        
        if (!totalObjectsForEntity) continue;
        
        if ([delegate respondsToSelector:kSELmigrationUpdate]) {
            [delegate performSelectorOnMainThread:kSELmigrationUpdate withObject:self waitUntilDone:NO];
        }
        
        unsigned migrationUpdateMarker = ((totalObjectsForEntity / 10) < 2 ? 2 : (totalObjectsForEntity / 10));
        currentObjectIndex = 0;
        
        NSEnumerator *oldEntitiesEnum = [[oldEntities objectEnumerator] retain];
        ZDSManagedObject *oldEntity = nil;
        while (oldEntity = [oldEntitiesEnum nextObject]) {
            if ([oldEntity orphan]) continue;
            ZDSManagedObject *newEntity = [NSEntityDescription insertNewObjectForEntityForName:currentEntityName
                                                                        inManagedObjectContext:newContext];
            if (currentObjectIndex % migrationUpdateMarker == 0 && [delegate respondsToSelector:kSELmigrationProgress]) {
                [delegate performSelectorOnMainThread:kSELmigrationProgress withObject:self waitUntilDone:NO];
            }
            [newEntity copyFromManagedObject:oldEntity];
            [newEntity copyRelationshipsFromManagedObject:oldEntity withReference:newEntitiesReference];
            [oldEntity fault];
            [newEntitiesReference setValue:newEntity forKey:[oldEntity objectIDString]];
            
            ++objectCounter;
            ++currentObjectIndex;

            if (objectCounter % kSaveMarker != 0) continue;
            
            if (![self saveAndFlush:&error]) {
                NSLog(@"Save Error: %@", error);
                [newEntitiesReference release], newEntitiesReference = nil;
                [oldEntitiesEnum release], oldEntitiesEnum = nil;
                [pool release], pool = nil;
                @throw [NSException exceptionWithName:@"Migration Failed"
                                               reason:[error localizedDescription]
                                             userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
            }

            [pool release];
            pool = [[NSAutoreleasePool alloc] init];
        }
        [oldEntitiesEnum release], oldEntitiesEnum = nil;
    }
    [newEntitiesReference release], newEntitiesReference = nil;
    
    if (![newContext save:&error]) {
        NSLog(@"Save Error: %@", error);
        [pool release], pool = nil;
        @throw [NSException exceptionWithName:@"Migration Failed" 
                                       reason:[error localizedDescription] 
                                     userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
    }
    [pool release], pool = nil;
}

- (void)kickOffMigrationInNewThread;
{
    @try {
        [ZDSManagedObject setZdsMigrationActive:YES];
        [self performMigration];
        [delegate performSelectorOnMainThread:kSELmigrationCompleted withObject:self waitUntilDone:NO];
    } @catch (NSException *exception) {
        if ([delegate respondsToSelector:kSELmigrationFailed]) {
            [delegate performSelectorOnMainThread:kSELmigrationFailed withObject:self waitUntilDone:NO];
        } else {
            NSError *exceptionerror = [[exception userInfo] valueForKey:@"error"];
            NSLog(@"%@:%s Failure in migration: %@\n%@", [self class], _cmd, exception, exceptionerror);
        }
    } @finally {
        [ZDSManagedObject setZdsMigrationActive:NO];
        [NSThread exit];
    }
    //[self performSelectorOnMainThread:@selector(autorrelease) withObject:nil waitUntilDone:NO];
}

@end

@implementation ZDSMigrationHandler

+ (void)initialize 
{
    kSELmigrationCompleted = @selector(migrationCompletedSuccessfully:);
    kSELmigrationFailed = @selector(migrationFailed:);
    kSELmigrationUpdate = @selector(migrationUpdate:);
    kSELmigrationProgress = @selector(migrationProgress:);
}

+ (void)migrateContext:(NSManagedObjectContext*)oldContext
               toModel:(NSManagedObjectModel*)model
          withDelegate:(id)delegate
               context:(void*)contextInfo;
{
    id migrationHandler = [[ZDSMigrationHandler alloc] init];
    
    [migrationHandler setValue:delegate forKey:@"delegate"];
    [migrationHandler setValue:contextInfo forKey:@"contextInfo"];
    [migrationHandler setNewModel:model];
    [migrationHandler setOldContext:oldContext];
    
    [NSThread detachNewThreadSelector:@selector(kickOffMigrationInNewThread) 
                             toTarget:migrationHandler 
                           withObject:nil];
}

- (id)init
{
    if (![super init]) return nil;
    
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
    tempFileURL = [[NSURL alloc] initFileURLWithPath:tempFilename];
    NSLog(@"%@:%s TempFile: %@", [self class], _cmd, tempFilename);
    
    return self;
}

- (void)dealloc
{
    [delegate release], delegate = nil;
    [newModel release], newModel = nil;
    [oldContext release], oldContext = nil;
    [tempFileURL release], tempFileURL = nil;
    [newContext release], newContext = nil;
    [modelWithoutConstraints release], modelWithoutConstraints = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (NSString*)tempFilePath;
{
    return [tempFileURL path];
}

- (NSError*)error;
{
    return error;
}

- (id)contextInfo;
{
    return contextInfo;
}

- (NSString*)currentEntityName;
{
    return currentEntityName;
}

- (unsigned)currentObjectIndex;
{
    return currentObjectIndex;
}

- (unsigned)totalObjectsForEntity;
{
    return totalObjectsForEntity;
}

@end
