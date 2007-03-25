//
//  ZDSManagedObject.h
//  
//  The ZDSManagedObject is designed as a subclass of the NSManagedObject and should be the parent
//  class of any object that you want to be in Core Data and migratable.
//
//  Created by Marcus S. Zarra on 3/25/07.
//  Copyright 2007 Zarra Studios LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ZDSManagedObject : NSManagedObject {

}

- (void)copyFromManagedObject:(id)object withReference:(NSMutableDictionary *)reference;
- (void)copyRelationshipsFromManagedObject:(id)object withReference:(NSMutableDictionary *)reference;

@end
