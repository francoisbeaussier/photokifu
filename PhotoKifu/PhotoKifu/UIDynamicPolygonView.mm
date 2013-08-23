//
//  UIDynamicPolygonView.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 14/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "UIDynamicPolygonView.h"
#include "GobanDetector.h"
#include "PerspectiveGrid.h"


@implementation UIDynamicPolygonView

@synthesize imageView = _imageView;
@synthesize scrollView = _scrollView;
@synthesize buttons = _buttons;
@synthesize corners = _corners;

@synthesize gridSize;

- (id) initWithImageView: (UIImageView *) contentImageView andScrollView: (UIScrollView *) scrollView andCorners: (cv::vector<cv::Point>) points;
{
    self = [super initWithFrame: contentImageView.frame];
    
    if (self)
    {
        self.imageView = contentImageView;
        self.scrollView = scrollView;
        
        self.buttons = [[NSMutableArray alloc] init];
        self.corners = [[NSMutableArray alloc] init];
        
        UIImage *targetImage = [UIImage imageNamed: @"target.png"];
        
        int defaultPositions[4 * 2] = {100, 100, 900, 100, 900, 900, 100, 900};
        
        for (int i = 0; i < 4; i++)
        {
            UIButton *button = [UIButton buttonWithType: UIButtonTypeCustom];
            [button setFrame: CGRectMake(0, 0, 60, 60)];
            
            if (points.size() == 4)
            {
                [button setCenter: CGPointMake(points[i].x, points[i].y)];
            }
            else
            {
                [button setCenter: CGPointMake(defaultPositions[i * 2], defaultPositions[i * 2 + 1])];
            }
            
//            [button addTarget: self action: @selector(buttonMoved:withEvent:) forControlEvents: UIControlEventTouchDragInside];
//            [button addTarget: self action: @selector(buttonMoved:withEvent:) forControlEvents: UIControlEventTouchDragOutside];
            [button setImage: targetImage forState: UIControlStateNormal];
            [button setTag: i];
            
            button.exclusiveTouch = YES;
            
            UILongPressGestureRecognizer* gestureMagnifier = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(handleMagnifier:)];
            gestureMagnifier.minimumPressDuration = 0.1;
            [button addGestureRecognizer: gestureMagnifier];
            
            [self.buttons addObject: button];
            [self.corners addObject: [NSValue valueWithCGPoint: button.center]];
        }
        
        for (UIButton *button in self.buttons)
        {
            [self addSubview: button];
        }
        
        loop = [[MagnifierView alloc] init];
        loop.viewToMagnify = self.imageView;
        
        [self updateAfterZoom];
    }
    
    return self;
}

float deltaTouchX, deltaTouchY;

- (void) handleMagnifier: (UILongPressGestureRecognizer*) recognizer
{
    CGPoint location = [recognizer locationInView: self];

    UIView *button = recognizer.view;

    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            //NSLog(@"handleLongPress: StateBegan (loc = %i, %i)", (int) location.x, (int) location.y);
            
            // save the delta between the button's center and the actual touch point
            deltaTouchX = location.x - button.center.x;
            deltaTouchY = location.y - button.center.y;
            
            // work with the center of the button from now on
            location = button.center;
            
            CGPoint imageViewLocation = [self convertPoint: location toView: self.imageView];
            loop.touchPoint = imageViewLocation;
//            loop.frame.origin = CGPointMake(location.x, location.y - 150);
            loop.center = CGPointMake(location.x, location.y - 66);
            [self addSubview: loop];
            [loop setNeedsDisplay];
        }
        break;
            
        case UIGestureRecognizerStateChanged:
        {
            // offset the touchlocation to be consistent with the button's center
            location = CGPointMake(location.x - deltaTouchX, location.y - deltaTouchY);
            
            //NSLog(@"handleLongPress: StateChanged (loc = %i, %i)", (int) location.x, (int) location.y);
            CGPoint imageViewLocation = [self convertPoint: location toView: self.imageView];
            loop.touchPoint = imageViewLocation;
            loop.center = CGPointMake(location.x, location.y - 66);
            [loop setNeedsDisplay];

            button.center = location;

//            CGPoint imageViewLocation = [self convertPoint: location toView: self.imageView];
            self.corners[button.tag] = [NSValue valueWithCGPoint: imageViewLocation];
            
            [self updateGrid];
        }
        break;
            
        case UIGestureRecognizerStateEnded:
        {
            //NSLog(@"handleLongPress: StateEnded");
            [loop removeFromSuperview];
        }
        break;
            
        default:
        break;
    }
}

- (IBAction) buttonMoved: (id) sender withEvent: (UIEvent *) event
{
    UIButton *button = sender;
    
    UITouch *t = [[event allTouches] anyObject];
    CGPoint pPrev = [t previousLocationInView: button];
    CGPoint p = [t locationInView: button];
    
    CGPoint center = button.center;
    center.x += p.x - pPrev.x;
    center.y += p.y - pPrev.y;
    button.center = center;
    
    self.corners[button.tag] = [NSValue valueWithCGPoint: [self convertPoint: center toView: self.imageView]];
    
    [self updateGrid];
}

- (void) updateAfterZoom
{
    for (UIButton *button in self.buttons)
    {
        CGPoint cornerPoint = [self.corners[button.tag] CGPointValue];
        CGPoint viewPoint = [self.imageView convertPoint: cornerPoint toView: self];
        
        [button setCenter: viewPoint];
    }
 
    [self updateGrid];
}

- (void) setGridSize: (int) size
{
    gridSize = size;
    
    [self setNeedsDisplay];
}

- (void) updateGrid
{
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void) drawRect: (CGRect) rect
{
//    CGPoint clipA = [self convertPoint: rect.origin toView: self.imageView];
//    CGPoint clipB = [self convertPoint: CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height) toView: self.imageView];

//    NSLog(@"clip: (%i, %i) -> (%i, %i)", (int)clipA.x, (int)clipA.y, (int)clipB.x, (int)clipA.y);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, 2.0);
    
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    
    PerspectiveGrid pg;
    
    cv::vector<cv::Point> cornerPoints = [self getCornersAsVector];

    cv::vector<cv::Point> sortedCorners = pg.sortCorners(cornerPoints);

    for (cv::vector<cv::Point>::iterator iter = sortedCorners.begin(); iter < sortedCorners.end(); iter++)
    {
        cv::Point corner = *iter;
        
        CGPoint cornerPoint = CGPointMake(corner.x, corner.y);
        
        CGPoint viewPoint = [self.imageView convertPoint: cornerPoint toView: self];
    
        if (iter == sortedCorners.begin())
        {
            CGContextMoveToPoint(context, viewPoint.x, viewPoint.y);
        }
        else
        {
            CGContextAddLineToPoint(context, viewPoint.x, viewPoint.y);
        }
    }
    
    cv::Point corner = sortedCorners.front();
    
    CGPoint cornerPoint = CGPointMake(corner.x, corner.y);
    CGPoint viewPoint = [self.imageView convertPoint: cornerPoint toView: self];
    
    CGContextAddLineToPoint(context, viewPoint.x, viewPoint.y);
    
    CGContextStrokePath(context);

    CGContextSetLineWidth(context, 1.0);
    
    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);

    if (pg.checkPolygonIsConvex(sortedCorners))
    {
        [self drawGrid: context withRect: self.corners withRows: gridSize withCols: gridSize];
    }
}

- (cv::vector<cv::Point>) getCornersAsVector
{
    cv::vector<cv::Point> cornerPoints;
    
    for (int i = 0 ; i < self.corners.count; i++)
    {
        CGPoint cornerPoint = [self.corners[i] CGPointValue];
        
        cornerPoints.push_back(cv::Point(cornerPoint.x, cornerPoint.y));
    }
    
    return cornerPoints;
}

- (void) drawGrid: (CGContextRef) context withRect: (NSMutableArray *) corners withRows: (int) rows withCols: (int) cols
{
    cv::vector<cv::Point> cornerPoints = [self getCornersAsVector];
    
    PerspectiveGrid pg;
    
    cv::vector<cv::vector<cv::Point>> lines = pg.getInnerGridLines(cornerPoints, rows);

    for (int i = 0; i < lines.size(); i++)
    {
        cv::vector<cv::Point> line = lines[i];
        
        CGPoint p1 = [self.imageView convertPoint: CGPointMake(line[0].x, line[0].y) toView: self];
        CGPoint p2 = [self.imageView convertPoint: CGPointMake(line[1].x, line[1].y) toView: self];

        [self drawLine: context from: p1 to: p2];
    }
    
    CGContextStrokePath(context);
}

- (void) drawLine: (CGContextRef) context from: (CGPoint) a to: (CGPoint) b
{
    CGContextMoveToPoint(context, a.x, a.y);
    CGContextAddLineToPoint(context, b.x, b.y);
}


@end
