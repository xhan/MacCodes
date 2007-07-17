// ZDSMigrationHandler.m
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

#import "ZDSMigrationHandler.h"

@interface NSManagedObject (ZDSMigration)

- (NSString*)objectIDString;

- (BOOL)orphan;
- (void)fault;

- (void)copyFromManagedObject:(id)object;
- (void)copyRelationshipsFromManagedObject:(id)object withReference:(NSDictionary *)reference;

@end

@implementation NSManagedObject (ZDSMigration)

- (BOOL)orphan;
{
    return NO;
}

- (NSString*)objectIDString;
{
    return [[[self objectID] URIRepresentation] absoluteString];
}

- (void)fault;
{
    if ([self isFault]) return;
    if (![self isInserted]) return;
    if ([self isUpdated]) NSLog(@"%@ marked as updated", [[self entity] name]);
    if ([self isDeleted]) NSLog(@"%@ marked as deleted", [[self entity] name]);
    NSManagedObjectContext* moc = [self managedObjectContext];
    if (!moc) return;
    [moc refreshObject:self mergeChanges:NO];
}

- (void)copyFromManagedObject:(id)object
{
    NSEntityDescription *entity = [object entity];
    
    NSArray *attributeKeys = [[entity attributesByName] allKeys]; 
    NSDictionary *attributeValues = [object dictionaryWithValuesForKeys:attributeKeys];
    [self setValuesForKeysWithDictionary:attributeValues];
}

- (void)copyRelationshipsFromManagedObject:(id)object withReference:(NSDictionary *)reference 
{
    NSEntityDescription *entity = [object entity];
    NSDictionary *relationships = [entity relationshipsByName];
    
    NSEnumerator *relationshipEnum = [[relationships allKeys] objectEnumerator];
    NSString *relationshipName;
    while (relationshipName = [relationshipEnum nextObject]) {
        if (![[[self entity] relationshipsByName] valueForKey:relationshipName]) {
            //relationship does not exist in the new model, skipping
            continue;
        }
        NSRelationshipDescription *relationshipDescription = [relationships valueForKey:relationshipName];
        if ([relationshipDescription isToMany]) {
            //To many relationship
            NSEnumerator *toManyEnum = [[object primitiveValueForKey:relationshipName] objectEnumerator];
            NSMutableSet *toManySet = [self primitiveValueForKey:relationshipName];
            NSManagedObject *toMany;
            while (toMany = [toManyEnum nextObject]) {
                NSString *uid = [[[toMany objectID] URIRepresentation] absoluteString];
                id newReference = [reference valueForKey:uid];
                if (newReference) [toManySet addObject:newReference];
            }
        } else {
            //To one relationship
            NSManagedObject *toOneObject = [object primitiveValueForKey:relationshipName];
            NSString *uid = [toOneObject objectIDString];
            if (!uid)  continue;
            id newReference = [reference valueForKey:uid];
            if (!newReference) continue;
            [self setPrimitiveValue:newReference forKey:relationshipName];
        }
    }
}

@end

@interface ZDSMigrationHandler (private)

- (void)performMigration;
- (BOOL)saveAndFlush:(NSError**)error;
- (void)kickOffMigration;
- (void)prepareSourceContext;
- (void)prepareDestinationContext;

@end

static int const kSaveMarker = 1000;
static SEL kSELmigrationCompleted;
static SEL kSELmigrationFailed;
static SEL kSELmigrationUpdate;
static SEL kSELmigrationStopped;

@implementation ZDSMigrationHandler (private)

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
    NSManagedObject *newEntity;
    while (newEntity = [toFlushEnum nextObject]) {
        [newContext refreshObject:newEntity mergeChanges:NO];
    }
    return YES;
}

- (void)performMigration;
{
    NSDictionary *oldEntityDict = [[[oldContext persistentStoreCoordinator] managedObjectModel] entitiesByName];
    totalEntities = [[oldEntityDict allKeys] count];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSEnumerator *entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    currentEntityIndex = 0;
    unsigned saveCounter = 0;
    
    NSMutableDictionary *newEntitiesReference = [[NSMutableDictionary alloc] init];
    while (currentEntityName = [entityNamesEnum nextObject]) {
        if (haltMigration) {
            @throw [NSException exceptionWithName:@"Migration Failed"
                                           reason:@"Halt requested"
                                         userInfo:nil];
        }
        ++currentEntityIndex;
        if (![[newModel entitiesByName] valueForKey:currentEntityName]) continue;
        
        NSEntityDescription *entityDescription = [oldEntityDict valueForKey:currentEntityName];
        if ([entityDescription isAbstract]) continue;
        
        [request setEntity:entityDescription];
        
        NSArray *oldEntities = [oldContext executeFetchRequest:request error:&error];
        totalInstances = [oldEntities count];
        if (!oldEntities) {
            [newEntitiesReference release], newEntitiesReference = nil;
            [pool release], pool = nil;
            @throw [NSException exceptionWithName:@"Migration Failed" 
                                           reason:[error localizedDescription] 
                                         userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
        }
        if (!totalInstances) continue;
        
        if ([delegate respondsToSelector:kSELmigrationUpdate]) {
            [delegate performSelectorOnMainThread:kSELmigrationUpdate
                                       withObject:self
                                    waitUntilDone:NO];
        }
        unsigned migrationUpdateMarker = ((totalInstances / 10) < 2 ? 2 : (totalInstances / 10));
        currentInstanceIndex = 0;
        
        NSEnumerator *oldEntitiesEnum = [[oldEntities objectEnumerator] retain];
        NSManagedObject *oldEntity = nil;
        while (oldEntity = [oldEntitiesEnum nextObject]) {
            if (haltMigration) {
                @throw [NSException exceptionWithName:@"Migration Failed"
                                               reason:@"Halt requested"
                                             userInfo:nil];
            }
            if ([oldEntity orphan]) continue;
            NSManagedObject *newEntity = [NSEntityDescription insertNewObjectForEntityForName:currentEntityName
                                                                        inManagedObjectContext:newContext];
            if (currentInstanceIndex % migrationUpdateMarker == 0 && [delegate respondsToSelector:kSELmigrationUpdate]) {
                [delegate performSelectorOnMainThread:kSELmigrationUpdate
                                           withObject:self
                                        waitUntilDone:NO];
            }
            [newEntity copyFromManagedObject:oldEntity];
            [newEntity copyRelationshipsFromManagedObject:oldEntity withReference:newEntitiesReference];
            [oldEntity fault];
            [newEntitiesReference setValue:newEntity forKey:[oldEntity objectIDString]];
            
            ++saveCounter;
            ++currentInstanceIndex;
            if (saveCounter % kSaveMarker != 0) continue;
            
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

- (void)prepareSourceContext;
{
    if (!pathToModelToMigrateFrom) {
        @throw [NSException exceptionWithName:@"Migration Error"
                                       reason:@"pathToModelToMigrationFrom not set"
                                     userInfo:nil];
    }
    if (!pathForFileToMigrate) {
        @throw [NSException exceptionWithName:@"Migration Error"
                                       reason:@"pathForFileToMigrate not set"
                                     userInfo:nil];
    }
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:pathToModelToMigrateFrom]];
    NSEnumerator *entityEnum = [[model entities] objectEnumerator];
    NSEntityDescription *entity;
    while (entity = [entityEnum nextObject]) {
        [entity setManagedObjectClassName:@"NSManagedObject"];
    }
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    if (![coordinator addPersistentStoreWithType:storeTypeToMigrateFrom
                             configuration:nil
                                       URL:[NSURL fileURLWithPath:pathForFileToMigrate]
                                   options:nil
                                     error:&error]) {
        @throw [NSException exceptionWithName:@"Migration Error"
                                       reason:[error localizedDescription]
                                     userInfo:nil];
    }
    oldContext = [[NSManagedObjectContext alloc] init];
    [oldContext setPersistentStoreCoordinator:coordinator];
    [coordinator release];
}

- (void)prepareDestinationContext;
{
    if (!pathToModelToMigrateFrom) {
        @throw [NSException exceptionWithName:@"Migration Error"
                                       reason:@"pathToModelToMigrateTo not set"
                                     userInfo:nil];
    }
    newModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:pathToModelToMigrateFrom]];
    NSEnumerator *entityEnum = [[newModel entities] objectEnumerator];
    NSEntityDescription *entity;
    while (entity = [entityEnum nextObject]) {
        [entity setManagedObjectClassName:@"NSManagedObject"];
        NSEnumerator *relationshipEnum = [[[entity relationshipsByName] allKeys] objectEnumerator];
        NSRelationshipDescription *relationship;
        NSString *relationshipKey;
        while (relationshipKey = [relationshipEnum nextObject]) {
            relationship = [[entity relationshipsByName] valueForKey:relationshipKey];
            [relationship setOptional:YES];
        }
    }
    
    NSString *databaseType = [self storeTypeToMigrateFrom];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:newModel];
    id store = [coordinator addPersistentStoreWithType:databaseType
                                   configuration:nil
                                             URL:tempFileURL
                                         options:nil
                                           error:&error];
    if (!store) {
        @throw [NSException exceptionWithName:@"Migration Error"
                                       reason:[error localizedDescription]
                                     userInfo:nil];
    }
    [coordinator setMetadata:newStoreMetadata forPersistentStore:store];
    newContext = [[NSManagedObjectContext alloc] init];
    [newContext setPersistentStoreCoordinator:coordinator];
    [coordinator release];
}

- (void)kickOffMigration;
{
    if ([self warnings]) NSLog(@"Starting migration flow");
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        if ([self warnings]) NSLog(@"Building source stack");
        [self prepareSourceContext];
        if ([self warnings]) NSLog(@"Building destination stack");
        [self prepareDestinationContext];
        if ([self warnings]) NSLog(@"Starting migration");
        [self performMigration];
        if ([delegate respondsToSelector:kSELmigrationCompleted]) {
            [delegate performSelectorOnMainThread:kSELmigrationCompleted
                                       withObject:self
                                    waitUntilDone:NO];
        }
    } @catch (NSException *exception) {
        if (![[exception userInfo] valueForKey:@"error"] && !error) {
            error = [[NSError alloc] initWithDomain:@"com.zarrastudios"
                                               code:1000
                                           userInfo:[NSDictionary dictionaryWithObject:[exception reason]
                                                                                forKey:NSLocalizedDescriptionKey]];
        }
        if ([delegate respondsToSelector:kSELmigrationFailed]) {
            [delegate performSelectorOnMainThread:kSELmigrationFailed
                                       withObject:self
                                    waitUntilDone:NO];
        }
        if ([self warnings]) {
            NSLog(@"%@:%s Failure in migration: %@", [self class], _cmd, [exception reason]);
        }
    } @finally {
        [pool release], pool = nil;
        if ([self threaded]) [NSThread exit];
    }
    if ([self threaded]) {
        [self performSelectorOnMainThread:@selector(autorrelease) withObject:nil waitUntilDone:NO];
    } else {
         [self autorelease];
    }
}

@end

@implementation ZDSMigrationHandler

+ (void)initialize 
{
    kSELmigrationCompleted = @selector(migrationCompletedSuccessfully:);
    kSELmigrationFailed = @selector(migrationFailed:);
    kSELmigrationUpdate = @selector(migrationUpdate:);
    kSELmigrationStopped = @selector(migrationStopped:);
}

- (id)init
{
    if (![self initWithDelegate:nil]) return nil;
    return self;
}

- (id)initWithDelegate:(id)newDelegate;
{
    if (![super init]) return nil;
    haltMigration = NO;
    
    currentEntityName = nil;
    currentInstanceIndex = 0;
    totalInstances = 0;
    totalEntities = 0;
    currentEntityIndex = 0;
    
    oldContext = nil;
    newContext = nil;
    newModel = nil;
    delegate = [newDelegate retain];
    contextInfo = nil;
    error = nil;
    
    pathForFileToMigrate = nil;
    pathToModelToMigrateFrom = nil;
    pathToModelToMigrateTo = nil;
    storeTypeToMigrateFrom = NSSQLiteStoreType;
    storeTypeToMigrateTo = NSSQLiteStoreType;
    newStoreMetadata = nil;
    migrationHelper = nil;
    
    warnings = YES;
    threaded = YES;
    
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
    tempFileURL = [[NSURL alloc] initFileURLWithPath:tempFilename];
    if ([self warnings]) NSLog(@"%@:%s TempFile: %@", [self class], _cmd, tempFilename);
    
    return self;
}

- (void)dealloc
{
    NSLog(@"%@:%s fired", [self class], _cmd);
    [delegate release], delegate = nil;
    [oldContext release], oldContext = nil;
    [tempFileURL release], tempFileURL = nil;
    [newContext release], newContext = nil;
    [newModel release], newModel = nil;

    [pathForFileToMigrate release];
    [pathToModelToMigrateFrom release];
    [pathToModelToMigrateTo release];
    [storeTypeToMigrateFrom release];
    [storeTypeToMigrateTo release];
    [migrationHelper release];
    
    pathForFileToMigrate = nil;
    pathToModelToMigrateFrom = nil;
    pathToModelToMigrateTo = nil;
    storeTypeToMigrateFrom = nil;
    storeTypeToMigrateTo = nil;
    migrationHelper = nil;
    
    [super dealloc];
}

- (void)stopMigration;
{
    if (![self threaded]) {
        @throw [NSException exceptionWithName:@"Migration Error"
                                       reason:@"stop attempted on non-threaded migration"
                                     userInfo:nil];
    }
    haltMigration = YES;
    [newContext release], newContext = nil;
    [newModel release], newModel = nil;
    [[NSFileManager defaultManager] removeFileAtPath:[tempFileURL path] handler:nil];
    if ([delegate respondsToSelector:kSELmigrationStopped]) {
        [delegate performSelectorOnMainThread:kSELmigrationStopped
                                   withObject:self
                                waitUntilDone:NO];
    }
}

- (void)startMigration;
{
    if ([self threaded]) {
        [NSThread detachNewThreadSelector:@selector(kickOffMigration)
                                 toTarget:self
                               withObject:nil];
    } else {
        [self kickOffMigration];
    }
}

#pragma mark -
#pragma mark Status Points

- (unsigned)currentEntityIndex;
{
    return currentEntityIndex;
}

- (unsigned)currentInstanceIndex;
{
    return currentInstanceIndex;
}

- (unsigned)totalInstances;
{
    return totalInstances;
}

- (unsigned)totalEntities;
{
    return totalEntities;
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

- (NSString *)pathForFileToMigrate
{
    return [[pathForFileToMigrate retain] autorelease]; 
}

- (void)setPathForFileToMigrate:(NSString *)aPathForFileToMigrate
{
    [pathForFileToMigrate release];
    pathForFileToMigrate = [aPathForFileToMigrate copy];
}

- (NSString *)pathToModelToMigrateFrom
{
    return [[pathToModelToMigrateFrom retain] autorelease]; 
}

- (void)setPathToModelToMigrateFrom:(NSString *)aPathToModelToMigrateFrom
{
    [pathToModelToMigrateFrom release];
    pathToModelToMigrateFrom = [aPathToModelToMigrateFrom copy];
}

- (NSString *)pathToModelToMigrateTo
{
    return [[pathToModelToMigrateTo retain] autorelease]; 
}

- (void)setPathToModelToMigrateTo:(NSString *)aPathToModelToMigrateTo
{
    [pathToModelToMigrateTo release];
    pathToModelToMigrateTo = [aPathToModelToMigrateTo copy];
}

- (NSString *)storeTypeToMigrateFrom
{
    return [[storeTypeToMigrateFrom retain] autorelease]; 
}

- (void)setStoreTypeToMigrateFrom:(NSString *)aStoreTypeToMigrateFrom
{
    [storeTypeToMigrateFrom release];
    storeTypeToMigrateFrom = [aStoreTypeToMigrateFrom copy];
}

- (NSString *)storeTypeToMigrateTo
{
    return [[storeTypeToMigrateTo retain] autorelease]; 
}

- (void)setStoreTypeToMigrateTo:(NSString *)aStoreTypeToMigrateTo
{
    [storeTypeToMigrateTo release];
    storeTypeToMigrateTo = [aStoreTypeToMigrateTo copy];
}

- (id)migrationHelper
{
    return [[migrationHelper retain] autorelease]; 
}

- (void)setMigrationHelper:(id)aMigrationHelper
{
    [migrationHelper release];
    migrationHelper = [aMigrationHelper copy];
}

- (BOOL)warnings
{
    return warnings;
}

- (void)setWarnings:(BOOL)flag
{
    warnings = flag;
}

- (BOOL)threaded
{
    return threaded;
}

- (void)setThreaded:(BOOL)flag
{
    threaded = flag;
}

- (NSDictionary *)newStoreMetadata
{
    return [[newStoreMetadata retain] autorelease]; 
}

- (void)setNewStoreMetadata:(NSDictionary *)aNewStoreMetadata
{
    [newStoreMetadata release];
    newStoreMetadata = [aNewStoreMetadata copy];
}

@end
