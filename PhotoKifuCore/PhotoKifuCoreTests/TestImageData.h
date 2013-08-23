//
//  TestImageData.h
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 15/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TestImageData : NSObject

@property (assign, nonatomic) CGPoint a;
@property (assign, nonatomic) CGPoint b;
@property (assign, nonatomic) CGPoint c;
@property (assign, nonatomic) CGPoint d;

@property (strong, nonatomic) UIImage *image;

- (id) initWithImage:(UIImage *)image andCoordinates:(CGPoint)a :(CGPoint)b :(CGPoint)c :(CGPoint)d;

@end
