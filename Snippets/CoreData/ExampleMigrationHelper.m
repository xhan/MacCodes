//
//  ExampleMigrationHandler.m
//  MigrationTest
//
//  Created by Marcus S. Zarra on 7/17/07.
//  Copyright 2007 Zarra Studios LLC. All rights reserved.
//

#import "ExampleMigrationHelper.h"

#import "ZDSMigrationHandler.h"

@implementation ExampleMigrationHelper

- (void)entitya_copyFromManagedObject:(NSManagedObject*)object 
                             toObject:(NSManagedObject*)newObject;
{
    NSEntityDescription *entity = [object entity];
    
    NSArray *attributeKeys = [[entity attributesByName] allKeys]; 
    NSDictionary *attributeValues = [object dictionaryWithValuesForKeys:attributeKeys];
    [self setValuesForKeysWithDictionary:attributeValues];
}

- (void)entitya_copyRelationshipsFromManagedObject:(NSManagedObject*)oldObject 
                                          toObject:(NSManagedObject*)newObject 
                                     withReference:(NSDictionary*)reference;
{
    [newObject copyRelationshipsFromManagedObject:oldObject withReference:reference];
}
@end
