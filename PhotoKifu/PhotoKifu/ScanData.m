//
//  ScanData.m
//  PhotoKifu
//
//  Created by Francois Beaussier on 29/12/2013.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "ScanData.h"

@implementation ScanData

@dynamic photoData;
@dynamic gridData;
@dynamic stonesData;
@dynamic player1Name;
@dynamic komi;
@dynamic rotation;
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
    
    self.gridData = data;
}

- (PKGrid *) getGrid
{
    if (self.gridData == nil)
        return nil;
    
    CGPoint array[4];
    
    [self.gridData getBytes: &array length: sizeof(CGPoint) * 4];

    PKGrid *grid = [[PKGrid alloc] init];
    
    grid.corner1 = array[0];
    grid.corner2 = array[1];
    grid.corner3 = array[2];
    grid.corner4 = array[3];
    
    return grid;
}

- (void) setStones: (PKStones *) stones
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: stones];
    
    self.stonesData = data;
}

- (PKStones *) getStones
{
    if (self.stonesData == nil)
        return nil;
    
    PKStones *stones = [NSKeyedUnarchiver unarchiveObjectWithData: self.stonesData];
    
    return stones;
}

@end
