//
//  GobanView.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 11/07/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "GobanView.h"

@implementation GobanView

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self configure];
        
        self.WarpedImageRotationAngle = 0;
        self.userInteractionEnabled = true;
        
    }
    return self;
}

-(void) configure
{
    int padding = 30;
    int width = 1000 - padding * 2;
    
    _gobanSize = 19;
    _gridCellWidth = (width / 18);
    _gridLeftPadding = padding + (width - _gridCellWidth * 18) / 2;
}

- (CGPoint) coordinateFromPoint: (CGPoint) point
{
    int x = (point.x - _gridLeftPadding + _gridCellWidth / 2) / _gridCellWidth;
    int y = (point.y - _gridLeftPadding + _gridCellWidth / 2) / _gridCellWidth;
    
    return CGPointMake(x, y);
}

#define radians(degrees) ((degrees) * M_PI/180)

- (void) drawRect:(CGRect)rect
{
    [self configure];
   
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (self.WarpedImageIsVisible)
    {
        CGRect grid = CGRectMake(rect.origin.x + _gridLeftPadding, rect.origin.y + _gridLeftPadding, rect.size.width - _gridLeftPadding * 2, rect.size.height - _gridLeftPadding * 2);
        
        CGContextSaveGState(context);
        
        CGContextTranslateCTM( context, 0.5f * rect.size.width, 0.5f * rect.size.height ) ;
        CGContextRotateCTM( context, radians( -90 + self.WarpedImageRotationAngle) ) ;
        CGContextTranslateCTM( context, -0.5f * rect.size.width, -0.5f * rect.size.height ) ;
        
        [ _warpedImage drawInRect:grid];
        
        CGContextRestoreGState(context);
    }
    
    CGContextSetLineWidth(context, 3.0);
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);

    for (int i = 0; i < _gobanSize; i++)
    {
        int x1 = _gridLeftPadding + i * _gridCellWidth;
        int y1 = _gridLeftPadding;
        int x2 = _gridLeftPadding + i * _gridCellWidth;
        int y2 = _gridLeftPadding + (_gobanSize - 1) * _gridCellWidth;
        
        [self drawLine:context x1:x1 y1:y1 x2:x2 y2:y2];

        x1 = _gridLeftPadding;
        y1 = _gridLeftPadding + i * _gridCellWidth;
        x2 = _gridLeftPadding + (_gobanSize - 1) * _gridCellWidth;
        y2 = _gridLeftPadding + i * _gridCellWidth;
        
        [self drawLine:context x1:x1 y1:y1 x2:x2 y2:y2];
    }
    
    CGContextStrokePath(context);
    
    if (self.stones.blackStones.count == 0 && self.stones.whiteStones.count == 0)
    {
        return;
    }
    
    //CGContextSetLineWidth(context, 3.0);
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);

    for (NSValue *value in self.stones.blackStones)
    {
        CGPoint point = [value CGPointValue];

        float diameter = (_gridCellWidth - 2);
        float radius = diameter / 2;
        
        if (self.WarpedImageIsVisible)
        {
            float innerDiameter = diameter * 0.8f;
            float innerRadius = innerDiameter / 2;
        
            CGRect circle = CGRectMake(_gridLeftPadding + point.x * _gridCellWidth - radius, _gridLeftPadding + point.y * _gridCellWidth - radius, diameter, diameter);
            CGRect innerCircle = CGRectMake(_gridLeftPadding + point.x * _gridCellWidth - innerRadius, _gridLeftPadding + point.y * _gridCellWidth - innerRadius, innerDiameter, innerDiameter);
        
            CGContextAddEllipseInRect(context, circle);
            CGContextAddEllipseInRect(context, innerCircle);
            
            CGContextEOFillPath(context);
            CGContextStrokeEllipseInRect(context, innerCircle);
        }
        else
        {
            CGRect circle = CGRectMake(_gridLeftPadding + point.x * _gridCellWidth - radius, _gridLeftPadding + point.y * _gridCellWidth - radius, diameter, diameter);
            
            CGContextFillEllipseInRect(context, circle);
        }
    }
    
    CGContextStrokePath(context);

    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);

    for (NSValue *value in self.stones.whiteStones)
    {
        CGPoint point = [value CGPointValue];
        
        float diameter = (_gridCellWidth - 2);
        float radius = diameter / 2;
        
        if (self.WarpedImageIsVisible)
        {
            float innerDiameter = diameter * 0.8f;
            float innerRadius = innerDiameter / 2;
            
            CGRect circle = CGRectMake(_gridLeftPadding + point.x * _gridCellWidth - radius, _gridLeftPadding + point.y * _gridCellWidth - radius, diameter, diameter);
            CGRect innerCircle = CGRectMake(_gridLeftPadding + point.x * _gridCellWidth - innerRadius, _gridLeftPadding + point.y * _gridCellWidth - innerRadius, innerDiameter, innerDiameter);
            
            CGContextAddEllipseInRect(context, circle);
            CGContextAddEllipseInRect(context, innerCircle);
            
            CGContextEOFillPath(context);
            CGContextStrokeEllipseInRect(context, innerCircle);
        }
        else
        {
            float radius = diameter / 2;
            
            CGRect circle = CGRectMake(_gridLeftPadding + point.x * _gridCellWidth - radius, _gridLeftPadding + point.y * _gridCellWidth - radius, diameter, diameter);
            
            CGContextFillEllipseInRect(context, circle);
            CGContextStrokeEllipseInRect(context, circle);
        }
    }
    
    CGContextDrawPath(context, kCGPathFillStroke);
    //CGContextStrokePath(context);
}

- (void) drawLine:(CGContextRef)context x1:(int)x1 y1:(int)y1 x2:(int)x2 y2:(int)y2
{
    CGContextMoveToPoint(context, x1, y1);
    CGContextAddLineToPoint(context, x2, y2);
}

- (void) setWarpedImage: (UIImage *) image
{
    _warpedImage = image;
}

@end
