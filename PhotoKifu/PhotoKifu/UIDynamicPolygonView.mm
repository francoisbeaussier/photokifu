//
//  UIDynamicPolygonView.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 14/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

#import "UIDynamicPolygonView.h"
#import <PhotoKifuCore/GobanDetector.h>
#import <PhotoKifuCore/PerspectiveGrid.h>


@implementation UIDynamicPolygonView

@synthesize gridSize;

- (id) initWithImageView: (UIImageView *) contentImageView andScrollView: (UIScrollView *) scrollView andGrid:(PKGrid *)grid;
{
    self = [super initWithFrame: contentImageView.frame];
    
    if (self)
    {
        self.imageView = contentImageView;
        self.scrollView = scrollView;
        
        self.buttons = [[NSMutableArray alloc] init];
        self.grid = [[PKGrid alloc] init];
        
        //self.alpha = 0.5f;
        //self.backgroundColor = [UIColor greenColor];
        
        UIImage *targetImage = [UIImage imageNamed: @"target.png"];
        

        float width = self.scrollView.contentSize.width / self.scrollView.zoomScale;
        float height = self.scrollView.contentSize.height / self.scrollView.zoomScale;
       
        float margin = width / 10;
        float defaultPositions[4 * 2] = {margin, margin, width - margin, margin, width - margin, height - margin, margin, height - margin};
        
        for (int i = 0; i < 4; i++)
        {
            UIButton *button = [UIButton buttonWithType: UIButtonTypeCustom];
            [button setFrame: CGRectMake(0, 0, 60, 60)];
            
            if (grid != nil)
            {
                CGPoint point = [grid getCornerAtZeroBasedIndex: i];
                [button setCenter: CGPointMake(point.x, point.y)];
            }
            else
            {
                [button setCenter: CGPointMake(defaultPositions[i * 2], defaultPositions[i * 2 + 1])];
            }
            
            self.HasCornerPostionChanged = false;
            
            [button setImage: targetImage forState: UIControlStateNormal];
            [button setTag: i];
            
            button.exclusiveTouch = YES;
            
            UILongPressGestureRecognizer* gestureMagnifier = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(handleMagnifier:)];
            gestureMagnifier.minimumPressDuration = 0.1;
            [button addGestureRecognizer: gestureMagnifier];
            
            [self.buttons addObject: button];
            
            [self.grid setCorner:button.center atZeroBasedIndex:i];
        }
        
        for (UIButton *button in self.buttons)
        {
            [self addSubview: button];
        }
    }
    
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [self updateAfterZoom];
}

float deltaTouchX, deltaTouchY;

//- (CGPoint) boundLocationAtX: (int) x andY: (int) y withFrame:(CGRect) frame
//{
//    if (x < frame.origin.x)
//        x = frame.origin.x;
//    else if (x > frame.origin.x + frame.size.width)
//        x = frame.origin.x + frame.size.width;
//
//    if (y < frame.origin.y)
//        y = frame.origin.y;
//    else if (y > frame.origin.y + frame.size.height)
//        y = frame.origin.y + frame.size.height;
//
//    return CGPointMake(x, y);
//}

- (void) handleMagnifier: (UILongPressGestureRecognizer*) recognizer
{
    //NSLog(@"(imgview = %i, %i)", (int) self.imageView.bounds.size.width, (int) self.imageView.bounds.size.height);
    
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
            _magnifier.touchPoint = imageViewLocation;
            
            [_magnifier trySetPosition:imageViewLocation];
            
            [_magnifier addToPreconfiguredView];
            [_magnifier setNeedsDisplay];
        }
        break;
            
        case UIGestureRecognizerStateChanged:
        {
            // offset the touchlocation to be consistent with the button's center
            location = CGPointMake(location.x - deltaTouchX, location.y - deltaTouchY);

            CGPoint imageViewLocation = [self convertPoint: location toView: self.imageView];
            _magnifier.touchPoint = imageViewLocation;
            
            //NSLog(@"(loc = %i, %i)", (int) imageViewLocation.x, (int) imageViewLocation.y);
            
            if (imageViewLocation.x < 0 || imageViewLocation.x > self.imageView.bounds.size.width)
                break;
            
            if (imageViewLocation.y < 0 || imageViewLocation.y > self.imageView.bounds.size.height)
                break;
            
            bool canMove = [_magnifier trySetPosition:imageViewLocation];
           
            if (canMove)
            {
                [_magnifier setNeedsDisplay];
                
                button.center = location;
                
                [self.grid setCorner:imageViewLocation atZeroBasedIndex:button.tag];
                
                self.HasCornerPostionChanged = true;
                
                [self updateGrid];
            }
        }
        break;
            
        case UIGestureRecognizerStateEnded:
        {
            //NSLog(@"handleLongPress: StateEnded");
            [_magnifier removeFromPreconfiguredView];
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
    
    CGPoint pointInImageView = [self convertPoint: center toView: self.imageView];
    [self.grid setCorner: pointInImageView atZeroBasedIndex:button.tag];
    
    [self updateGrid];
}

- (void) updateAfterZoom
{
    for (UIButton *button in self.buttons)
    {
        CGPoint cornerPoint = [self.grid getCornerAtZeroBasedIndex:button.tag];
        CGPoint viewPoint = [self.imageView convertPoint: cornerPoint toView: self];
        
        NSLog(@"updateAfterZoom: set button from (%.0f, %.0f) to (%.0f, %.0f)", button.center.x, button.center.y, viewPoint.x, viewPoint.y);
        
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
    
//    //CGMutablePathRef path = CGPathCreateMutable();
//    
//    //CGContextBeginPath(context);
//    CGContextAddRect(context, CGRectMake(1000, 1000, 800, 800));
//    //CGContextAddRect(context, CGRectMake(1500, 1500, 400, 400));
//    
//    //CGContextClosePath(context);
//    CGContextClip(context);
//    
////    CGContextMoveToPoint(context, 500, 500);
////    CGContextAddLineToPoint(context, 1500, 500);
////    CGContextAddLineToPoint(context, 1500, 1500);
////    CGContextAddLineToPoint(context, 500, 1500);
////    CGContextClosePath(context);
//    
//    // Inner subpath: the area inside the whole rect
//    //CGContextMoveToPoint(context, 1000, 1000);
//    // Close the inner subpath
//    //CGContextClosePath(context);
//    
//    //CGContextAddRect(context, CGRectInfinite);
//    //CGContextAddPath(context, path);
//    //CGContextEOClip(context);
//    
//    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:50/255. green:57/255. blue:63/255. alpha: 1].CGColor);    // Fill the path
//    CGContextFillRect(context, rect);
//    CGContextDrawPath(context, kCGPathEOFill);
//    
//    
//    
//    //CGPathRelease(path);
//
//    return;
    
    
    CGContextSetShouldAntialias(context, YES);
    
    PerspectiveGrid pg;
    
    cv::vector<cv::Point> cornerPoints = [self getCornersAsVector: self.grid];

    cv::vector<cv::Point> sortedCorners = pg.sortCorners(cornerPoints);

    if (pg.checkPolygonIsConvex(sortedCorners))
    {
        
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:50/255. green:50/255. blue:200/255. alpha: 1].CGColor);
        [self drawGrid: context withGrid: self.grid withRows: gridSize withCols: gridSize];
    }
    
    // Draw the outline
    
    CGContextSetLineWidth(context, 2.0);
    
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:180/255. green:57/255. blue:63/255. alpha: 1].CGColor);
    
    CGContextBeginPath(context);
    
    int midX = 0;
    int midY = 0;
    
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
        
        midX += viewPoint.x;
        midY += viewPoint.y;
    }
    
    CGContextClosePath(context);
    
    CGContextStrokePath(context);
    
    /*
    CGContextSaveGState(context);
    {
        CGContextBeginPath(context);
        CGContextAddPath(context, path);
        CGContextAddRect(context, CGRectInfinite);
        CGContextEOClip(context);
        
        // drawing code here is clipped to the exterior of myRect
        CGContextSetFillColorWithColor(context, [UIColor orangeColor].CGColor);
        CGContextFillRect(context, rect);
        
    }
    CGContextRestoreGState(context);*/
    }

- (cv::vector<cv::Point>) getCornersAsVector:(PKGrid *) grid
{
    cv::vector<cv::Point> cornerPoints;
    
    for (int i = 0 ; i < 4; i++)
    {
        CGPoint cornerPoint = [grid getCornerAtZeroBasedIndex:i];
        
        cornerPoints.push_back(cv::Point(cornerPoint.x, cornerPoint.y));
    }
    
    return cornerPoints;
}

- (void) drawGrid: (CGContextRef) context withGrid: (PKGrid *) grid withRows: (int) rows withCols: (int) cols
{
    cv::vector<cv::Point> cornerPoints = [self getCornersAsVector:grid];
    
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
