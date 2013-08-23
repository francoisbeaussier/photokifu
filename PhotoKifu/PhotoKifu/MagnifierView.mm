//
//  MagnifierView.m
//  PhotoKifu2
//
//  Created by Francois Beaussier on 20/06/13.
//  Copyright (c) 2013 Francois Beaussier. All rights reserved.
//

//
//  MagnifierView.m
//  SimplerMaskTest
//

#import "MagnifierView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MagnifierView
@synthesize viewToMagnify;
@dynamic touchPoint;

- (id) initWithFrame: (CGRect) frame
{
    return [self initWithFrame: frame radius: 118];
}

- (id) initWithFrame: (CGRect) frame radius: (int)r
{
    int radius = r;
    
    if ((self = [super initWithFrame: CGRectMake(0, 0, radius, radius)]))
    {
        //Make the layer circular.
        self.layer.cornerRadius = radius / 2;
        self.layer.masksToBounds = YES;
        
        mask = [UIImage imageNamed: @"magnify-mask@2x.png"].CGImage;
        glass = [UIImage imageNamed: @"magnify@2x.png"];

    }
    
    return self;
}

- (void) setTouchPoint: (CGPoint) pt
{
    touchPoint = pt;
    // whenever touchPoint is set, update the position of the magnifier (to just above what's being magnified)
//    self.center = CGPointMake(pt.x, pt.y-66);
    //NSLog(@"setTouchPoint (%i, %i)", (int) pt.x, (int) pt.y);

}

- (CGPoint)getTouchPoint
{
    return touchPoint;
}

- (void) drawRect: (CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    
    CGContextSaveGState(context);
    CGContextClipToMask(context, bounds, mask);
    CGContextFillRect(context, bounds);
    //CGContextScaleCTM(context, 1.2, 1.2);
    
    // this assumes that the viewToMagnify's superview is the scrollView, not so great
    UIScrollView *scrollView = (UIScrollView *) self.viewToMagnify.superview;
    
    float magnifyScale = MIN(scrollView.zoomScale * 1.5, scrollView.maximumZoomScale);
    
    CGContextTranslateCTM(context, 1 * (self.frame.size.width * 0.5), 1 * (self.frame.size.height * 0.5));
    CGContextScaleCTM(context, magnifyScale, magnifyScale);
    CGContextTranslateCTM(context, -1 * (touchPoint.x) , -1 * (touchPoint.y));
    
    [self.viewToMagnify.layer renderInContext: context];
    
//    self.viewToMagnify.layer ren
    
    CGContextRestoreGState(context);
    
    // draw crosshair
    
    CGContextSetLineWidth(context, 1.0);
    
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    
    CGContextMoveToPoint(context, 0, self.frame.size.height * 0.5);
    CGContextAddLineToPoint(context, self.frame.size.width, self.frame.size.height * 0.5);
    
    CGContextMoveToPoint(context, self.frame.size.width * 0.5, 0);
    CGContextAddLineToPoint(context, self.frame.size.width * 0.5, self.frame.size.height);
    
    CGContextStrokePath(context);
    
    // draw magnifying glass
    [glass drawInRect: bounds];
}

@end