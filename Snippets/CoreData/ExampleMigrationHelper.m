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

- (BOOL)entitya_orphan;
{
    //Testing to make sure orphan calls are performing
    return NO;
}

- (void)entityb_copyFromManagedObject:(NSManagedObject*)object 
                             toObject:(NSManagedObject*)newObject;
{
    NSEntityDescription *entity = [object entity];
    
    NSMutableArray *attributeKeys = [[[entity attributesByName] allKeys] mutableCopy]; 
    
    [attributeKeys removeObject:@"number1"];
    
    NSDictionary *attributeValues = [object dictionaryWithValuesForKeys:attributeKeys];
    [newObject setValuesForKeysWithDictionary:attributeValues];
    [attributeKeys release];
    
    long number1 = ([[object valueForKey:@"number1"] doubleValue] * 100);
    NSDecimalNumber *decimal = [NSDecimalNumber decimalNumberWithMantissa:number1 exponent:-2 isNegative:(number1 < 0 ? YES : NO)];
    [newObject setValue:decimal forKey:@"number1"];
}

- (void)entityc_copyFromManagedObject:(NSManagedObject*)object 
                             toObject:(NSManagedObject*)newObject;
{
    NSEntityDescription *entity = [object entity];
    
    NSMutableArray *attributeKeys = [[[entity attributesByName] allKeys] mutableCopy]; 
    
    [attributeKeys removeObject:@"number1"];
    
    NSDictionary *attributeValues = [object dictionaryWithValuesForKeys:attributeKeys];
    [newObject setValuesForKeysWithDictionary:attributeValues];
    [attributeKeys release];
    
    long number1 = ([[object valueForKey:@"number1"] doubleValue] * 100);
    NSDecimalNumber *decimal = [NSDecimalNumber decimalNumberWithMantissa:number1 exponent:-2 isNegative:(number1 < 0 ? YES : NO)];
    [newObject setValue:decimal forKey:@"number1"];
}

- (void)entitya_copyFromManagedObject:(NSManagedObject*)object 
                             toObject:(NSManagedObject*)newObject;
{
    NSEntityDescription *entity = [object entity];
    
    NSMutableArray *attributeKeys = [[[entity attributesByName] allKeys] mutableCopy]; 
    
    [attributeKeys removeObject:@"number1"];
    [attributeKeys removeObject:@"data1"];
    
    NSDictionary *attributeValues = [object dictionaryWithValuesForKeys:attributeKeys];
    [newObject setValuesForKeysWithDictionary:attributeValues];
    [attributeKeys release];
    
    NSString *data1 = [object valueForKey:@"data1"];
    int breakPoint = [data1 length]/2;
    NSString *data11 = [data1 substringToIndex:breakPoint];
    NSString *data12 = [data1 substringFromIndex:breakPoint];
    [newObject setValue:data11 forKey:@"data11"];
    [newObject setValue:data12 forKey:@"data12"];
    
    long number1 = ([[object valueForKey:@"number1"] doubleValue] * 100);
    NSDecimalNumber *decimal = [NSDecimalNumber decimalNumberWithMantissa:number1 exponent:-2 isNegative:(number1 < 0 ? YES : NO)];
    [newObject setValue:decimal forKey:@"number1"];
}

- (void)entitya_copyRelationshipsFromManagedObject:(NSManagedObject*)oldObject 
                                          toObject:(NSManagedObject*)newObject 
                                     withReference:(NSDictionary*)reference;
{
    //Just testing to make sure NSInvocation is working
    [newObject copyRelationshipsFromManagedObject:oldObject withReference:reference];
}

@end
