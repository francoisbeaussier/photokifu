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

- (ScanDisplay *) addNewScanFromBundle: (NSString *) photoName withTitle: (NSString *) title
{
    UIImage *image = [UIImage imageNamed: photoName];
    
    ScanDisplay *scanDisplay = [self addNewScan: image withTitle: title];
    
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
    const int targetHeight = 58;
    
    
    CGSize targetSize = CGSizeMake(targetHeight / 3 * 4, targetHeight);
    
    UIImage *croped = [self cropImage: image cropSize: targetSize];
    
    return croped;
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, UIScreen.mainScreen.scale);
    
    CGRect thumbnailRect = (CGRect){ 0, 0, targetSize.width, targetSize.height };
    
    [image drawInRect: thumbnailRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *) cropImage:(UIImage *)originalImage cropSize:(CGSize)cropSize
{
    //calculate scale factor to go between cropframe and original image
    float SF = originalImage.size.width / cropSize.width;
    
    //find the centre x,y coordinates of image
    float centreX = originalImage.size.width / 2;
    float centreY = originalImage.size.height / 2;
    
    //calculate crop parameters
    float cropX = centreX - ((cropSize.width / 2) * SF);
    float cropY = centreY - ((cropSize.height / 2) * SF);
    
    CGRect cropRect = CGRectMake(cropX, cropY, (cropSize.width *SF), (cropSize.height * SF));
    
    CGAffineTransform rectTransform;
    switch (originalImage.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI_2), 0, -originalImage.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), -originalImage.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI), -originalImage.size.width, -originalImage.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    rectTransform = CGAffineTransformScale(rectTransform, originalImage.scale, originalImage.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([originalImage CGImage], CGRectApplyAffineTransform(cropRect, rectTransform));
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:originalImage.scale orientation:originalImage.imageOrientation];
    CGImageRelease(imageRef);
    
    //Now want to scale down cropped image!
    //want to multiply frames by 2 to get retina resolution
    CGRect scaledImgRect = CGRectMake(0, 0, cropSize.width, cropSize.height);
    
    UIGraphicsBeginImageContextWithOptions(cropSize, NO, [UIScreen mainScreen].scale);
    
    [result drawInRect:scaledImgRect];
    
    UIImage *scaledNewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledNewImage;
    
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
