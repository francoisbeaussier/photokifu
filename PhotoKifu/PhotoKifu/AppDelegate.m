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

@implementation AppDelegate

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

- (GobanScanData *) LoadScanPhoto: (NSString *) photoName
{
    UIImage *image = [UIImage imageNamed: photoName];

//    CGSize newSize = CGSizeMake(1600, 1200);
    
//    image = [Utils resizeImage:image scaledToSize:newSize];

    UIImage *thumb = [AppDelegate generateThumb: image];
    
    GobanScanData *scan = [[GobanScanData alloc] initWithTitle: photoName thumbImage: thumb fullImage: image];

    return scan;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    GobanScanData *scan0 = [self LoadScanPhoto: @"photo_0.jpg"];
    GobanScanData *scan1 = [self LoadScanPhoto: @"photo_1.jpg"];
    GobanScanData *scan2 = [self LoadScanPhoto: @"photo_2.jpg"];
    GobanScanData *scan3 = [self LoadScanPhoto: @"photo_3.jpg"];
    GobanScanData *scan4 = [self LoadScanPhoto: @"photo_4.jpg"];
    GobanScanData *scan5 = [self LoadScanPhoto: @"photo_5.jpg"];
    GobanScanData *scan6 = [self LoadScanPhoto: @"photo_6.jpg"];
    
    NSMutableArray *scans = [NSMutableArray arrayWithObjects: scan0, scan1, scan2, scan3, scan4, scan5, scan6, nil];
    
    UINavigationController * navController = (UINavigationController *) self.window.rootViewController;
    MasterViewController *masterController = [navController.viewControllers objectAtIndex: 0];
    masterController.scans = scans;
    
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

@end
