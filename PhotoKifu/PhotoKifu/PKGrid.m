//
//  PKGrid.m
//  PhotoKifu
//
//  Created by Francois Beaussier on 31/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "PKGrid.h"

@implementation PKGrid

- (void) setCorner: (CGPoint) point atZeroBasedIndex: (int) zeroBasedIndex
{
    [self setValue: [NSValue valueWithCGPoint:point] forKey: [NSString stringWithFormat: @"corner%i", zeroBasedIndex + 1]];
}

- (CGPoint) getCornerAtZeroBasedIndex: (int) zeroBasedIndex
{
    NSValue *value = [self valueForKey: [NSString stringWithFormat: @"corner%i", zeroBasedIndex + 1]];

    return [value CGPointValue];
}

@end
