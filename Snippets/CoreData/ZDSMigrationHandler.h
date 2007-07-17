// ZDSMigrationHandler.h
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

#import <Cocoa/Cocoa.h>

@interface ZDSMigrationHandler : NSObject {
    BOOL threaded;
    BOOL warnings;
    BOOL haltMigration;
    NSString *pathForFileToMigrate;
    NSString *pathToModelToMigrateFrom;
    NSString *pathToModelToMigrateTo;
    NSString *storeTypeToMigrateFrom;
    NSString *storeTypeToMigrateTo;
    NSDictionary *newStoreMetadata;
    id migrationHelper;
    
    NSError *error;
    
    NSString *currentEntityName;
    unsigned currentEntityIndex;
    unsigned currentInstanceIndex;
    unsigned totalInstances;
    unsigned totalEntities;
    
    NSManagedObjectContext *oldContext;
    NSManagedObjectContext *newContext;
    NSManagedObjectModel *newModel;
    
    NSURL *tempFileURL;

    id delegate;
    id contextInfo;
}

- (id)initWithDelegate:(id)newDelegate;

- (void)stopMigration;
- (void)startMigration;

- (NSString*)tempFilePath;
- (NSError*)error;
- (id)contextInfo;
- (NSString*)currentEntityName;

#pragma mark -
#pragma mark Status Points

- (unsigned)currentEntityIndex;
- (unsigned)currentInstanceIndex;
- (unsigned)totalInstances;
- (unsigned)totalEntities;

#pragma mark -
#pragma mark accessors

- (NSString*)pathForFileToMigrate;
- (void)setPathForFileToMigrate:(NSString*)aPathForFileToMigrate;
- (NSString*)pathToModelToMigrateFrom;
- (void)setPathToModelToMigrateFrom:(NSString*)aPathToModelToMigrateFrom;
- (NSString*)pathToModelToMigrateTo;
- (void)setPathToModelToMigrateTo:(NSString*)aPathToModelToMigrateTo;
- (NSString*)storeTypeToMigrateFrom;
- (void)setStoreTypeToMigrateFrom:(NSString*)aStoreTypeToMigrateFrom;
- (NSString*)storeTypeToMigrateTo;
- (void)setStoreTypeToMigrateTo:(NSString*)aStoreTypeToMigrateTo;
- (id)migrationHelper;
- (void)setMigrationHelper:(id)aMigrationHelper;
- (BOOL)warnings;
- (void)setWarnings:(BOOL)flag;
- (BOOL)threaded;
- (void)setThreaded:(BOOL)flag;
- (NSDictionary*)newStoreMetadata;
- (void)setNewStoreMetadata:(NSDictionary*)aNewStoreMetadata;

@end

@interface NSObject(ZDSMigrationHandlerDelegate)

- (void)migrationCompletedSuccessfully:(id)migrationHandler;
- (void)migrationFailed:(id)migrationHandler;
- (void)migrationUpdate:(id)migrationHandler;
- (void)migrationStopped:(id)migrationHandler;

@end


@interface NSManagedObject (ZDSMigration)

- (NSString*)objectIDString;

- (BOOL)orphan;
- (void)fault;

- (void)copyFromManagedObject:(id)object;
- (void)copyRelationshipsFromManagedObject:(id)object withReference:(NSDictionary *)reference;

@end
