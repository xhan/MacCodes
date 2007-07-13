//
//  ZDSMigrationHandler.h
//  A simple class that will handle the migration of entities from one context to another.
//
//  Created by Marcus S. Zarra on 3/25/07.
//  Copyright 2007 Zarra Studios LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ZDSMigrationHandler : NSObject {
    NSError *error;
    
    NSString *currentEntityName;
    unsigned currentObjectIndex;
    unsigned totalObjectsForEntity;
    
    NSManagedObjectContext *oldContext;
    NSManagedObjectContext *newContext;
    NSManagedObjectModel *newModel;
    NSManagedObjectModel *modelWithoutConstraints;
    
    NSURL *tempFileURL;

    id delegate;
    id contextInfo;
}

- (NSString*)tempFilePath;
- (NSError*)error;
- (id)contextInfo;
- (NSString*)currentEntityName;
- (unsigned)currentObjectIndex;
- (unsigned)totalObjectsForEntity;

+ (void)migrateContext:(NSManagedObjectContext*)oldContext
               toModel:(NSManagedObjectModel*)model
          withDelegate:(id)delegate
           context:(void*)contextInfo;

@end

@interface NSObject(ZDSMigrationHandlerDelegate)

- (void)migrationCompletedSuccessfully:(id)migrationHandler;
- (void)migrationFailed:(id)migrationHandler;
- (void)migrationUpdate:(id)migrationHandler;
- (void)migrationProgress:(id)migrationHandler;

@end