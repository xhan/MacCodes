#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject {
    IBOutlet NSWindow *progressWindow;
    IBOutlet NSPanel *waitSheet;
    
    NSString *currentEntityName;
    
    int totalEntities;
    int currentEntityIndex;
    int totalInstances;
    int currentInstanceIndex;

    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    
    NSURL *databaseURL;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)startMigration:(id)sender;

@end
