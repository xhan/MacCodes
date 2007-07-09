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
    //build the new context
    
    NSString *filePath = NSTemporaryDirectory();
    filePath = [filePath stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
    tempFileURL = [NSURL fileURLWithPath:filePath];
    
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:newModelPath]];
    //Release all of the relationship constraints now
    NSEnumerator *entityEnum = [[mom entities] objectEnumerator];
    NSEntityDescription *entity;
    while (entity = [entityEnum nextObject]) {
        NSEnumerator *relationshipEnum = [[[entity relationshipsByName] allKeys] objectEnumerator];
        NSRelationshipDescription *relationship;
        NSString *relationshipKey;
        while (relationshipKey = [relationshipEnum nextObject]) {
            relationship = [[entity relationshipsByName] valueForKey:relationshipKey];
            NSLog(@"optional: %@", ([relationship isOptional] ? @"YES" : @"NO"));
            [relationship setOptional:YES];
        }
    }
    
    NSError *error;
    id store = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![store addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:tempFileURL options:nil error:&error]) {
        NSLog(@"Error creating new store: %@", error);
        @throw [NSException exceptionWithName:@"Migration Error" reason:[error localizedDescription] userInfo:nil];
    }
    
    newContext = [[NSManagedObjectContext alloc] init];
    [newContext setPersistentStoreCoordinator:store];
    [mom release];
    [store release];
}

- (void)performMigration;
{
    [self initializeNewContext];
    
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"Starting migration");
    NSDictionary *oldEntityDict = [[[oldContext persistentStoreCoordinator] managedObjectModel] entitiesByName];
    NSLog(@"entityDictionaryKeys: %@", [oldEntityDict allKeys]);
    NSEnumerator *entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
    
    NSMutableDictionary *newEntitiesReference = [[NSMutableDictionary alloc] init];
    
    NSError *error;
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSString *currentEntityName;
    
    int objectCounter = 0;
    
    while (currentEntityName = [entityNamesEnum nextObject]) {
        NSLog(@"Starting on entity: %@", currentEntityName);
        [request setEntity:[oldEntityDict valueForKey:currentEntityName]];
        NSArray *oldEntities = [[oldContext executeFetchRequest:request
                                                          error:&error] retain];
        NSAssert(oldEntities != nil, ([NSString stringWithFormat:@"Error retrieving entity %@:%@", currentEntityName, error]));
        
        if (![oldEntities count]) {
            [oldEntities release], oldEntities = nil;
            continue;
        }
        
        NSEnumerator *oldEntitiesEnum = [[oldEntities objectEnumerator] retain];
        id oldEntity;
        
        while (oldEntity = [oldEntitiesEnum nextObject]) {
            ZDSManagedObject *newEntity = [NSEntityDescription insertNewObjectForEntityForName:currentEntityName
                                                                        inManagedObjectContext:newContext];
            ++objectCounter;
            
            if (![newEntity isKindOfClass:[ZDSManagedObject class]]) {
                @throw [NSException exceptionWithName:@"Invalid object type"
                                               reason:[NSString stringWithFormat:@"Unknown class in the context: %@", oldEntity]
                                             userInfo:nil];
            }
            
            [newEntity copyFromManagedObject:oldEntity
                               withReference:newEntitiesReference];
            
            if ((objectCounter % kSaveMarker) == 0) {
                NSLog(@"Saving context");
                NSAssert([newContext save:&error], ([NSString stringWithFormat:@"Save marker failed: %@", error]));
                // [pool release], pool = nil;
                // pool = [[NSAutoreleasePool alloc] init];
            }
        }
        [oldEntities release], oldEntities = nil;
        [oldEntitiesEnum release], oldEntitiesEnum = nil;
    }
    
    NSLog(@"Saving the new context");
    if (![newContext save:&error]) {
        @throw [NSException exceptionWithName:@"Failed to save new context"
                                       reason:@"There was an error "
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, @"error"]];
    }
    // [pool release], pool = nil;
    [newEntitiesReference release], newEntitiesReference = nil;
    
    NSLog(@"Migration complete.");
}

@end

@implementation ZDSMigrationHandler

+ (void)migrateContext:(NSManagedObjectContext*)oldContext toModelAtPath:(NSString*)modelFilePath withDelegate:(id)delegate;
{
    id migrationHandler = [[ZDSMigrationHandler alloc] init];
    [migrationHandler setValue:delegate forKey:@"delegate"];
    [migrationHandler setValue:modelFilePath forKey:@"newModelPath"];
    [migrationHandler setValue:oldContext forKey:@"oldContext"];
    [migrationHandler performMigration];
}

@end
