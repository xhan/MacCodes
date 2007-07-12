#import "ZDSMigrationHandler.h"
#import "ZDSManagedObject.h"

@interface ZDSMigrationHandler (private)

- (void)performMigration;
- (void)initializeNewContext;

@end

static int const kSaveMarker = 500;
static SEL kSELmigrationCompleted;
static SEL kSELmigrationFailed;
static SEL kSELmigrationUpdate;
static SEL kSELmigrationProgress;
static SEL kSELmigrationStage;

@implementation ZDSMigrationHandler (private)

- (void)initializeNewContext;
{
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tempFilename = NSTemporaryDirectory();
    tempFilename = [tempFilename stringByAppendingPathComponent:guid];
    tempFileURL = [[NSURL fileURLWithPath:tempFilename] retain];
    NSLog(@"%@:%s TempFile: %@", [self class], _cmd, tempFilename);
    
    //Release all of the relationship constraints now
    noRelationshipModel = [newModel copy];
    NSEnumerator *entityEnum = [[noRelationshipModel entities] objectEnumerator];
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
    
    NSError *error;
    NSPersistentStoreCoordinator *store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:noRelationshipModel];
    if (![store addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:tempFileURL options:nil error:&error]) {
        NSLog(@"Error creating new store: %@", error);
        @throw [NSException exceptionWithName:@"Migration Error" reason:[error localizedDescription] userInfo:nil];
    }
    
    newContext = [[NSManagedObjectContext alloc] init];
    [newContext setPersistentStoreCoordinator:store];
    [store release];
}

- (NSDictionary*)copyAttributes;
{
    NSDictionary *oldEntityDict = [[[oldContext persistentStoreCoordinator] managedObjectModel] entitiesByName];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEnumerator *entityNamesEnum = [[[oldEntityDict allKeys] objectEnumerator] retain];
    NSMutableDictionary *newEntitiesReference = [[NSMutableDictionary alloc] init];
    NSMutableArray *oldObjectsToFlush = [[NSMutableArray alloc] init];
    @try {
        NSError *error = nil;
        ZDSManagedObject* oldEntity = nil;
        ZDSManagedObject* newEntity = nil;
        
        unsigned objectCounter = 0;
        
        if ([delegate respondsToSelector:kSELmigrationStage]) {
            [delegate migrationStage:self stage:NSLocalizedString(@"Attributes", @"attribute migration stage name") context:contextInfo];
        }
        NSLog(@"Doing attributes pass");
        NSString *currentEntityName;
        while (currentEntityName = [entityNamesEnum nextObject]) {
            if (![[newModel entitiesByName] valueForKey:currentEntityName]) {
                NSLog(@"\tSkipping: %@", currentEntityName);
                continue;
            }
            NSEntityDescription *entityDescription = [oldEntityDict valueForKey:currentEntityName];
            if ([entityDescription isAbstract]) {
                NSLog(@"\tAbstract: %@", currentEntityName);
                continue;
            }
            if ([NSClassFromString([entityDescription managedObjectClassName]) isKindOfClass:[ZDSManagedObject class]]) {
                NSLog(@"\tNot a ZDSManagedObject: %@", currentEntityName);
                continue;
            }
            NSLog(@"\tEntity: %@", currentEntityName);
            [request setEntity:[oldEntityDict valueForKey:currentEntityName]];
            
            error = nil;
            NSArray *oldEntities = [[oldContext executeFetchRequest:request error:&error] retain];
            if (error) {
                [oldEntities release], oldEntities = nil;
                @throw [NSException exceptionWithName:@"Migration Failed" 
                                               reason:[error localizedDescription] 
                                             userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
            }
            
            if (![oldEntities count]) continue;
            if ([delegate respondsToSelector:kSELmigrationUpdate]) {
                [delegate migrationUpdate:self entity:currentEntityName count:[oldEntities count] context:contextInfo];
            }
            int migrationUpdateMarker = [oldEntities count] / 10;
            unsigned migrationCounter = 0;
            
            NSEnumerator *oldEntitiesEnum = [[oldEntities objectEnumerator] retain];
            
            while (oldEntity = [oldEntitiesEnum nextObject]) {
                if ([oldEntity orphan]) continue;
                newEntity = [NSEntityDescription insertNewObjectForEntityForName:currentEntityName inManagedObjectContext:newContext];
                ++objectCounter;
                ++migrationCounter;
                if (migrationCounter % migrationUpdateMarker == 0 && [delegate respondsToSelector:kSELmigrationProgress]) {
                    [delegate migrationProgress:self currentCount:migrationCounter context:contextInfo];
                }
                [oldObjectsToFlush addObject:oldEntity];
                [newEntity copyFromManagedObject:oldEntity];
                [newEntitiesReference setValue:newEntity forKey:[[[oldEntity objectID] URIRepresentation] absoluteString]];
                if (objectCounter % kSaveMarker == 0) {
                    NSLog(@"Save fired: %u", objectCounter);
                    error = nil;
                    if (![newContext save:&error]) {
                        [oldEntitiesEnum release], oldEntitiesEnum = nil;
                        [oldEntities release], oldEntities = nil;
                        @throw [NSException exceptionWithName:@"Migration Failed" reason:[error localizedDescription] userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
                    }
                    NSEnumerator *toFlushEnum = [[newContext insertedObjects] objectEnumerator];
                    NSManagedObject *entity;
                    while (entity = [toFlushEnum nextObject]) {
                        [newContext refreshObject:entity mergeChanges:NO];
                    }
                    toFlushEnum = [oldObjectsToFlush objectEnumerator];
                    while (entity = [toFlushEnum nextObject]) {
                        [oldContext refreshObject:entity mergeChanges:NO];
                    }
                    [oldObjectsToFlush removeAllObjects];
                    //Pop the autorelease pool
                    [pool release];
                    pool = [[NSAutoreleasePool alloc] init];
                }
            }
            [oldEntitiesEnum release], oldEntitiesEnum = nil;
            [oldEntities release], oldEntities = nil;
        }
        
        
        NSLog(@"Saving the new context");
        error = nil;
        if (![newContext save:&error]) {
            @throw [NSException exceptionWithName:@"Migration Failed" reason:[error localizedDescription] userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
        }
        return newEntitiesReference;
    } @finally {
        [entityNamesEnum release], entityNamesEnum = nil;
        [request release], request = nil;
        [pool release], pool = nil;
        [newEntitiesReference autorelease];
    }
}

- (void)performMigration;
{
    [ZDSManagedObject setZdsMigrationActive:YES];
    [self initializeNewContext];
    
    NSDictionary *entityLookup = [self copyAttributes];
    NSLog(@"count: %u", [[entityLookup allKeys] count]);
    
    NSLog(@"%@:%s Phase one complete", [self class], _cmd);
    /*
    if ([delegate respondsToSelector:kSELmigrationStage]) {
        [delegate migrationStage:self stage:NSLocalizedString(@"Relationships", @"relationship migration stage name") context:contextInfo];
    }
    NSLog(@"Doing relationships pass");
    entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
    objectCounter = 0;
    while (currentEntityName = [entityNamesEnum nextObject]) {
        NSLog(@"\tEntity: %@", currentEntityName);
        [request setEntity:[oldEntityDict valueForKey:currentEntityName]];
        
        error = nil;
        NSArray *oldEntities = [oldContext executeFetchRequest:request error:&error];
        if (error) {
            @throw [NSException exceptionWithName:@"Migration Failed" 
                                           reason:[error localizedDescription] 
                                         userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
        }
        
        if (![oldEntities count]) continue;
        
        int migrationUpdateMarker = [oldEntities count] / 10;
        unsigned migrationCounter = 0;
        
        NSEnumerator *oldEntitiesEnum = [oldEntities objectEnumerator];
        
        while (oldEntity = [oldEntitiesEnum nextObject]) {
            newEntity = [newEntitiesReference valueForKey:[[[oldEntity objectID] URIRepresentation] absoluteString]];
            ++objectCounter;
            ++migrationCounter;
            if (migrationCounter % migrationUpdateMarker == 0 && [delegate respondsToSelector:kSELmigrationProgress]) {
                [delegate migrationProgress:self currentCount:migrationCounter context:contextInfo];
            }
            [newEntity copyRelationshipsFromManagedObject:oldEntity withReference:newEntitiesReference];
            if (objectCounter % kSaveMarker == 0) {
                NSLog(@"Save fired: %u", objectCounter);
            }
        }
    }
    
    NSLog(@"Saving the new context");
    error = nil;
    if (![newContext save:&error]) {
        @throw [NSException exceptionWithName:@"Migration Failed" reason:[error localizedDescription] userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
    }
    
    [newEntitiesReference release], newEntitiesReference = nil;
    //release the temporary context
    [newContext release], newContext = nil;
    
    if ([delegate respondsToSelector:kSELmigrationStage]) {
        [delegate migrationStage:self stage:NSLocalizedString(@"Validation", @"validation migration stage name") context:contextInfo];
    }
    NSLog(@"Validating new context");
    error = nil;
    NSPersistentStoreCoordinator *store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:newModel];
    if (![store addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:tempFileURL options:nil error:&error]) {
        @throw [NSException exceptionWithName:@"Migration Failed" 
                                       reason:[error localizedDescription] 
                                     userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
    }
    
    NSManagedObjectContext *validateContext = [[NSManagedObjectContext alloc] init];
    [validateContext setPersistentStoreCoordinator:store];
    [store release];
    
    NSDictionary *newEntitiesByName = [newModel entitiesByName];
    entityNamesEnum = [[newEntitiesByName allKeys] objectEnumerator];
    
    objectCounter = 0;
    
    while (currentEntityName = [entityNamesEnum nextObject]) {
        NSLog(@"\tEntity: %@", currentEntityName);
        [request setEntity:[newEntitiesByName valueForKey:currentEntityName]];

        error = nil;
        NSArray *entities = [validateContext executeFetchRequest:request error:&error];
        NSAssert(error == nil, ([NSString stringWithFormat:@"Error retrieving entity %@:%@", currentEntityName, error]));
        if (![entities count]) continue;
        
        int migrationUpdateMarker = [entities count] / 10;
        unsigned migrationCounter = 0;
        
        NSEnumerator *entitiesEnum = [entities objectEnumerator];
        
        while (newEntity = [entitiesEnum nextObject]) {
            error = nil;
            ++migrationCounter;
            ++objectCounter;
            if (migrationCounter % migrationUpdateMarker == 0 && [delegate respondsToSelector:kSELmigrationProgress]) {
                [delegate migrationProgress:self currentCount:migrationCounter context:contextInfo];
            }
            if (![newEntity validateForUpdate:&error]) {
                @throw [NSException exceptionWithName:@"Migration Failed" 
                                               reason:[error localizedDescription] 
                                             userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
            }
            if (objectCounter % kSaveMarker == 0) {
                NSLog(@"Save fired: %u", objectCounter);
            }
        }
    }
    
    NSLog(@"Migration complete.");
    
    
    if ([delegate respondsToSelector:kSELmigrationCompleted]) {
        [delegate migrationCompletedSuccessfully:self filePath:[tempFileURL path] context:contextInfo];
    } else {
        NSLog(@"%@:%s Migation completed", [self class], _cmd);
    }
     */
}

@end

@implementation ZDSMigrationHandler

+ (void)initialize {
    kSELmigrationCompleted = @selector(migrationCompletedSuccessfully:filePath:context:);
    kSELmigrationFailed = @selector(migrationFailed:error:context:);
    kSELmigrationUpdate = @selector(migrationUpdate:entity:count:context:);
    kSELmigrationProgress = @selector(migrationProgress:currentCount:context:);
    kSELmigrationStage = @selector(migrationStage:stage:context:);
}

+ (void)migrateContext:(NSManagedObjectContext*)oldContext
               toModel:(NSManagedObjectModel*)model
          withDelegate:(id)delegate
               context:(void*)contextInfo;
{
    id migrationHandler = [[ZDSMigrationHandler alloc] init];
    
    [migrationHandler setValue:delegate forKey:@"delegate"];
    [migrationHandler setValue:model forKey:@"newModel"];
    [migrationHandler setValue:oldContext forKey:@"oldContext"];
    [migrationHandler setValue:contextInfo forKey:@"contextInfo"];
    
    @try {
        [ZDSManagedObject setZdsMigrationActive:YES];
        [migrationHandler performMigration];
    } @catch (NSException *exception) {
        [ZDSManagedObject setZdsMigrationActive:NO];
        NSError *error = [[exception userInfo] valueForKey:@"error"];
        if ([delegate respondsToSelector:kSELmigrationFailed]) {
            [delegate migrationFailed:self error:error context:contextInfo];
        } else {
            NSLog(@"%@:%s Failure in migration: %@", [self class], _cmd, error);
        }
        
    } @finally {
        [ZDSManagedObject setZdsMigrationActive:NO];
        [migrationHandler autorelease];
    }
}

- (void)dealloc
{
    [delegate release], delegate = nil;
    [newModel release], newModel = nil;
    [oldContext release], oldContext = nil;
    [tempFileURL release], tempFileURL = nil;
    [newContext release], newContext = nil;
    [noRelationshipModel release], noRelationshipModel = nil;
    [super dealloc];
}

@end
