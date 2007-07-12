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

- (void)copyFromManagedObject:(id)object
{
    NSEntityDescription *entity = [object entity];
    
    NSArray *attributeKeys = [[entity attributesByName] allKeys]; 
    NSDictionary *attributeValues = [object dictionaryWithValuesForKeys:attributeKeys];
    [self setValuesForKeysWithDictionary:attributeValues];
}

- (void)copyRelationshipsFromManagedObject:(id)object withReference:(NSMutableDictionary *)reference 
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
            NSEnumerator *toManyEnum = [[object valueForKey:relationshipName] objectEnumerator];
            NSManagedObject *toMany;
            NSMutableSet *toManySet = [self mutableSetValueForKey:relationshipName];
            while (toMany = [toManyEnum nextObject]) {
                NSString *uid = [[[toMany objectID] URIRepresentation] absoluteString];
                ZDSManagedObject *toManyNew = [reference valueForKey:uid];
                if (toManyNew) [toManySet addObject:toManyNew];
            }
        } else {
            //To one relationship
            //see if the receiver has already been copied, if so link
            NSString *uid = [[[[object valueForKey:relationshipName] objectID] URIRepresentation] absoluteString];
            if (uid) {
                ZDSManagedObject *toOne = [reference valueForKey:uid];
                if (toOne) [self setValue:toOne forKey:relationshipName];
            }
        }
    }
}

@end
