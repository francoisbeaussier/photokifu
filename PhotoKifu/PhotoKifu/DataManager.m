//
//  DataManager.m
//  PhotoKifu
//
//  Created by Francois Beaussier on 29/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "DataManager.h"

@implementation DataManager

+ (instancetype) sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^
                  {
                      sharedInstance = [self new];
                  });
    
    return sharedInstance;
}

- (id) init
{
    self = [super init];
    
    if (self != nil)
    {
    }
    
    return self;
}


- (void) save
{
    NSError *error;
    if (![self.context save:&error])
    {
        NSLog(@"Could not save update to corners: %@", [error localizedDescription]);
    }
}

- (ScanDisplay *) addNewScanFromBundle: (NSString *) photoName
{
    UIImage *image = [UIImage imageNamed: photoName];
    
    ScanDisplay *scanDisplay = [self addNewScan: image withTitle: photoName];
    
    return scanDisplay;
}

- (ScanDisplay *) addNewScan: (UIImage *) image withTitle: (NSString *) title
{
    //    CGSize newSize = CGSizeMake(1600, 1200);
    //    image = [Utils resizeImage:image scaledToSize:newSize];
    UIImage *thumb = [self generateThumb: image];
    
    ScanDisplay *scanDisplay = [NSEntityDescription
                                insertNewObjectForEntityForName:@"ScanDisplay"
                                inManagedObjectContext:self.context];
    scanDisplay.title = title;
    scanDisplay.thumbnailData = UIImageJPEGRepresentation(thumb, 0.0);
    scanDisplay.scanDate = [NSDate date];
    
    ScanData *scanData = [NSEntityDescription
                          insertNewObjectForEntityForName:@"ScanData"
                          inManagedObjectContext:self.context];
    
    scanData.photoData = UIImageJPEGRepresentation(image, 0.0);
    scanData.komi = [NSNumber numberWithFloat: 6.5f];
    scanData.rotation = [NSNumber numberWithInt: 0];
    scanData.blackPlaysNext = [NSNumber numberWithBool: true];
    
    scanDisplay.details = scanData;
    
    NSError *error;
    if (![self.context save:&error]) {
        NSLog(@"Could not save ScanDisplay or ScanData: %@", [error localizedDescription]);
    }
    
    return scanDisplay;
}

- (UIImage *) generateThumb: (UIImage *) image
{
    CGSize targetSize = (CGSize) { 100, 80 };
    UIGraphicsBeginImageContext(targetSize);
    
    CGRect thumbnailRect = (CGRect){ 0, 0, targetSize.width, targetSize.height };
    
    [image drawInRect: thumbnailRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (NSMutableArray *) loadScans
{
   
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ScanDisplay" inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    
    NSMutableArray *result = [NSMutableArray arrayWithArray: [self.context executeFetchRequest:fetchRequest error:&error]];
    
    if (error != nil) {
        NSLog(@"Could not fetch ScanDisplays: %@", [error localizedDescription]);
    }
    
    return result;
}

@end
