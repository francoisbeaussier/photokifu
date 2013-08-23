//
//  TestImageData.m
//  PhotoKifuCore
//
//  Created by Francois Beaussier on 15/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "TestImageData.h"

@implementation TestImageData

- (id) initWithImage:(UIImage *)image andCoordinates:(CGPoint)a :(CGPoint)b :(CGPoint)c :(CGPoint)d
{
    if (self = [super init])
    {
        self.image = image;

        self.a = a;
        self.b = b;
        self.c = c;
        self.d = d;
    }
    
    return self;
}

@end
