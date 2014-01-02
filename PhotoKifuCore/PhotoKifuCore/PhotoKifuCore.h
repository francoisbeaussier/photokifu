//
//  PhotoKifuCore.h
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 9/04/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PhotoKifuCore : NSObject

@property (nonatomic, assign) int alpha;

+ (UIImage *) imageWithImage: (UIImage *) image scaledToSize: (CGSize) newSize;

+ (cv::Mat) cvMatFromUIImage: (UIImage *) image;
 
+ (cv::Mat) cvMatFromUIImageHSV: (UIImage *)image;

+ (UIImage *) UIImageFromCVMat: (cv::Mat) cvMat;

@end
