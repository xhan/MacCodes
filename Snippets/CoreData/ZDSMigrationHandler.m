#import "ZDSMigrationHandler.h"
#import "ZDSManagedObject.h"

@interface ZDSMigrationHandler (private)

- (void)performMigration;
- (void)initializeNewContext;

@end

static int const kSaveMarker = 100;

@implementation ZDSMigrationHandler (private)

- (void)initializeNewContext;
{
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tempFilename = NSTemporaryDirectory();
    tempFilename = [tempFilename stringByAppendingPathComponent:guid];
    tempFileURL = [[NSURL fileURLWithPath:tempFilename] retain];
    
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

- (void)performMigration;
{
    [self initializeNewContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSLog(@"Starting migration");
    NSDictionary *oldEntityDict = [[[oldContext persistentStoreCoordinator] managedObjectModel] entitiesByName];
    NSEnumerator *entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
    
    NSMutableDictionary *newEntitiesReference = [NSMutableDictionary dictionary];
    NSError *error = nil;
    ZDSManagedObject* oldEntity = nil;
    ZDSManagedObject* newEntity = nil;
    
    uint objectCounter = 0;
    
    NSLog(@"Doing attributes pass");
    NSString *currentEntityName;
    while (currentEntityName = [entityNamesEnum nextObject]) {
        NSLog(@"\tEntity: %@", currentEntityName);
        [request setEntity:[oldEntityDict valueForKey:currentEntityName]];
        
        error = nil;
        NSArray *oldEntities = [oldContext executeFetchRequest:request error:&error];
        if (error) {
            //TODO Notify delegate of failure
        }
        
        if (![oldEntities count]) continue;
        
        NSEnumerator *oldEntitiesEnum = [oldEntities objectEnumerator];
        
        while (oldEntity = [oldEntitiesEnum nextObject]) {
            newEntity = [NSEntityDescription insertNewObjectForEntityForName:currentEntityName inManagedObjectContext:newContext];
            ++objectCounter;
            [newEntity copyFromManagedObject:oldEntity];
            [newEntitiesReference setValue:newEntity forKey:[[[oldEntity objectID] URIRepresentation] absoluteString]];
        }
    }
    
    NSLog(@"Doing relationships pass");
    entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
    while (currentEntityName = [entityNamesEnum nextObject]) {
        NSLog(@"\tEntity: %@", currentEntityName);
        [request setEntity:[oldEntityDict valueForKey:currentEntityName]];
        
        error = nil;
        NSArray *oldEntities = [oldContext executeFetchRequest:request error:&error];
        if (error) {
            //TODO Notify delegate of failure
        }
        
        if (![oldEntities count]) continue;
        
        NSEnumerator *oldEntitiesEnum = [oldEntities objectEnumerator];
        
        while (oldEntity = [oldEntitiesEnum nextObject]) {
            newEntity = [newEntitiesReference valueForKey:[[[oldEntity objectID] URIRepresentation] absoluteString]];
            [newEntity copyRelationshipsFromManagedObject:oldEntity withReference:newEntitiesReference];
        }
    }
    
    NSLog(@"Saving the new context");
    error = nil;
    if (![newContext save:&error]) {
        //TODO Notify delegate of failure
    }
    
    [newEntitiesReference release], newEntitiesReference = nil;
    //release the temporary context
    [newContext release], newContext = nil;
    
    NSLog(@"Validating new context");
    error = nil;
    NSPersistentStoreCoordinator *store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:newModel];
    if (![store addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:tempFileURL options:nil error:&error]) {
        NSLog(@"Error creating new store: %@", error);
        //TODO Notify delegate of failure
    }
    
    NSManagedObjectContext *validateContext = [[NSManagedObjectContext alloc] init];
    [validateContext setPersistentStoreCoordinator:store];
    [store release];
    
    NSDictionary *newEntitiesByName = [newModel entitiesByName];
    entityNamesEnum = [[newEntitiesByName allKeys] objectEnumerator];
    while (currentEntityName = [entityNamesEnum nextObject]) {
        NSLog(@"\tEntity: %@", currentEntityName);
        [request setEntity:[newEntitiesByName valueForKey:currentEntityName]];

        error = nil;
        NSArray *entities = [validateContext executeFetchRequest:request error:&error];
        NSAssert(error == nil, ([NSString stringWithFormat:@"Error retrieving entity %@:%@", currentEntityName, error]));
        if (![entities count]) continue;
        
        NSEnumerator *entitiesEnum = [entities objectEnumerator];
        
        while (newEntity = [entitiesEnum nextObject]) {
            error = nil;
            if (![newEntity validateForUpdate:&error]) {
                NSLog(@"Failed to validate: %@", error);
                //TODO Notify delegate of failure
            }
        }
    }
    
    NSLog(@"Migration complete.");
    
    //TODO Notify delegate of success
}

@end

@implementation ZDSMigrationHandler

+ (void)migrateContext:(NSManagedObjectContext*)oldContext
               toModel:(NSManagedObjectModel*)model
          withDelegate:(id)delegate
           contextInfo:(void*)contextInfo;
{
    id migrationHandler = [[ZDSMigrationHandler alloc] init];
    
    [migrationHandler setValue:delegate forKey:@"delegate"];
    [migrationHandler setValue:model forKey:@"newModel"];
    [migrationHandler setValue:oldContext forKey:@"oldContext"];
    [migrationHandler setValue:contextInfo forKey:@"contextInfo"];
    
    [migrationHandler performMigration];
    
    [migrationHandler release];
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
