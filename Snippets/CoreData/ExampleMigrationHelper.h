//
//  ExampleMigrationHandler.h
//  MigrationTest
//
//  Created by Marcus S. Zarra on 7/17/07.
//  Copyright 2007 Zarra Studios LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ExampleMigrationHelper : NSObject {

}

- (void)entitya_copyFromManagedObject:(NSManagedObject*)oldObject 
                             toObject:(NSManagedObject*)newObject;

- (void)entitya_copyRelationshipsFromManagedObject:(NSManagedObject*)oldObject 
                                          toObject:(NSManagedObject*)newObject 
                                     withReference:(NSDictionary*)reference;

@end
