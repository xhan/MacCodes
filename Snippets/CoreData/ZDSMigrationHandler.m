//
//  ZDSMigrationHandler.m
//
//  Created by Marcus S. Zarra on 3/25/07.
//  Copyright 2007 Zarra Studios LLC. All rights reserved.
//

#import "ZDSMigrationHandler.h"
#import "ZDSManagedObject.h"

@implementation ZDSMigrationHandler


+ (BOOL)migrateContext:(NSManagedObjectContext*)oldMOC toContext:(NSManagedObjectContext*)newMOC;
{
    NSDictionary *oldEntityDict = [[[oldMOC persistentStoreCoordinator] managedObjectModel] entitiesByName];
    NSEnumerator *entityNamesEnum = [[oldEntityDict allKeys] objectEnumerator];
    
    NSMutableDictionary *newEntitiesReference = [[[NSMutableDictionary alloc] init] autorelease];
    
    NSError *error;
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSString *currentEntityName;
    while (currentEntityName = [entityNamesEnum nextObject]) {
        [request setEntity:[oldEntityDict valueForKey:currentEntityName]];
        NSArray *oldEntities = [oldMOC executeFetchRequest:request error:&error];
        NSAssert(oldEntities != nil, ([NSString stringWithFormat:@"Error retrieving entity %@:%@", currentEntityName, error]));
        
        if ([oldEntities count] == 0) continue;
        
        NSEnumerator *oldEntitiesEnum = [oldEntities objectEnumerator];
        
        id oldEntity;
        while (oldEntity = [oldEntitiesEnum nextObject]) {
            ZDSManagedObject *newEntity;
            newEntity = [NSEntityDescription insertNewObjectForEntityForName:currentEntityName inManagedObjectContext:newMOC];
            if (![newEntity isKindOfClass:[ZDSManagedObject class]]) {
                @throw [NSException exceptionWithName:@"Invalid object type" reason:[NSString stringWithFormat:@"Unknown class in the context: %@", oldEntity] userInfo:nil];
            }
            [newEntity copyFromManagedObject:oldEntity withReference:newEntitiesReference];
        }
    }
    
    if (![newMOC save:&error]) {
        @throw [NSException exceptionWithName:@"Failed to save new context" reason:@"There was an error " userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, @"error"]];
    }
    
    return YES;
}

@end
