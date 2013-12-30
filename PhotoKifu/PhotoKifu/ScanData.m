//
//  ScanData.m
//  PhotoKifu
//
//  Created by Francois Beaussier on 29/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "ScanData.h"


@implementation ScanData

@dynamic photo;
@dynamic gridCorners;
@dynamic stones;
@dynamic player1Name;
@dynamic komi;
@dynamic player2Name;
@dynamic blackPlaysNext;

- (void) setGrid: (PKGrid *) grid
{
    CGPoint array[4];
    
    array[0] = grid.corner1;
    array[1] = grid.corner2;
    array[2] = grid.corner3;
    array[3] = grid.corner4;
    
    NSData *data = [[NSData alloc] initWithBytes:&array length:sizeof(CGPoint) * 4];
    
   [self setGridCorners:data];
}

- (PKGrid *) getGrid
{
    if (self.gridCorners == nil)
        return nil;
    
    CGPoint array[4];
    
    [self.gridCorners getBytes: &array length: sizeof(CGPoint) * 4];

    PKGrid *grid = [[PKGrid alloc] init];
    
    grid.corner1 = array[0];
    grid.corner2 = array[1];
    grid.corner3 = array[2];
    grid.corner4 = array[3];
    
    return grid;
}

@end
