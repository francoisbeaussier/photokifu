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
       // [self configure];
    }
    return self;
}

/*
- (id) initWithCoder:(NSCoder *)aCoder
{
    if(self = [super initWithCoder:aCoder])
    {
        [self configure];
    }
    return self;
}
*/

-(void) configure
{
    _gobanSize = 19;
    _gridCellWidth = 17;
    _gridLeftPadding = 7;
    
}

- (void) setStones: (cv::vector<cv::vector<cv::Point>>) stones
{
    _stones = stones;
}

- (void) drawRect:(CGRect)rect
{
    [self configure];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 1.0);
    
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

    if (_stones.size() == 0)
    {
        return;
    }
    
    cv::vector<cv::Point> blackStones = _stones[0];
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);

    for (int i = 0; i < blackStones.size(); i++)
    {
        cv::Point point = blackStones[i];

        float diameter = (_gridCellWidth - 2);
        float radius = diameter / 2;
        
        CGRect circle = CGRectMake(_gridLeftPadding + point.x * _gridCellWidth - radius, _gridLeftPadding + point.y * _gridCellWidth - radius, diameter, diameter);
        
        CGContextFillEllipseInRect(context, circle);
    }
    
    CGContextStrokePath(context);

    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);

    cv::vector<cv::Point> whiteStones = _stones[1];

    for (int i = 0; i < whiteStones.size(); i++)
    {
        cv::Point point = whiteStones[i];
        
        int radius = _gridCellWidth * 0.9;
        CGRect circle = CGRectMake(_gridLeftPadding + point.x * _gridCellWidth - radius / 2, _gridLeftPadding + point.y * _gridCellWidth - radius / 2, radius, radius);
        
        CGContextFillEllipseInRect(context, circle);
        CGContextStrokeEllipseInRect(context, circle);
    }
    
    CGContextDrawPath(context, kCGPathFillStroke);
    //CGContextStrokePath(context);
}

- (void) drawLine:(CGContextRef)context x1:(int)x1 y1:(int)y1 x2:(int)x2 y2:(int)y2
{
    CGContextMoveToPoint(context, x1, y1);
    CGContextAddLineToPoint(context, x2, y2);
}

@end
