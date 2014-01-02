//
//  AppDelegate.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 13/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "GobanScanData.h"
#import "Utils.h"
#import "ScanDisplay.h"
#import "ScanData.h"
#import <UIKit/UIImage.h>
#import "DataManager.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (UIImage *) generateThumb: (UIImage *) image
{
    CGSize targetSize = (CGSize) { 100, 80 };
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = (CGRect){ 0, 0, targetSize.width, targetSize.height };
    
    [image drawInRect: thumbnailRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void) StoreScanPhoto: (NSString *) photoName
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    UIImage *image = [UIImage imageNamed: photoName];
    //    CGSize newSize = CGSizeMake(1600, 1200);
    //    image = [Utils resizeImage:image scaledToSize:newSize];
    UIImage *thumb = [AppDelegate generateThumb: image];
    
    ScanDisplay *scanDisplay = [NSEntityDescription
                                insertNewObjectForEntityForName:@"ScanDisplay"
                                inManagedObjectContext:context];
    scanDisplay.title = photoName;
    scanDisplay.thumbnailData = UIImageJPEGRepresentation(thumb, 0.0);
    scanDisplay.scanDate = [NSDate date];
    
    ScanData *scanData = [NSEntityDescription
                          insertNewObjectForEntityForName:@"ScanData"
                          inManagedObjectContext:context];
    
    scanData.photoData = UIImageJPEGRepresentation(image, 0.0);
    scanData.komi = [NSNumber numberWithDouble: 6.5];
    scanData.blackPlaysNext = [NSNumber numberWithBool: true];
    
    scanDisplay.details = scanData;
    
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Could not save ScanDisplay or ScanData: %@", [error localizedDescription]);
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ScanDisplay" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects.count == 0)
    {
        [self StoreScanPhoto: @"photo_0.jpg"];
        [self StoreScanPhoto: @"photo_1.jpg"];
        [self StoreScanPhoto: @"photo_2.jpg"];
        [self StoreScanPhoto: @"photo_3.jpg"];
        [self StoreScanPhoto: @"photo_4.jpg"];
        [self StoreScanPhoto: @"photo_5.jpg"];
        [self StoreScanPhoto: @"photo_6.jpg"];
        
        [context save: &error];
    }
    
    // Pass the managedObjectContext down to the view controller
    
    [DataManager sharedInstance].context = self.managedObjectContext;
    
//    UINavigationController * navController = (UINavigationController *) self.window.rootViewController;
//    MasterViewController *masterController = [navController.viewControllers objectAtIndex: 0];
//    masterController.managedObjectContext = self.managedObjectContext;
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [[DataManager sharedInstance] save];
        
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
