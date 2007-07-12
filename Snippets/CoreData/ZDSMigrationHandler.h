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
    id contextInfo;
}

+ (void)migrateContext:(NSManagedObjectContext*)oldContext
               toModel:(NSManagedObjectModel*)model
          withDelegate:(id)delegate
           context:(void*)contextInfo;

@end

@interface NSObject(ZDSMigrationHandlerDelegate)

- (void)migrationCompletedSuccessfully:(id)migrationHandler filePath:(NSString*)filePath context:(void*)contextInfo;
- (void)migrationFailed:(id)migrationHandler error:(NSError*)error context:(void*)contextInfo;
- (void)migrationUpdate:(id)migrationHandler entity:(NSString*)entityName count:(unsigned)numberOfEntities context:(void*)contextInfo;
- (void)migrationProgress:(id)migrationHandler currentCount:(unsigned)current context:(void*)contextInfo;
- (void)migrationStage:(id)migrationHandler stage:(NSString*)stageName context:(void*)contextInfo;

@end