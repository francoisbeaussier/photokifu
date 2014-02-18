//
//  PKStones.m
//  PhotoKifu
//
//  Created by Francois Beaussier on 1/01/2014.
//  Copyright (c) 2014 Francois Beaussier. All rights reserved.
//

#import "PKStones.h"
#import "ScanData.h"

const int PKStonesEmpty = 0;
const int PKStonesBlack = 1;
const int PKStonesWhite = 2;

@implementation PKStones

- (id) init
{
    self = [super init];
    
    if (self)
    {
        self.blackStones = [[NSMutableArray alloc] init];
        self.whiteStones = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (int) getStoneColor:(CGPoint) coordinates
{
    for (NSValue *value in self.blackStones)
    {
        CGPoint point = [value CGPointValue];
        
        if (point.x == coordinates.x && point.y == coordinates.y)
        {
            return PKStonesBlack;
        }
    }

    for (NSValue *value in self.whiteStones)
    {
        CGPoint point = [value CGPointValue];
        
        if (point.x == coordinates.x && point.y == coordinates.y)
        {
            return PKStonesWhite;
        }
    }
    
    return PKStonesEmpty;
}

- (void) addBlackStone:(CGPoint) coordinates
{
    [self.blackStones addObject: [NSValue valueWithCGPoint: coordinates]];
}

- (void) addWhiteStone:(CGPoint) coordinates
{
    [self.whiteStones addObject: [NSValue valueWithCGPoint: coordinates]];
}

- (void) removeBlackStone:(CGPoint) coordinates
{
    [self.blackStones removeObject: [NSValue valueWithCGPoint: coordinates]];
}

- (void) removeWhiteStone:(CGPoint) coordinates
{
    [self.whiteStones removeObject: [NSValue valueWithCGPoint: coordinates]];
}

- (NSString *) generateSgfContentWithScanDisplay: (ScanDisplay *) scanDisplay
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz";
    
    NSMutableString *content = [NSMutableString stringWithString: @"(;GM[1]SZ[19]FF[4]"];
    
    if (scanDisplay.details.player1Name != nil)
    {
        [content appendFormat: @"PB[%@]", scanDisplay.details.player1Name];
    }

    if (scanDisplay.details.player2Name != nil)
    {
        [content appendFormat: @"PW[%@]", scanDisplay.details.player2Name];
    }
    
    if (scanDisplay.scanDate != nil)
    {
        [content appendFormat: @"DT[%@]", scanDisplay.scanDate];
    }
    
    [content appendString: @"AP[PhotoKifu]"];
    
    if (self.blackStones.count > 0)
    {
        [content appendString: @"AB"];
        
        for (NSValue *value in self.blackStones)
        {
            CGPoint point = [value CGPointValue];
            
            NSString *x = [letters substringWithRange: NSMakeRange(point.x, 1)];
            NSString *y = [letters substringWithRange: NSMakeRange(point.y, 1)];
            
            [content appendFormat: @"[%@%@]", x , y];
        }
    }
    
    if (self.whiteStones.count > 0)
    {
        [content appendString: @"AW"];
        
        for (NSValue *value in self.whiteStones)
        {
            CGPoint point = [value CGPointValue];
            
            NSString *x = [letters substringWithRange: NSMakeRange(point.x, 1)];
            NSString *y = [letters substringWithRange: NSMakeRange(point.y, 1)];
            
            [content appendFormat: @"[%@%@]", x , y];
        }
    }
    
    if ([scanDisplay.details.blackPlaysNext intValue] == 0)
    {
        [content appendString: @";AB[]"];
    }
    
    [content appendString: @")"];
    
    return content;
}

- (void) rotate
{
    const int boardSize = 19;
    
    for (int i = 0; i < self.blackStones.count; i++)
    {
        NSValue *value = [self.blackStones objectAtIndex: i];
        CGPoint point = [value CGPointValue];
        
        value = [NSValue valueWithCGPoint: CGPointMake(boardSize - 1 - point.y, point.x)];
        
        [self.blackStones replaceObjectAtIndex: i withObject:value];
    }


    for (int i = 0; i < self.whiteStones.count; i++)
    {
        NSValue *value = [self.whiteStones objectAtIndex: i];
        CGPoint point = [value CGPointValue];
        
        value = [NSValue valueWithCGPoint: CGPointMake(boardSize - 1 - point.y, point.x)];
        
        [self.whiteStones replaceObjectAtIndex: i withObject:value];
    }
}

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.blackStones forKey:@"blackStones"];
    [coder encodeObject:self.whiteStones forKey:@"whiteStones"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    if (self)
    {
        self.blackStones = [coder decodeObjectForKey:@"blackStones"];
        self.whiteStones = [coder decodeObjectForKey:@"whiteStones"];
    }
    
    return self;
}

@end
