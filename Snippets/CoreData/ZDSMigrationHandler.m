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
    
<<<<<<< .mine
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
=======
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
>>>>>>> .r138
    
    NSLog(@"Starting migration");
    NSDictionary *oldEntityDict = [[[oldContext persistentStoreCoordinator] managedObjectModel] entitiesByName];
    NSLog(@"entityDictionaryKeys: %@", [oldEntityDict allKeys]);
    NSEnumerator *entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
    
    NSMutableDictionary *newEntitiesReference = [NSMutableDictionary dictionary];
    
    NSError *error;
    
    NSString *currentEntityName;
    
    uint objectCounter = 0;
    id oldEntity, newEntity;
    
    while (currentEntityName = [entityNamesEnum nextObject]) {
        NSLog(@"Starting on entity: %@", currentEntityName);
        [request setEntity:[oldEntityDict valueForKey:currentEntityName]];
<<<<<<< .mine
        NSArray *oldEntities = [oldContext executeFetchRequest:request error:&error];
        
=======
        NSArray *oldEntities = [[oldContext executeFetchRequest:request
                                                          error:&error] retain];
>>>>>>> .r138
        NSAssert(oldEntities != nil, ([NSString stringWithFormat:@"Error retrieving entity %@:%@", currentEntityName, error]));
        
        if (![oldEntities count]) continue;
        
        NSEnumerator *oldEntitiesEnum = [oldEntities objectEnumerator];
        
        while (oldEntity = [oldEntitiesEnum nextObject]) {
<<<<<<< .mine
            newEntity = [NSEntityDescription insertNewObjectForEntityForName:currentEntityName inManagedObjectContext:newContext];
=======
            ZDSManagedObject *newEntity = [NSEntityDescription insertNewObjectForEntityForName:currentEntityName
                                                                        inManagedObjectContext:newContext];
>>>>>>> .r138
            ++objectCounter;
            
            if (![newEntity isKindOfClass:[ZDSManagedObject class]]) {
                @throw [NSException exceptionWithName:@"Invalid object type"
                                               reason:[NSString stringWithFormat:@"Unknown class in the context: %@", oldEntity]
                                             userInfo:nil];
            }
            
            [newEntity copyFromManagedObject:oldEntity
                               withReference:newEntitiesReference];
            
            /*
            if ((objectCounter % kSaveMarker) == 0) {
                NSLog(@"Saving context");
                NSEnumerator *insertedEnum = [[newContext insertedObjects] objectEnumerator];
                NSAssert([newContext save:&error], ([NSString stringWithFormat:@"Save marker failed: %@", error]));
<<<<<<< .mine
                id insertedObject;
                while (insertedObject = [insertedEnum nextObject]) {
                    [newContext refreshObject:insertedObject mergeChanges:NO];
                }
            }*/
=======
                // [pool release], pool = nil;
                // pool = [[NSAutoreleasePool alloc] init];
            }
>>>>>>> .r138
        }
    }
    
    NSLog(@"Saving the new context");
    if (![newContext save:&error]) {
        @throw [NSException exceptionWithName:@"Failed to save new context"
                                       reason:@"There was an error "
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, @"error"]];
    }
<<<<<<< .mine
    //[oldContext reset];
    //[newContext reset];
=======
    // [pool release], pool = nil;
    [newEntitiesReference release], newEntitiesReference = nil;
>>>>>>> .r138
    
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
