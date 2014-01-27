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

- (id) initWithFrame: (CGRect) frame andBoundingView: (UIView *) boundingView
{
    return [self initWithFrame: frame andRadius: 118 andBoundingView: (UIView *) boundingView];
}

- (id) initWithFrame: (CGRect) frame andRadius: (int) r andBoundingView: (UIView *) boundingView
{
    int radius = r;
    
    _boundingView = boundingView;
    
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

- (void) addToPreconfiguredView
{
    //[_parentView addSubview: self];
    
    [[[[UIApplication sharedApplication] delegate] window] addSubview: self];
}

- (void) removeFromPreconfiguredView
{
    [self removeFromSuperview];
}

- (bool) trySetPosition:(CGPoint)center
{
    // Ugly: should not rely on the superview to be the top level view
    
    UIScrollView * scrollView = (UIScrollView *) _boundingView;
    
    
    float origX = 0;
    float origY = 0;
    float widthCropper = 0;
    float heightCropper = 0;
    
    
    if (scrollView.contentOffset.x > 0){
        origX = (scrollView.contentOffset.x) * (1/scrollView.zoomScale);
    }
    if (scrollView.contentOffset.y > 0){
        origY = (scrollView.contentOffset.y) * (1/scrollView.zoomScale);
    }
    widthCropper = (scrollView.frame.size.width * (1/scrollView.zoomScale));
    heightCropper = (scrollView.frame.size.height * (1/scrollView.zoomScale));
    
    NSLog(@"center = (%i, %i) x = %i, y = %i, w = %i, h = %i", (int) center.x, (int) center.y, (int) origX, (int) origY, (int) widthCropper, (int) heightCropper);
    
    UIView *topLevelView = [_boundingView superview];
    
    CGPoint imageViewLocation = [topLevelView convertPoint: center fromView: viewToMagnify];
 
    CGRect bounds = _boundingView.frame;
    
    if (imageViewLocation.x < 0 || imageViewLocation.x > bounds.size.width)
        return false;
    
    if (imageViewLocation.y < 0 || imageViewLocation.y > bounds.size.height)
        return false;
    
    self.center = CGPointMake(imageViewLocation.x, imageViewLocation. y - 16);
    
    return true;
}

- (void) setTouchPoint: (CGPoint) pt
{
    touchPoint = pt;
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
    
//    float magnifyScale = MIN(scrollView.zoomScale * 1.5, scrollView.maximumZoomScale);
    float magnifyScale = scrollView.zoomScale * 1.5;
    
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