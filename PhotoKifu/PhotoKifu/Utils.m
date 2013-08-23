//
//  Utils.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 15/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (UIImage *)resizeImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
