//
//  PhotoKifuCore.m
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 9/04/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "PhotoKifuCore.h"

@implementation PhotoKifuCore

+ (UIImage *) imageWithImage: (UIImage *) image scaledToSize: (CGSize) newSize
{
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSString *) generateSgfContent: (cv::vector<cv::vector<cv::Point>>) stones
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz";

    NSMutableString *content = [NSMutableString stringWithString: @"(;GM[1]SZ[19]FF[4]"];

    cv::vector<cv::Point> blackStones = stones[0];

    if (blackStones.size() > 0)
    {
        [content appendFormat: @"AB"];
        
        for (cv::vector<cv::Point>::iterator it = blackStones.begin(); it < blackStones.end(); it++)
        {
            cv::Point point = *it;
            
            NSString *x = [letters substringWithRange: NSMakeRange(point.x, 1)];
            NSString *y = [letters substringWithRange: NSMakeRange(point.y, 1)];
            
            [content appendFormat: @"[%@%@]", x , y];
        }
    }
    
    cv::vector<cv::Point> whiteStones = stones[1];
    
    if (whiteStones.size() > 0)
    {
        [content appendFormat: @"AW"];
        
        for (cv::vector<cv::Point>::iterator it = whiteStones.begin(); it < whiteStones.end(); it++)
        {
            cv::Point point = *it;
            
            NSString *x = [letters substringWithRange: NSMakeRange(point.x, 1)];
            NSString *y = [letters substringWithRange: NSMakeRange(point.y, 1)];
            
            [content appendFormat: @"[%@%@]", x , y];
        }
    }
    
    [content appendString: @")"];
    
    return content;
}

+ (cv::Mat) cvMatFromUIImage: (UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (cv::Mat) cvMatFromUIImageHSV: (UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC3); // 8 bits per component, 3 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (UIImage *) UIImageFromCVMat: (cv::Mat) cvMat
{
    NSData *data = [NSData dataWithBytes: cvMat.data length: cvMat.elemSize() * cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef) data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    //UIImage *finalImage = [UIImage imageWithCGImage: imageRef];
    
    // I had to add the orientation parameter
    UIImage *finalImage = [UIImage imageWithCGImage: imageRef scale:1.0 orientation:UIImageOrientationRight];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
