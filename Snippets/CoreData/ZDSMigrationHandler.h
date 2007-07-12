//
//  ZDSMigrationHandler.h
//  A simple class that will handle the migration of entities from one context to another.
//
//  Created by Marcus S. Zarra on 3/25/07.
//  Copyright 2007 Zarra Studios LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ZDSMigrationHandler : NSObject {
    id delegate;
    NSManagedObjectContext *oldContext;
    NSManagedObjectContext *newContext;
    NSManagedObjectModel *newModel;
    NSManagedObjectModel *noRelationshipModel;
    NSURL *tempFileURL;
    void* contextInfo;
}

+ (void)migrateContext:(NSManagedObjectContext*)oldContext
               toModel:(NSManagedObjectModel*)model
          withDelegate:(id)delegate
           contextInfo:(void*)contextInfo;

@end
