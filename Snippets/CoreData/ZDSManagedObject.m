//
//  ZDSManagedObject.m
//
//  Created by Marcus S. Zarra on 3/25/07.
//  Copyright 2007 Zarra Studios LLC. All rights reserved.
//

#import "ZDSManagedObject.h"

static BOOL zdsMigrationActive = NO;

@implementation ZDSManagedObject

+ (bool)zdsMigrationActive;
{
    return zdsMigrationActive;
}

+ (void)setZdsMigrationActive:(BOOL)b;
{
    zdsMigrationActive = b;
}

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
            ZDSManagedObject *toMany;
            while (toMany = [toManyEnum nextObject]) {
                NSString *uid = [[[toMany objectID] URIRepresentation] absoluteString];
                id newReference = [reference valueForKey:uid];
                if (newReference) [toManySet addObject:newReference];
            }
        } else {
            //To one relationship
            ZDSManagedObject *toOneObject = [object primitiveValueForKey:relationshipName];
            NSString *uid = [toOneObject objectIDString];
            if (uid) {
                id newReference = [reference valueForKey:uid];
                if (newReference) {
                    [self setPrimitiveValue:newReference forKey:relationshipName];
                }
            }
        }
    }
}

@end
